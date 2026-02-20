# 🔄 Flujo de Datos - EduGrade Global

## Arquitectura Multimodelo

Este documento explica cómo fluyen los datos a través de las 4 bases de datos del sistema EduGrade Global.

---

## 📋 Resumen Ejecutivo

| Base de Datos | Rol | Patrón de Escritura | Consistencia |
|---------------|-----|---------------------|--------------|
| **MongoDB (RF1)** | Source of Truth | Síncrona, MAJORITY | Fuerte |
| **Redis (RF2)** | Cache + Reglas | On-demand | Eventual |
| **Neo4j (RF3)** | Grafo de Equivalencias | Read-heavy | Fuerte |
| **Cassandra RF4** | Analítica | Asíncrona, ONE | Eventual |
| **Cassandra RF5** | Auditoría | Síncrona, QUORUM | Fuerte |

---

## 🔄 FLUJO COMPLETO DE DATOS

### **FASE 1: Alta de Calificación (RF1 - MongoDB)**

```
┌─────────────────────────────────────────────────────┐
│ 1. ENTRADA: Nueva calificación                     │
│    • Estudiante: stu_000001                         │
│    • Institución: inst_AR_01                        │
│    • Materia: mat_001                               │
│    • Sistema origen: AR (1-10)                      │
│    • Valor: 8                                       │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│ 2. ESCRITURA EN MONGODB (SOURCE OF TRUTH)          │
│    ✅ Write Concern: MAJORITY                       │
│    ✅ Read Preference: PRIMARY                      │
│                                                     │
│    {                                                │
│      "_id": "grd_000001",                          │
│      "id_estudiante": "stu_000001",                │
│      "id_materia": "mat_001",                      │
│      "periodo": {"anio": 2025},                    │
│      "original": {                                  │
│        "sistema": "AR",                            │
│        "valor_raw": 8,                             │
│        "valor_num_za7": 6.0  ← Conversión base    │
│      },                                            │
│      "conversiones": [],  ← Inicialmente vacío     │
│      "inmutabilidad": {                            |
│        "version": 1,                                │
│        "hash": "abc123...",                         │
│        "event_id": "evt_grd_000001"                 │
│      }                                              │
│    }                                                │
└─────────────────────────────────────────────────────┘
```

**Características:**
- MongoDB es la **única fuente de verdad**
- Escritura con `writeConcern: { w: "majority" }`
- Inmutabilidad: el campo `original` nunca se modifica
- Versionado: cada corrección crea un nuevo documento

---

### **FASE 2: Auditoría (RF5 - Cassandra)**

```
┌─────────────────────────────────────────────────────┐
│ 3. REGISTRO DE AUDITORÍA (Inmediatamente después)  │
│    ⚡ Write: QUORUM consistency                     │
│    📝 Keyspace: edugrade_auditoria                  │
│    📝 Tabla: registro_auditoria_por_entidad_mes    │
│                                                     │
│    INSERT INTO ... VALUES (                         │
│      id_entidad: "grd_000001",                     │
│      aaaamm: "202501",                             │
│      marca_tiempo: 2025-01-15T10:30:00Z,           │
│      tipo_entidad: "GRADE",                        │
│      accion: "GRADE_CREATED",                      │
│      id_actor: "user_demo",                        │
│      ip: "127.0.0.1",                              │
│      hash_anterior: "0",                           │
│      hash_nuevo: "abc123...",  ← Enlace con Mongo │
│      carga_util: "{...}"                           │
│    )                                               │
└─────────────────────────────────────────────────────┘
```

**Características:**
- Append-only (nunca se borra ni modifica)
- Cadena de hashes (blockchain-style)
- Consistency Level: QUORUM (mayoría de réplicas)
- Particionado por entidad + mes

---

### **FASE 3: Conversión a ZA7 (RF2 - Redis)**

