# 📋 PLAN DE ARQUITECTURA DE DATOS CONSISTENTE

**Fecha:** 20 de febrero de 2026  
**Objetivo:** Dataset pequeño (10 registros) consistente entre las 4 bases de datos

---

## 🎯 Objetivo General

Crear un dataset pequeño con **10 registros de calificaciones** que sea **consistente** entre las 4 bases de datos del sistema y permita probar el flujo completo:

```
PERSISTENCIA → CONVERSIÓN → RELACIONES → ANALYTICS → AUDITORÍA
(MongoDB)     (Redis)       (Neo4j)      (Cassandra)
```

---

## 📊 DISEÑO DEL DATASET

### 👥 Estudiantes (10 registros)

| student_id | Nombre Completo | Nacionalidad | Fecha Nac. | Institución Actual |
|------------|----------------|--------------|------------|-------------------|
| STU-0001 | Liam Nkosi | ZA | 2007-05-14 | INS-001 |
| STU-0002 | Sofía Danko | AR | 2006-11-02 | INS-003 |
| STU-0003 | Noah van der Merwe | ZA | 2006-08-19 | INS-002 |
| STU-0004 | Ava Smith | US | 2006-07-19 | INS-005 |
| STU-0005 | Oliver Patel | UK | 2007-01-30 | INS-007 |
| STU-0006 | Mia Johnson | US | 2005-10-08 | INS-006 |
| STU-0007 | Emma Iuzzolino | AR | 2006-02-21 | INS-004 |
| STU-0008 | Theo Samaan | ZA | 2005-12-11 | INS-001 |
| STU-0009 | Charlotte Brown | UK | 2006-06-15 | INS-007 |
| STU-0010 | Felix Müller | DE | 2007-03-22 | INS-008 |

**Distribución:**
- ZA (Sudáfrica): 3 estudiantes
- AR (Argentina): 2 estudiantes
- US (Estados Unidos): 2 estudiantes
- UK (Reino Unido): 2 estudiantes
- DE (Alemania): 1 estudiante

---

### 🏫 Instituciones (8 registros)

| institution_id | Nombre | País | Región | Sistema |
|----------------|--------|------|--------|---------|
| INS-001 | Cape Town Central High | ZA | Western Cape | ZA |
| INS-002 | Pretoria Academy | ZA | Gauteng | ZA |
| INS-003 | UADE Argentina | AR | CABA | AR |
| INS-004 | Buenos Aires High School | AR | Buenos Aires | AR |
| INS-005 | New York State HS | US | New York | US |
| INS-006 | California Tech High | US | California | US |
| INS-007 | London Sixth Form College | UK | London | UK |
| INS-008 | Berlin Gymnasium | DE | Berlin | DE |

**Distribución geográfica:**
- Sudáfrica: 2 (Western Cape, Gauteng)
- Argentina: 2 (CABA, Buenos Aires)
- Estados Unidos: 2 (New York, California)
- Reino Unido: 1 (London)
- Alemania: 1 (Berlin)

---

### 📚 Materias (8 registros base)

Las materias se replican según el sistema educativo que las usa:

| subject_id | Nombre | Sistemas | Instituciones |
|------------|--------|----------|---------------|
| SUB-MATH | Mathematics | AR, US, UK, DE | INS-001, INS-003, INS-005, INS-007, INS-008 |
| SUB-ENG | English | AR, US, UK | INS-001, INS-003, INS-005, INS-007 |
| SUB-CS | Computer Science | AR, US, UK | INS-003, INS-005, INS-007 |
| SUB-PHY | Physics | AR, UK | INS-003, INS-007 |
| SUB-CHEM | Chemistry | UK, DE | INS-007, INS-008 |
| SUB-BIO | Biology | US, UK | INS-005, INS-007 |
| SUB-HIST | History | UK, DE | INS-007, INS-008 |
| SUB-ECO | Economics | US | INS-005, INS-006 |

**Total variantes en Neo4j:** ~20 nodos (SUB-MATH:AR, SUB-MATH:US, SUB-MATH:UK, etc.)

---

### 📝 Calificaciones (10 registros)

