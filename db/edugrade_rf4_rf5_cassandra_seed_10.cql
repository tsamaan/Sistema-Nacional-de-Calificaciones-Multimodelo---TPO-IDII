-- ============================================================================
-- CARGA DE DATOS - CASSANDRA RF4 + RF5
-- Sistema EduGrade Global - 10 Registros Coherentes
-- ============================================================================
-- Este archivo carga datos en las tablas previamente creadas por
-- cassandra_seed_consolidado.cql
--
-- RF4: Analítica (edugrade_analitica)
--      - Fact table: 10 calificaciones
--      - Agregados: Promedios pre-calculados
--
-- RF5: Auditoría (edugrade_auditoria)
--      - 10 eventos de auditoría con blockchain hash chain
-- ============================================================================

-- ============================================================================
-- RF4 - ANALYTICS (edugrade_analitica)
-- ============================================================================

USE edugrade_analitica;

CONSISTENCY ONE;

-- ----------------------------------------------------------------------------
-- LIMPIEZA: Truncar tablas antes de cargar
-- ----------------------------------------------------------------------------
TRUNCATE TABLE rf4_fact_grades_by_region_year_system;
TRUNCATE TABLE promedio_por_region_anio;

-- ----------------------------------------------------------------------------
-- FACT TABLE: rf4_fact_grades_by_region_year_system
-- 10 Registros de calificaciones normalizadas
-- ----------------------------------------------------------------------------

-- Registro 1: Liam Nkosi (ZA) - Mathematics 75%
INSERT INTO rf4_fact_grades_by_region_year_system (
  region, academic_year, system, institution_id, subject_id, event_ts, 
  record_id, student_id, grade_raw, grade_norm_0_100, passed
) VALUES (
  'Western Cape', 2025, 'ZA', 'INS-001', 'SUB-MATH-ZA', '2025-03-10 14:22:00+0000',
  'GR-2025-0001', 'STU-0001', '75%', 75.0, true
);

-- Registro 2: Sofía Danko (AR) - Computer Science 8/10
INSERT INTO rf4_fact_grades_by_region_year_system (
  region, academic_year, system, institution_id, subject_id, event_ts, 
  record_id, student_id, grade_raw, grade_norm_0_100, passed
) VALUES (
  'CABA', 2025, 'AR', 'INS-003', 'SUB-CS-AR', '2025-03-11 11:00:00+0000',
  'GR-2025-0002', 'STU-0002', '8', 80.0, true
);

-- Registro 3: Noah van der Merwe (ZA) - English 68%
INSERT INTO rf4_fact_grades_by_region_year_system (
  region, academic_year, system, institution_id, subject_id, event_ts, 
  record_id, student_id, grade_raw, grade_norm_0_100, passed
) VALUES (
  'Gauteng', 2025, 'ZA', 'INS-002', 'SUB-ENG-ZA', '2025-03-12 10:15:00+0000',
  'GR-2025-0003', 'STU-0003', '68%', 68.0, true
);

-- Registro 4: Ava Smith (US) - Biology A (4.0 GPA)
INSERT INTO rf4_fact_grades_by_region_year_system (
  region, academic_year, system, institution_id, subject_id, event_ts, 
  record_id, student_id, grade_raw, grade_norm_0_100, passed
) VALUES (
  'New York', 2025, 'US', 'INS-005', 'SUB-BIO-US', '2025-03-13 09:30:00+0000',
  'GR-2025-0004', 'STU-0004', 'A', 100.0, true
);

-- Registro 5: Oliver Patel (UK) - Physics B (3.3)
INSERT INTO rf4_fact_grades_by_region_year_system (
  region, academic_year, system, institution_id, subject_id, event_ts, 
  record_id, student_id, grade_raw, grade_norm_0_100, passed
) VALUES (
  'London', 2025, 'UK', 'INS-007', 'SUB-PHY-UK', '2025-03-14 12:00:00+0000',
  'GR-2025-0005', 'STU-0005', 'B', 82.5, true
);

