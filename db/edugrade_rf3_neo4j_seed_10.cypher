// =========================================
// SEED NEO4J - EDUGRADE MULTIMODELO
// 10 registros coherentes en ESPAÑOL
// =========================================

// 1. CREAR CONSTRAINTS (unicidad de IDs)
// =========================================

CREATE CONSTRAINT estudiante_id IF NOT EXISTS
FOR (e:Estudiante) REQUIRE e.student_id IS UNIQUE;

CREATE CONSTRAINT institucion_id IF NOT EXISTS
FOR (i:Institucion) REQUIRE i.institution_id IS UNIQUE;

CREATE CONSTRAINT materia_key IF NOT EXISTS
FOR (m:Materia) REQUIRE m.subject_id IS UNIQUE;

CREATE CONSTRAINT calificacion_id IF NOT EXISTS
FOR (c:Calificacion) REQUIRE c.record_id IS UNIQUE;


// 2. CREAR NODOS DE ESTUDIANTES (10)
// =========================================

MERGE (e1:Estudiante {
  student_id: 'STU-0001',
  full_name: 'Liam Nkosi',
  dob: date('2007-05-14'),
  nationality: 'ZA'
});

MERGE (e2:Estudiante {
  student_id: 'STU-0002',
  full_name: 'Sofía Danko',
  dob: date('2006-11-02'),
  nationality: 'AR'
});

MERGE (e3:Estudiante {
  student_id: 'STU-0003',
  full_name: 'Noah van der Merwe',
  dob: date('2006-08-19'),
  nationality: 'ZA'
});

MERGE (e4:Estudiante {
  student_id: 'STU-0004',
  full_name: 'Ava Smith',
  dob: date('2006-07-19'),
  nationality: 'US'
});

MERGE (e5:Estudiante {
  student_id: 'STU-0005',
  full_name: 'Oliver Patel',
  dob: date('2007-01-30'),
  nationality: 'UK'
});

MERGE (e6:Estudiante {
  student_id: 'STU-0006',
  full_name: 'Mia Johnson',
  dob: date('2005-10-08'),
  nationality: 'US'
});

MERGE (e7:Estudiante {
  student_id: 'STU-0007',
  full_name: 'Emma Iuzzolino',
  dob: date('2006-02-21'),
  nationality: 'AR'
});

MERGE (e8:Estudiante {
  student_id: 'STU-0008',
  full_name: 'Theo Samaan',
  dob: date('2005-12-11'),
  nationality: 'DE'
});

MERGE (e9:Estudiante {
  student_id: 'STU-0009',
  full_name: 'Charlotte Brown',
  dob: date('2006-06-15'),
  nationality: 'UK'
});

MERGE (e10:Estudiante {
  student_id: 'STU-0010',
  full_name: 'Felix Müller',
  dob: date('2007-03-22'),
  nationality: 'DE'
});


// 3. CREAR NODOS DE INSTITUCIONES (8)
// =========================================

MERGE (i1:Institucion {
  institution_id: 'INS-001',
  name: 'Cape Town Central High',
  country: 'ZA',
  region: 'Western Cape',
  codigo_sistema: 'ZA7'
});

MERGE (i2:Institucion {
  institution_id: 'INS-002',
  name: 'Pretoria Academy',
  country: 'ZA',
  region: 'Gauteng',
  codigo_sistema: 'ZA7'
});

MERGE (i3:Institucion {
  institution_id: 'INS-003',
  name: 'UADE Argentina',
  country: 'AR',
  region: 'CABA',
  codigo_sistema: 'AR'
});

MERGE (i4:Institucion {
  institution_id: 'INS-004',
  name: 'Buenos Aires High School',
  country: 'AR',
  region: 'Buenos Aires',
  codigo_sistema: 'AR'
});

MERGE (i5:Institucion {
  institution_id: 'INS-005',
  name: 'New York State HS',
  country: 'US',
  region: 'New York',
  codigo_sistema: 'US'
});