| record_id | student_id | Institución | Materia | Sistema | Calificación | Aprobó | Año | Término |
|-----------|------------|-------------|---------|---------|--------------|--------|-----|---------|
| GR-2025-0001 | STU-0001 | INS-001 | SUB-MATH | ZA | 75% | ✅ | 2025 | T1 |
| GR-2025-0002 | STU-0002 | INS-003 | SUB-CS | AR | 8 | ✅ | 2025 | T1 |
| GR-2025-0003 | STU-0003 | INS-002 | SUB-ENG | ZA | 68% | ✅ | 2025 | T1 |
| GR-2025-0004 | STU-0004 | INS-005 | SUB-BIO | US | A (4.0) | ✅ | 2025 | T1 |
| GR-2025-0005 | STU-0005 | INS-007 | SUB-PHY | UK | B | ✅ | 2025 | T1 |
| GR-2024-0006 | STU-0006 | INS-006 | SUB-ECO | US | C+ (2.3) | ✅ | 2024 | T4 |
| GR-2024-0007 | STU-0007 | INS-004 | SUB-MATH | AR | 4 | ❌ | 2024 | T4 |
| GR-2024-0008 | STU-0008 | INS-001 | SUB-CS | ZA | 82% | ✅ | 2024 | T4 |
| GR-2024-0009 | STU-0009 | INS-007 | SUB-HIST | UK | A* | ✅ | 2024 | T4 |
| GR-2024-0010 | STU-0010 | INS-008 | SUB-CHEM | DE | 2.3 | ✅ | 2024 | T4 |

**Variedad:**
- Años: 2024 (5) + 2025 (5)
- Sistemas educativos: ZA (2), AR (2), US (2), UK (2), DE (2)
- Aprobados: 9/10 (90%)
- Desaprobados: 1/10 (STU-0007 con nota 4 en AR)

---

### 🎓 Trayectorias (10 registros)

Cada estudiante tiene **1 trayectoria activa** en su institución actual:

| trayectoria_id | student_id | institution_id | Fecha Inicio | Fecha Fin | Estado |
|----------------|------------|----------------|--------------|-----------|--------|
| TRAY-001 | STU-0001 | INS-001 | 2023-01-15 | null | activo |
| TRAY-002 | STU-0002 | INS-003 | 2023-03-01 | null | activo |
| TRAY-003 | STU-0003 | INS-002 | 2024-01-20 | null | activo |
| TRAY-004 | STU-0004 | INS-005 | 2023-09-01 | null | activo |
| TRAY-005 | STU-0005 | INS-007 | 2022-09-01 | null | activo |
| TRAY-006 | STU-0006 | INS-006 | 2023-09-01 | null | activo |
| TRAY-007 | STU-0007 | INS-004 | 2024-03-01 | null | activo |
| TRAY-008 | STU-0008 | INS-001 | 2023-01-15 | null | activo |
| TRAY-009 | STU-0009 | INS-007 | 2023-09-01 | null | activo |
| TRAY-010 | STU-0010 | INS-008 | 2023-08-15 | null | activo |

---

## 🔄 FLUJO DE DATOS ENTRE BASES

### 1️⃣ MongoDB (RF1) - Fuente de Verdad

**Database:** `edugrade`  
**Write Concern:** MAJORITY

**5 Colecciones:**

```
estudiantes (10 docs)
├── _id, student_id, full_name, dob, nationality, documento
├── academic_history[]
└── timestamps

instituciones (8 docs)
├── _id, institution_id, name, country, region
├── codigo_sistema, metadata
└── timestamps

materias (8 base docs, ~20 con variantes por sistema)
├── _id, subject_id, name, system
├── course_code, id_institucion
└── timestamps

trayectorias (10 docs)
├── _id, trayectoria_id, id_estudiante, id_institucion
├── fecha_inicio, fecha_fin, estado
└── timestamps

calificaciones (10 docs)
├── _id, record_id, student_id, zone
├── student_snapshot{}, institution_snapshot{}
├── academic_context{}, subject_snapshot{}
├── evaluation{}, original_grade{}
├── evidence[], immutability{}, history[]
└── timestamps
```

**Integridad referencial:**
- calificaciones.student_id → estudiantes.student_id
- calificaciones.institution_id → instituciones.institution_id
- calificaciones.subject_id → materias.subject_id
- trayectorias.id_estudiante → estudiantes.student_id
- trayectorias.id_institucion → instituciones.institution_id

---

