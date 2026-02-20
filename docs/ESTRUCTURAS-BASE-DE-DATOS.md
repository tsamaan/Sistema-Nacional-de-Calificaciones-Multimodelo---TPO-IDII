# 📊 Estructuras de Base de Datos - EduGrade Global

**Sistema Nacional de Calificaciones Multimodelo**  
Documentación completa de esquemas y estructuras de datos

---

## 🗂️ Índice

1. [MongoDB - Fuente de Verdad (RF1)](#mongodb)
2. [Redis - Cache de Conversiones (RF2)](#redis)
3. [Neo4j - Grafo de Equivalencias (RF3)](#neo4j)
4. [Cassandra - Analítica y Auditoría (RF4, RF5)](#cassandra)

---

## 🍃 MongoDB

**Base de datos:** `edugrade`  
**Propósito:** Fuente de verdad transaccional con write concern MAJORITY  
**Total colecciones:** 5

### Colección: `calificaciones`

Almacena las calificaciones originales con snapshots de contexto académico e inmutabilidad.

```json
{
  "_id": "ObjectId | string",
  "record_id": "string (único)",
  "student_id": "string",
  "zone": "string",
  
  "student_snapshot": {
    "full_name": "string",
    "dob": "ISODate",
    "nationality": "string (código país)"
  },
  
  "institution_snapshot": {
    "institution_id": "string",
    "name": "string",
    "country": "string",
    "region": "string"
  },
  
  "academic_context": {
    "academic_year": "int",
    "term": "string",
    "level": "string (secondary|post_secondary)",
    "cycle": "string"
  },
  
  "subject_snapshot": {
    "subject_id": "string",
    "name": "string",
    "course_code": "string"
  },
  
  "evaluation": {
    "type": "string (final|partial)",
    "date": "ISODate",
    "components": [
      {
        "component_type": "string (exam|coursework|project)",
        "weight": "double",
        "raw": {
          "grade": "string|number"
        }
      }
    ],
    "notes": "string (opcional)"
  },
  
  "original_grade": {
    "system": "string (AR|US|UK|DE)",
    "scale_type": "string (numeric|letter)",
    "value": "string|number",
    "passed": "boolean",
    "details": {
      "qualification": "string",
      "exam_board": "string (opcional)",
      "components": "string (opcional)"
    }
  },
  
  "evidence": [
    {
      "kind": "string (acta|norm_ref|certificate)",
      "ref": "string (referencia externa)"
    }
  ],
  
  "immutability": {
    "created_at": "ISODate",
    "created_by": "string (actor)",
    "immutable_id": "string (único)",
    "integrity_hash_sha256": "string (hash SHA256)"
  },
  
  "history": [
    {
      "action": "string (correction|annotation)",
      "timestamp": "ISODate",
      "actor": "string",
      "previous_value": "any"
    }
  ]
}
```

**Índices:**
- `_id` (automático)
- `record_id` (único)
- `student_id`
- `original_grade.system`
- `academic_context.academic_year`

---

### Colección: `estudiantes`

```json
{
  "_id": "ObjectId | string",
  "region": "string (requerido)",
  "full_name": "string (requerido)",
  
  "documento": {
    "tipo": "string (DNI|PASSPORT|etc)",
    "numero": "string"
  },
  
  "academic_history": [
    {
      "country": "string",
      "instance_type": "string (secondary|university)",
      "board": "string (opcional)",
      "details": {}
    }
  ],
  
  "created_at": "ISODate",
  "updated_at": "ISODate"
}
```

**Índices:**
- `documento.tipo + documento.numero` (único)
- `region`

---

### Colección: `instituciones`

```json
{
  "_id": "ObjectId | string",
  "region": "string (requerido)",
  "pais": "string (requerido)",
  "codigo_sistema": "string (requerido)",
  "codigo_externo": "string (opcional)",
  "nombre": "string (requerido)",
  "metadata": {},
  "created_at": "ISODate",
  "updated_at": "ISODate"
}
```

**Índices:**
- `codigo_sistema + codigo_externo`
- `region`

---

### Colección: `materias`

```json
{
  "_id": "ObjectId | string",
  "id_institucion": "ObjectId | string (FK)",
  "nombre": "string (requerido)",
  "codigo_sistema": "string",
  "codigo_externo": "string",
  "metadata": {},
  "created_at": "ISODate",
  "updated_at": "ISODate"
}
```

**Índices:**
- `id_institucion + nombre`
- `codigo_sistema + codigo_externo`

---

### Colección: `trayectorias`

```json
{
  "_id": "ObjectId | string",
  "id_estudiante": "ObjectId | string (FK)",
  "id_institucion": "ObjectId | string (FK)",
  "fecha_inicio": "ISODate (requerido)",
  "fecha_fin": "ISODate | null",
  "estado": "string (activo|finalizado|suspendido)",
  "detalles": {},
  "created_at": "ISODate",
  "updated_at": "ISODate"
}
```

**Índices:**
- `id_estudiante + fecha_inicio` (DESC)

---

## 🔴 Redis

**Propósito:** Cache in-memory para reglas de conversión y resultados convertidos  
**Estructura:** Key-Value con Hashes y Strings

### Patrón 1: Reglas de Conversión

**Pattern:** `regla:{FROM}#{TO}:{ORGANISMO}:{NIVEL}:{ANIO}:{VERSION}`

**Ejemplo:** `regla:AR#ZA7:MINISTERIO:SECUNDARIO:2025:1`

**Tipo:** Hash (HSET)

**Campos:**
```
from = "AR"
to = "ZA7"
version = "1"
organismo = "MINISTERIO"
nivel = "SECUNDARIO"
anio = "2025"
metodo = "tabla"
vigencia_desde = "2025-01-01"
vigencia_hasta = "2025-12-31"
mapping = '{"REEMPLAZAR":"AR->ZA7"}'  # JSON string
```

**Comandos:**
```bash
HGETALL regla:AR#ZA7:MINISTERIO:SECUNDARIO:2025:1
HGET regla:AR#ZA7:MINISTERIO:SECUNDARIO:2025:1 mapping
```

---

### Patrón 2: Puntero de Versión Activa

**Pattern:** `regla_activa:{FROM}#{TO}:{ORGANISMO}:{NIVEL}:{ANIO}`

**Ejemplo:** `regla_activa:AR#ZA7:MINISTERIO:SECUNDARIO:2025`

**Tipo:** String (SET)

**Valor:** `"1"` (número de versión activa)

**Comandos:**
```bash
GET regla_activa:AR#ZA7:MINISTERIO:SECUNDARIO:2025
SET regla_activa:AR#ZA7:MINISTERIO:SECUNDARIO:2025 1
```

---

### Patrón 3: Cache de Conversiones

**Pattern:** `conv:{ID_CALIFICACION}:{TO}:{VERSION}`

**Ejemplo:** `conv:grd_000001:ZA7:1`

**Tipo:** String con TTL (SETEX)

**Valor:** JSON string
```json
{
  "za_1_7": 6,
  "src": {
    "pais": "UK",
    "valor": "B"
  },
  "regla_version": 1
}
```

**Comandos:**
```bash
SETEX conv:grd_000001:ZA7:1 86400 '{"za_1_7":6,"src":{"pais":"UK","valor":"B"},"regla_version":1}'
GET conv:grd_000001:ZA7:1
TTL conv:grd_000001:ZA7:1
```

**TTL:** 86400 segundos (24 horas)

---

### Patrón 4: Metadata de Reglas (Legacy)

**Pattern:** `RULE#{FROM}#{TO}#{ORGANISMO}#{VERSION}`

**Ejemplo:** `RULE#AR#US#MINEDU_ZA#v2025-01`

**Tipo:** String (JSON completo de la regla)

---

### Patrón 5: Datasets por RF

**Pattern:** `DATASET#{RF}#{TIPO}`

**Ejemplo:** `DATASET#RF2#RECORD_IDS`

**Tipo:** Set o List con IDs relacionados

---

## 🟢 Neo4j

**Propósito:** Grafo de equivalencias académicas y prerequisitos  
**Base de datos:** `neo4j` (default)

### Nodos (Labels)

#### 1. Student (Estudiante)

**Labels:** `Student` o `Estudiante`

**Propiedades:**
```cypher
{
  student_id: "string (único)",
  full_name: "string",
  nationality: "string (código país)",
  dob: "date"
}
```

**Constraints:**
```cypher
CREATE CONSTRAINT id_estudiante_unico IF NOT EXISTS
FOR (e:Estudiante) REQUIRE e.id_estudiante IS UNIQUE;
```

**Ejemplo:**
```cypher
(:Student {
  student_id: "STU-0001",
  full_name: "Liam Nkosi",
  nationality: "ZA",
  dob: date("2007-05-14")
})
```

---

#### 2. Institution (Institucion)

**Labels:** `Institution` o `Institucion`

**Propiedades:**
```cypher
{
  institution_id: "string (único)",
  name: "string",
  country: "string",
  region: "string",
  type: "string (university|secondary)"
}
```

**Constraints:**
```cypher
CREATE CONSTRAINT id_institucion_unico IF NOT EXISTS
FOR (i:Institucion) REQUIRE i.id_institucion IS UNIQUE;
```

**Índices:**
```cypher
CREATE INDEX institucion_geo IF NOT EXISTS
FOR (i:Institucion) ON (i.pais, i.region);
```

---

#### 3. Subject / Materia

**Labels:** `Subject` o `Materia`

**Propiedades:**
```cypher
{
  subject_id: "string",           # Para Subject
  id_materia: "string (único)",   # Para Materia
  name: "string",
  nombre: "string",
  codigo_sistema: "string",
  nivel: "string (secundario|universitario)",
  course_code: "string (opcional)"
}
```

**Constraints:**
```cypher
CREATE CONSTRAINT id_materia_unico IF NOT EXISTS
FOR (m:Materia) REQUIRE m.id_materia IS UNIQUE;
```

**Índices:**
```cypher
CREATE INDEX materia_lookup IF NOT EXISTS
FOR (m:Materia) ON (m.codigo_sistema, m.nivel);

CREATE INDEX materia_nombre IF NOT EXISTS
FOR (m:Materia) ON (m.nombre);
```

**Ejemplo:**
```cypher
(:Materia {
  id_materia: "MAT_AR_MAT1",
  nivel: "secundario",
  nombre: "Matemática I",
  codigo_sistema: "AR"
})
```

---

#### 4. GradeRecord

**Label:** `GradeRecord`

**Propiedades:**
```cypher
{
  record_id: "string (único)",
  grade_value: "string|number",
  system: "string",
  passed: "boolean",
  date: "datetime"
}
```

---

### Relaciones (Relationship Types)

#### 1. EQUIVALENT_TO / EQUIVALENTE_A

**Tipo:** Bidireccional entre `Subject` o `Materia`

**Propiedades:**
```cypher
{
  type: "string (full|partial)",
  normative_ref: "string (referencia legal)",
  organismo: "string (opcional)",
  version_regla: "string (opcional)",
  vigente_desde: "date (opcional)",
  vigente_hasta: "date (opcional)",
  tipo: "string (opcional)"
}
```

**Ejemplo:**
```cypher
(m1:Subject)-[:EQUIVALENT_TO {
  type: "full",
  normative_ref: "NORM-ARUK-CS-2025"
}]-(m2:Subject)
```

**Índice:**
```cypher
CREATE INDEX equiv_filtros IF NOT EXISTS
FOR ()-[r:EQUIVALENTE_A]-() ON (
  r.organismo,
  r.version_regla,
  r.vigente_desde,
  r.vigente_hasta,
  r.tipo
);
```

---

#### 2. PREREQUISITE_FOR / PREREQUISITO_DE

**Tipo:** Dirigido de materia prerequisito → materia dependiente

**Propiedades:**
```cypher
{
  mandatory: "boolean",
  notes: "string (opcional)"
}
```

**Ejemplo:**
```cypher
(m1:Materia)-[:PREREQUISITO_DE {mandatory: true}]->(m2:Materia)
```

---

#### 3. HAS_RECORD

**Tipo:** `(Student)-[:HAS_RECORD]->(GradeRecord)`

**Propiedades:**
```cypher
{
  timestamp: "datetime"
}
```

---

#### 4. FOR_SUBJECT

**Tipo:** `(GradeRecord)-[:FOR_SUBJECT]->(Subject)`

---

#### 5. AT_INSTITUTION

**Tipo:** `(GradeRecord)-[:AT_INSTITUTION]->(Institution)`

---

#### 6. ATTENDED / ASISTIO

**Tipo:** `(Student)-[:ATTENDED]->(Institution)`

**Propiedades:**
```cypher
{
  from_date: "date",
  to_date: "date (opcional)",
  status: "string (active|graduated|withdrawn)"
}
```

---

#### 7. TOOK

**Tipo:** `(Student)-[:TOOK]->(Subject)`

---

#### 8. CONVALIDATES

**Tipo:** Relación de convalidación entre materias

---

#### 9. OFRECE

**Tipo:** `(Institucion)-[:OFRECE]->(Materia)`

---

### Queries de Ejemplo

```cypher
// Buscar equivalencias de una materia en un país destino
MATCH (m1:Subject {subject_id: 'Math101_US'})-[:EQUIVALENT_TO]-(m2:Subject)
WHERE m2.country = 'AR'
RETURN m1, m2

// Cadena de prerequisitos (hasta 3 niveles)
MATCH path = (m1:Materia)-[:PREREQUISITO_DE*1..3]->(m2:Materia {id_materia: 'MAT_AR_CAL2'})
RETURN path

// Historial académico de estudiante
MATCH (s:Student {student_id: 'STU-0001'})-[:HAS_RECORD]->(gr:GradeRecord)-[:FOR_SUBJECT]->(sub:Subject)
RETURN s, gr, sub
```

---

## 🟡 Cassandra

**Keyspaces:** 3 (`edugrade`, `edugrade_analitica`, `edugrade_auditoria`)  
**Propósito:** Analítica agregada (RF4) y auditoría append-only (RF5)  
**Replicación:** SimpleStrategy, factor 1

---

### Keyspace: `edugrade_analitica`

#### Tabla: `promedio_por_region_anio`

**Propósito:** Agregados estadísticos para RF4 (analítica)

**Schema:**
```cql
CREATE TABLE edugrade_analitica.promedio_por_region_anio (
  -- Partition Key (compuesta)
  region text,
  anio int,
  
  -- Clustering Keys
  codigo_sistema text,
  id_materia text,
  id_institucion text,
  
  -- Columnas de datos
  n bigint,                    # cantidad de notas
  suma double,                 # suma total
  suma_cuadrados double,       # para calcular varianza
  actualizado_en timestamp,
  
  PRIMARY KEY ((region, anio), codigo_sistema, id_materia, id_institucion)
) WITH CLUSTERING ORDER BY (
  codigo_sistema ASC,
  id_materia ASC,
  id_institucion ASC
);
```

**Ejemplo de datos:**
```
region  | anio | codigo_sistema | id_materia | id_institucion | n | suma | suma_cuadrados | actualizado_en
--------|------|----------------|------------|----------------|---|------|----------------|---------------
UK-SCT  | 2023 | UK             | mat_001    | inst_UK_01     | 2 | 6    | 18             | 2026-02-18 ...
AR-BA   | 2026 | AR             | mat_005    | inst_AR_07     | 6 | 18   | 70             | 2026-02-18 ...
US-NY   | 2025 | US             | mat_010    | inst_US_05     | 3 | 9    | 33             | 2026-02-18 ...
```

**Queries típicos:**
```cql
-- Promedios de una región y año
SELECT * FROM edugrade_analitica.promedio_por_region_anio
WHERE region = 'AR-BA' AND anio = 2026;

-- Filtrar por sistema
SELECT * FROM edugrade_analitica.promedio_por_region_anio
WHERE region = 'UK-SCT' AND anio = 2023 AND codigo_sistema = 'UK';

-- Calcular promedio general
SELECT region, anio, SUM(suma) / SUM(n) as promedio_general
FROM edugrade_analitica.promedio_por_region_anio
WHERE region = 'AR-BA' AND anio = 2026;
```

**Datos actuales:** ~3,000 registros  
**Regiones disponibles:** UK-SCT, US-CA, US-NY, AR-BA, AR-CBA, DE-BY, DE-BE, UK-ENG  
**Años disponibles:** 2023-2026

---

### Keyspace: `edugrade_auditoria`

#### Tabla: `registro_auditoria_por_entidad_mes`

**Propósito:** Trazabilidad inmutable append-only para RF5

**Schema:**
```cql
CREATE TABLE edugrade_auditoria.registro_auditoria_por_entidad_mes (
  -- Partition Key (compuesta)
  id_entidad text,            # grd_000001, stu_000005, etc.
  aaaamm text,                # formato: YYYYMM (202602)
  
  -- Clustering Key
  marca_tiempo timestamp,     # DESC para orden cronológico inverso
  
  -- Columnas de auditoría
  tipo_entidad text,          # GRADE, STUDENT, INSTITUTION
  accion text,                # GRADE_CREATED, GRADE_UPDATED, etc.
  id_actor text,              # user_demo, auditor_ministry
  ip text,                    # 127.0.0.1
  hash_anterior text,         # 0 para creación
  hash_nuevo text,            # SHA256 del estado actual
  carga_util text,            # JSON string con detalles
  
  PRIMARY KEY ((id_entidad, aaaamm), marca_tiempo)
) WITH CLUSTERING ORDER BY (marca_tiempo DESC);
```

**Ejemplo de datos:**
```
id_entidad    | aaaamm | marca_tiempo          | accion        | tipo_entidad | hash_nuevo                           | carga_util
--------------|--------|------------------------|---------------|--------------|--------------------------------------|-----------
grd_000008825 | 202602 | 2026-02-18 23:15:06   | GRADE_CREATED | GRADE        | b680ffe44109077611dc6fca2bde86c4...  | {"id_calificacion":"grd_000008825","sistema":"UK","valor_raw":"A","za7":6}
grd_000007621 | 202512 | 2026-02-18 23:15:04   | GRADE_CREATED | GRADE        | 2a701d135da40b2a76280c46c581bd03...  | {"id_calificacion":"grd_000007621","sistema":"UK","valor_raw":"B","za7":5}
```

**Queries típicos:**
```cql
-- Auditoría de una entidad en un mes
SELECT * FROM edugrade_auditoria.registro_auditoria_por_entidad_mes
WHERE id_entidad = 'grd_000008825' AND aaaamm = '202602';

-- Últimos 10 eventos de una entidad
SELECT * FROM edugrade_auditoria.registro_auditoria_por_entidad_mes
WHERE id_entidad = 'grd_000007621' AND aaaamm = '202512'
LIMIT 10;
```

**Datos actuales:** 10,000 registros  
**Meses disponibles:** 202306, 202401, 202404, 202408, 202410, 202512, 202602, 202612  
**Entidades:** grd_* (grades)

---

### Keyspace: `edugrade` (RF4 Fact Tables)

#### Tabla: `rf4_fact_grades_by_region_year_system`

**Propósito:** Tabla fact dimensional para consultas analíticas complejas

**Schema:**
```cql
CREATE TABLE edugrade.rf4_fact_grades_by_region_year_system (
  -- Partition Key (compuesta)
  region text,
  academic_year int,
  system text,
  
  -- Clustering Keys
  institution_id text,
  subject_id text,
  event_ts timestamp,         # DESC
  record_id text,
  
  -- Dimensiones y métricas
  student_id text,
  grade_raw text,
  grade_norm_0_100 double,
  passed boolean,
  
  PRIMARY KEY ((region, academic_year, system), institution_id, subject_id, event_ts, record_id)
) WITH CLUSTERING ORDER BY (
  institution_id ASC,
  subject_id ASC,
  event_ts DESC,
  record_id ASC
);
```

**Ejemplo de datos:**
```
region  | academic_year | system | institution_id | subject_id | record_id   | grade_raw | grade_norm_0_100 | passed
--------|---------------|--------|----------------|------------|-------------|-----------|------------------|-------
ZA-BFN  | 2024          | AR     | INS-004        | SUB-MATH   | GR-2024-0008| 5         | 50               | true
ZA-CPT  | 2025          | US     | INS-004        | SUB-CS     | GR-2025-0001| F         | 0                | false
```

**Datos actuales:** 20 registros (tabla dimensional de prueba)

---

#### Tabla: `rf5_audit_timeline_by_entity_month`

**Propósito:** Timeline de auditoría por entidad (alternativa a keyspace separado)

**Schema:**
```cql
CREATE TABLE edugrade.rf5_audit_timeline_by_entity_month (
  -- Partition Key
  entity_id text,
  month_bucket text,          # formato: YYYY-MM
  
  -- Clustering Key
  ts timestamp,               # ASC para orden cronológico
  
  -- Datos de auditoría
  event_type text,
  actor text,
  ip text,
  hash_anterior text,
  hash_nuevo text,
  integrity_hash_sha256 text,
  details_json text,
  record_id text,
  
  PRIMARY KEY ((entity_id, month_bucket), ts)
) WITH CLUSTERING ORDER BY (ts ASC);
```

---

## 📌 Resumen de Arquitectura

### Distribución de Responsabilidades

| Base de Datos | RF | Propósito | Consistency | Datos Actuales |
|--------------|-----|-----------|-------------|----------------|
| **MongoDB** | RF1 | Source of truth transaccional | MAJORITY | 20 calificaciones |
| **Redis** | RF2 | Cache de conversiones | Eventual | 4 reglas, ~20 conversions |
| **Neo4j** | RF3 | Grafo académico | Read-heavy | 54 nodos, 124 relaciones |
| **Cassandra (analitica)** | RF4 | Agregados estadísticos | Eventual | ~3,000 registros |
| **Cassandra (auditoria)** | RF5 | Trazabilidad inmutable | QUORUM | 10,000 eventos |

---

### Flujo de Datos

1. **Escritura Síncrona:**
   - MongoDB (calificaciones) → write concern MAJORITY
   - Cassandra (auditoria) → append-only, QUORUM

2. **Escritura On-Demand:**
   - Redis: lazy loading al solicitar conversión
   - Neo4j: actualización periódica de equivalencias

3. **Escritura Asíncrona:**
   - Cassandra (analitica): batch jobs agregando promedios

---

## 🔗 Referencias

- [FLUJO-DE-DATOS.md](./FLUJO-DE-DATOS.md) - Flujo completo de datos
- [API README](./api/README.md) - Documentación de endpoints
- [Docker Compose](./docker/docker-compose.yml) - Configuración de servicios

---

**Última actualización:** 19 de febrero de 2026  
**Versión:** 1.0.0