MERGE (i6:Institucion {
  institution_id: 'INS-006',
  name: 'California Tech High',
  country: 'US',
  region: 'California',
  codigo_sistema: 'US'
});

MERGE (i7:Institucion {
  institution_id: 'INS-007',
  name: 'London Sixth Form College',
  country: 'UK',
  region: 'London',
  codigo_sistema: 'UK'
});

MERGE (i8:Institucion {
  institution_id: 'INS-008',
  name: 'Berlin Gymnasium',
  country: 'DE',
  region: 'Berlin',
  codigo_sistema: 'DE'
});


// 4. CREAR NODOS DE MATERIAS (10)
// =========================================

MERGE (m1:Materia {
  subject_id: 'SUB-MATH-ZA',
  name: 'Mathematics',
  system: 'ZA7',
  course_code: 'MATH-101-ZA'
});

MERGE (m2:Materia {
  subject_id: 'SUB-CS-AR',
  name: 'Computer Science',
  system: 'AR',
  course_code: 'CS-201-AR'
});

MERGE (m3:Materia {
  subject_id: 'SUB-ENG-ZA',
  name: 'English',
  system: 'ZA7',
  course_code: 'ENG-101-ZA'
});

MERGE (m4:Materia {
  subject_id: 'SUB-BIO-US',
  name: 'Biology',
  system: 'US',
  course_code: 'BIO-101-US'
});

MERGE (m5:Materia {
  subject_id: 'SUB-PHY-UK',
  name: 'Physics',
  system: 'UK',
  course_code: 'PHY-AS-UK'
});

MERGE (m6:Materia {
  subject_id: 'SUB-ECO-US',
  name: 'Economics',
  system: 'US',
  course_code: 'ECO-201-US'
});

MERGE (m7:Materia {
  subject_id: 'SUB-MATH-AR',
  name: 'Matemática',
  system: 'AR',
  course_code: 'MAT-101-AR'
});

MERGE (m8:Materia {
  subject_id: 'SUB-CS-ZA',
  name: 'Computer Science',
  system: 'ZA7',
  course_code: 'CS-101-ZA'
});

MERGE (m9:Materia {
  subject_id: 'SUB-HIST-UK',
  name: 'History',
  system: 'UK',
  course_code: 'HIST-A2-UK'
});

MERGE (m10:Materia {
  subject_id: 'SUB-CHEM-DE',
  name: 'Chemie',
  system: 'DE',
  course_code: 'CHEM-11-DE'
});


// 5. CREAR NODOS DE CALIFICACIONES (10)
// =========================================

MERGE (gr1:Calificacion {
  record_id: 'GR-2025-0001',
  system: 'ZA7',
  scale_type: 'percentage',
  grade_value: '75%',
  numeric_value: 75.0,
  passed: true,
  academic_year: 2025,
  term: 'T1',
  created_at: datetime('2025-03-10T14:22:00Z')
});

MERGE (gr2:Calificacion {
  record_id: 'GR-2025-0002',
  system: 'AR',
  scale_type: 'numeric_scale',
  grade_value: '8',
  numeric_value: 8.0,
  passed: true,
  academic_year: 2025,
  term: 'T1',
  created_at: datetime('2025-03-11T11:00:00Z')
});

MERGE (gr3:Calificacion {
  record_id: 'GR-2025-0003',
  system: 'ZA7',
  scale_type: 'percentage',
  grade_value: '68%',
  numeric_value: 68.0,
  passed: true,
  academic_year: 2025,
  term: 'T1',
  created_at: datetime('2025-03-12T10:15:00Z')
});

MERGE (gr4:Calificacion {
  record_id: 'GR-2025-0004',
  system: 'US',
  scale_type: 'letter_grade',
  grade_value: 'A',
  numeric_value: 4.0,
  passed: true,
  academic_year: 2025,
  term: 'T1',
  created_at: datetime('2025-03-13T09:30:00Z')
});