### 2️⃣ Redis (RF2) - Conversión y Cache

**Propósito:** Conversión rápida de calificaciones entre sistemas

**Estructura de datos:**

```redis
# Reglas de conversión (4 sistemas → US)
RULE#ZA#US#MINEDU_ZA#v2025-01 → Hash {60%: 2.0, 70%: 3.0, 80%: 4.0}
RULE#AR#US#MINEDU_ZA#v2025-01 → Hash {4: 0.0, 6: 2.0, 8: 3.7, 10: 4.0}
RULE#UK#US#MINEDU_ZA#v2026-01 → Hash {E: 1.0, C: 2.3, B: 3.3, A: 4.0, A*: 4.0}
RULE#DE#US#MINEDU_ZA#v2025-01 → Hash {1.0: 4.0, 2.3: 3.0, 3.0: 2.7, 4.0: 1.0}
RULE#US#US#MINEDU_ZA#v2025-01 → Hash {A: 4.0, B: 3.0, C: 2.0, D: 1.0, F: 0.0}

# Metadatos de reglas (fechas de vigencia, organismo, etc.)
RULEMETA#ZA#US#MINEDU_ZA#v2025-01 → Hash {valid_from, valid_to, org, normative_ref}
... (mismo para AR, UK, DE, US)

# Reglas activas (apuntadores a la versión actual)
RULEACTIVE#ZA#US → Hash {org: MINEDU_ZA, version: v2025-01, updated_at}
RULEACTIVE#AR#US → Hash {org: MINEDU_ZA, version: v2025-01, updated_at}
RULEACTIVE#UK#US → Hash {org: MINEDU_ZA, version: v2026-01, updated_at}
RULEACTIVE#DE#US → Hash {org: MINEDU_ZA, version: v2025-01, updated_at}

# Conversiones cacheadas (TTL 24h)
CONV#GR-2025-0001#US → List [{from_system, from_value, to_value, rule, converted_at}]
CONV#GR-2025-0002#US → List [...]
... (10 conversiones en total)
```

**Conversiones esperadas:**
- GR-2025-0001 (ZA 75%) → US 3.0 GPA
- GR-2025-0002 (AR 8) → US 3.7 GPA
- GR-2025-0005 (UK B) → US 3.3 GPA
- GR-2024-0007 (AR 4) → US 0.0 GPA (desaprobado)
- GR-2024-0010 (DE 2.3) → US 3.0 GPA

---

### 3️⃣ Neo4j (RF3) - Trazabilidad y Relaciones

**Database:** `neo4j`

**Nodos:**

```cypher
(:Student) - 10 nodos
├── student_id (PK), full_name, dob, nationality

(:Institution) - 8 nodos
├── institution_id (PK), name, country, region

(:Subject) - ~20 nodos (con variantes por sistema)
├── subject_key (PK), subject_id, name, system, course_code
├── Ejemplos: SUB-MATH:AR, SUB-MATH:US, SUB-CS:UK, SUB-BIO:US

(:GradeRecord) - 10 nodos
├── record_id (PK), system, scale_type, grade_value, passed
├── academic_year, term, created_at
```

**Relaciones:**

```cypher
# Estudiante → Calificación
(Student)-[:HAS_RECORD]->(GradeRecord)
10 relaciones (1 calificación por estudiante)

# Estudiante → Materia (con metadata)
(Student)-[:TOOK {record_id, academic_year, term, attempt, passed, grade_value}]->(Subject)
10 relaciones

# Estudiante → Institución (trayectoria)
(Student)-[:ATTENDED {academic_year, term, system}]->(Institution)
10 relaciones

# Calificación → Materia
(GradeRecord)-[:FOR_SUBJECT]->(Subject)
10 relaciones

# Calificación → Institución
(GradeRecord)-[:AT_INSTITUTION]->(Institution)
10 relaciones
```

**Total elementos:**
- Nodos: 48 (10 + 8 + 20 + 10)
- Relaciones: 50 (10 + 10 + 10 + 10 + 10)