```
┌─────────────────────────────────────────────────────┐
│ 4. CONSULTAMOS CONVERSIÓN (Solo cuando se solicita)│
│    🔍 Cliente solicita: "convertir a ZA7"           │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│ 5. BUSCAR VERSIÓN ACTIVA DE REGLA                  │
│    GET regla_activa:AR#ZA7:MINISTERIO:SECUNDARIO:2025│
│    → Retorna: "1" (versión activa)                  │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│ 6. VERIFICAR CACHE                                  │
│    GET conv:grd_000001:ZA7:1                       │
│    ❌ Cache miss → Necesitamos calcular             │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│ 7. LEER REGLA COMPLETA                             │
│    HGETALL regla:AR#ZA7:MINISTERIO:SECUNDARIO:2025:1│
│    {                                                │
│      "from": "AR",                                 │
│      "to": "ZA7",                                  │
│      "metodo": "tabla",                            │
│      "mapping": "{\"8\": 6, \"9\": 6, \"10\": 7}"  │
│    }                                               │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│ 8. CALCULAR Y CACHEAR RESULTADO                    │
│    Aplicar regla: AR(8) → ZA7(6)                   │
│    SETEX conv:grd_000001:ZA7:1 86400 "{...}"       │
│    ⏰ TTL: 24 horas                                 │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│ 9. ACTUALIZAR MONGODB CON CONVERSIÓN               │
│    db.calificaciones.updateOne(                    │
│      {_id: "grd_000001"},                          │
│      {$push: {conversiones: {                      │
│        to: "ZA7",                                  │
│        version_regla: 1,                           │
│        resultado: {"za_1_7": 6},                   │
│        timestamp: now()                            │
│      }}}                                           │
│    )                                               │
│    ⚠️ NO modifica "original" (inmutable)            │
└─────────────────────────────────────────────────────┘
```

**Características:**
- **Lazy loading**: solo se calcula cuando se solicita
- **Cache-aside pattern**: primero cache, luego compute
- TTL de 24 horas (configurable)
- Reglas versionadas: permite cambios sin impactar cálculos anteriores
- El resultado de la conversión **sí se persiste en MongoDB** como historial

---

### **FASE 4: Agregación Analítica (RF4 - Cassandra)**

```
┌─────────────────────────────────────────────────────┐
│ 10. ACTUALIZAR AGREGADOS (Batch o tiempo real)     │
│     ⚡ Write: ONE consistency (velocidad)           │
│     📊 Keyspace: edugrade_analitica                 │
│     📊 Tabla: promedio_por_region_anio             │
│                                                     │
│     UPDATE promedio_por_region_anio SET            │
│       n = n + 1,                                   │
│       suma = suma + 6.0,                           │
│       suma_cuadrados = suma_cuadrados + 36.0,      │
│       actualizado_en = now()                       │
│     WHERE                                          │
│       region = 'AR-BA' AND                         │
│       anio = 2025 AND                              │
│       codigo_sistema = 'AR' AND                    │
│       id_materia = 'mat_001' AND                   │
│       id_institucion = 'inst_AR_01';               │
│                                                     │
│     📈 Permite calcular: promedio, desv. estándar   │
└─────────────────────────────────────────────────────┘
```

**Características:**
- **Escritura asíncrona**: no bloquea el alta de calificaciones
- Consistency Level: ONE (prioriza velocidad)
- Eventual consistency aceptable para reportes
- Agregados precalculados: n, suma, suma_cuadrados
- Permite calcular promedio y desviación estándar sin recorrer todas las notas

---

### **FASE 5: Grafo de Equivalencias (RF3 - Neo4j)**

```
┌─────────────────────────────────────────────────────┐
│ 11. CONSULTA DE EQUIVALENCIAS (On demand)          │
│     🔍 No se escribe en cada calificación          │
│     🔍 Se consulta cuando:                          │
│        • Se necesita validar equivalencias          │
│        • Se buscan trayectorias académicas          │
│        • Se verifican prerequisitos                 │
│                                                     │
│     MATCH (m1:Materia {id_materia: 'mat_001_AR'})  │
│           -[e:EQUIVALENTE_A]->                      │
│           (m2:Materia {id_materia: 'mat_001_US'})  │
│     WHERE e.vigente_desde <= date()                │
│       AND e.vigente_hasta >= date()                │
│     RETURN e                                       │
└─────────────────────────────────────────────────────┘
```

**Características:**
- **Read-heavy**: principalmente consultas
- No se escribe por cada calificación
- Se actualiza solo cuando cambian reglas ministeriales
- Permite consultas complejas:
  - Equivalencias entre materias de distintos países
  - Prerequisitos (ej: "Cálculo II requiere Cálculo I")
  - Trayectorias académicas válidas
  - Validación de convalidaciones

---

## 📊 ORDEN DE ESCRITURA

### ✅ Escritura Síncrona (Bloquea hasta completar)

```
1. MongoDB (RF1)         ← SOURCE OF TRUTH
   • Write Concern: MAJORITY
   • Si falla aquí → ROLLBACK total
   • Tiempo: ~50-100ms

2. Cassandra Auditoría (RF5)
   • Write Consistency: QUORUM
   • Hash enlaza con MongoDB
   • Si falla → Log error pero NO rollback MongoDB
   • Tiempo: ~10-30ms
```