MERGE (gr5:Calificacion {
  record_id: 'GR-2025-0005',
  system: 'UK',
  scale_type: 'letter_grade',
  grade_value: 'B',
  numeric_value: 3.3,
  passed: true,
  academic_year: 2025,
  term: 'T1',
  created_at: datetime('2025-03-14T12:00:00Z')
});

MERGE (gr6:Calificacion {
  record_id: 'GR-2024-0006',
  system: 'US',
  scale_type: 'letter_grade',
  grade_value: 'C+',
  numeric_value: 2.3,
  passed: true,
  academic_year: 2024,
  term: 'T4',
  created_at: datetime('2024-12-15T10:45:00Z')
});

MERGE (gr7:Calificacion {
  record_id: 'GR-2024-0007',
  system: 'AR',
  scale_type: 'numeric_scale',
  grade_value: '4',
  numeric_value: 4.0,
  passed: false,
  academic_year: 2024,
  term: 'T4',
  created_at: datetime('2024-12-20T14:00:00Z')
});

MERGE (gr8:Calificacion {
  record_id: 'GR-2024-0008',
  system: 'ZA7',
  scale_type: 'percentage',
  grade_value: '82%',
  numeric_value: 82.0,
  passed: true,
  academic_year: 2024,
  term: 'T4',
  created_at: datetime('2024-12-22T16:30:00Z')
});

MERGE (gr9:Calificacion {
  record_id: 'GR-2024-0009',
  system: 'UK',
  scale_type: 'letter_grade',
  grade_value: 'A*',
  numeric_value: 4.0,
  passed: true,
  academic_year: 2024,
  term: 'T4',
  created_at: datetime('2024-12-25T11:20:00Z')
});

MERGE (gr10:Calificacion {
  record_id: 'GR-2024-0010',
  system: 'DE',
  scale_type: 'numeric_inverted',
  grade_value: '2.3',
  numeric_value: 2.3,
  passed: true,
  academic_year: 2024,
  term: 'T4',
  created_at: datetime('2024-12-28T13:45:00Z')
});


// 6. CREAR RELACIONES
// =========================================

// 6.1 TIENE_REGISTRO: Estudiante → Calificacion
MATCH (e:Estudiante {student_id: 'STU-0001'}), (gr:Calificacion {record_id: 'GR-2025-0001'})
MERGE (e)-[:TIENE_REGISTRO]->(gr);

MATCH (e:Estudiante {student_id: 'STU-0002'}), (gr:Calificacion {record_id: 'GR-2025-0002'})
MERGE (e)-[:TIENE_REGISTRO]->(gr);

MATCH (e:Estudiante {student_id: 'STU-0003'}), (gr:Calificacion {record_id: 'GR-2025-0003'})
MERGE (e)-[:TIENE_REGISTRO]->(gr);

MATCH (e:Estudiante {student_id: 'STU-0004'}), (gr:Calificacion {record_id: 'GR-2025-0004'})
MERGE (e)-[:TIENE_REGISTRO]->(gr);

MATCH (e:Estudiante {student_id: 'STU-0005'}), (gr:Calificacion {record_id: 'GR-2025-0005'})
MERGE (e)-[:TIENE_REGISTRO]->(gr);

MATCH (e:Estudiante {student_id: 'STU-0006'}), (gr:Calificacion {record_id: 'GR-2024-0006'})
MERGE (e)-[:TIENE_REGISTRO]->(gr);

MATCH (e:Estudiante {student_id: 'STU-0007'}), (gr:Calificacion {record_id: 'GR-2024-0007'})
MERGE (e)-[:TIENE_REGISTRO]->(gr);

MATCH (e:Estudiante {student_id: 'STU-0008'}), (gr:Calificacion {record_id: 'GR-2024-0008'})
MERGE (e)-[:TIENE_REGISTRO]->(gr);