**Queries de ejemplo:**
```cypher
// ¿Qué materias cursó STU-0001?
MATCH (s:Student {student_id: 'STU-0001'})-[:TOOK]->(m:Subject)
RETURN m.name, m.system

// ¿Quiénes estudiaron en INS-007 (London)?
MATCH (s:Student)-[:ATTENDED]->(i:Institution {institution_id: 'INS-007'})
RETURN s.full_name

// Historia académica completa de STU-0005
MATCH path = (s:Student {student_id: 'STU-0005'})-[:HAS_RECORD]->(r)-[:FOR_SUBJECT]->(m)
RETURN path
```

---

### 4️⃣ Cassandra (RF4/RF5) - Analytics + Auditoría

**RF4: edugrade_analitica (Analytics)**

```sql
rf4_fact_grades_by_region_year_system (10 registros)
├── Partition Key: (region, academic_year, system)
├── Clustering: (institution_id, subject_id, event_ts, record_id)
└── Data: student_id, grade_norm_0_100, grade_raw, passed

rf4_report_by_region_year_system (agregados por sistema)
├── Partition Key: (region, academic_year, system)
├── Datos: n_records, avg, min, max, pass_rate

rf4_report_by_region_year (comparación cross-system)
├── Partition Key: (region, academic_year)
├── Clustering: (system, institution_id, subject_id)
└── Permite comparar sistemas en misma región

promedio_por_region_anio (promedios pre-calculados)
├── Partition Key: (region, anio)
├── Clustering: (codigo_sistema, id_materia, id_institucion)
└── Datos: n, suma, suma_cuadrados, actualizado_en
```

**RF5: edugrade_auditoria (Auditoría)**

```sql
registro_auditoria_por_entidad_mes (10 eventos de creación)
├── Partition Key: (id_entidad, aaaamm)
├── Clustering: (marca_tiempo DESC)
├── Datos: tipo_entidad, accion, id_actor, ip
└── Blockchain: hash_anterior, hash_nuevo, carga_util

# Ejemplo de chain:
GR-2025-0001 → hash: abc123...
GR-2025-0002 → hash_anterior: abc123, hash_nuevo: def456...
GR-2025-0003 → hash_anterior: def456, hash_nuevo: ghi789...
```

---

## 🛠️ ESTRATEGIA DE IMPLEMENTACIÓN

### Opción Recomendada: Script Python Unificado ✅

**Archivo:** `cargar_mvp.py`

**Orden de ejecución:**

```python
# 1. MongoDB (RF1) - Fuente de verdad
conectar_mongodb()
cargar_estudiantes(10)      # → collection: estudiantes
cargar_instituciones(8)     # → collection: instituciones
cargar_materias(20)         # → collection: materias (8 base × variantes)
cargar_trayectorias(10)     # → collection: trayectorias
cargar_calificaciones(10)   # → collection: calificaciones

# 2. Redis (RF2) - Reglas y conversiones
conectar_redis()
cargar_reglas_conversion(4) # ZA→US, AR→US, UK→US, DE→US, US→US
marcar_reglas_activas(4)
convertir_y_cachear(10)     # Convertir las 10 calificaciones a US

# 3. Neo4j (RF3) - Grafo de relaciones
conectar_neo4j()
crear_constraints()
crear_nodos_estudiantes(10)
crear_nodos_instituciones(8)
crear_nodos_materias(20)
crear_nodos_calificaciones(10)
crear_relaciones(50)

# 4. Cassandra (RF4/RF5) - Analytics + Audit
conectar_cassandra_analitica()
cargar_fact_table(10)
calcular_agregados()
cargar_promedios()

conectar_cassandra_auditoria()
registrar_eventos_creacion(10)
calcular_hash_chain()
```

**Comando único:**
```bash
python3 cargar_mvp.py
```

---

## ✅ CONSISTENCIA GARANTIZADA

### Integridad Referencial

```
MongoDB                Neo4j               Redis               Cassandra
─────────             ─────────           ─────────           ─────────
STU-0001        →     (:Student)    →     CONV#..#US    →     fact_table
  ↓                      ↓                                       ↓
calificaciones    →  (:GradeRecord) →   cache 24h       →   agregados
  ↓                      ↓
INS-001         →    (:Institution)                     →   audit_log
  ↓                      ↓
SUB-MATH        →     (:Subject)
```

### Validaciones Cruzadas