### ⚡ Procesamiento On-Demand (Solo cuando se solicita)

```
3. Redis (RF2) - Conversiones
   • Lazy: solo cuando cliente solicita conversión
   • Cache-aside pattern
   • TTL: 24 horas
   • Tiempo: ~1-5ms (hit) | ~10-20ms (miss)

4. Neo4j (RF3) - Equivalencias
   • Read-only: consulta relaciones existentes
   • NO se escribe por cada calificación
   • Se actualiza cuando cambian reglas ministeriales
   • Tiempo: ~20-50ms por query
```

### 🔄 Escritura Asíncrona (Background jobs)

```
5. Cassandra Analítica (RF4)
   • Write Consistency: ONE (velocidad)
   • Batch updates cada N minutos o N registros
   • Eventual consistency OK para reportes
   • Tiempo: no impacta latencia del usuario
```

---

## 🎯 EJEMPLO COMPLETO: Estudiante argentino va a EEUU

### Caso: María (Argentina) quiere estudiar en Universidad de California

#### 1️⃣ ALTA EN ARGENTINA (2024)

```javascript
// POST /api/grades
{
  id_estudiante: "maria_001",
  id_materia: "matematica_ar",
  sistema: "AR",
  valor: 9
}
```

**Flujo interno:**
```
MongoDB: {
  id: "grd_maria_mat_2024",
  id_estudiante: "maria_001",
  id_materia: "matematica_ar",
  original: {
    sistema: "AR",
    valor_raw: 9,
    valor_num_za7: 6  // Conversión base local
  },
  conversiones: []
}

Cassandra RF5: INSERT INTO auditoria...
  accion: "GRADE_CREATED"
  hash_nuevo: "abc123..."
```

#### 2️⃣ SOLICITA EQUIVALENCIA PARA EEUU (2025)

```javascript
// GET /api/grades/maria_001/convert/US
```

**Flujo interno:**
```
1. Redis: GET conv:grd_maria_mat_2024:US:1
   → Cache miss

2. Redis: GET regla_activa:AR#US:MINISTERIO:SECUNDARIO:2025
   → "1"

3. Redis: HGETALL regla:AR#US:MINISTERIO:SECUNDARIO:2025:1
   → {"9": "A-", "10": "A"}

4. Calcular: AR(9) → US(A-)

5. Redis: SETEX conv:grd_maria_mat_2024:US:1 86400 '{"us_grade":"A-"}'

6. MongoDB: $push conversiones: {
     to: "US",
     version_regla: 1,
     resultado: {"us_grade": "A-"},
     timestamp: "2025-01-15T10:30:00Z"
   }
```

#### 3️⃣ UNIVERSIDAD DE CALIFORNIA CONSULTA EQUIVALENCIAS

```javascript
// GET /api/neo4j/equivalences?from=matematica_ar&to=calculus_us
```

**Neo4j Query:**
```cypher
MATCH (ar:Materia {nombre: 'Matemática AR'})
      -[e:EQUIVALENTE_A]->
      (us:Materia {nombre: 'Calculus I US'})
WHERE e.organismo = 'MINISTERIO'
  AND e.vigente_desde <= date()
  AND e.vigente_hasta >= date()
RETURN e
```

**Respuesta:**
```json
{
  "equivalente": true,
  "organismo": "MINISTERIO",
  "tipo": "COMPLETA",
  "vigencia": "2024-01-01 a 2026-12-31"
}
```

#### 4️⃣ ANALYTICS: Promedios regionales

```javascript
// GET /api/cassandra/analytics/regional?region=AR-BA&year=2025
```

**Cassandra RF4 Query:**
```cql
SELECT 
  region,
  anio,
  suma/n as promedio,
  SQRT((suma_cuadrados/n) - POWER(suma/n, 2)) as desviacion
FROM promedio_por_region_anio
WHERE region='AR-BA' AND anio=2025
```

**Respuesta:**
```json
{
  "region": "AR-BA",
  "anio": 2025,
  "promedio": 6.8,
  "desviacion": 0.8,
  "cantidad_notas": 125000
}
```

---

## ✅ VENTAJAS DE ESTE DISEÑO

| Aspecto | Beneficio |
|---------|-----------|
| **MongoDB como Source of Truth** | Un solo lugar para la verdad, write concern MAJORITY garantiza durabilidad |
| **Redis lazy loading** | Solo calcula conversiones solicitadas, ahorra CPU y memoria |
| **Cassandra RF4 async** | Reportes no afectan latencia de escritura de calificaciones |
| **Neo4j read-only** | Grafo se actualiza solo cuando cambian reglas oficiales (poco frecuente) |
| **Auditoría inmutable** | Cassandra RF5 append-only con cadena de hashes impide manipulación |
| **Versionado de reglas** | Permite cambiar criterios sin invalidar conversiones anteriores |
| **Inmutabilidad** | Calificaciones originales nunca se modifican, solo se agregan conversiones |