MATCH (e:Estudiante {student_id: 'STU-0009'}), (gr:Calificacion {record_id: 'GR-2024-0009'})
MERGE (e)-[:TIENE_REGISTRO]->(gr);

MATCH (e:Estudiante {student_id: 'STU-0010'}), (gr:Calificacion {record_id: 'GR-2024-0010'})
MERGE (e)-[:TIENE_REGISTRO]->(gr);


// 6.2 CURSO: Estudiante → Materia
MATCH (e:Estudiante {student_id: 'STU-0001'}), (m:Materia {subject_id: 'SUB-MATH-ZA'})
MERGE (e)-[:CURSO {record_id: 'GR-2025-0001', academic_year: 2025, term: 'T1', attempt: 1, passed: true, grade_value: '75%'}]->(m);

MATCH (e:Estudiante {student_id: 'STU-0002'}), (m:Materia {subject_id: 'SUB-CS-AR'})
MERGE (e)-[:CURSO {record_id: 'GR-2025-0002', academic_year: 2025, term: 'T1', attempt: 1, passed: true, grade_value: '8'}]->(m);

MATCH (e:Estudiante {student_id: 'STU-0003'}), (m:Materia {subject_id: 'SUB-ENG-ZA'})
MERGE (e)-[:CURSO {record_id: 'GR-2025-0003', academic_year: 2025, term: 'T1', attempt: 1, passed: true, grade_value: '68%'}]->(m);

MATCH (e:Estudiante {student_id: 'STU-0004'}), (m:Materia {subject_id: 'SUB-BIO-US'})
MERGE (e)-[:CURSO {record_id: 'GR-2025-0004', academic_year: 2025, term: 'T1', attempt: 1, passed: true, grade_value: 'A'}]->(m);

MATCH (e:Estudiante {student_id: 'STU-0005'}), (m:Materia {subject_id: 'SUB-PHY-UK'})
MERGE (e)-[:CURSO {record_id: 'GR-2025-0005', academic_year: 2025, term: 'T1', attempt: 1, passed: true, grade_value: 'B'}]->(m);

MATCH (e:Estudiante {student_id: 'STU-0006'}), (m:Materia {subject_id: 'SUB-ECO-US'})
MERGE (e)-[:CURSO {record_id: 'GR-2024-0006', academic_year: 2024, term: 'T4', attempt: 1, passed: true, grade_value: 'C+'}]->(m);

MATCH (e:Estudiante {student_id: 'STU-0007'}), (m:Materia {subject_id: 'SUB-MATH-AR'})
MERGE (e)-[:CURSO {record_id: 'GR-2024-0007', academic_year: 2024, term: 'T4', attempt: 1, passed: false, grade_value: '4'}]->(m);

MATCH (e:Estudiante {student_id: 'STU-0008'}), (m:Materia {subject_id: 'SUB-CS-ZA'})
MERGE (e)-[:CURSO {record_id: 'GR-2024-0008', academic_year: 2024, term: 'T4', attempt: 1, passed: true, grade_value: '82%'}]->(m);

MATCH (e:Estudiante {student_id: 'STU-0009'}), (m:Materia {subject_id: 'SUB-HIST-UK'})
MERGE (e)-[:CURSO {record_id: 'GR-2024-0009', academic_year: 2024, term: 'T4', attempt: 1, passed: true, grade_value: 'A*'}]->(m);

MATCH (e:Estudiante {student_id: 'STU-0010'}), (m:Materia {subject_id: 'SUB-CHEM-DE'})
MERGE (e)-[:CURSO {record_id: 'GR-2024-0010', academic_year: 2024, term: 'T4', attempt: 1, passed: true, grade_value: '2.3'}]->(m);


// 6.3 ASISTIO: Estudiante → Institucion
MATCH (e:Estudiante {student_id: 'STU-0001'}), (i:Institucion {institution_id: 'INS-001'})
MERGE (e)-[:ASISTIO {academic_year: 2025, term: 'T1', system: 'ZA7'}]->(i);