```bash
# Verificar que todos los IDs existen en todas las bases
./scripts/verificar_consistencia.sh

# Checks:
1. ¿10 estudiantes en MongoDB = 10 en Neo4j?
2. ¿8 instituciones en MongoDB = 8 en Neo4j?
3. ¿10 conversiones en Redis = 10 calificaciones en MongoDB?
4. ¿10 eventos de audit en Cassandra = 10 calificaciones en MongoDB?
```

---

## 📁 ARCHIVOS A CREAR

### Seeds individuales (backup/alternativa)

```
db/
├── mongo_estudiantes.json          (10 docs)
├── mongo_instituciones.json        (8 docs)
├── mongo_materias.json             (20 docs con variantes)
├── mongo_trayectorias.json         (10 docs)
├── mongo_calificaciones.json       (10 docs)
├── redis_seed_v2.resp              (reglas + conversiones)
├── neo4j_seed_v2.cypher            (nodos + relaciones)
└── cassandra_seed_consolidado.cql  (ya existe, estructura vacía)
```

### Script de carga principal

```
cargar_mvp.py (modificar para usar nuevos seeds)
```

---

## 🧪 CASOS DE PRUEBA

### Flujo Completo

**Caso 1: Crear nueva calificación**
```
1. POST /api/mongodb/calificaciones
   → Crear GR-2026-0011 para STU-0001
   
2. Automático: Redis
   → Convertir a US (cache)
   
3. Automático: Neo4j
   → Crear nodo GradeRecord + relaciones
   
4. Automático: Cassandra
   → Insertar en fact_table + audit_log
```

**Caso 2: Consultar historial académico**
```
GET /api/neo4j/estudiante/STU-0005/historial
→ Retorna: materias, instituciones, calificaciones
→ Grafo completo de trayectoria
```

**Caso 3: Reportes analíticos**
```
GET /api/cassandra/analitica/reportes?region=London&anio=2024&sistema=UK
→ Retorna: agregados de INS-007 (London College)
→ n=2, avg, pass_rate, etc.
```

**Caso 4: Auditoría**
```
GET /api/cassandra/auditoria?entidad=GR-2025-0001
→ Retorna: timeline de eventos
→ Hash chain verificable
```

---

## 🚀 PRÓXIMOS PASOS

### Fase 1: Generación de Seeds
- [ ] Crear `db/mongo_estudiantes.json`
- [ ] Crear `db/mongo_instituciones.json`
- [ ] Crear `db/mongo_materias.json`
- [ ] Crear `db/mongo_trayectorias.json`
- [ ] Crear `db/mongo_calificaciones.json`
- [ ] Actualizar `db/redis_seed_v2.resp`
- [ ] Actualizar `db/neo4j_seed_v2.cypher`

### Fase 2: Actualización del Script de Carga
- [ ] Modificar `cargar_mvp.py`
  - Leer 5 colecciones de MongoDB
  - Cargar reglas coherentes en Redis
  - Crear nodos/relaciones consistentes en Neo4j
  - Poblar Cassandra con datos correlacionados

### Fase 3: Validación
- [ ] Ejecutar `python3 cargar_mvp.py`
- [ ] Verificar conteos en cada base
- [ ] Probar queries cruzadas
- [ ] Validar integridad referencial

### Fase 4: Documentación
- [ ] Actualizar README con estructura nueva
- [ ] Crear guía de queries por base de datos
- [ ] Documentar API endpoints

---

## 📊 RESUMEN NUMÉRICO

| Base de Datos | Entidades | Registros Totales | Propósito |
|---------------|-----------|-------------------|-----------|
| MongoDB | 5 colecciones | 56 docs | Fuente de verdad |
| Redis | 3 tipos de keys | ~30 keys | Conversión + cache |
| Neo4j | 4 tipos de nodos | 48 nodos + 50 rels | Trazabilidad |
| Cassandra | 5 tablas | ~30 rows | Analytics + audit |

**Total dataset:** ~164 elementos distribuidos coherentemente

---

## ❓ PREGUNTAS PARA VALIDAR

1. ¿Te parece correcto el balance de 10 estudiantes?
2. ¿Las 8 instituciones cubren suficiente diversidad geográfica?
3. ¿8 materias base son suficientes para probar el sistema?
4. ¿Prefieres cargar todo con `cargar_mvp.py` o seeds individuales?
5. ¿Alguna modificación al flujo de datos propuesto?

---

**Estado:** Plan completo - Esperando aprobación para ejecutar