---

## 🚨 MANEJO DE ERRORES

```
SI FALLA MongoDB (RF1)
├─ ❌ Rechazar operación completa
├─ HTTP 500: "No se pudo persistir la calificación"
└─ NO se escriben las demás bases

SI FALLA Cassandra Auditoría (RF5)
├─ ⚠️ Log error crítico
├─ Calificación ya está en MongoDB (OK)
└─ Encolar para retry de auditoría

SI FALLA Redis (RF2)
├─ ⚠️ Calcular sin cache
├─ Performance degradada pero funcional
└─ Log warning

SI FALLA Cassandra Analytics (RF4)
├─ ⚠️ Encolar para batch posterior
├─ NO impacta al usuario
└─ Reportes pueden tener lag temporal

SI FALLA Neo4j (RF3)
├─ ⚠️ Responder sin validación de equivalencias
├─ Indicar al usuario: "No se pudo validar equivalencia"
└─ Permitir continuar con advertencia
```

---

## 🔐 GARANTÍAS DE CONSISTENCIA

### Consistencia Fuerte
- **MongoDB (RF1)**: Write Concern MAJORITY
- **Cassandra (RF5)**: Write Consistency QUORUM
- La calificación original es inmutable y está garantizada

### Consistencia Eventual
- **Cassandra (RF4)**: Write Consistency ONE
- Los reportes pueden tener un pequeño lag (segundos a minutos)
- Aceptable para analítica no crítica

### Cache
- **Redis (RF2)**: TTL de 24 horas
- Cache invalidation cuando se publica nueva versión de regla
- Key pattern: `conv:{id}:{to}:{version}`

---

## 📈 ESCALABILIDAD

### MongoDB (RF1)
- Sharding por `region` (geográfico)
- Índices compuestos para consultas frecuentes
- Read replicas para reporting

### Redis (RF2)
- Redis Cluster para alta disponibilidad
- Particionado automático por key
- Réplicas para failover

### Neo4j (RF3)
- Causal clustering para read scalability
- Sharding manual por región/país si es necesario
- Queries indexadas por id_materia

### Cassandra (RF4 + RF5)
- Particionado natural por región/año (RF4) y entidad/mes (RF5)
- Multi-datacenter replication para disaster recovery
- Compactation strategies: TimeWindowCompactionStrategy (RF5)

---

## 🔍 QUERIES TÍPICAS

### 1. Historial académico completo de un estudiante
```javascript
// MongoDB
db.calificaciones.find({
  id_estudiante: "maria_001"
}).sort({ "periodo.anio": -1, "evaluacion.fecha": -1 })
```

### 2. Conversión a sistema específico
```javascript
// 1. Redis: buscar en cache
// 2. Si no existe: calcular y cachear
// 3. Persistir en MongoDB
```

### 3. Validar equivalencia entre materias
```cypher
// Neo4j
MATCH (m1:Materia)-[e:EQUIVALENTE_A]->(m2:Materia)
WHERE m1.id_materia = 'mat_ar_001'
  AND m2.pais = 'US'
  AND e.vigente_desde <= date()
RETURN m2, e
```

### 4. Promedio regional por año
```cql
-- Cassandra RF4
SELECT region, suma/n as promedio
FROM promedio_por_region_anio
WHERE region = 'AR-BA' AND anio = 2025
```

### 5. Auditoría de cambios en una calificación
```cql
-- Cassandra RF5
SELECT marca_tiempo, accion, hash_nuevo
FROM registro_auditoria_por_entidad_mes
WHERE id_entidad = 'grd_000001'
  AND aaaamm = '202501'
ORDER BY marca_tiempo DESC
```

---

## 🎓 CONCLUSIÓN

Este diseño multimodelo aprovecha las fortalezas de cada base de datos:

- **MongoDB**: Documentos flexibles, transacciones ACID
- **Redis**: Velocidad in-memory, TTL, pub/sub
- **Neo4j**: Relaciones complejas, traversals eficientes
- **Cassandra**: Write throughput masivo, append-only, time-series

**El flujo es deliberadamente asíncrono donde es posible**, priorizando la experiencia del usuario (baja latencia) mientras mantiene **consistencia fuerte en los datos críticos** (calificaciones, auditoría).