-- Registro 6: Mia Johnson (US) - Economics C+ (2.3 GPA)
INSERT INTO rf4_fact_grades_by_region_year_system (
  region, academic_year, system, institution_id, subject_id, event_ts, 
  record_id, student_id, grade_raw, grade_norm_0_100, passed
) VALUES (
  'California', 2024, 'US', 'INS-006', 'SUB-ECO-US', '2024-12-15 10:45:00+0000',
  'GR-2024-0006', 'STU-0006', 'C+', 57.5, true
);

-- Registro 7: Emma Iuzzolino (AR) - Matemática 4/10 (desaprobada)
INSERT INTO rf4_fact_grades_by_region_year_system (
  region, academic_year, system, institution_id, subject_id, event_ts, 
  record_id, student_id, grade_raw, grade_norm_0_100, passed
) VALUES (
  'Buenos Aires', 2024, 'AR', 'INS-004', 'SUB-MATH-AR', '2024-12-20 14:00:00+0000',
  'GR-2024-0007', 'STU-0007', '4', 40.0, false
);

-- Registro 8: Theo Samaan (ZA) - Computer Science 82%
INSERT INTO rf4_fact_grades_by_region_year_system (
  region, academic_year, system, institution_id, subject_id, event_ts, 
  record_id, student_id, grade_raw, grade_norm_0_100, passed
) VALUES (
  'Western Cape', 2024, 'ZA', 'INS-001', 'SUB-CS-ZA', '2024-12-22 16:30:00+0000',
  'GR-2024-0008', 'STU-0008', '82%', 82.0, true
);

-- Registro 9: Charlotte Brown (UK) - History A* (4.0)
INSERT INTO rf4_fact_grades_by_region_year_system (
  region, academic_year, system, institution_id, subject_id, event_ts, 
  record_id, student_id, grade_raw, grade_norm_0_100, passed
) VALUES (
  'London', 2024, 'UK', 'INS-007', 'SUB-HIST-UK', '2024-12-25 11:20:00+0000',
  'GR-2024-0009', 'STU-0009', 'A*', 100.0, true
);

-- Registro 10: Felix Müller (DE) - Chemie 2.3 (sistema invertido)
INSERT INTO rf4_fact_grades_by_region_year_system (
  region, academic_year, system, institution_id, subject_id, event_ts, 
  record_id, student_id, grade_raw, grade_norm_0_100, passed
) VALUES (
  'Berlin', 2024, 'DE', 'INS-008', 'SUB-CHEM-DE', '2024-12-28 13:45:00+0000',
  'GR-2024-0010', 'STU-0010', '2.3', 74.0, true
);

-- ----------------------------------------------------------------------------
-- AGREGADOS: promedio_por_region_anio
-- Promedios pre-calculados por región/año/sistema/materia/institución
-- ----------------------------------------------------------------------------

-- Agregado 1: Western Cape / 2025 / ZA / MATH / INS-001
INSERT INTO promedio_por_region_anio (
  region, anio, codigo_sistema, id_materia, id_institucion,
  n, suma, suma_cuadrados, actualizado_en
) VALUES (
  'Western Cape', 2025, 'ZA', 'SUB-MATH-ZA', 'INS-001',
  1, 75.0, 5625.0, toTimestamp(now())
);

-- Agregado 2: CABA / 2025 / AR / CS / INS-003
INSERT INTO promedio_por_region_anio (
  region, anio, codigo_sistema, id_materia, id_institucion,
  n, suma, suma_cuadrados, actualizado_en
) VALUES (
  'CABA', 2025, 'AR', 'SUB-CS-AR', 'INS-003',
  1, 80.0, 6400.0, toTimestamp(now())
);

-- Agregado 3: Gauteng / 2025 / ZA / ENG / INS-002
INSERT INTO promedio_por_region_anio (
  region, anio, codigo_sistema, id_materia, id_institucion,
  n, suma, suma_cuadrados, actualizado_en
) VALUES (
  'Gauteng', 2025, 'ZA', 'SUB-ENG-ZA', 'INS-002',
  1, 68.0, 4624.0, toTimestamp(now())
);

