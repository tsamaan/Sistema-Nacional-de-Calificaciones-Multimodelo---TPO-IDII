# 🎓 EduGrade Global - Sistema Nacional de Calificaciones Multimodelo

**Trabajo Práctico Obligatorio - Introducción al Diseño de Datos II**  
**UADE - Verano 2026**

---

## 📋 Índice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Arquitectura Multimodelo](#arquitectura-multimodelo)
3. [Flujo Completo de Datos](#flujo-completo-de-datos)
4. [Base de Datos MongoDB (RF1)](#mongodb-rf1---fuente-de-verdad)
5. [Base de Datos Redis (RF2)](#redis-rf2---cache-de-conversiones)
6. [Base de Datos Neo4j (RF3)](#neo4j-rf3---grafo-de-equivalencias)
7. [Base de Datos Cassandra (RF4, RF5)](#cassandra-rf4-rf5---analítica-y-auditoría)
8. [API REST y Endpoints](#api-rest-y-endpoints)
9. [Dataset de Prueba](#dataset-de-prueba)
10. [Cómo Ejecutar el Sistema](#cómo-ejecutar-el-sistema)

---

## 🎯 Resumen Ejecutivo

**EduGrade Global** es un sistema de gestión de calificaciones académicas internacionales que utiliza **4 bases de datos diferentes** (arquitectura multimodelo) para resolver diferentes requerimientos funcionales:

- **MongoDB**: Fuente de verdad transaccional con consistencia fuerte
- **Redis**: Cache de alta velocidad para conversiones entre sistemas educativos
- **Neo4j**: Grafo de relaciones académicas y equivalencias
- **Cassandra**: Analítica distribuida y auditoría inmutable

El sistema permite gestionar calificaciones de estudiantes de diferentes países (Argentina, Sudáfrica, Reino Unido, Estados Unidos, Alemania) con sus respectivos sistemas de calificación, y convertirlas a un sistema unificado (ZA7) para comparaciones internacionales.

---

## 🏗️ Arquitectura Multimodelo

### Diagrama de Alto Nivel

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CLIENTE / USUARIO                               │
│                    (Profesores, Administradores)                        │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ HTTP REST
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         API REST (Node.js)                              │
│                         Puerto 3000                                     │
│                                                                         │
│  Endpoints:                                                             │
│  • /api/mongodb/*      - CRUD calificaciones                           │
│  • /api/redis/*        - Conversiones y cache                          │
│  • /api/neo4j/*        - Consultas de grafo                            │
│  • /api/cassandra/*    - Analítica y auditoría                         │
└─────────────────────────────────────────────────────────────────────────┘
         │                    │                   │                   │
         │                    │                   │                   │
         ▼                    ▼                   ▼                   ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   MONGODB       │  │     REDIS       │  │    NEO4J        │  │   CASSANDRA     │
│   Puerto 27017  │  │   Puerto 6379   │  │   Puerto 7687   │  │   Puerto 9042   │
│                 │  │                 │  │                 │  │                 │
│  RF1: Fuente    │  │  RF2: Cache de  │  │  RF3: Grafo de  │  │  RF4: Analítica │
│  de Verdad      │  │  Conversiones   │  │  Equivalencias  │  │  RF5: Auditoría │
│                 │  │                 │  │                 │  │                 │
│  Write: MAJORITY│  │  TTL: 24h       │  │  Read-Heavy     │  │  RF4: ONE       │
│  Read: PRIMARY  │  │  In-Memory      │  │  ACID Local     │  │  RF5: QUORUM    │
│                 │  │                 │  │                 │  │                 │
└─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘
        │                    │                   │                   │
        ▼                    ▼                   ▼                   ▼
   Persistencia          Reglas de          Relaciones          Agregados +
   Inmutable            Conversión          Académicas          Event Logs
   + Snapshots          Versionadas         + Trayectorias      Inmutables
```

---

## 🔄 Flujo Completo de Datos

### Secuencia de Interacción Entre Modelos

```
════════════════════════════════════════════════════════════════════════════
                    FLUJO DE ALTA DE CALIFICACIÓN
════════════════════════════════════════════════════════════════════════════

[1] CLIENTE
     │
     │ POST /api/mongodb/calificaciones
     │ Body: { student_id, original_grade: { system: "AR", value: 8 }, ... }
     │
     ▼
[2] API REST (Node.js)
     │
     │ Valida datos de entrada
     │ Genera record_id único (GR-2025-0001)
     │ Calcula hash SHA256 para inmutabilidad
     │
     ▼
════════════════════════════════════════════════════════════════════════════
                          FASE 1: PERSISTENCIA
════════════════════════════════════════════════════════════════════════════

[3] MONGODB (RF1) - ✅ FUENTE DE VERDAD
     │
     │ db.calificaciones.insertOne({
     │   _id: "GR-2025-0001",
     │   student_id: "STU-0001",
     │   original_grade: {
     │     system: "AR",
     │     value: 8,
     │     passed: true
     │   },
     │   conversiones: [],  ← Vacío inicialmente
     │   immutability: {
     │     hash: "abc123...",
     │     created_at: ISODate("2025-01-15T10:30:00Z")
     │   }
     │ })
     │
     │ Write Concern: MAJORITY (espera mayoría de réplicas)
     │ ⏱️ ~50-100ms
     │
     ▼ ✅ PERSISTIDO

════════════════════════════════════════════════════════════════════════════
                          FASE 2: AUDITORÍA
════════════════════════════════════════════════════════════════════════════

[4] CASSANDRA (RF5) - 📝 REGISTRO DE AUDITORÍA
     │
     │ INSERT INTO edugrade_auditoria.registro_auditoria_por_entidad_mes
     │ (
     │   id_entidad,           → "GR-2025-0001"
     │   aaaamm,               → "202501"
     │   marca_tiempo,         → 2025-01-15 10:30:00
     │   tipo_entidad,         → "GRADE"
     │   accion,               → "GRADE_CREATED"
     │   id_actor,             → "profesor_matematica"
     │   hash_anterior,        → "0" (primera versión)
     │   hash_nuevo,           → "abc123..." (enlace con MongoDB)
     │   carga_util            → JSON con datos completos
     │ )
     │
     │ Consistency Level: QUORUM (mayoría de réplicas)
     │ ⏱️ ~30-50ms
     │ Append-only: NUNCA se modifica ni elimina
     │
     ▼ ✅ AUDITADO

════════════════════════════════════════════════════════════════════════════
                        FASE 3: GRAFO ACADÉMICO
════════════════════════════════════════════════════════════════════════════

[5] NEO4J (RF3) - 🕸️ RELACIONES ACADÉMICAS
     │
     │ // Crear nodo de calificación
     │ CREATE (g:GradeRecord {
     │   record_id: "GR-2025-0001",
     │   system: "AR",
     │   value: 8,
     │   year: 2025,
     │   term: "T1",
     │   passed: true
     │ })
     │
     │ // Relacionar con estudiante
     │ MATCH (s:Student {student_id: "STU-0001"})
     │ CREATE (s)-[:HAS_RECORD {date: datetime()}]->(g)
     │
     │ // Relacionar con institución
     │ MATCH (i:Institution {institution_id: "INS-003"})
     │ CREATE (g)-[:AT_INSTITUTION]->(i)
     │
     │ // Relacionar con materia
     │ MATCH (sub:Subject {subject_id: "SUB-MATH", system: "AR"})
     │ CREATE (g)-[:FOR_SUBJECT]->(sub)
     │
     │ ⏱️ ~20-40ms por transacción
     │
     ▼ ✅ GRAFO ACTUALIZADO

════════════════════════════════════════════════════════════════════════════
                     FASE 4: CONVERSIÓN A SISTEMA UNIFICADO
                         (Solo cuando se solicita)
════════════════════════════════════════════════════════════════════════════

[6] CLIENTE
     │
     │ GET /api/redis/conversion?record_id=GR-2025-0001&to_system=ZA7
     │
     ▼

[7] REDIS (RF2) - 🔄 CACHE DE CONVERSIONES
     │
     │ PASO 7.1: Buscar versión activa de regla
     │ GET regla_activa:AR#ZA7:MINISTERIO:SECUNDARIO:2025
     │ → Retorna: "1"
     │
     │ PASO 7.2: Verificar cache
     │ GET conv:GR-2025-0001:ZA7:1
     │ ❌ CACHE MISS
     │
     │ PASO 7.3: Leer regla de conversión
     │ HGETALL regla:AR#ZA7:MINISTERIO:SECUNDARIO:2025:1
     │ → {
     │     from: "AR",
     │     to: "ZA7",
     │     metodo: "tabla",
     │     mapping: "{\"8\": 6, \"9\": 6, \"10\": 7}"
     │   }
     │
     │ PASO 7.4: Calcular conversión
     │ AR(8) → ZA7(6)  ← Aplicar mapping
     │
     │ PASO 7.5: Cachear resultado
     │ SETEX conv:GR-2025-0001:ZA7:1 86400 "{\"za_1_7\": 6}"
     │ TTL: 86400 segundos (24 horas)
     │
     │ ⏱️ ~5-10ms
     │
     ▼ ✅ CONVERSIÓN CALCULADA

[8] MONGODB (RF1) - 💾 PERSISTIR CONVERSIÓN
     │
     │ db.calificaciones.updateOne(
     │   { _id: "GR-2025-0001" },
     │   {
     │     $push: {
     │       conversiones: {
     │         to: "ZA7",
     │         version_regla: 1,
     │         resultado: { za_1_7: 6 },
     │         timestamp: ISODate("2025-01-15T10:35:00Z")
     │       }
     │     }
     │   }
     │ )
     │
     │ ⚠️ IMPORTANTE: El campo "original_grade" NUNCA se modifica (inmutable)
     │ Las conversiones se agregan al array "conversiones"
     │
     ▼ ✅ CONVERSIÓN PERSISTIDA

════════════════════════════════════════════════════════════════════════════
                        FASE 5: ANALÍTICA (ASÍNCRONA)
════════════════════════════════════════════════════════════════════════════

[9] CASSANDRA (RF4) - 📊 AGREGADOS ANALÍTICOS
     │
     │ PASO 9.1: Insertar en fact table
     │ INSERT INTO edugrade_analitica.rf4_fact_grades_by_region_year_system
     │ (
     │   region,              → "AR-CABA"
     │   academic_year,       → 2025
     │   system,              → "AR"
     │   grade_id,            → "GR-2025-0001"
     │   institution_id,      → "INS-003"
     │   subject_id,          → "SUB-MATH"
     │   original_value,      → "8"
     │   normalized_value,    → 80.0 (para escala 0-100)
     │   passed,              → true
     │   timestamp            → 2025-01-15 10:30:00
     │ )
     │ Consistency Level: ONE (máxima velocidad)
     │
     │ PASO 9.2: Actualizar agregados
     │ UPDATE edugrade_analitica.promedio_por_region_anio
     │ SET
     │   n = n + 1,                    ← Contador de registros
     │   suma = suma + 80.0,           ← Suma para promedio
     │   suma_cuadrados = suma_cuadrados + 6400.0,  ← Para desv. std.
     │   actualizado_en = now()
     │ WHERE
     │   region = 'AR-CABA' AND
     │   anio = 2025 AND
     │   codigo_sistema = 'AR' AND
     │   id_materia = 'SUB-MATH' AND
     │   id_institucion = 'INS-003'
     │
     │ ⏱️ ~10-20ms
     │ Eventual Consistency OK (para reportes)
     │
     ▼ ✅ ANALÍTICA ACTUALIZADA

════════════════════════════════════════════════════════════════════════════
                           RESUMEN DEL FLUJO
════════════════════════════════════════════════════════════════════════════

┌────────────┬───────────────────┬──────────────┬──────────────────────────┐
│ FASE       │ BASE DE DATOS     │ LATENCIA     │ PROPÓSITO                │
├────────────┼───────────────────┼──────────────┼──────────────────────────┤
│ 1. Persist │ MongoDB (RF1)     │ ~50-100ms    │ Fuente de verdad         │
│ 2. Audit   │ Cassandra (RF5)   │ ~30-50ms     │ Trazabilidad inmutable   │
│ 3. Graph   │ Neo4j (RF3)       │ ~20-40ms     │ Relaciones académicas    │
│ 4. Convert │ Redis (RF2)       │ ~5-10ms      │ Conversión + Cache       │
│ 5. Analyt  │ Cassandra (RF4)   │ ~10-20ms     │ Reportes y estadísticas  │
└────────────┴───────────────────┴──────────────┴──────────────────────────┘

LATENCIA TOTAL (síncrona): ~100-190ms
LATENCIA TOTAL (+ async):  ~120-230ms

✅ Consistencia fuerte: MongoDB (RF1) + Cassandra (RF5)
⚡ Consistency eventual: Cassandra (RF4), Redis (RF2)
```

---

## 🍃 MongoDB (RF1) - Fuente de Verdad

### Propósito

MongoDB es la **única fuente de verdad** del sistema. Cada calificación se persiste aquí primero con:

- **Write Concern: MAJORITY** - Espera confirmación de la mayoría de réplicas
- **Read Preference: PRIMARY** - Siempre lee del nodo primario
- **Inmutabilidad** - Los datos originales nunca se modifican
- **Snapshots** - Captura el estado completo de estudiante, institución y materia

### Colecciones Principales

#### 1. `calificaciones` (Colección principal)

```javascript
{
  _id: "GR-2025-0001",
  record_id: "GR-2025-0001",
  student_id: "STU-0001",
  zone: "AR-CABA",
  
  // Snapshot del estudiante (inmutable)
  student_snapshot: {
    full_name: "Sofía Danko",
    dob: ISODate("2006-11-02T00:00:00Z"),
    nationality: "AR"
  },
  
  // Snapshot de la institución (inmutable)
  institution_snapshot: {
    institution_id: "INS-003",
    name: "UADE Argentina",
    country: "AR",
    region: "CABA"
  },
  
  // Contexto académico
  academic_context: {
    academic_year: 2025,
    term: "T1",
    level: "post_secondary",
    cycle: "University"
  },
  
  // Snapshot de la materia (inmutable)
  subject_snapshot: {
    subject_id: "SUB-CS",
    name: "Introducción al Diseño de Datos II",
    course_code: "CS-202"
  },
  
  // Evaluación
  evaluation: {
    type: "final",
    date: ISODate("2025-01-15T10:00:00Z"),
    components: [
      {
        component_type: "exam",
        weight: 1.0,
        raw: { grade: 8 }
      }
    ]
  },
  
  // Calificación original (INMUTABLE)
  original_grade: {
    system: "AR",
    scale_type: "numeric",
    value: 8,
    passed: true,
    details: {
      qualification: "Aprobado"
    }
  },
  
  // Conversiones (se agregan dinámicamente)
  conversiones: [
    {
      to: "ZA7",
      version_regla: 1,
      resultado: { za_1_7: 6 },
      timestamp: ISODate("2025-01-15T10:35:00Z")
    },
    {
      to: "US",
      version_regla: 1,
      resultado: { gpa: 3.3, letter: "B+" },
      timestamp: ISODate("2025-01-16T14:20:00Z")
    }
  ],
  
  // Inmutabilidad y trazabilidad
  immutability: {
    created_at: ISODate("2025-01-15T10:30:00Z"),
    created_by: "profesor_matematica",
    immutable_id: "imm_GR-2025-0001_v1",
    integrity_hash_sha256: "abc123def456..."
  },
  
  // Historial de cambios (correcciones)
  history: []
}
```

#### 2. `estudiantes`

```javascript
{
  _id: ObjectId("..."),
  student_id: "STU-0001",
  full_name: "Sofía Danko",
  documento: {
    tipo: "DNI",
    numero: "40123456"
  },
  dob: ISODate("2006-11-02T00:00:00Z"),
  nationality: "AR",
  region: "AR-CABA",
  academic_history: [
    {
      country: "AR",
      instance_type: "secondary",
      board: "Ministerio de Educación"
    }
  ],
  created_at: ISODate("2023-01-10T00:00:00Z"),
  updated_at: ISODate("2025-01-15T10:30:00Z")
}
```

#### 3. `instituciones`

```javascript
{
  _id: ObjectId("..."),
  institution_id: "INS-003",
  nombre: "UADE Argentina",
  pais: "AR",
  region: "CABA",
  codigo_sistema: "AR",
  codigo_externo: "UADE",
  metadata: {
    tipo: "Universidad Privada",
    fundacion: 1957
  },
  created_at: ISODate("2020-01-01T00:00:00Z")
}
```

#### 4. `materias`

```javascript
{
  _id: ObjectId("..."),
  subject_id: "SUB-CS",
  nombre: "Introducción al Diseño de Datos II",
  id_institucion: "INS-003",
  codigo_sistema: "AR",
  codigo_externo: "CS-202",
  metadata: {
    creditos: 6,
    nivel: "segundo_año"
  },
  created_at: ISODate("2023-01-01T00:00:00Z")
}
```

#### 5. `trayectorias`

```javascript
{
  _id: ObjectId("..."),
  trayectoria_id: "TRAY-002",
  student_id: "STU-0002",
  institution_id: "INS-003",
  fecha_inicio: ISODate("2023-03-01T00:00:00Z"),
  fecha_fin: null,
  estado: "activo",
  records: ["GR-2025-0001", "GR-2024-0007"]
}
```

### Índices MongoDB

```javascript
// calificaciones
db.calificaciones.createIndex({ record_id: 1 }, { unique: true })
db.calificaciones.createIndex({ student_id: 1 })
db.calificaciones.createIndex({ "original_grade.system": 1 })
db.calificaciones.createIndex({ "academic_context.academic_year": 1 })

// estudiantes
db.estudiantes.createIndex({ student_id: 1 }, { unique: true })
db.estudiantes.createIndex({ "documento.tipo": 1, "documento.numero": 1 }, { unique: true })

// instituciones
db.instituciones.createIndex({ institution_id: 1 }, { unique: true })

// materias
db.materias.createIndex({ subject_id: 1, id_institucion: 1 })

// trayectorias
db.trayectorias.createIndex({ student_id: 1 })
db.trayectorias.createIndex({ institution_id: 1 })
```

### Garantías de Consistencia

- **Atomicidad**: Cada operación en un documento es atómica
- **Durabilidad**: Write Concern MAJORITY asegura persistencia antes de confirmar
- **Inmutabilidad**: El campo `original_grade` nunca se modifica
- **Versionado**: Las correcciones crean nuevos documentos con `version` incrementado

---

## 🔴 Redis (RF2) - Cache de Conversiones

### Propósito

Redis actúa como **cache de alta velocidad** para:

1. **Conversiones entre sistemas educativos**: AR ↔ ZA7, UK ↔ US, etc.
2. **Reglas de conversión versionadas**: Permite actualizar reglas sin impactar cálculos históricos
3. **Pattern cache-aside**: Primero busca en cache, si no existe, calcula y cachea
4. **TTL de 24 horas**: Las conversiones se invalidan automáticamente

### Estructura de Datos

#### 1. Reglas de Conversión (Hash)

```redis
# Key: regla:{from}#{to}:{authority}:{level}:{year}:{version}
# Type: HASH

HGETALL regla:AR#ZA7:MINISTERIO:SECUNDARIO:2025:1
{
  "from": "AR",
  "to": "ZA7",
  "authority": "MINISTERIO",
  "level": "SECUNDARIO",
  "year": "2025",
  "version": "1",
  "method": "tabla",
  "mapping": "{\"1\":1,\"2\":1,\"3\":2,\"4\":3,\"5\":4,\"6\":4,\"7\":5,\"8\":6,\"9\":6,\"10\":7}",
  "created_at": "2025-01-01T00:00:00Z",
  "created_by": "admin_sistema"
}
```

#### 2. Versión Activa de Regla (String)

```redis
# Key: regla_activa:{from}#{to}:{authority}:{level}:{year}
# Type: STRING

GET regla_activa:AR#ZA7:MINISTERIO:SECUNDARIO:2025
→ "1"  # Versión activa actual
```

#### 3. Cache de Conversiones (String con TTL)

```redis
# Key: conv:{record_id}:{to_system}:{version}
# Type: STRING
# TTL: 86400 segundos (24 horas)

GET conv:GR-2025-0001:ZA7:1
→ '{"za_1_7":6,"timestamp":"2025-01-15T10:35:00Z"}'
```

#### 4. Índice de Conversiones por Sistema (Set)

```redis
# Key: conversiones_calculadas:{system}
# Type: SET

SMEMBERS conversiones_calculadas:ZA7
→ ["GR-2025-0001", "GR-2025-0003", "GR-2024-0008"]
```

### Flujo de Conversión (Cache-Aside Pattern)

```
┌─────────────────────────────────────────────────────────────┐
│ CLIENTE solicita conversión                                 │
│ GET /api/redis/conversion?record_id=GR-2025-0001&to=ZA7    │
└─────────────────────────────────────────────────────────────┘
                          ⬇️
┌─────────────────────────────────────────────────────────────┐
│ PASO 1: Obtener datos originales de MongoDB                │
│ db.calificaciones.findOne({_id: "GR-2025-0001"})          │
│ → { system: "AR", value: 8 }                               │
└─────────────────────────────────────────────────────────────┘
                          ⬇️
┌─────────────────────────────────────────────────────────────┐
│ PASO 2: Buscar versión activa de regla en Redis            │
│ GET regla_activa:AR#ZA7:MINISTERIO:SECUNDARIO:2025        │
│ → "1"                                                       │
└─────────────────────────────────────────────────────────────┘
                          ⬇️
┌─────────────────────────────────────────────────────────────┐
│ PASO 3: Verificar cache                                    │
│ GET conv:GR-2025-0001:ZA7:1                                │
└─────────────────────────────────────────────────────────────┘
         ⬇️ CACHE MISS                           ⬇️ CACHE HIT
┌──────────────────────────┐         ┌─────────────────────────┐
│ PASO 4: Leer regla       │         │ PASO 4b: Retornar cache │
│ HGETALL regla:AR#ZA7:... │         │ → {za_1_7: 6}          │
│ → {mapping: {...}}       │         └─────────────────────────┘
└──────────────────────────┘
         ⬇️
┌──────────────────────────┐
│ PASO 5: Calcular         │
│ AR(8) → ZA7(6)          │
└──────────────────────────┘
         ⬇️
┌──────────────────────────────────────────────────────────────┐
│ PASO 6: Cachear resultado                                    │
│ SETEX conv:GR-2025-0001:ZA7:1 86400 '{"za_1_7":6}'         │
│ SADD conversiones_calculadas:ZA7 "GR-2025-0001"            │
└──────────────────────────────────────────────────────────────┘
         ⬇️
┌──────────────────────────────────────────────────────────────┐
│ PASO 7: Persistir en MongoDB                                 │
│ db.calificaciones.updateOne(                                │
│   {_id: "GR-2025-0001"},                                     │
│   {$push: {conversiones: {to: "ZA7", resultado: ...}}}      │
│ )                                                            │
└──────────────────────────────────────────────────────────────┘
```

### Sistemas de Calificación Soportados

| Sistema | País | Escala | Ejemplo |
|---------|------|--------|---------|
| **AR** | Argentina | 1-10 (numérico) | 8 = Aprobado |
| **US** | Estados Unidos | GPA 0.0-4.0 + Letras | A (4.0) = Excelente |
| **UK** | Reino Unido | A\*-U (letras) | A\* = Máxima distinción |
| **DE** | Alemania | 1.0-6.0 (numérico) | 1.0 = Sehr gut |
| **ZA** | Sudáfrica | 1-7 (numérico) | 7 = Distinción |
| **ZA7** | Sistema Unificado | 1-7 (normalizado) | Escala de referencia |

### Ventajas de Redis

- ⚡ **Latencia ultra-baja**: ~1-5ms para operaciones GET/SET
- 🔄 **Versionado de reglas**: Permite cambiar conversiones sin afectar historial
- ♻️ **TTL automático**: Cache se limpia solo después de 24 horas
- 📊 **Trazabilidad**: Cada conversión sabe qué versión de regla usó

---

## 🟢 Neo4j (RF3) - Grafo de Equivalencias

### Propósito

Neo4j modela las **relaciones académicas** como un grafo, permitiendo consultas complejas sobre:

- **Trayectorias académicas**: ¿Por qué instituciones pasó un estudiante?
- **Equivalencias entre materias**: ¿"Mathematics" de UK equivale a "Matemática" de AR?
- **Prerequisitos**: ¿Qué materias debe aprobar antes de cursar otra?
- **Análisis de cohortes**: ¿Qué estudiantes cursaron juntos?

### Modelo de Grafo

```
┌─────────────────────────────────────────────────────────────────────┐
│                         MODELO DE GRAFO                             │
└─────────────────────────────────────────────────────────────────────┘

    (Student)                                         (Institution)
        │                                                    │
        │ [:HAS_RECORD {date}]                              │
        │                                                    │
        ▼                                                    │
 (GradeRecord) ──────[:AT_INSTITUTION]──────────────────────┘
        │
        │ [:FOR_SUBJECT]
        │
        ▼
    (Subject:AR) ─────[:EQUIVALENT_TO {confidence}]─────> (Subject:UK)
        │                                                    │
        │ [:REQUIRES]                                        │
        ▼                                                    │
    (Subject:AR)                                        (Subject:UK)
  "Matemática II"                                    "Mathematics A-Level"
```

### Nodos Principales

#### 1. Student (Estudiante)

```cypher
CREATE (s:Student {
  student_id: "STU-0001",
  full_name: "Sofía Danko",
  nationality: "AR",
  dob: date("2006-11-02")
})
```

#### 2. Institution (Institución)

```cypher
CREATE (i:Institution {
  institution_id: "INS-003",
  name: "UADE Argentina",
  country: "AR",
  region: "CABA",
  system: "AR"
})
```

#### 3. Subject (Materia con sistema)

```cypher
// Materia en sistema argentino
CREATE (sub_ar:Subject:AR {
  subject_id: "SUB-MATH",
  name: "Matemática",
  system: "AR",
  level: "secondary"
})

// Materia equivalente en sistema británico
CREATE (sub_uk:Subject:UK {
  subject_id: "SUB-MATH",
  name: "Mathematics",
  system: "UK",
  level: "A-Level"
})

// Relación de equivalencia
CREATE (sub_ar)-[:EQUIVALENT_TO {
  confidence: 0.95,
  established_by: "academic_board",
  date: date("2025-01-01")
}]->(sub_uk)
```

#### 4. GradeRecord (Registro de calificación)

```cypher
CREATE (g:GradeRecord {
  record_id: "GR-2025-0001",
  system: "AR",
  value: 8,
  normalized_value: 6,  // Conversión a ZA7
  passed: true,
  academic_year: 2025,
  term: "T1",
  timestamp: datetime("2025-01-15T10:30:00Z")
})
```

### Relaciones Principales

#### 1. HAS_RECORD (Estudiante → Calificación)

```cypher
MATCH (s:Student {student_id: "STU-0001"})
MATCH (g:GradeRecord {record_id: "GR-2025-0001"})
CREATE (s)-[:HAS_RECORD {
  date: datetime(),
  record_date: datetime("2025-01-15T10:30:00Z")
}]->(g)
```

#### 2. AT_INSTITUTION (Calificación → Institución)

```cypher
MATCH (g:GradeRecord {record_id: "GR-2025-0001"})
MATCH (i:Institution {institution_id: "INS-003"})
CREATE (g)-[:AT_INSTITUTION]->(i)
```

#### 3. FOR_SUBJECT (Calificación → Materia)

```cypher
MATCH (g:GradeRecord {record_id: "GR-2025-0001"})
MATCH (sub:Subject:AR {subject_id: "SUB-MATH"})
CREATE (g)-[:FOR_SUBJECT]->(sub)
```

#### 4. ATTENDED (Estudiante → Institución)

```cypher
MATCH (s:Student {student_id: "STU-0001"})
MATCH (i:Institution {institution_id: "INS-003"})
CREATE (s)-[:ATTENDED {
  from_date: date("2023-03-01"),
  to_date: null,
  status: "active"
}]->(i)
```

#### 5. EQUIVALENT_TO (Materia ↔ Materia)

```cypher
MATCH (sub_ar:Subject:AR {subject_id: "SUB-MATH"})
MATCH (sub_uk:Subject:UK {subject_id: "SUB-MATH"})
CREATE (sub_ar)-[:EQUIVALENT_TO {
  confidence: 0.95,
  bidirectional: true
}]->(sub_uk)
```

#### 6. REQUIRES (Prerequisito)

```cypher
MATCH (sub1:Subject {subject_id: "SUB-MATH-II"})
MATCH (sub2:Subject {subject_id: "SUB-MATH-I"})
CREATE (sub1)-[:REQUIRES {
  minimum_grade: 4
}]->(sub2)
```

### Consultas Típicas en Neo4j

#### Consulta 1: Trayectoria completa de un estudiante

```cypher
MATCH path = (s:Student {student_id: "STU-0001"})-[:HAS_RECORD]->(g:GradeRecord)
            -[:AT_INSTITUTION]->(i:Institution)
RETURN s.full_name AS estudiante,
       i.name AS institucion,
       g.system AS sistema,
       g.value AS nota,
       g.academic_year AS año
ORDER BY g.academic_year DESC, g.timestamp DESC
```

#### Consulta 2: Materias equivalentes entre sistemas

```cypher
MATCH (sub1:Subject {system: "AR"})-[eq:EQUIVALENT_TO]-(sub2:Subject {system: "UK"})
RETURN sub1.name AS materia_ar,
       sub2.name AS materia_uk,
       eq.confidence AS confianza
ORDER BY eq.confidence DESC
```

#### Consulta 3: Estudiantes con calificaciones en múltiples países

```cypher
MATCH (s:Student)-[:HAS_RECORD]->(g:GradeRecord)-[:AT_INSTITUTION]->(i:Institution)
WITH s, COUNT(DISTINCT i.country) AS paises
WHERE paises > 1
RETURN s.full_name AS estudiante,
       paises AS cantidad_paises
ORDER BY paises DESC
```

#### Consulta 4: Prerequisitos para cursar una materia

```cypher
MATCH path = (materia:Subject {subject_id: "SUB-MATH-III"})
            -[:REQUIRES*1..3]->(prereq:Subject)
RETURN materia.name AS materia_objetivo,
       [node IN nodes(path) | node.name] AS cadena_prerequisitos
```

### Ventajas de Neo4j

- 🔍 **Consultas de trayectoria**: Encuentra paths complejos en milisegundos
- 🧩 **Equivalencias académicas**: Modela relaciones many-to-many naturalmente
- 📈 **Análisis de redes**: Identifica patrones en cohortes de estudiantes
- 🔗 **Relaciones tipadas**: Cada relación tiene semántica clara

---

## 🟣 Cassandra (RF4, RF5) - Analítica y Auditoría

### Propósito

Cassandra maneja **dos requerimientos funcionales distintos**:

- **RF4**: Analítica de calificaciones (eventual consistency)
- **RF5**: Auditoría de eventos (strong consistency)

Cada uno usa un **keyspace diferente** con configuraciones de replicación específicas.

---

### RF4: Analítica (Keyspace: `edugrade_analitica`)

#### Propósito

Permite consultas analíticas de alta velocidad sobre grandes volúmenes de calificaciones:

- Promedios por región/año/institución
- Comparaciones entre sistemas educativos
- Tasas de aprobación
- Distribución de calificaciones

#### Configuración

```cql
CREATE KEYSPACE edugrade_analitica
WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': 3
};
```

**Consistency Level para RF4: ONE** (prioriza velocidad sobre consistencia inmediata)

#### Tabla 1: `rf4_fact_grades_by_region_year_system` (Fact Table)

```cql
CREATE TABLE edugrade_analitica.rf4_fact_grades_by_region_year_system (
    region TEXT,
    academic_year INT,
    system TEXT,
    grade_id TEXT,
    institution_id TEXT,
    subject_id TEXT,
    student_id TEXT,
    original_value TEXT,
    normalized_value_0_100 DOUBLE,
    passed BOOLEAN,
    timestamp TIMESTAMP,
    PRIMARY KEY ((region, academic_year, system), grade_id)
) WITH CLUSTERING ORDER BY (grade_id ASC);
```

**Uso**: Almacena cada calificación individual con información dimensional

**Ejemplo de consulta**:

```cql
SELECT * FROM rf4_fact_grades_by_region_year_system
WHERE region = 'AR-CABA'
  AND academic_year = 2025
  AND system = 'AR';
```

#### Tabla 2: `rf4_report_by_region_year_system` (Agregados por institución/materia)

```cql
CREATE TABLE edugrade_analitica.rf4_report_by_region_year_system (
    region TEXT,
    academic_year INT,
    system TEXT,
    institution_id TEXT,
    subject_id TEXT,
    n INT,
    sum_normalized DOUBLE,
    sum_squared DOUBLE,
    avg_norm_0_100 DOUBLE,
    min_norm DOUBLE,
    max_norm DOUBLE,
    pass_count INT,
    fail_count INT,
    pass_rate DOUBLE,
    last_updated TIMESTAMP,
    PRIMARY KEY ((region, academic_year, system), institution_id, subject_id)
);
```

**Uso**: Estadísticas agregadas por institución y materia

**Ejemplo de consulta**:

```cql
SELECT institution_id, subject_id, avg_norm_0_100, pass_rate
FROM rf4_report_by_region_year_system
WHERE region = 'AR-CABA'
  AND academic_year = 2025
  AND system = 'AR';
```

#### Tabla 3: `rf4_report_by_region_year` (Agregados cross-system)

```cql
CREATE TABLE edugrade_analitica.rf4_report_by_region_year (
    region TEXT,
    academic_year INT,
    system TEXT,
    institution_id TEXT,
    subject_id TEXT,
    avg_norm_0_100 DOUBLE,
    pass_rate DOUBLE,
    n INT,
    PRIMARY KEY ((region, academic_year), system, institution_id, subject_id)
);
```

**Uso**: Comparar sistemas educativos en una misma región/año

**Ejemplo de consulta**:

```cql
SELECT system, institution_id, avg_norm_0_100, pass_rate
FROM rf4_report_by_region_year
WHERE region = 'ZA-CPT'
  AND academic_year = 2024;
```

#### Tabla 4: `promedio_por_region_anio` (Agregados simplificados)

```cql
CREATE TABLE edugrade_analitica.promedio_por_region_anio (
    region TEXT,
    anio INT,
    codigo_sistema TEXT,
    id_materia TEXT,
    id_institucion TEXT,
    n INT,
    suma DOUBLE,
    suma_cuadrados DOUBLE,
    actualizado_en TIMESTAMP,
    PRIMARY KEY ((region, anio, codigo_sistema), id_materia, id_institucion)
);
```

**Uso**: Cálculo de promedio y desviación estándar sin recorrer todas las filas

**Fórmulas**:

```
promedio = suma / n
varianza = (suma_cuadrados / n) - (promedio^2)
desviación_estándar = sqrt(varianza)
```

---

### RF5: Auditoría (Keyspace: `edugrade_auditoria`)

#### Propósito

Registro inmutable de **todos los eventos** del sistema para trazabilidad y cumplimiento normativo:

- Cadena de hashes enlaces (blockchain-style)
- Append-only (nunca se modifica ni elimina)
- Fuerte consistencia (QUORUM)
- Particionado por entidad + mes

#### Configuración

```cql
CREATE KEYSPACE edugrade_auditoria
WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': 3
};
```

**Consistency Level para RF5: QUORUM** (mayoría de réplicas confirma)

#### Tabla: `registro_auditoria_por_entidad_mes`

```cql
CREATE TABLE edugrade_auditoria.registro_auditoria_por_entidad_mes (
    id_entidad TEXT,
    aaaamm TEXT,
    marca_tiempo TIMESTAMP,
    tipo_entidad TEXT,
    accion TEXT,
    id_actor TEXT,
    ip TEXT,
    hash_anterior TEXT,
    hash_nuevo TEXT,
    carga_util TEXT,
    PRIMARY KEY ((id_entidad, aaaamm), marca_tiempo)
) WITH CLUSTERING ORDER BY (marca_tiempo DESC);
```

**Campos clave**:

- `id_entidad`: ID del objeto auditado (ej: "GR-2025-0001")
- `aaaamm`: Año-mes (ej: "202501") para particionamiento
- `marca_tiempo`: Timestamp exacto del evento
- `accion`: Tipo de evento (GRADE_CREATED, GRADE_UPDATED, etc.)
- `hash_anterior`: Hash del evento previo (cadena de bloques)
- `hash_nuevo`: Hash de este evento
- `carga_util`: JSON con datos completos del evento

**Ejemplo de registro**:

```cql
INSERT INTO registro_auditoria_por_entidad_mes (
    id_entidad, aaaamm, marca_tiempo,
    tipo_entidad, accion, id_actor, ip,
    hash_anterior, hash_nuevo, carga_util
) VALUES (
    'GR-2025-0001',
    '202501',
    '2025-01-15 10:30:00',
    'GRADE',
    'GRADE_CREATED',
    'profesor_matematica',
    '127.0.0.1',
    '0',  -- Primera entrada
    'abc123def456...',  -- Hash SHA256 de este registro
    '{"record_id":"GR-2025-0001","student_id":"STU-0001",...}'
);
```

**Consulta de auditoría**:

```cql
SELECT marca_tiempo, accion, id_actor, hash_nuevo
FROM registro_auditoria_por_entidad_mes
WHERE id_entidad = 'GR-2025-0001'
  AND aaaamm = '202501'
ORDER BY marca_tiempo DESC;
```

**Cadena de hashes**:

```
Evento 1: hash_anterior="0", hash_nuevo="abc123..."
    ↓
Evento 2: hash_anterior="abc123...", hash_nuevo="def456..."
    ↓
Evento 3: hash_anterior="def456...", hash_nuevo="ghi789..."
```

### Ventajas de Cassandra

- ⚡ **Escritura masiva**: Miles de inserts por segundo
- 📊 **Agregados precalculados**: No necesita recorrer millones de registros
- 🔒 **Inmutabilidad**: RF5 nunca modifica datos históricos
- 🌍 **Distribución geográfica**: Particiones por región optimizan latencia

---

## 🌐 API REST y Endpoints

### Servidor Node.js + Express

```javascript
// Estructura
api/
  server.js          ← Servidor principal
  routes/
    mongodb.js       ← Rutas para CRUD de calificaciones
    redis.js         ← Rutas para conversiones
    neo4j.js         ← Rutas para consultas de grafo
    cassandra.js     ← Rutas para analítica y auditoría
```

### Endpoints Principales

#### MongoDB (RF1)

```
POST   /api/mongodb/calificaciones           ← Crear calificación
GET    /api/mongodb/calificaciones/:id       ← Obtener por ID
GET    /api/mongodb/calificaciones/student/:student_id  ← Obtener por estudiante
PUT    /api/mongodb/calificaciones/:id       ← Actualizar calificación
DELETE /api/mongodb/calificaciones/:id       ← Eliminar (soft delete)

GET    /api/mongodb/estudiantes              ← Listar estudiantes
POST   /api/mongodb/estudiantes              ← Crear estudiante
GET    /api/mongodb/instituciones            ← Listar instituciones
GET    /api/mongodb/materias                 ← Listar materias
```

#### Redis (RF2)

```
GET    /api/redis/conversion?record_id={id}&to_system={system}  ← Convertir calificación
POST   /api/redis/reglas                     ← Crear regla de conversión
GET    /api/redis/reglas?from={sys}&to={sys}  ← Obtener reglas
GET    /api/redis/regla-activa?from={sys}&to={sys}  ← Ver versión activa
PUT    /api/redis/regla-activa               ← Activar versión de regla
GET    /api/redis/cache-stats                ← Estadísticas de cache
```

#### Neo4j (RF3)

```
GET    /api/neo4j/trayectoria/:student_id    ← Trayectoria de estudiante
GET    /api/neo4j/equivalencias?system_from={sys}&system_to={sys}  ← Materias equivalentes
GET    /api/neo4j/estudiantes-multicountry   ← Estudiantes con calificaciones en múltiples países
GET    /api/neo4j/prerequisitos/:subject_id  ← Prerequisitos de una materia
GET    /api/neo4j/cohorte/:institution_id/:year  ← Estudiantes de una cohorte
```

#### Cassandra RF4 (Analítica)

```
GET    /api/cassandra/analitica/facts?region={reg}&anio={year}&sistema={sys}  ← Fact table
GET    /api/cassandra/analitica/reportes?region={reg}&anio={year}&sistema={sys}  ← Agregados por institución
GET    /api/cassandra/analitica/cross-system?region={reg}&anio={year}  ← Comparar sistemas
GET    /api/cassandra/analitica/promedio?region={reg}&anio={year}  ← Promedios simplificados
```

#### Cassandra RF5 (Auditoría)

```
GET    /api/cassandra/auditoria?id_entidad={id}&aaaamm={YYYYMM}  ← Eventos de auditoría
GET    /api/cassandra/auditoria/verificar-cadena?id_entidad={id}  ← Verificar integridad de hashes
```

### Ejemplo de Uso Completo

```bash
# 1. Crear calificación en MongoDB
curl -X POST http://localhost:3000/api/mongodb/calificaciones \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "STU-0001",
    "original_grade": {
      "system": "AR",
      "value": 8,
      "passed": true
    },
    ...
  }'

# Respuesta: { "record_id": "GR-2025-0001" }

# 2. Convertir a sistema ZA7 (Redis)
curl http://localhost:3000/api/redis/conversion?record_id=GR-2025-0001&to_system=ZA7

# Respuesta: { "za_1_7": 6, "cached": false }

# 3. Ver trayectoria en Neo4j
curl http://localhost:3000/api/neo4j/trayectoria/STU-0001

# 4. Ver estadísticas en Cassandra
curl "http://localhost:3000/api/cassandra/analitica/reportes?region=AR-CABA&anio=2025&sistema=AR"

# 5. Ver auditoría
curl "http://localhost:3000/api/cassandra/auditoria?id_entidad=GR-2025-0001&aaaamm=202501"
```

---

## 📊 Dataset de Prueba

### Resumen del Dataset

El sistema incluye un dataset pequeño pero consistente con:

- **10 estudiantes** de 5 países diferentes
- **8 instituciones** en 4 países
- **8 materias** con variantes por sistema (~20 nodos en Neo4j)
- **10 calificaciones** en 5 sistemas educativos diferentes
- **10 trayectorias** activas

### Estudiantes

| student_id | Nombre | País | Institución |
|----------|---------|------|-------------|
| STU-0001 | Liam Nkosi | ZA | Cape Town Central High |
| STU-0002 | Sofía Danko | AR | UADE Argentina |
| STU-0003 | Noah van der Merwe | ZA | Pretoria Academy |
| STU-0004 | Ava Smith | US | New York State HS |
| STU-0005 | Oliver Patel | UK | London Sixth Form |
| STU-0006 | Mia Johnson | US | California Tech High |
| STU-0007 | Emma Iuzzolino | AR | Buenos Aires HS |
| STU-0008 | Theo Samaan | ZA | Cape Town Central High |
| STU-0009 | Charlotte Brown | UK | London Sixth Form |
| STU-0010 | Felix Müller | DE | Berlin Gymnasium |

### Calificaciones

| record_id | Estudiante | Sistema | Materia | Nota | ¿Aprobó? | Año |
|-----------|-----------|---------|---------|------|----------|-----|
| GR-2025-0001 | STU-0001 | ZA | Mathematics | 75% | ✅ | 2025 |
| GR-2025-0002 | STU-0002 | AR | Computer Science | 8 | ✅ | 2025 |
| GR-2025-0003 | STU-0003 | ZA | English | 68% | ✅ | 2025 |
| GR-2025-0004 | STU-0004 | US | Biology | A (4.0) | ✅ | 2025 |
| GR-2025-0005 | STU-0005 | UK | Physics | B | ✅ | 2025 |
| GR-2024-0006 | STU-0006 | US | Economics | C+ (2.3) | ✅ | 2024 |
| GR-2024-0007 | STU-0007 | AR | Mathematics | 4 | ❌ | 2024 |
| GR-2024-0008 | STU-0008 | ZA | Computer Science | 82% | ✅ | 2024 |
| GR-2024-0009 | STU-0009 | UK | History | A* | ✅ | 2024 |
| GR-2024-0010 | STU-0010 | DE | Chemistry | 2.3 | ✅ | 2024 |

### Reglas de Conversión

El sistema incluye reglas de conversión entre todos los pares de sistemas:

- AR → ZA7 (1-10 a 1-7)
- US → ZA7 (GPA a 1-7)
- UK → ZA7 (Letras a 1-7)
- DE → ZA7 (1-6 a 1-7)
- Y viceversa para cada par

---

## 🚀 Cómo Ejecutar el Sistema

### Requisitos Previos

- Docker y Docker Compose
- Node.js 18+ (para la API)
- Python 3.8+ (para scripts de carga)

### Paso 1: Levantar las bases de datos

```bash
cd docker
docker-compose up -d

# Verificar que estén corriendo
docker ps
```

**Servicios levantados**:
- MongoDB: `localhost:27017`
- Redis: `localhost:6379`
- Neo4j: `localhost:7474` (interface) y `localhost:7687` (bolt)
- Cassandra: `localhost:9042`

### Paso 2: Esperar a que Cassandra esté listo

```bash
# Esperar ~30 segundos
docker-compose logs -f cassandra

# Buscar mensaje: "Starting listening for CQL clients..."
```

### Paso 3: Aplicar seeds de inicialización

```bash
cd ..  # Volver al directorio raíz

# Aplicar seed consolidado de Cassandra
./scripts/aplicar_seed_cassandra.sh

# O manualmente:
docker exec -it cassandra cqlsh -f /tmp/cassandra_seed_consolidado.cql
```

### Paso 4: Cargar dataset consistente

```bash
# Cargar las 4 bases de datos con datos coherentes
python3 scripts/cargar_seeds_coherentes.py

# O aplicar seeds individuales
./scripts/aplicar_seeds_completos.sh
```

### Paso 5: Levantar la API

```bash
cd api
npm install
npm start

# La API corre en http://localhost:3000
```

### Paso 6: Probar endpoints

```bash
# Health check
curl http://localhost:3000/

# Ver calificaciones
curl http://localhost:3000/api/mongodb/calificaciones

# Convertir calificación
curl http://localhost:3000/api/redis/conversion?record_id=GR-2025-0001&to_system=ZA7

# Ver trayectoria
curl http://localhost:3000/api/neo4j/trayectoria/STU-0001

# Ver reportes analíticos
curl "http://localhost:3000/api/cassandra/analitica/reportes?region=AR-CABA&anio=2025&sistema=AR"
```

### Paso 7: Verificar datos en cada base

```bash
# MongoDB
docker exec -it mongo mongosh edugrade --eval "db.calificaciones.countDocuments()"

# Redis
docker exec -it redis redis-cli KEYS "*"

# Neo4j (abrir navegador)
# http://localhost:7474
# MATCH (n) RETURN COUNT(n)

# Cassandra
docker exec -it cassandra cqlsh -e "SELECT COUNT(*) FROM edugrade_analitica.rf4_fact_grades_by_region_year_system"
```

---

## 📚 Resumen de Conceptos Clave

### ¿Por qué 4 bases de datos?

Cada base de datos resuelve un problema diferente de manera óptima:

1. **MongoDB**: Documentos JSON flexibles con consistencia fuerte (ACID local)
2. **Redis**: Cache en memoria con latencia ultra-baja (<5ms)
3. **Neo4j**: Grafo para relaciones complejas (trayectorias, equivalencias)
4. **Cassandra**: Escritura masiva y agregados distribuidos

### Patrones de Diseño Aplicados

- **Source of Truth**: MongoDB es la única fuente autoritativa
- **Cache-Aside**: Redis cachea conversiones on-demand
- **Event Sourcing**: Cassandra RF5 registra todos los eventos
- **Materialized Views**: Cassandra RF4 precalcula agregados
- **Immutability**: MongoDB y Cassandra RF5 nunca modifican datos originales
- **Versionado**: Redis mantiene versiones de reglas de conversión

### Garantías de Consistencia

| Base de Datos | Consistency Level | ¿Por qué? |
|---------------|------------------|----------|
| MongoDB | MAJORITY | Datos críticos (calificaciones) |
| Cassandra RF5 | QUORUM | Auditoría requiere fuerte consistencia |
| Cassandra RF4 | ONE | Velocidad > consistencia inmediata |
| Neo4j | ACID local | Transacciones atómicas en cada nodo |
| Redis | In-memory | Cache, eventual consistency OK |

### Flujo de Datos Simplificado

```
Alta de Calificación
  → MongoDB (PERSIST)
  → Cassandra RF5 (AUDIT)
  → Neo4j (GRAPH)

Consulta de Conversión
  → Redis (CACHE CHECK)
  → MongoDB (READ ORIGINAL si cache miss)
  → Redis (CALCULATE + CACHE)
  → MongoDB (UPDATE conversiones array)

Consulta Analítica
  → Cassandra RF4 (READ AGGREGATES)

Consulta de Trayectoria
  → Neo4j (GRAPH TRAVERSAL)

Consulta de Auditoría
  → Cassandra RF5 (READ APPEND-ONLY LOG)
```

---

## 🎓 Conclusión

**EduGrade Global** demuestra cómo una **arquitectura multimodelo** puede resolver requisitos complejos usando la base de datos correcta para cada tarea:

- ✅ **MongoDB**: Fuente de verdad con inmutabilidad
- ✅ **Redis**: Conversiones de alta velocidad con versionado
- ✅ **Neo4j**: Relaciones académicas y equivalencias
- ✅ **Cassandra**: Analítica distribuida + auditoría inmutable

El sistema es **escalable**, **traceable** y **consistente**, cumpliendo con los requisitos de un sistema académico internacional real.

---

**Autores**: Teo Samaan y equipo  
**Fecha**: 20 de febrero de 2026  
**Curso**: Introducción al Diseño de Datos II - UADE  
**Versión**: 1.0