MATCH (e:Estudiante {student_id: 'STU-0002'}), (i:Institucion {institution_id: 'INS-003'})
MERGE (e)-[:ASISTIO {academic_year: 2025, term: 'T1', system: 'AR'}]->(i);

MATCH (e:Estudiante {student_id: 'STU-0003'}), (i:Institucion {institution_id: 'INS-002'})
MERGE (e)-[:ASISTIO {academic_year: 2025, term: 'T1', system: 'ZA7'}]->(i);

MATCH (e:Estudiante {student_id: 'STU-0004'}), (i:Institucion {institution_id: 'INS-005'})
MERGE (e)-[:ASISTIO {academic_year: 2025, term: 'T1', system: 'US'}]->(i);

MATCH (e:Estudiante {student_id: 'STU-0005'}), (i:Institucion {institution_id: 'INS-007'})
MERGE (e)-[:ASISTIO {academic_year: 2025, term: 'T1', system: 'UK'}]->(i);

MATCH (e:Estudiante {student_id: 'STU-0006'}), (i:Institucion {institution_id: 'INS-006'})
MERGE (e)-[:ASISTIO {academic_year: 2024, term: 'T4', system: 'US'}]->(i);

MATCH (e:Estudiante {student_id: 'STU-0007'}), (i:Institucion {institution_id: 'INS-004'})
MERGE (e)-[:ASISTIO {academic_year: 2024, term: 'T4', system: 'AR'}]->(i);

MATCH (e:Estudiante {student_id: 'STU-0008'}), (i:Institucion {institution_id: 'INS-001'})
MERGE (e)-[:ASISTIO {academic_year: 2024, term: 'T4', system: 'ZA7'}]->(i);

MATCH (e:Estudiante {student_id: 'STU-0009'}), (i:Institucion {institution_id: 'INS-007'})
MERGE (e)-[:ASISTIO {academic_year: 2024, term: 'T4', system: 'UK'}]->(i);

MATCH (e:Estudiante {student_id: 'STU-0010'}), (i:Institucion {institution_id: 'INS-008'})
MERGE (e)-[:ASISTIO {academic_year: 2024, term: 'T4', system: 'DE'}]->(i);


// 6.4 DE_MATERIA: Calificacion → Materia
MATCH (gr:Calificacion {record_id: 'GR-2025-0001'}), (m:Materia {subject_id: 'SUB-MATH-ZA'})
MERGE (gr)-[:DE_MATERIA]->(m);

MATCH (gr:Calificacion {record_id: 'GR-2025-0002'}), (m:Materia {subject_id: 'SUB-CS-AR'})
MERGE (gr)-[:DE_MATERIA]->(m);

MATCH (gr:Calificacion {record_id: 'GR-2025-0003'}), (m:Materia {subject_id: 'SUB-ENG-ZA'})
MERGE (gr)-[:DE_MATERIA]->(m);

MATCH (gr:Calificacion {record_id: 'GR-2025-0004'}), (m:Materia {subject_id: 'SUB-BIO-US'})
MERGE (gr)-[:DE_MATERIA]->(m);

MATCH (gr:Calificacion {record_id: 'GR-2025-0005'}), (m:Materia {subject_id: 'SUB-PHY-UK'})
MERGE (gr)-[:DE_MATERIA]->(m);

MATCH (gr:Calificacion {record_id: 'GR-2024-0006'}), (m:Materia {subject_id: 'SUB-ECO-US'})
MERGE (gr)-[:DE_MATERIA]->(m);

MATCH (gr:Calificacion {record_id: 'GR-2024-0007'}), (m:Materia {subject_id: 'SUB-MATH-AR'})
MERGE (gr)-[:DE_MATERIA]->(m);

MATCH (gr:Calificacion {record_id: 'GR-2024-0008'}), (m:Materia {subject_id: 'SUB-CS-ZA'})
MERGE (gr)-[:DE_MATERIA]->(m);

