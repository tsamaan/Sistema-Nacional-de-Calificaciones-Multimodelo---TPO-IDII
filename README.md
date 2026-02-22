# 🎓 Sistema Nacional de Calificaciones Multimodelo - EduGrade Global

**Trabajo Práctico Obligatorio - Introducción al Diseño de Datos II**  
**UADE - Verano 2026**

---

## 📋 Tabla de Contenidos

- [Resumen Ejecutivo](#-resumen-ejecutivo)
- [Arquitectura Multimodelo](#-arquitectura-multimodelo)
- [Requerimientos Funcionales](#-requerimientos-funcionales)
- [Bases de Datos](#-bases-de-datos)
  - [MongoDB (RF1)](#mongodb-rf1---fuente-de-verdad)
  - [Redis (RF2)](#redis-rf2---cache-de-conversiones)
  - [Neo4j (RF3)](#neo4j-rf3---grafo-de-equivalencias)
  - [Cassandra (RF4, RF5)](#cassandra-rf4-rf5---analítica-y-auditoría)
- [Flujo de Datos](#-flujo-de-datos)
- [API REST](#-api-rest)
- [Instalación y Configuración](#-instalación-y-configuración)
- [Scripts Disponibles](#-scripts-disponibles)
- [Dataset de Prueba](#-dataset-de-prueba)
- [Testing](#-testing)
- [Estructura del Proyecto](#-estructura-del-proyecto)

---

## 🎯 Resumen Ejecutivo

**EduGrade Global** es un sistema de gestión de calificaciones académicas internacionales que utiliza una **arquitectura multimodelo** con 4 bases de datos diferentes para resolver necesidades específicas:

- **MongoDB** → Fuente de verdad transaccional con consistencia fuerte
- **Redis** → Cache de alta velocidad para conversiones entre sistemas educativos
- **Neo4j** → Grafo de relaciones académicas y trayectorias estudiantiles
- **Cassandra** → Analítica distribuida y auditoría inmutable

El sistema permite gestionar calificaciones de estudiantes de diferentes países (Argentina, Sudáfrica, Reino Unido, Estados Unidos, Alemania) con sus respectivos sistemas de calificación, y convertirlas a un sistema unificado para comparaciones internacionales.

### 🌍 Sistemas Educativos Soportados

| País | Sistema | Escala | Ejemplo |
|------|---------|--------|---------|
| 🇦🇷 Argentina | AR | 1-10 (numérico) | 8 = Aprobado |
| 🇿🇦 Sudáfrica | ZA | 0-100% | 75% = Aprobado |
| 🇺🇸 Estados Unidos | US | GPA 0.0-4.0 | A = 4.0 |
| 🇬🇧 Reino Unido | UK | A*-E (letras) | B = Aprobado |
| 🇩🇪 Alemania | DE | 1.0-5.0 (nota alemana) | 2.3 = Aprobado |

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
└─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘
        │                    │                   │                   │
        ▼                    ▼                   ▼                   ▼
   Persistencia          Reglas de          Relaciones          Agregados +
   Inmutable            Conversión          Académicas          Event Logs
   + Snapshots          Versionadas         + Trayectorias      Inmutables
```

### 🔍 ¿Por qué Multimodelo?

Cada base de datos fue seleccionada por sus fortalezas específicas:

| Base de Datos | Modelo | Fortaleza | Uso en EduGrade |
|---------------|--------|-----------|-----------------|
| **MongoDB** | Documento | Flexibilidad de esquema, ACID en documentos | Almacenar calificaciones con contexto completo |
| **Redis** | Clave-Valor | Velocidad extrema, estructuras en memoria | Cache de conversiones con TTL |
| **Neo4j** | Grafo | Consultas de relaciones, path finding | Trayectorias académicas, equivalencias |
| **Cassandra** | Columnar | Escritura masiva, particionamiento | Analytics y logs de auditoría inmutables |

---

## 📊 Requerimientos Funcionales

### RF1: Persistencia Transaccional (MongoDB)

**Objetivo:** Almacenar calificaciones como fuente de verdad con consistencia fuerte.

**Características clave:**
- Write Concern: `MAJORITY` (espera confirmación de mayoría de réplicas)
- Read Preference: `PRIMARY` (lee siempre del nodo primario)
- Inmutabilidad: campo `original_grade` nunca se modifica
- Versionado: cada corrección crea entrada en array `history`
- Snapshots: guarda contexto completo (estudiante, institución, materia) al momento de la calificación

**Colecciones:**
- `estudiantes` - Datos personales y académicos
- `instituciones` - Centros educativos por país/región
- `materias` - Asignaturas y códigos de materias
- `trayectorias` - Historial académico de cada estudiante
- `calificaciones` - Registros de calificaciones con contexto completo

**Ejemplo de documento de calificación:**
```json
{
  "_id": "GR-2025-0001",
  "student_id": "STU-0001",
  "zone": "ZA-CPT",
  "student_snapshot": {
    "full_name": "Liam Nkosi",
    "dob": "2007-05-14",
    "nationality": "ZA"
  },
  "institution_snapshot": {
    "institution_id": "INS-001",
    "name": "Cape Town Central High",
    "country": "ZA",
    "region": "Western Cape"
  },
  "academic_context": {
    "academic_year": 2025,
    "term": "T1",
    "level": "secondary"
  },
  "subject_snapshot": {
    "subject_id": "SUB-MATH",
    "name": "Mathematics"
  },
  "original_grade": {
    "system": "ZA",
    "value": 75,
    "passed": true
  },
  "conversiones": [],
  "immutability": {
    "hash": "abc123...",
    "created_at": "2025-01-15T10:30:00Z"
  }
}
```

---

### RF2: Conversión de Sistemas Educativos (Redis)

**Objetivo:** Convertir calificaciones entre diferentes sistemas educativos de forma rápida.

**Características clave:**
- Cache-aside pattern: primero consulta cache, si no existe, calcula y cachea
- TTL de 24 horas por conversión
- Reglas versionadas: permite cambios sin impactar cálculos anteriores
- In-memory: latencia <5ms por conversión

**Estructura de datos:**
```redis
# Reglas de conversión activas
RULEACTIVE#AR#US → {version: "v2025-01", org: "MINEDU_ZA"}

# Regla completa
RULE#AR#US#MINEDU_ZA#v2025-01 → Hash {4: 0.0, 6: 2.0, 8: 3.7, 10: 4.0}

# Conversión cacheada
CONV#GR-2025-0001#US → [{from_system, from_value, to_value, rule, timestamp}]
```

**Flujo de conversión:**
1. Cliente solicita conversión (ej: AR → US)
2. API busca versión activa de la regla
3. API busca en cache la conversión
4. Si no existe, calcula usando la regla y cachea (TTL 24h)
5. Resultado se persiste también en MongoDB (array `conversiones`)

**Reglas de conversión disponibles:**

**Argentina (AR 1-10) → US (GPA)**
```
1-3: 0.0 (Desaprobado)
4: 0.0 (Insuficiente)
5: 1.0 (Regular-)
6: 2.0 (Regular)
7: 2.7 (Bueno)
8: 3.7 (Muy Bueno)
9: 3.7 (Distinguido)
10: 4.0 (Sobresaliente)
```

**Sudáfrica (ZA 0-100%) → US (GPA)**
```
0-49%: 0.0 (Fail)
50-59%: 1.0 (Pass)
60-69%: 2.0 (Adequate Achievement)
70-79%: 3.0 (Substantial Achievement)
80-89%: 3.7 (Meritorious Achievement)
90-100%: 4.0 (Outstanding Achievement)
```

**Reino Unido (UK A*-E) → US (GPA)**
```
E: 1.0 (Pass)
D: 2.0 (Pass)
C: 2.3 (Average)
B: 3.3 (Above Average)
A: 4.0 (Excellent)
A*: 4.0 (Outstanding)
```

**Alemania (DE 1.0-5.0) → US (GPA)**
```
1.0: 4.0 (sehr gut - very good)
2.0: 3.3 (gut - good)
2.3: 3.0 (gut - good)
3.0: 2.7 (befriedigend - satisfactory)
4.0: 1.0 (ausreichend - sufficient)
5.0: 0.0 (ungenügend - insufficient)
```

---

### RF3: Relaciones Académicas (Neo4j)

**Objetivo:** Modelar y consultar trayectorias académicas y equivalencias entre materias.

**Características clave:**
- Modelo de grafo: nodos (entidades) + relaciones (edges)
- Consultas Cypher para path finding
- ACID a nivel de transacción local
- Read-heavy: optimizado para consultas

**Nodos:**
- `(:Student)` - Estudiantes
- `(:Institution)` - Instituciones educativas
- `(:Subject)` - Materias (con variantes por sistema: SUB-MATH:AR, SUB-MATH:US)
- `(:GradeRecord)` - Calificaciones

**Relaciones:**
- `(Student)-[:HAS_RECORD]->(GradeRecord)` - Estudiante tiene calificación
- `(Student)-[:TOOK]->(Subject)` - Estudiante cursó materia
- `(Student)-[:ATTENDED]->(Institution)` - Estudiante asistió a institución
- `(GradeRecord)-[:FOR_SUBJECT]->(Subject)` - Calificación de materia
- `(GradeRecord)-[:AT_INSTITUTION]->(Institution)` - Calificación en institución

**Consultas típicas:**
```cypher
// Trayectoria académica de un estudiante
MATCH path = (s:Student {student_id: 'STU-0001'})-[:HAS_RECORD]->(r)-[:FOR_SUBJECT]->(m)
RETURN path

// Estudiantes que cursaron la misma materia
MATCH (s:Student)-[:TOOK]->(m:Subject {subject_id: 'SUB-MATH'})
RETURN s.full_name, m.name

// Historia académica completa
MATCH (s:Student {student_id: 'STU-0005'})-[:ATTENDED]->(i:Institution)
MATCH (s)-[:HAS_RECORD]->(r:GradeRecord)-[:FOR_SUBJECT]->(sub:Subject)
RETURN s, i, r, sub
```

---

### RF4: Analítica Distribuida (Cassandra)

**Objetivo:** Calcular agregados estadísticos y reportes analíticos de forma distribuida.

**Características clave:**
- Consistency Level: `ONE` (prioriza velocidad sobre consistencia)
- Escritura asíncrona: no bloquea operaciones transaccionales
- Agregados precalculados: suma, suma_cuadrados, n, min, max
- Particionamiento por región + año + sistema

**Keyspace:** `edugrade_analitica`

**Tablas:**

1. **rf4_fact_grades_by_region_year_system** (Fact Table)
   - Calificaciones individuales con dimensiones completas
   - Partition key: `(region, academic_year, system)`
   - Clustering: `(institution_id, subject_id, event_ts, record_id)`
   
2. **rf4_report_by_region_year_system** (Agregados por Sistema)
   - Estadísticas agregadas por sistema educativo
   - Métricas: promedio, min, max, tasa de aprobación
   
3. **rf4_report_by_region_year** (Comparación Cross-System)
   - Permite comparar métricas entre sistemas en misma región/año
   
4. **promedio_por_region_anio** (Agregados Simplificados)
   - Agregados ligeros para cálculo de promedios y desviación estándar

**Ejemplo de consulta analítica:**
```sql
-- Ver fact table de calificaciones
SELECT * FROM rf4_fact_grades_by_region_year_system
WHERE region = 'ZA-PTA' 
  AND academic_year = 2025 
  AND system = 'UK';

-- Ver agregados por sistema
SELECT * FROM rf4_report_by_region_year_system
WHERE region = 'ZA-PTA' 
  AND academic_year = 2025 
  AND system = 'UK';

-- Comparar sistemas educativos
SELECT system, institution_id, subject_id, avg_norm_0_100, pass_rate
FROM rf4_report_by_region_year
WHERE region = 'ZA-BFN' 
  AND academic_year = 2025;
```

---

### RF5: Auditoría Inmutable (Cassandra)

**Objetivo:** Registrar todos los eventos del sistema de forma inmutable para auditoría.

**Características clave:**
- Consistency Level: `QUORUM` (mayoría de réplicas, alta confiabilidad)
- Append-only: nunca se modifican ni eliminan registros
- Cadena de hashes: cada evento enlaza con el anterior (blockchain-style)
- Particionamiento por entidad + mes

**Keyspace:** `edugrade_auditoria`

**Tabla:** `registro_auditoria_por_entidad_mes`

**Campos clave:**
- `id_entidad` - ID de la entidad afectada (ej: "GR-2025-0001")
- `aaaamm` - Año-mes de particionamiento (ej: "202501")
- `marca_tiempo` - Timestamp del evento
- `accion` - Tipo de evento: GRADE_CREATED, GRADE_UPDATED, SYSTEM_CONVERSION, etc.
- `id_actor` - Quién realizó la acción
- `hash_anterior` - Hash del evento previo (cadena de bloques)
- `hash_nuevo` - Hash SHA256 del evento actual
- `carga_util` - JSON con datos completos del evento

**Ejemplo de consulta de auditoría:**
```sql
SELECT marca_tiempo, accion, id_actor, hash_nuevo
FROM registro_auditoria_por_entidad_mes
WHERE id_entidad = 'GR-2025-0001' 
  AND aaaamm = '202501'
ORDER BY marca_tiempo DESC;
```

**Eventos de auditoría registrados:**
- `GRADE_CREATED` - Calificación creada
- `GRADE_UPDATED` - Calificación modificada
- `SYSTEM_CONVERSION` - Conversión entre sistemas
- `GRADE_DELETED` - Calificación eliminada (soft delete)
- `CACHE_INVALIDATED` - Cache de Redis invalidado

---

## 🔄 Flujo de Datos

### Secuencia Completa: Alta de Calificación

```
════════════════════════════════════════════════════════════════════
                    FLUJO DE ALTA DE CALIFICACIÓN
════════════════════════════════════════════════════════════════════

[1] CLIENTE
     │ POST /api/mongodb/calificaciones
     │ Body: { student_id, original_grade: { system: "AR", value: 8 }, ... }
     ▼
[2] API REST (Node.js)
     │ Valida datos de entrada
     │ Genera record_id único (GR-2025-0001)
     │ Calcula hash SHA256 para inmutabilidad
     ▼
════════════════════════════════════════════════════════════════════
                          FASE 1: PERSISTENCIA
════════════════════════════════════════════════════════════════════
[3] MONGODB (RF1) ✅ FUENTE DE VERDAD
     │ db.calificaciones.insertOne({...})
     │ Write Concern: MAJORITY (espera mayoría de réplicas)
     │ ⏱️ ~50-100ms
     ▼ ✅ PERSISTIDO

════════════════════════════════════════════════════════════════════
                          FASE 2: AUDITORÍA
════════════════════════════════════════════════════════════════════
[4] CASSANDRA (RF5) 📝 REGISTRO DE AUDITORÍA
     │ INSERT INTO registro_auditoria_por_entidad_mes
     │ Consistency Level: QUORUM (mayoría de réplicas)
     │ ⏱️ ~30-50ms
     │ Append-only: NUNCA se modifica ni elimina
     ▼ ✅ AUDITADO

════════════════════════════════════════════════════════════════════
                        FASE 3: GRAFO ACADÉMICO
════════════════════════════════════════════════════════════════════
[5] NEO4J (RF3) 🕸️ RELACIONES ACADÉMICAS
     │ CREATE (g:GradeRecord {...})
     │ CREATE (s:Student)-[:HAS_RECORD]->(g)
     │ CREATE (g)-[:FOR_SUBJECT]->(sub)
     │ CREATE (g)-[:AT_INSTITUTION]->(i)
     │ ⏱️ ~20-40ms por transacción
     ▼ ✅ GRAFO ACTUALIZADO

════════════════════════════════════════════════════════════════════
                FASE 4: CONVERSIÓN A SISTEMA UNIFICADO
                         (Solo cuando se solicita)
════════════════════════════════════════════════════════════════════
[6] CLIENTE
     │ GET /api/redis/conversion?record_id=GR-2025-0001&to_system=US
     ▼
[7] REDIS (RF2) 🔄 CACHE DE CONVERSIONES
     │ PASO 7.1: Buscar versión activa de regla
     │ GET RULEACTIVE#AR#US → Retorna: "v2025-01"
     │
     │ PASO 7.2: Verificar cache
     │ GET CONV#GR-2025-0001#US
     │ ❌ Cache miss → Necesitamos calcular
     │
     │ PASO 7.3: Leer regla completa
     │ HGETALL RULE#AR#US#MINEDU_ZA#v2025-01
     │ → {4: 0.0, 6: 2.0, 8: 3.7, 10: 4.0}
     │
     │ PASO 7.4: Calcular y cachear resultado
     │ Aplicar regla: AR(8) → US(3.7)
     │ SETEX CONV#GR-2025-0001#US 86400 "{...}"
     │ ⏰ TTL: 24 horas
     ▼ ✅ CONVERSIÓN CACHEADA

[8] MONGODB - ACTUALIZAR CON CONVERSIÓN
     │ db.calificaciones.updateOne(
     │   {_id: "GR-2025-0001"},
     │   {$push: {conversiones: {...}}}
     │ )
     │ ⚠️ NO modifica "original" (inmutable)
     ▼ ✅ PERSISTIDO

════════════════════════════════════════════════════════════════════
                FASE 5: AGREGACIÓN ANALÍTICA
                         (Batch o tiempo real)
════════════════════════════════════════════════════════════════════
[9] CASSANDRA (RF4) 📊 ACTUALIZAR AGREGADOS
     │ INSERT INTO rf4_fact_grades_by_region_year_system
     │ UPDATE rf4_report_by_region_year_system
     │   n = n + 1,
     │   suma = suma + 3.7,
     │   suma_cuadrados = suma_cuadrados + 13.69
     │ Consistency Level: ONE (velocidad)
     ▼ ✅ AGREGADOS ACTUALIZADOS
```

---

## 🌐 API REST

### Arquitectura de la API

**Tecnología:** Node.js + Express  
**Puerto:** 3000  
**Formato:** JSON  

### Endpoints por Base de Datos

#### 📄 MongoDB - Gestión de Calificaciones

**Base URL:** `/api/mongodb`

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `POST` | `/calificaciones` | Crear nueva calificación |
| `GET` | `/calificaciones/:id` | Obtener calificación por ID |
| `GET` | `/calificaciones/estudiante/:student_id` | Historial de estudiante |
| `PUT` | `/calificaciones/:id` | Actualizar calificación (versiona) |
| `DELETE` | `/calificaciones/:id` | Soft delete (marca como eliminado) |
| `GET` | `/estudiantes` | Listar estudiantes |
| `GET` | `/instituciones` | Listar instituciones |
| `GET` | `/materias` | Listar materias |

**Ejemplo - Crear calificación:**
```bash
curl -X POST http://localhost:3000/api/mongodb/calificaciones \
  -H "Content-Type: application/json" \
  -d '{
    "student_id": "STU-0001",
    "zone": "ZA-CPT",
    "institution_snapshot": {
      "institution_id": "INS-001",
      "name": "Cape Town Central High",
      "country": "ZA"
    },
    "subject_snapshot": {
      "subject_id": "SUB-MATH",
      "name": "Mathematics"
    },
    "academic_context": {
      "academic_year": 2025,
      "term": "T1"
    },
    "original_grade": {
      "system": "ZA",
      "value": 75,
      "passed": true
    }
  }'
```

---

#### 🔄 Redis - Conversiones

**Base URL:** `/api/redis`

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/conversion?record_id={id}&to_system={system}` | Convertir calificación |
| `GET` | `/reglas?from={sys}&to={sys}` | Obtener regla de conversión |
| `POST` | `/reglas` | Crear/actualizar regla de conversión |
| `GET` | `/cache/stats` | Estadísticas del cache |
| `DELETE` | `/cache/:record_id` | Invalidar cache de conversión |

**Ejemplo - Convertir calificación AR → US:**
```bash
curl "http://localhost:3000/api/redis/conversion?record_id=GR-2025-0001&to_system=US"

# Respuesta:
{
  "record_id": "GR-2025-0001",
  "from_system": "AR",
  "from_value": 8,
  "to_system": "US",
  "to_value": 3.7,
  "rule_version": "v2025-01",
  "cached": false
}
```

---

#### 🕸️ Neo4j - Grafo Académico

**Base URL:** `/api/neo4j`

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/trayectoria/:student_id` | Trayectoria académica completa |
| `GET` | `/materias/:student_id` | Materias cursadas por estudiante |
| `GET` | `/estudiantes/:institution_id` | Estudiantes de una institución |
| `GET` | `/equivalencias/:subject_id` | Equivalencias de materia |
| `GET` | `/path?from={sid}&to={sid}` | Camino entre dos estudiantes |

**Ejemplo - Trayectoria de estudiante:**
```bash
curl "http://localhost:3000/api/neo4j/trayectoria/STU-0001"

# Respuesta:
{
  "student_id": "STU-0001",
  "full_name": "Liam Nkosi",
  "records": [
    {
      "record_id": "GR-2025-0001",
      "subject": "Mathematics",
      "system": "ZA",
      "grade_value": 75,
      "passed": true,
      "institution": "Cape Town Central High",
      "year": 2025,
      "term": "T1"
    }
  ]
}
```

---

#### 📊 Cassandra - Analítica y Auditoría

**Base URL:** `/api/cassandra`

**Endpoints RF4 (Analítica):**

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/analitica/facts?region={reg}&anio={year}&sistema={sys}` | Fact table (calificaciones individuales) |
| `GET` | `/analitica/reportes?region={reg}&anio={year}&sistema={sys}` | Reportes agregados por sistema |
| `GET` | `/analitica/cross-system?region={reg}&anio={year}` | Comparación entre sistemas |
| `GET` | `/analitica/promedio?region={reg}&anio={year}&sistema={sys}` | Promedios precalculados |
| `GET` | `/analitica/keys?region={reg}&anio={year}` | Listar claves disponibles |

**Endpoints RF5 (Auditoría):**

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET` | `/auditoria?id_entidad={id}&aaaamm={YYYYMM}` | Logs de auditoría por entidad/mes |
| `GET` | `/auditoria/verificar?id_entidad={id}&aaaamm={YYYYMM}` | Verificar cadena de hashes |

**Ejemplo - Analítica por región/año:**
```bash
curl "http://localhost:3000/api/cassandra/analitica/reportes?region=ZA-PTA&anio=2025&sistema=UK"

# Respuesta:
{
  "region": "ZA-PTA",
  "academic_year": 2025,
  "system": "UK",
  "aggregates": [
    {
      "institution_id": "INS-007",
      "subject_id": "SUB-MATH",
      "n_records": 15,
      "avg_norm_0_100": 72.3,
      "min_norm": 45,
      "max_norm": 98,
      "pass_rate": 0.87
    }
  ]
}
```

**Ejemplo - Auditoría:**
```bash
curl "http://localhost:3000/api/cassandra/auditoria?id_entidad=GR-2025-0001&aaaamm=202501"

# Respuesta:
{
  "id_entidad": "GR-2025-0001",
  "events": [
    {
      "marca_tiempo": "2025-01-15T10:30:00Z",
      "accion": "GRADE_CREATED",
      "id_actor": "profesor_matematica",
      "hash_anterior": "0",
      "hash_nuevo": "abc123...",
      "carga_util": "{...}"
    },
    {
      "marca_tiempo": "2025-01-20T14:15:00Z",
      "accion": "SYSTEM_CONVERSION",
      "id_actor": "sistema_conversiones",
      "hash_anterior": "abc123...",
      "hash_nuevo": "def456...",
      "carga_util": "{...}"
    }
  ]
}
```

---

## 🚀 Instalación y Configuración

### Prerrequisitos

- **Docker** >= 20.10
- **Docker Compose** >= 2.0
- **Node.js** >= 18 (para API)
- **Python** >= 3.8 (para scripts de carga)

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/tsamaan/Sistema-Nacional-de-Calificaciones-Multimodelo---TPO-IDII.git
cd Sistema-Nacional-de-Calificaciones-Multimodelo---TPO-IDII
```

### Paso 2: Levantar las Bases de Datos con Docker

```bash
cd docker
docker-compose up -d
```

Esto levantará:
- **MongoDB** en puerto 27017
- **Redis** en puerto 6379
- **Redis Commander** (UI web) en puerto 8081
- **Neo4j** en puertos 7474 (browser) y 7687 (bolt)
- **Cassandra** en puerto 9042

**Verificar que estén corriendo:**
```bash
docker ps
```

Deberías ver 5-6 contenedores activos: edugrade-mongo, edugrade-redis, edugrade-redis-ui, edugrade-neo4j, edugrade-cassandra.

**Esperar que las bases estén completamente iniciadas:**
```bash
# MongoDB
docker exec edugrade-mongo mongosh --eval "db.adminCommand('ping')"

# Redis
docker exec edugrade-redis redis-cli -a redis123 ping

# Neo4j (tarda ~30 segundos)
docker logs edugrade-neo4j | grep "Started"

# Cassandra (tarda ~60 segundos)
docker logs edugrade-cassandra | grep "Starting listening for CQL clients"
```

### Paso 3: Crear Estructuras de Bases de Datos

**MongoDB** (se crea automáticamente al insertar datos)

**Redis** (en memoria, sin estructura previa)

**Neo4j** (sin estructura previa, se crean constraints opcionalmente)

**Cassandra** (requiere aplicar seed):
```bash
cd ..  # volver a raíz del proyecto

# Copiar el archivo al contenedor
docker cp db/txts/cassandra_seed_consolidado.cql edugrade-cassandra:/tmp/

# Aplicar el seed
docker exec -it edugrade-cassandra cqlsh -f /tmp/cassandra_seed_consolidado.cql
```

**Verificar estructura Cassandra:**
```bash
docker exec edugrade-cassandra cqlsh -e "DESCRIBE KEYSPACES" | grep edugrade

# Deberías ver:
# edugrade_analitica
# edugrade_auditoria
```

### Paso 4: Cargar Datos de Prueba (10 registros)

**Opción A: Script Bash automático (recomendado)**
```bash
cd scripts
chmod +x cargar_seeds.sh
./cargar_seeds.sh
```

Este script cargará en orden:
1. MongoDB: estudiantes, instituciones, materias, trayectorias, calificaciones
2. Redis: reglas de conversión
3. Neo4j: nodos y relaciones
4. Cassandra: fact tables + logs de auditoría

**Opción B: Manual por base de datos**

Ver instrucciones detalladas en [scripts/cargar_seeds.sh](scripts/cargar_seeds.sh)

### Paso 5: Instalar Dependencias de la API

```bash
cd api
npm install
```

### Paso 6: Iniciar la API

```bash
npm start

# O en modo desarrollo con auto-reload:
npm run dev
```

La API estará disponible en: `http://localhost:3000`

**Verificar:**
```bash
curl http://localhost:3000

# Respuesta esperada:
{
  "message": "EduGrade Global API - Sistema Multimodelo",
  "version": "1.0.0",
  "endpoints": { ... }
}
```

### Paso 7: Acceder a las Interfaces Web

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| API REST | http://localhost:3000 | - |
| Neo4j Browser | http://localhost:7474 | neo4j / Neo4j2026! |
| Redis Commander | http://localhost:8081 | - |

---

## 📜 Scripts Disponibles

### 1. cargar_seeds.sh

Carga los datos de prueba (10 registros) en las 4 bases de datos.

```bash
cd scripts
chmod +x cargar_seeds.sh
./cargar_seeds.sh
```

**Características:**
- Pide confirmación antes de cargar cada base
- Verifica existencia de archivos seed
- Muestra progreso y resultados

---

### 2. limpiar_todo.sh

Elimina TODOS los datos de las 4 bases de datos (útil para empezar de cero).

```bash
cd scripts
chmod +x limpiar_todo.sh
./limpiar_todo.sh
```

**⚠️ ADVERTENCIA:** Este script es destructivo y borrará todos los datos sin confirmación adicional.

---

### 3. probar_sistema.py

Script interactivo en Python para probar el flujo completo de conversión de calificaciones.

```bash
cd scripts
python3 probar_sistema.py
```

**Funcionalidades:**
- Ver trayectoria académica de un estudiante
- Convertir calificación entre sistemas
- Ver logs de auditoría
- Consultar grafo Neo4j
- Verificar cache Redis

**Requisitos:**
```bash
pip install pymongo redis neo4j-driver cassandra-driver
```

---

## 📦 Dataset de Prueba

El sistema incluye un dataset de 10 registros coherentes entre las 4 bases de datos.

### Estudiantes (10 registros)

| student_id | Nombre | Nacionalidad | Institución |
|------------|--------|--------------|-------------|
| STU-0001 | Liam Nkosi | ZA | INS-001 (Cape Town) |
| STU-0002 | Sofía Danko | AR | INS-003 (UADE) |
| STU-0003 | Noah van der Merwe | ZA | INS-002 (Pretoria) |
| STU-0004 | Ava Smith | US | INS-005 (New York) |
| STU-0005 | Oliver Patel | UK | INS-007 (London) |
| STU-0006 | Mia Johnson | US | INS-006 (California) |
| STU-0007 | Emma Iuzzolino | AR | INS-004 (Buenos Aires) |
| STU-0008 | Theo Samaan | ZA | INS-001 (Cape Town) |
| STU-0009 | Charlotte Brown | UK | INS-007 (London) |
| STU-0010 | Felix Müller | DE | INS-008 (Berlin) |

### Calificaciones (10 registros)

| record_id | Estudiante | Materia | Sistema | Calificación | Año |
|-----------|------------|---------|---------|--------------|-----|
| GR-2025-0001 | STU-0001 | Mathematics | ZA | 75% | 2025 |
| GR-2025-0002 | STU-0002 | Computer Science | AR | 8 | 2025 |
| GR-2025-0003 | STU-0003 | English | ZA | 68% | 2025 |
| GR-2025-0004 | STU-0004 | Biology | US | A (4.0) | 2025 |
| GR-2025-0005 | STU-0005 | Physics | UK | B | 2025 |
| GR-2024-0006 | STU-0006 | Economics | US | C+ (2.3) | 2024 |
| GR-2024-0007 | STU-0007 | Mathematics | AR | 4 (Desaprobado) | 2024 |
| GR-2024-0008 | STU-0008 | Computer Science | ZA | 82% | 2024 |
| GR-2024-0009 | STU-0009 | History | UK | A* | 2024 |
| GR-2024-0010 | STU-0010 | Chemistry | DE | 2.3 | 2024 |

---

## 🧪 Testing

### Test 1: Verificar Conexión a Bases de Datos

```bash
# MongoDB
docker exec edugrade-mongo mongosh edugrade -u admin -p admin123 --authenticationDatabase admin --eval "db.calificaciones.countDocuments()"
# Esperado: 10

# Redis
docker exec edugrade-redis redis-cli -a redis123 DBSIZE
# Esperado: >10 (reglas + metadatos)

# Neo4j
docker exec edugrade-neo4j cypher-shell -u neo4j -p "Neo4j2026!" "MATCH (n) RETURN count(n)"
# Esperado: ~48 (10 estudiantes + 10 calificaciones + 8 instituciones + ~20 materias)

# Cassandra
docker exec edugrade-cassandra cqlsh -e "SELECT COUNT(*) FROM edugrade_auditoria.registro_auditoria_por_entidad_mes"
# Esperado: 10
```

### Test 2: Probar Endpoints de la API

```bash
# Health check
curl http://localhost:3000

# Listar estudiantes (MongoDB)
curl http://localhost:3000/api/mongodb/estudiantes

# Obtener calificación (MongoDB)
curl http://localhost:3000/api/mongodb/calificaciones/GR-2025-0001

# Convertir calificación AR → US (Redis)
curl "http://localhost:3000/api/redis/conversion?record_id=GR-2025-0002&to_system=US"

# Trayectoria de estudiante (Neo4j)
curl http://localhost:3000/api/neo4j/trayectoria/STU-0001

# Analítica por región (Cassandra RF4)
curl "http://localhost:3000/api/cassandra/analitica/promedio?region=ZA-CPT&anio=2025&sistema=ZA"

# Auditoría (Cassandra RF5)
curl "http://localhost:3000/api/cassandra/auditoria?id_entidad=GR-2025-0001&aaaamm=202501"
```

### Test 3: Flujo Completo de Conversión

```bash
# 1. Ver calificación original (AR)
curl http://localhost:3000/api/mongodb/calificaciones/GR-2025-0002

# 2. Convertir a US
curl "http://localhost:3000/api/redis/conversion?record_id=GR-2025-0002&to_system=US"
# Respuesta: AR(8) → US(3.7)

# 3. Verificar que se guardó en MongoDB
curl http://localhost:3000/api/mongodb/calificaciones/GR-2025-0002
# Ver campo "conversiones" array

# 4. Verificar log de auditoría
curl "http://localhost:3000/api/cassandra/auditoria?id_entidad=GR-2025-0002&aaaamm=202501"
# Buscar evento "SYSTEM_CONVERSION"
```

---

## 📁 Estructura del Proyecto

```
Sistema-Nacional-de-Calificaciones-Multimodelo---TPO-IDII/
│
├── README.md                      # Este archivo (documentación completa)
│
├── api/                           # API REST (Node.js + Express)
│   ├── package.json               # Dependencias npm
│   ├── server.js                  # Servidor principal
│   └── routes/                    # Rutas por base de datos
│       ├── mongodb.js             # Endpoints MongoDB
│       ├── redis.js               # Endpoints Redis
│       ├── neo4j.js               # Endpoints Neo4j
│       └── cassandra.js           # Endpoints Cassandra
│
├── db/                            # Seeds y scripts de bases de datos
│   ├── edugrade_rf1_seed_10.json            # Seed MongoDB (10 registros)
│   ├── edugrade_rf2_redis_seed_10.resp      # Seed Redis (reglas conversión)
│   ├── edugrade_rf3_neo4j_seed_10.cypher    # Seed Neo4j (grafo)
│   ├── edugrade_rf4_rf5_cassandra_seed_10.cql # Seed Cassandra (RF4+RF5)
│   └── txts/                                # Documentación de queries
│       ├── cassandra_seed_consolidado.cql   # Estructura keyspaces
│       ├── levantar colecciones en cassandra.txt
│       ├── levantar colecciones en mongo.txt
│       ├── levantar colecciones en neo.txt
│       └── levantar estructura en redis.txt
│
├── docker/                        # Configuración Docker
│   └── docker-compose.yml         # Definición de los 5 servicios
│
├── scripts/                       # Scripts de utilidad
│   ├── cargar_seeds.sh            # Carga automática de datos
│   ├── limpiar_todo.sh            # Limpieza completa de bases
│   └── probar_sistema.py          # Testing interactivo
│
└── pdfs/                          # Documentos del TPO (opcional)
```

---

## 🎓 Decisiones de Diseño

### ¿Por qué MongoDB para RF1?

- **Flexibilidad de esquema:** Las calificaciones tienen contextos variables (sistemas educativos diferentes)
- **ACID en documentos:** Write Concern MAJORITY garantiza consistencia
- **Snapshots:** Guardar contexto completo evita joins costosos
- **Inmutabilidad:** Modelo append-only con versionado en array `history`

### ¿Por qué Redis para RF2?

- **Velocidad:** <5ms de latencia para conversiones frecuentes
- **TTL automático:** Cache se invalida a las 24 horas
- **Reglas versionadas:** Permite actualizar reglas sin romper conversiones antiguas
- **Estructuras ricas:** Hash para reglas, List para conversiones

### ¿Por qué Neo4j para RF3?

- **Queries naturales:** Cypher expresa relaciones de forma declarativa
- **Path finding:** Encontrar trayectorias académicas es trivial
- **Rendimiento en grafos:** Relaciones se recorren en O(1)
- **Equivalencias:** Modelar prerequisitos y equivalencias entre materias

### ¿Por qué Cassandra para RF4 y RF5?

- **Escritura masiva:** Millones de logs de auditoría sin degradar rendimiento
- **Particionamiento:** Datos se distribuyen por región/año automáticamente
- **Consistency levels:** Flexible según necesidad (ONE para analytics, QUORUM para auditoría)
- **Append-only:** Perfecto para logs inmutables
- **Time-series:** Optimizado para datos temporales (auditoría)

### ¿Por qué Consistencia Eventual en RF4?

El requerimiento de analítica (RF4) permite eventual consistency porque:
- Los reportes no necesitan precisión al segundo
- Prioriza velocidad de escritura (no bloquea transacciones)
- Los agregados se recalculan periódicamente

### ¿Por qué Consistencia Fuerte en RF5?

El requerimiento de auditoría (RF5) requiere QUORUM porque:
- Los logs de auditoría son evidencia legal
- La cadena de hashes debe ser consistente
- Es crítico que no se pierdan eventos

---

## 🔐 Consideraciones de Seguridad

### Producción

Para un entorno de producción se recomienda:

1. **Credenciales:**
   - Cambiar todas las contraseñas
   - Usar variables de entorno con `.env`
   - Implementar rotación de secretos

2. **Red:**
   - No exponer puertos de bases de datos públicamente
   - Usar red Docker interna
   - Implementar reverse proxy (nginx)

3. **Autenticación API:**
   - Implementar JWT o OAuth2
   - Rate limiting
   - CORS configurado restrictivamente

4. **Auditoría:**
   - Logs centralizados
   - Alertas de eventos críticos
   - Monitoreo de integridad de hashes

---

## 📚 Referencias Técnicas

### Documentación Oficial

- [MongoDB Manual](https://docs.mongodb.com/)
- [Redis Documentation](https://redis.io/documentation)
- [Neo4j Cypher Manual](https://neo4j.com/docs/cypher-manual/)
- [Cassandra CQL Reference](https://cassandra.apache.org/doc/latest/cql/)
- [Express.js Guide](https://expressjs.com/)

### Patrones de Diseño Aplicados

- **Cache-Aside Pattern** (Redis): consulta cache → si miss, calcula y cachea
- **Event Sourcing** (Cassandra RF5): eventos inmutables con cadena de hashes
- **CQRS** (separación Read/Write): MongoDB para escrituras fuertes, Cassandra para lecturas analíticas
- **Snapshot Pattern** (MongoDB): guardar contexto completo en calificación
- **Saga Pattern** (flujo multibase): transacción coordinada entre bases

---

## 🤝 Contribución

Este es un proyecto académico del TPO de Introducción al Diseño de Datos II - UADE.

**Autores:**
- Equipo de desarrollo TPO IDII

**Profesores:**
- Cátedra de Introducción al Diseño de Datos II

---

## 📄 Licencia

MIT License - Proyecto Académico UADE 2026

---

## 🐛 Troubleshooting

### MongoDB no acepta conexiones

```bash
# Verificar que el contenedor esté corriendo
docker ps | grep mongo

# Ver logs
docker logs edugrade-mongo

# Reiniciar
docker restart edugrade-mongo
```

### Redis requiere autenticación

```bash
# Todas las conexiones a Redis deben usar contraseña: redis123
redis-cli -a redis123 ping
```

### Neo4j tarda mucho en iniciar

```bash
# Neo4j puede tardar 30-60 segundos en la primera inicialización
docker logs -f edugrade-neo4j

# Esperar el mensaje: "Started."
```

### Cassandra: "Cannot connect"

```bash
# Cassandra puede tardar 60-120 segundos
docker logs -f edugrade-cassandra

# Esperar: "Starting listening for CQL clients"

# Verificar conectividad
docker exec edugrade-cassandra cqlsh -e "DESCRIBE KEYSPACES"
```

### API no conecta a las bases

```bash
# Verificar variables de entorno en api/server.js
# Verificar que todos los contenedores estén en la misma red
docker network inspect docker_edugrade_net
```

### Error "ECONNREFUSED" en API

```bash
# Asegurarse que las bases están corriendo y escuchando en los puertos correctos
netstat -tuln | grep -E '27017|6379|7687|9042'
```

---

## ✅ Checklist de Verificación Post-Instalación

- [ ] Docker compose levantado (`docker ps` muestra 5-6 contenedores)
- [ ] MongoDB responde (`docker exec edugrade-mongo mongosh --eval "db.version()"`)
- [ ] Redis responde (`docker exec edugrade-redis redis-cli -a redis123 ping`)
- [ ] Neo4j responde (`docker exec edugrade-neo4j cypher-shell -u neo4j -p "Neo4j2026!" "RETURN 1"`)
- [ ] Cassandra responde (`docker exec edugrade-cassandra cqlsh -e "DESCRIBE KEYSPACES"`)
- [ ] Keyspaces Cassandra creados (`edugrade_analitica`, `edugrade_auditoria`)
- [ ] Seeds cargados (10 registros en cada base)
- [ ] API iniciada (`curl http://localhost:3000` retorna JSON)
- [ ] Endpoints funcionan (probar al menos uno de cada base)
- [ ] Neo4j Browser accesible (http://localhost:7474)
- [ ] Redis Commander accesible (http://localhost:8081)

---

## 📞 Contacto

Para consultas sobre el proyecto académico:
- Repositorio: https://github.com/tsamaan/Sistema-Nacional-de-Calificaciones-Multimodelo---TPO-IDII
- Universidad: UADE
- Materia: Introducción al Diseño de Datos II

---

**¡Gracias por revisar EduGrade Global!** 🎓✨