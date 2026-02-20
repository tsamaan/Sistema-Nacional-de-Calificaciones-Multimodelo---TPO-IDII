-- ============================================================================
-- SEED CONSOLIDADO - CASSANDRA
-- Sistema EduGrade Global - RF4 + RF5
-- ============================================================================
-- RF4: Analítica (edugrade_analitica)
--      - Fact tables dimensionales
--      - Reportes agregados
--      - Promedios pre-calculados
--
-- RF5: Auditoría (edugrade_auditoria)  
--      - Timeline de eventos
--      - Registro inmutable append-only
-- ============================================================================

-- Limpieza: Borrar keyspaces antiguos si existen
DROP KEYSPACE IF EXISTS edugrade;
DROP KEYSPACE IF EXISTS edugrade_analitica;
DROP KEYSPACE IF EXISTS edugrade_auditoria;

-- ============================================================================
-- KEYSPACE: edugrade_analitica (RF4 - Analítica)
-- ============================================================================

CREATE KEYSPACE edugrade_analitica 
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE edugrade_analitica;

-- Consistency para RF4: lecturas rápidas, escrituras asíncronas
CONSISTENCY ONE;

-- ----------------------------------------------------------------------------
-- TABLA 1: Fact Table Dimensional
-- Propósito: Tabla de hechos para análisis multidimensional
-- Partition Key: (region, academic_year, system)
-- ----------------------------------------------------------------------------
CREATE TABLE rf4_fact_grades_by_region_year_system (
  -- Partition Key (compuesta)
  region text,
  academic_year int,
  system text,
  
  -- Clustering Keys
  institution_id text,
  subject_id text,
  event_ts timestamp,
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
)
AND comment = 'RF4: Fact table dimensional para análisis por región/año/sistema';

-- ----------------------------------------------------------------------------
-- TABLA 2: Reportes Agregados por Sistema
-- Propósito: Agregados pre-calculados por sistema
-- Partition Key: (region, academic_year, system)
-- ----------------------------------------------------------------------------
CREATE TABLE rf4_report_by_region_year_system (
  -- Partition Key (compuesta)
  region text,
  academic_year int,
  system text,
  
  -- Clustering Keys
  institution_id text,
  subject_id text,
  
  -- Agregados
  n_records int,
  avg_norm_0_100 double,
  min_norm_0_100 double,
  max_norm_0_100 double,
  pass_rate double,
  updated_at timestamp,
  
  PRIMARY KEY ((region, academic_year, system), institution_id, subject_id)
) WITH comment = 'RF4: Reportes agregados por sistema educativo';

-- ----------------------------------------------------------------------------
-- TABLA 3: Reportes Agregados Cross-System
-- Propósito: Agregados para comparación entre sistemas
-- Partition Key: (region, academic_year)
-- ----------------------------------------------------------------------------
CREATE TABLE rf4_report_by_region_year (
  -- Partition Key (compuesta)
  region text,
  academic_year int,
  
  -- Clustering Keys
  system text,
  institution_id text,
  subject_id text,
  
  -- Agregados
  n_records int,
  avg_norm_0_100 double,
  min_norm_0_100 double,
  max_norm_0_100 double,
  pass_rate double,
  updated_at timestamp,
  
  PRIMARY KEY ((region, academic_year), system, institution_id, subject_id)
) WITH CLUSTERING ORDER BY (system ASC, institution_id ASC, subject_id ASC)
AND comment = 'RF4: Reportes para comparación entre sistemas';

-- ----------------------------------------------------------------------------
-- TABLA 4: Promedios Pre-calculados (formato simplificado)
-- Propósito: Agregados estadísticos para consultas rápidas
-- Partition Key: (region, anio)
-- ----------------------------------------------------------------------------
CREATE TABLE promedio_por_region_anio (
  -- Partition Key (compuesta)
  region text,
  anio int,
  
  -- Clustering Keys
  codigo_sistema text,
  id_materia text,
  id_institucion text,
  
  -- Columnas de datos
  n bigint,
  suma double,
  suma_cuadrados double,
  actualizado_en timestamp,
  
  PRIMARY KEY ((region, anio), codigo_sistema, id_materia, id_institucion)
) WITH CLUSTERING ORDER BY (
  codigo_sistema ASC,
  id_materia ASC,
  id_institucion ASC
)
AND comment = 'RF4: Promedios y estadísticas pre-calculadas por región/año';

-- ============================================================================
-- KEYSPACE: edugrade_auditoria (RF5 - Auditoría)
-- ============================================================================

CREATE KEYSPACE edugrade_auditoria 
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE edugrade_auditoria;

-- Consistency para RF5: escrituras fuertes para integridad
CONSISTENCY QUORUM;

-- ----------------------------------------------------------------------------
-- TABLA: Registro de Auditoría por Entidad/Mes
-- Propósito: Timeline inmutable de eventos (append-only)
-- Partition Key: (id_entidad, aaaamm)
-- ----------------------------------------------------------------------------
CREATE TABLE registro_auditoria_por_entidad_mes (
  -- Partition Key (compuesta)
  id_entidad text,
  aaaamm text,
  
  -- Clustering Key
  marca_tiempo timestamp,
  
  -- Columnas de auditoría
  tipo_entidad text,
  accion text,
  id_actor text,
  ip text,
  hash_anterior text,
  hash_nuevo text,
  carga_util text,
  
  PRIMARY KEY ((id_entidad, aaaamm), marca_tiempo)
) WITH CLUSTERING ORDER BY (marca_tiempo DESC)
AND comment = 'RF5: Registro inmutable de auditoría (append-only, blockchain-style)';

-- ============================================================================
-- VERIFICACIÓN DE ESTRUCTURA
-- ============================================================================

-- Mostrar keyspaces creados
DESCRIBE KEYSPACES;

-- Verificar tablas RF4 (Analítica)
USE edugrade_analitica;
DESCRIBE TABLES;
DESCRIBE TABLE rf4_fact_grades_by_region_year_system;
DESCRIBE TABLE rf4_report_by_region_year_system;
DESCRIBE TABLE rf4_report_by_region_year;
DESCRIBE TABLE promedio_por_region_anio;

-- Verificar tablas RF5 (Auditoría)
USE edugrade_auditoria;
DESCRIBE TABLES;
DESCRIBE TABLE registro_auditoria_por_entidad_mes;

-- ============================================================================
-- ESTRUCTURA CREADA - LISTA PARA CARGA DE DATOS
-- ============================================================================
-- Las tablas están vacías y listas para recibir datos a través de:
-- 1. python3 cargar_mvp.py  (carga de datos MVP)
-- 2. API REST endpoints para CRUD operations
-- 3. Scripts de carga masiva personalizados
-- ============================================================================