MATCH (gr:Calificacion {record_id: 'GR-2024-0009'}), (m:Materia {subject_id: 'SUB-HIST-UK'})
MERGE (gr)-[:DE_MATERIA]->(m);

MATCH (gr:Calificacion {record_id: 'GR-2024-0010'}), (m:Materia {subject_id: 'SUB-CHEM-DE'})
MERGE (gr)-[:DE_MATERIA]->(m);


// 6.5 EN_INSTITUCION: Calificacion → Institucion
MATCH (gr:Calificacion {record_id: 'GR-2025-0001'}), (i:Institucion {institution_id: 'INS-001'})
MERGE (gr)-[:EN_INSTITUCION]->(i);

MATCH (gr:Calificacion {record_id: 'GR-2025-0002'}), (i:Institucion {institution_id: 'INS-003'})
MERGE (gr)-[:EN_INSTITUCION]->(i);

MATCH (gr:Calificacion {record_id: 'GR-2025-0003'}), (i:Institucion {institution_id: 'INS-002'})
MERGE (gr)-[:EN_INSTITUCION]->(i);

MATCH (gr:Calificacion {record_id: 'GR-2025-0004'}), (i:Institucion {institution_id: 'INS-005'})
MERGE (gr)-[:EN_INSTITUCION]->(i);

MATCH (gr:Calificacion {record_id: 'GR-2025-0005'}), (i:Institucion {institution_id: 'INS-007'})
MERGE (gr)-[:EN_INSTITUCION]->(i);

MATCH (gr:Calificacion {record_id: 'GR-2024-0006'}), (i:Institucion {institution_id: 'INS-006'})
MERGE (gr)-[:EN_INSTITUCION]->(i);

MATCH (gr:Calificacion {record_id: 'GR-2024-0007'}), (i:Institucion {institution_id: 'INS-004'})
MERGE (gr)-[:EN_INSTITUCION]->(i);

MATCH (gr:Calificacion {record_id: 'GR-2024-0008'}), (i:Institucion {institution_id: 'INS-001'})
MERGE (gr)-[:EN_INSTITUCION]->(i);

MATCH (gr:Calificacion {record_id: 'GR-2024-0009'}), (i:Institucion {institution_id: 'INS-007'})
MERGE (gr)-[:EN_INSTITUCION]->(i);

MATCH (gr:Calificacion {record_id: 'GR-2024-0010'}), (i:Institucion {institution_id: 'INS-008'})
MERGE (gr)-[:EN_INSTITUCION]->(i);


// =========================================
// VERIFICACIÓN FINAL
// =========================================

// Contar nodos por tipo
MATCH (e:Estudiante) RETURN 'Estudiantes' AS tipo, count(e) AS cantidad
UNION
MATCH (i:Institucion) RETURN 'Instituciones' AS tipo, count(i) AS cantidad
UNION
MATCH (m:Materia) RETURN 'Materias' AS tipo, count(m) AS cantidad
UNION
MATCH (c:Calificacion) RETURN 'Calificaciones' AS tipo, count(c) AS cantidad;

// Contar relaciones por tipo
MATCH ()-[r:TIENE_REGISTRO]->() RETURN 'TIENE_REGISTRO' AS relacion, count(r) AS cantidad
UNION
MATCH ()-[r:CURSO]->() RETURN 'CURSO' AS relacion, count(r) AS cantidad
UNION
MATCH ()-[r:ASISTIO]->() RETURN 'ASISTIO' AS relacion, count(r) AS cantidad
UNION
MATCH ()-[r:DE_MATERIA]->() RETURN 'DE_MATERIA' AS relacion, count(r) AS cantidad
UNION
MATCH ()-[r:EN_INSTITUCION]->() RETURN 'EN_INSTITUCION' AS relacion, count(r) AS cantidad;

// =========================================
// SEED COMPLETADO
// Total: 38 nodos + 50 relaciones
// =========================================