-- Agregado 4: New York / 2025 / US / BIO / INS-005
INSERT INTO promedio_por_region_anio (
  region, anio, codigo_sistema, id_materia, id_institucion,
  n, suma, suma_cuadrados, actualizado_en
) VALUES (
  'New York', 2025, 'US', 'SUB-BIO-US', 'INS-005',
  1, 100.0, 10000.0, toTimestamp(now())
);

-- Agregado 5: London / 2025 / UK / PHY / INS-007
INSERT INTO promedio_por_region_anio (
  region, anio, codigo_sistema, id_materia, id_institucion,
  n, suma, suma_cuadrados, actualizado_en
) VALUES (
  'London', 2025, 'UK', 'SUB-PHY-UK', 'INS-007',
  1, 82.5, 6806.25, toTimestamp(now())
);

-- Agregado 6: California / 2024 / US / ECO / INS-006
INSERT INTO promedio_por_region_anio (
  region, anio, codigo_sistema, id_materia, id_institucion,
  n, suma, suma_cuadrados, actualizado_en
) VALUES (
  'California', 2024, 'US', 'SUB-ECO-US', 'INS-006',
  1, 57.5, 3306.25, toTimestamp(now())
);

-- Agregado 7: Buenos Aires / 2024 / AR / MATH / INS-004
INSERT INTO promedio_por_region_anio (
  region, anio, codigo_sistema, id_materia, id_institucion,
  n, suma, suma_cuadrados, actualizado_en
) VALUES (
  'Buenos Aires', 2024, 'AR', 'SUB-MATH-AR', 'INS-004',
  1, 40.0, 1600.0, toTimestamp(now())
);

-- Agregado 8: Western Cape / 2024 / ZA / CS / INS-001
INSERT INTO promedio_por_region_anio (
  region, anio, codigo_sistema, id_materia, id_institucion,
  n, suma, suma_cuadrados, actualizado_en
) VALUES (
  'Western Cape', 2024, 'ZA', 'SUB-CS-ZA', 'INS-001',
  1, 82.0, 6724.0, toTimestamp(now())
);

-- Agregado 9: London / 2024 / UK / HIST / INS-007
INSERT INTO promedio_por_region_anio (
  region, anio, codigo_sistema, id_materia, id_institucion,
  n, suma, suma_cuadrados, actualizado_en
) VALUES (
  'London', 2024, 'UK', 'SUB-HIST-UK', 'INS-007',
  1, 100.0, 10000.0, toTimestamp(now())
);

-- Agregado 10: Berlin / 2024 / DE / CHEM / INS-008
INSERT INTO promedio_por_region_anio (
  region, anio, codigo_sistema, id_materia, id_institucion,
  n, suma, suma_cuadrados, actualizado_en
) VALUES (
  'Berlin', 2024, 'DE', 'SUB-CHEM-DE', 'INS-008',
  1, 74.0, 5476.0, toTimestamp(now())
);

-- ============================================================================
-- RF5 - AUDITORÍA (edugrade_auditoria)
-- ============================================================================

USE edugrade_auditoria;

CONSISTENCY QUORUM;

-- ----------------------------------------------------------------------------
-- LIMPIEZA: Truncar tabla antes de cargar
-- ----------------------------------------------------------------------------
TRUNCATE TABLE registro_auditoria_por_entidad_mes;

-- ----------------------------------------------------------------------------
-- EVENTOS DE AUDITORÍA: registro_auditoria_por_entidad_mes
-- 10 Eventos con blockchain hash chain
-- ----------------------------------------------------------------------------

-- Evento 1: Creación GR-2025-0001 (primer bloque, sin hash anterior)
INSERT INTO registro_auditoria_por_entidad_mes (
  id_entidad, aaaamm, marca_tiempo, tipo_entidad, accion,
  id_actor, ip, hash_anterior, hash_nuevo, carga_util
) VALUES (
  'GR-2025-0001', '202503', '2025-03-10 14:22:00+0000', 'calificacion', 'CREATE',
  'sistema_carga', '127.0.0.1', '',
  'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0',
  '{"record_id":"GR-2025-0001","student_id":"STU-0001","grade":"75%","system":"ZA","passed":true}'
);

-- Evento 2: Creación GR-2025-0002
INSERT INTO registro_auditoria_por_entidad_mes (
  id_entidad, aaaamm, marca_tiempo, tipo_entidad, accion,
  id_actor, ip, hash_anterior, hash_nuevo, carga_util
) VALUES (
  'GR-2025-0002', '202503', '2025-03-11 11:00:00+0000', 'calificacion', 'CREATE',
  'sistema_carga', '127.0.0.1',
  'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0',
  'b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1',
  '{"record_id":"GR-2025-0002","student_id":"STU-0002","grade":"8","system":"AR","passed":true}'
);

-- Evento 3: Creación GR-2025-0003
INSERT INTO registro_auditoria_por_entidad_mes (
  id_entidad, aaaamm, marca_tiempo, tipo_entidad, accion,
  id_actor, ip, hash_anterior, hash_nuevo, carga_util
) VALUES (
  'GR-2025-0003', '202503', '2025-03-12 10:15:00+0000', 'calificacion', 'CREATE',
  'sistema_carga', '127.0.0.1',
  'b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1',
  'c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2',
  '{"record_id":"GR-2025-0003","student_id":"STU-0003","grade":"68%","system":"ZA","passed":true}'
);

-- Evento 4: Creación GR-2025-0004
INSERT INTO registro_auditoria_por_entidad_mes (
  id_entidad, aaaamm, marca_tiempo, tipo_entidad, accion,
  id_actor, ip, hash_anterior, hash_nuevo, carga_util
) VALUES (
  'GR-2025-0004', '202503', '2025-03-13 09:30:00+0000', 'calificacion', 'CREATE',
  'sistema_carga', '127.0.0.1',
  'c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2',
  'd4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3',
  '{"record_id":"GR-2025-0004","student_id":"STU-0004","grade":"A","system":"US","passed":true}'
);

-- Evento 5: Creación GR-2025-0005
INSERT INTO registro_auditoria_por_entidad_mes (
  id_entidad, aaaamm, marca_tiempo, tipo_entidad, accion,
  id_actor, ip, hash_anterior, hash_nuevo, carga_util
) VALUES (
  'GR-2025-0005', '202503', '2025-03-14 12:00:00+0000', 'calificacion', 'CREATE',
  'sistema_carga', '127.0.0.1',
  'd4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3',
  'e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4',
  '{"record_id":"GR-2025-0005","student_id":"STU-0005","grade":"B","system":"UK","passed":true}'
);

-- Evento 6: Creación GR-2024-0006
INSERT INTO registro_auditoria_por_entidad_mes (
  id_entidad, aaaamm, marca_tiempo, tipo_entidad, accion,
  id_actor, ip, hash_anterior, hash_nuevo, carga_util
) VALUES (
  'GR-2024-0006', '202412', '2024-12-15 10:45:00+0000', 'calificacion', 'CREATE',
  'sistema_carga', '127.0.0.1',
  'e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4',
  'f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5',
  '{"record_id":"GR-2024-0006","student_id":"STU-0006","grade":"C+","system":"US","passed":true}'
);

-- Evento 7: Creación GR-2024-0007
INSERT INTO registro_auditoria_por_entidad_mes (
  id_entidad, aaaamm, marca_tiempo, tipo_entidad, accion,
  id_actor, ip, hash_anterior, hash_nuevo, carga_util
) VALUES (
  'GR-2024-0007', '202412', '2024-12-20 14:00:00+0000', 'calificacion', 'CREATE',
  'sistema_carga', '127.0.0.1',
  'f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5',
  'g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6',
  '{"record_id":"GR-2024-0007","student_id":"STU-0007","grade":"4","system":"AR","passed":false}'
);

-- Evento 8: Creación GR-2024-0008
INSERT INTO registro_auditoria_por_entidad_mes (
  id_entidad, aaaamm, marca_tiempo, tipo_entidad, accion,
  id_actor, ip, hash_anterior, hash_nuevo, carga_util
) VALUES (
  'GR-2024-0008', '202412', '2024-12-22 16:30:00+0000', 'calificacion', 'CREATE',
  'sistema_carga', '127.0.0.1',
  'g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6',
  'h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6k7',
  '{"record_id":"GR-2024-0008","student_id":"STU-0008","grade":"82%","system":"ZA","passed":true}'
);

-- Evento 9: Creación GR-2024-0009
INSERT INTO registro_auditoria_por_entidad_mes (
  id_entidad, aaaamm, marca_tiempo, tipo_entidad, accion,
  id_actor, ip, hash_anterior, hash_nuevo, carga_util
) VALUES (
  'GR-2024-0009', '202412', '2024-12-25 11:20:00+0000', 'calificacion', 'CREATE',
  'sistema_carga', '127.0.0.1',
  'h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6k7',
  'i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6k7l8',
  '{"record_id":"GR-2024-0009","student_id":"STU-0009","grade":"A*","system":"UK","passed":true}'
);

-- Evento 10: Creación GR-2024-0010
INSERT INTO registro_auditoria_por_entidad_mes (
  id_entidad, aaaamm, marca_tiempo, tipo_entidad, accion,
  id_actor, ip, hash_anterior, hash_nuevo, carga_util
) VALUES (
  'GR-2024-0010', '202412', '2024-12-28 13:45:00+0000', 'calificacion', 'CREATE',
  'sistema_carga', '127.0.0.1',
  'i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6k7l8',
  'j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6k7l8m9',
  '{"record_id":"GR-2024-0010","student_id":"STU-0010","grade":"2.3","system":"DE","passed":true}'
);

-- ============================================================================
-- VERIFICACIÓN DE CARGA
-- ============================================================================

-- Contar registros en RF4 (Analytics)
SELECT COUNT(*) AS total_fact_grades FROM edugrade_analitica.rf4_fact_grades_by_region_year_system;
SELECT COUNT(*) AS total_agregados FROM edugrade_analitica.promedio_por_region_anio;

-- Contar registros en RF5 (Auditoría)
SELECT COUNT(*) AS total_eventos_auditoria FROM edugrade_auditoria.registro_auditoria_por_entidad_mes;

-- Mostrar primeros registros de cada tabla
SELECT * FROM edugrade_analitica.rf4_fact_grades_by_region_year_system LIMIT 5;
SELECT * FROM edugrade_analitica.promedio_por_region_anio LIMIT 5;
SELECT * FROM edugrade_auditoria.registro_auditoria_por_entidad_mes LIMIT 5;

-- ============================================================================
-- RESUMEN DE CARGA
-- ============================================================================
-- ✅ RF4 - Analytics (edugrade_analitica):
--    • 10 registros en fact table (rf4_fact_grades_by_region_year_system)
--    • 10 agregados pre-calculados (promedio_por_region_anio)
--
-- ✅ RF5 - Auditoría (edugrade_auditoria):
--    • 10 eventos con blockchain hash chain (registro_auditoria_por_entidad_mes)
--
-- 📊 Dataset coherente con MongoDB, Redis y Neo4j:
--    • Mismos 10 estudiantes (STU-0001 a STU-0010)
--    • Mismas 8 instituciones (INS-001 a INS-008)
--    • Mismas 10 calificaciones (GR-2025-0001 a GR-2024-0010)
--
-- 🔗 Grades normalizadas a escala 0-100:
--    • ZA (percentage): valor directo
--    • AR (1-10): (value / 10) * 100
--    • US (GPA 0-4): (value / 4) * 100
--    • UK (grades): convertido a GPA equivalente * 25
--    • DE (1-6 invertido): ((6 - value) / 5) * 100
-- ============================================================================
