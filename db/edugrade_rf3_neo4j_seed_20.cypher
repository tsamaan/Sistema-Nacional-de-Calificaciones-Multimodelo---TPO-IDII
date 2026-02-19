// EduGrade Global - RF3 (Neo4j) seed data from the same 20 MongoDB RF1 records
// Neo4j stores only relationship-relevant data (IDs/names) and lightweight record pointers.

// ---------- Constraints (Neo4j 4.4+/5.x) ----------
CREATE CONSTRAINT student_id IF NOT EXISTS FOR (s:Student) REQUIRE s.student_id IS UNIQUE;
CREATE CONSTRAINT institution_id IF NOT EXISTS FOR (i:Institution) REQUIRE i.institution_id IS UNIQUE;
CREATE CONSTRAINT subject_key IF NOT EXISTS FOR (m:Subject) REQUIRE m.subject_key IS UNIQUE;
CREATE CONSTRAINT record_id IF NOT EXISTS FOR (r:GradeRecord) REQUIRE r.record_id IS UNIQUE;

// ---------- Nodes: Students ----------
MERGE (s:Student {student_id: 'STU-0001'}) SET s.full_name = 'Liam Nkosi', s.dob = date('2007-05-14'), s.nationality = 'ZA';
MERGE (s:Student {student_id: 'STU-0002'}) SET s.full_name = 'Sofía Danko', s.dob = date('2006-11-02'), s.nationality = 'AR';
MERGE (s:Student {student_id: 'STU-0004'}) SET s.full_name = 'Ava Smith', s.dob = date('2006-07-19'), s.nationality = 'US';
MERGE (s:Student {student_id: 'STU-0005'}) SET s.full_name = 'Oliver Patel', s.dob = date('2007-01-30'), s.nationality = 'UK';
MERGE (s:Student {student_id: 'STU-0006'}) SET s.full_name = 'Mia Johnson', s.dob = date('2005-10-08'), s.nationality = 'US';
MERGE (s:Student {student_id: 'STU-0007'}) SET s.full_name = 'Emma Iuzzolino', s.dob = date('2006-02-21'), s.nationality = 'AR';
MERGE (s:Student {student_id: 'STU-0008'}) SET s.full_name = 'Theo Samaan', s.dob = date('2005-12-11'), s.nationality = 'ZA';

// ---------- Nodes: Institutions ----------
MERGE (i:Institution {institution_id: 'INS-001'}) SET i.name = 'Cape Town Central High', i.country = 'ZA', i.region = 'Western Cape';
MERGE (i:Institution {institution_id: 'INS-003'}) SET i.name = 'Bloemfontein Public School', i.country = 'ZA', i.region = 'Free State';
MERGE (i:Institution {institution_id: 'INS-004'}) SET i.name = 'Port Elizabeth International School', i.country = 'ZA', i.region = 'Eastern Cape';
MERGE (i:Institution {institution_id: 'INS-005'}) SET i.name = 'UADE (Argentina) - Ext Program', i.country = 'AR', i.region = 'CABA';
MERGE (i:Institution {institution_id: 'INS-006'}) SET i.name = 'Berlin Studienkolleg', i.country = 'DE', i.region = 'Berlin';
MERGE (i:Institution {institution_id: 'INS-007'}) SET i.name = 'New York State HS', i.country = 'US', i.region = 'NY';
MERGE (i:Institution {institution_id: 'INS-008'}) SET i.name = 'London Sixth Form College', i.country = 'UK', i.region = 'London';

// ---------- Nodes: Subjects (variants by system) ----------
MERGE (m:Subject {subject_key: 'SUB-BIO:US'}) SET m.subject_id = 'SUB-BIO', m.name = 'Biology', m.system = 'US', m.course_code = 'SUB-BIO-416';
MERGE (m:Subject {subject_key: 'SUB-CHEM:AR'}) SET m.subject_id = 'SUB-CHEM', m.name = 'Chemistry', m.system = 'AR', m.course_code = 'SUB-CHEM-387';
MERGE (m:Subject {subject_key: 'SUB-CHEM:UK'}) SET m.subject_id = 'SUB-CHEM', m.name = 'Chemistry', m.system = 'UK', m.course_code = 'SUB-CHEM-353';
MERGE (m:Subject {subject_key: 'SUB-CS:AR'}) SET m.subject_id = 'SUB-CS', m.name = 'Computer Science', m.system = 'AR', m.course_code = 'SUB-CS-405';
MERGE (m:Subject {subject_key: 'SUB-CS:UK'}) SET m.subject_id = 'SUB-CS', m.name = 'Computer Science', m.system = 'UK', m.course_code = 'SUB-CS-136';
MERGE (m:Subject {subject_key: 'SUB-CS:US'}) SET m.subject_id = 'SUB-CS', m.name = 'Computer Science', m.system = 'US', m.course_code = 'SUB-CS-256';
MERGE (m:Subject {subject_key: 'SUB-ECO:US'}) SET m.subject_id = 'SUB-ECO', m.name = 'Economics', m.system = 'US', m.course_code = 'SUB-ECO-169';
MERGE (m:Subject {subject_key: 'SUB-ENG:AR'}) SET m.subject_id = 'SUB-ENG', m.name = 'English', m.system = 'AR', m.course_code = 'SUB-ENG-137';
MERGE (m:Subject {subject_key: 'SUB-ENG:UK'}) SET m.subject_id = 'SUB-ENG', m.name = 'English', m.system = 'UK', m.course_code = 'SUB-ENG-191';
MERGE (m:Subject {subject_key: 'SUB-ENG:US'}) SET m.subject_id = 'SUB-ENG', m.name = 'English', m.system = 'US', m.course_code = 'SUB-ENG-474';
MERGE (m:Subject {subject_key: 'SUB-HIST:UK'}) SET m.subject_id = 'SUB-HIST', m.name = 'History', m.system = 'UK', m.course_code = 'SUB-HIST-473';
MERGE (m:Subject {subject_key: 'SUB-MATH:AR'}) SET m.subject_id = 'SUB-MATH', m.name = 'Mathematics', m.system = 'AR', m.course_code = 'SUB-MATH-297';
MERGE (m:Subject {subject_key: 'SUB-MATH:DE'}) SET m.subject_id = 'SUB-MATH', m.name = 'Mathematics', m.system = 'DE', m.course_code = 'SUB-MATH-125';
MERGE (m:Subject {subject_key: 'SUB-MATH:UK'}) SET m.subject_id = 'SUB-MATH', m.name = 'Mathematics', m.system = 'UK', m.course_code = 'SUB-MATH-291';
MERGE (m:Subject {subject_key: 'SUB-PHY:AR'}) SET m.subject_id = 'SUB-PHY', m.name = 'Physics', m.system = 'AR', m.course_code = 'SUB-PHY-241';

// ---------- Nodes + Relationships: GradeRecord stubs (20) ----------
MERGE (r:GradeRecord {record_id: 'GR-2023-0006'}) SET r.system = 'US', r.scale_type = 'letter_and_gpa', r.grade_value = 'B+ (GPA 3.3)', r.passed = true, r.academic_year = 2023, r.term = 'T2', r.created_at = datetime('2026-02-09T17:30:00Z');
MATCH (s:Student {student_id: 'STU-0006'}), (r:GradeRecord {record_id: 'GR-2023-0006'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2023-0006'}), (m:Subject {subject_key: 'SUB-ENG:US'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2023-0006'}), (i:Institution {institution_id: 'INS-007'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0006'}), (i:Institution {institution_id: 'INS-007'}) MERGE (s)-[:ATTENDED {academic_year: 2023, term: 'T2', system: 'US'}]->(i);
MATCH (s:Student {student_id: 'STU-0006'}), (m:Subject {subject_key: 'SUB-ENG:US'}) MERGE (s)-[t:TOOK {record_id: 'GR-2023-0006'}]->(m) SET t.academic_year = 2023, t.term = 'T2', t.attempt = 1, t.passed = true, t.grade_value = 'B+ (GPA 3.3)';

MERGE (r:GradeRecord {record_id: 'GR-2023-0007'}) SET r.system = 'UK', r.scale_type = 'letter', r.grade_value = 'E', r.passed = true, r.academic_year = 2023, r.term = 'T2', r.created_at = datetime('2026-02-02T13:30:00Z');
MATCH (s:Student {student_id: 'STU-0005'}), (r:GradeRecord {record_id: 'GR-2023-0007'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2023-0007'}), (m:Subject {subject_key: 'SUB-CHEM:UK'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2023-0007'}), (i:Institution {institution_id: 'INS-007'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0005'}), (i:Institution {institution_id: 'INS-007'}) MERGE (s)-[:ATTENDED {academic_year: 2023, term: 'T2', system: 'UK'}]->(i);
MATCH (s:Student {student_id: 'STU-0005'}), (m:Subject {subject_key: 'SUB-CHEM:UK'}) MERGE (s)-[t:TOOK {record_id: 'GR-2023-0007'}]->(m) SET t.academic_year = 2023, t.term = 'T2', t.attempt = 1, t.passed = true, t.grade_value = 'E';

MERGE (r:GradeRecord {record_id: 'GR-2023-0009'}) SET r.system = 'UK', r.scale_type = 'letter', r.grade_value = 'A*', r.passed = true, r.academic_year = 2023, r.term = 'T4', r.created_at = datetime('2026-02-13T14:00:00Z');
MATCH (s:Student {student_id: 'STU-0001'}), (r:GradeRecord {record_id: 'GR-2023-0009'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2023-0009'}), (m:Subject {subject_key: 'SUB-ENG:UK'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2023-0009'}), (i:Institution {institution_id: 'INS-008'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0001'}), (i:Institution {institution_id: 'INS-008'}) MERGE (s)-[:ATTENDED {academic_year: 2023, term: 'T4', system: 'UK'}]->(i);
MATCH (s:Student {student_id: 'STU-0001'}), (m:Subject {subject_key: 'SUB-ENG:UK'}) MERGE (s)-[t:TOOK {record_id: 'GR-2023-0009'}]->(m) SET t.academic_year = 2023, t.term = 'T4', t.attempt = 2, t.passed = true, t.grade_value = 'A*';

MERGE (r:GradeRecord {record_id: 'GR-2023-0011'}) SET r.system = 'US', r.scale_type = 'letter_and_gpa', r.grade_value = 'A- (GPA 3.7)', r.passed = true, r.academic_year = 2023, r.term = 'T2', r.created_at = datetime('2026-02-05T16:15:00Z');
MATCH (s:Student {student_id: 'STU-0004'}), (r:GradeRecord {record_id: 'GR-2023-0011'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2023-0011'}), (m:Subject {subject_key: 'SUB-ENG:US'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2023-0011'}), (i:Institution {institution_id: 'INS-007'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0004'}), (i:Institution {institution_id: 'INS-007'}) MERGE (s)-[:ATTENDED {academic_year: 2023, term: 'T2', system: 'US'}]->(i);
MATCH (s:Student {student_id: 'STU-0004'}), (m:Subject {subject_key: 'SUB-ENG:US'}) MERGE (s)-[t:TOOK {record_id: 'GR-2023-0011'}]->(m) SET t.academic_year = 2023, t.term = 'T2', t.attempt = 1, t.passed = true, t.grade_value = 'A- (GPA 3.7)';

MERGE (r:GradeRecord {record_id: 'GR-2023-0013'}) SET r.system = 'AR', r.scale_type = 'numeric_1_10', r.grade_value = '3', r.passed = false, r.academic_year = 2023, r.term = 'T4', r.created_at = datetime('2026-02-05T13:30:00Z');
MATCH (s:Student {student_id: 'STU-0007'}), (r:GradeRecord {record_id: 'GR-2023-0013'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2023-0013'}), (m:Subject {subject_key: 'SUB-PHY:AR'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2023-0013'}), (i:Institution {institution_id: 'INS-005'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0007'}), (i:Institution {institution_id: 'INS-005'}) MERGE (s)-[:ATTENDED {academic_year: 2023, term: 'T4', system: 'AR'}]->(i);
MATCH (s:Student {student_id: 'STU-0007'}), (m:Subject {subject_key: 'SUB-PHY:AR'}) MERGE (s)-[t:TOOK {record_id: 'GR-2023-0013'}]->(m) SET t.academic_year = 2023, t.term = 'T4', t.attempt = 1, t.passed = false, t.grade_value = '3';

MERGE (r:GradeRecord {record_id: 'GR-2023-0014'}) SET r.system = 'US', r.scale_type = 'letter_and_gpa', r.grade_value = 'F (GPA 0.0)', r.passed = false, r.academic_year = 2023, r.term = 'T2', r.created_at = datetime('2026-02-12T13:15:00Z');
MATCH (s:Student {student_id: 'STU-0004'}), (r:GradeRecord {record_id: 'GR-2023-0014'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2023-0014'}), (m:Subject {subject_key: 'SUB-CS:US'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2023-0014'}), (i:Institution {institution_id: 'INS-007'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0004'}), (i:Institution {institution_id: 'INS-007'}) MERGE (s)-[:ATTENDED {academic_year: 2023, term: 'T2', system: 'US'}]->(i);
MATCH (s:Student {student_id: 'STU-0004'}), (m:Subject {subject_key: 'SUB-CS:US'}) MERGE (s)-[t:TOOK {record_id: 'GR-2023-0014'}]->(m) SET t.academic_year = 2023, t.term = 'T2', t.attempt = 1, t.passed = false, t.grade_value = 'F (GPA 0.0)';

MERGE (r:GradeRecord {record_id: 'GR-2023-0015'}) SET r.system = 'DE', r.scale_type = 'numeric_inverse_1_6', r.grade_value = '2.7', r.passed = true, r.academic_year = 2023, r.term = 'T2', r.created_at = datetime('2026-02-03T13:30:00Z');
MATCH (s:Student {student_id: 'STU-0008'}), (r:GradeRecord {record_id: 'GR-2023-0015'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2023-0015'}), (m:Subject {subject_key: 'SUB-MATH:DE'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2023-0015'}), (i:Institution {institution_id: 'INS-001'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0008'}), (i:Institution {institution_id: 'INS-001'}) MERGE (s)-[:ATTENDED {academic_year: 2023, term: 'T2', system: 'DE'}]->(i);
MATCH (s:Student {student_id: 'STU-0008'}), (m:Subject {subject_key: 'SUB-MATH:DE'}) MERGE (s)-[t:TOOK {record_id: 'GR-2023-0015'}]->(m) SET t.academic_year = 2023, t.term = 'T2', t.attempt = 1, t.passed = true, t.grade_value = '2.7';

MERGE (r:GradeRecord {record_id: 'GR-2023-0017'}) SET r.system = 'US', r.scale_type = 'letter_and_gpa', r.grade_value = 'C+ (GPA 2.3)', r.passed = true, r.academic_year = 2023, r.term = 'T2', r.created_at = datetime('2026-02-12T11:00:00Z');
MATCH (s:Student {student_id: 'STU-0006'}), (r:GradeRecord {record_id: 'GR-2023-0017'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2023-0017'}), (m:Subject {subject_key: 'SUB-ECO:US'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2023-0017'}), (i:Institution {institution_id: 'INS-005'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0006'}), (i:Institution {institution_id: 'INS-005'}) MERGE (s)-[:ATTENDED {academic_year: 2023, term: 'T2', system: 'US'}]->(i);
MATCH (s:Student {student_id: 'STU-0006'}), (m:Subject {subject_key: 'SUB-ECO:US'}) MERGE (s)-[t:TOOK {record_id: 'GR-2023-0017'}]->(m) SET t.academic_year = 2023, t.term = 'T2', t.attempt = 1, t.passed = true, t.grade_value = 'C+ (GPA 2.3)';

MERGE (r:GradeRecord {record_id: 'GR-2023-0018'}) SET r.system = 'UK', r.scale_type = 'letter', r.grade_value = 'C', r.passed = true, r.academic_year = 2023, r.term = 'T3', r.created_at = datetime('2026-02-02T08:00:00Z');
MATCH (s:Student {student_id: 'STU-0001'}), (r:GradeRecord {record_id: 'GR-2023-0018'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2023-0018'}), (m:Subject {subject_key: 'SUB-ENG:UK'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2023-0018'}), (i:Institution {institution_id: 'INS-007'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0001'}), (i:Institution {institution_id: 'INS-007'}) MERGE (s)-[:ATTENDED {academic_year: 2023, term: 'T3', system: 'UK'}]->(i);
MATCH (s:Student {student_id: 'STU-0001'}), (m:Subject {subject_key: 'SUB-ENG:UK'}) MERGE (s)-[t:TOOK {record_id: 'GR-2023-0018'}]->(m) SET t.academic_year = 2023, t.term = 'T3', t.attempt = 1, t.passed = true, t.grade_value = 'C';

MERGE (r:GradeRecord {record_id: 'GR-2023-0019'}) SET r.system = 'UK', r.scale_type = 'letter', r.grade_value = 'C', r.passed = true, r.academic_year = 2023, r.term = 'T2', r.created_at = datetime('2026-02-08T12:30:00Z');
MATCH (s:Student {student_id: 'STU-0004'}), (r:GradeRecord {record_id: 'GR-2023-0019'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2023-0019'}), (m:Subject {subject_key: 'SUB-CS:UK'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2023-0019'}), (i:Institution {institution_id: 'INS-004'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0004'}), (i:Institution {institution_id: 'INS-004'}) MERGE (s)-[:ATTENDED {academic_year: 2023, term: 'T2', system: 'UK'}]->(i);
MATCH (s:Student {student_id: 'STU-0004'}), (m:Subject {subject_key: 'SUB-CS:UK'}) MERGE (s)-[t:TOOK {record_id: 'GR-2023-0019'}]->(m) SET t.academic_year = 2023, t.term = 'T2', t.attempt = 1, t.passed = true, t.grade_value = 'C';

MERGE (r:GradeRecord {record_id: 'GR-2024-0003'}) SET r.system = 'AR', r.scale_type = 'numeric_1_10', r.grade_value = '6', r.passed = true, r.academic_year = 2024, r.term = 'T2', r.created_at = datetime('2026-02-07T17:15:00Z');
MATCH (s:Student {student_id: 'STU-0002'}), (r:GradeRecord {record_id: 'GR-2024-0003'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2024-0003'}), (m:Subject {subject_key: 'SUB-ENG:AR'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2024-0003'}), (i:Institution {institution_id: 'INS-001'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0002'}), (i:Institution {institution_id: 'INS-001'}) MERGE (s)-[:ATTENDED {academic_year: 2024, term: 'T2', system: 'AR'}]->(i);
MATCH (s:Student {student_id: 'STU-0002'}), (m:Subject {subject_key: 'SUB-ENG:AR'}) MERGE (s)-[t:TOOK {record_id: 'GR-2024-0003'}]->(m) SET t.academic_year = 2024, t.term = 'T2', t.attempt = 1, t.passed = true, t.grade_value = '6';

MERGE (r:GradeRecord {record_id: 'GR-2024-0008'}) SET r.system = 'AR', r.scale_type = 'numeric_1_10', r.grade_value = '5', r.passed = true, r.academic_year = 2024, r.term = 'T2', r.created_at = datetime('2026-02-04T15:00:00Z');
MATCH (s:Student {student_id: 'STU-0002'}), (r:GradeRecord {record_id: 'GR-2024-0008'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2024-0008'}), (m:Subject {subject_key: 'SUB-MATH:AR'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2024-0008'}), (i:Institution {institution_id: 'INS-004'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0002'}), (i:Institution {institution_id: 'INS-004'}) MERGE (s)-[:ATTENDED {academic_year: 2024, term: 'T2', system: 'AR'}]->(i);
MATCH (s:Student {student_id: 'STU-0002'}), (m:Subject {subject_key: 'SUB-MATH:AR'}) MERGE (s)-[t:TOOK {record_id: 'GR-2024-0008'}]->(m) SET t.academic_year = 2024, t.term = 'T2', t.attempt = 1, t.passed = true, t.grade_value = '5';

MERGE (r:GradeRecord {record_id: 'GR-2024-0010'}) SET r.system = 'AR', r.scale_type = 'numeric_1_10', r.grade_value = '6', r.passed = true, r.academic_year = 2024, r.term = 'T4', r.created_at = datetime('2026-02-14T11:00:00Z');
MATCH (s:Student {student_id: 'STU-0001'}), (r:GradeRecord {record_id: 'GR-2024-0010'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2024-0010'}), (m:Subject {subject_key: 'SUB-ENG:AR'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2024-0010'}), (i:Institution {institution_id: 'INS-005'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0001'}), (i:Institution {institution_id: 'INS-005'}) MERGE (s)-[:ATTENDED {academic_year: 2024, term: 'T4', system: 'AR'}]->(i);
MATCH (s:Student {student_id: 'STU-0001'}), (m:Subject {subject_key: 'SUB-ENG:AR'}) MERGE (s)-[t:TOOK {record_id: 'GR-2024-0010'}]->(m) SET t.academic_year = 2024, t.term = 'T4', t.attempt = 1, t.passed = true, t.grade_value = '6';

MERGE (r:GradeRecord {record_id: 'GR-2024-0020'}) SET r.system = 'US', r.scale_type = 'letter_and_gpa', r.grade_value = 'B+ (GPA 3.3)', r.passed = true, r.academic_year = 2024, r.term = 'T3', r.created_at = datetime('2026-02-07T15:15:00Z');
MATCH (s:Student {student_id: 'STU-0006'}), (r:GradeRecord {record_id: 'GR-2024-0020'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2024-0020'}), (m:Subject {subject_key: 'SUB-ECO:US'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2024-0020'}), (i:Institution {institution_id: 'INS-006'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0006'}), (i:Institution {institution_id: 'INS-006'}) MERGE (s)-[:ATTENDED {academic_year: 2024, term: 'T3', system: 'US'}]->(i);
MATCH (s:Student {student_id: 'STU-0006'}), (m:Subject {subject_key: 'SUB-ECO:US'}) MERGE (s)-[t:TOOK {record_id: 'GR-2024-0020'}]->(m) SET t.academic_year = 2024, t.term = 'T3', t.attempt = 2, t.passed = true, t.grade_value = 'B+ (GPA 3.3)';

MERGE (r:GradeRecord {record_id: 'GR-2025-0001'}) SET r.system = 'US', r.scale_type = 'letter_and_gpa', r.grade_value = 'F (GPA 0.0)', r.passed = false, r.academic_year = 2025, r.term = 'T2', r.created_at = datetime('2026-02-11T15:00:00Z');
MATCH (s:Student {student_id: 'STU-0006'}), (r:GradeRecord {record_id: 'GR-2025-0001'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2025-0001'}), (m:Subject {subject_key: 'SUB-CS:US'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2025-0001'}), (i:Institution {institution_id: 'INS-004'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0006'}), (i:Institution {institution_id: 'INS-004'}) MERGE (s)-[:ATTENDED {academic_year: 2025, term: 'T2', system: 'US'}]->(i);
MATCH (s:Student {student_id: 'STU-0006'}), (m:Subject {subject_key: 'SUB-CS:US'}) MERGE (s)-[t:TOOK {record_id: 'GR-2025-0001'}]->(m) SET t.academic_year = 2025, t.term = 'T2', t.attempt = 1, t.passed = false, t.grade_value = 'F (GPA 0.0)';

MERGE (r:GradeRecord {record_id: 'GR-2025-0002'}) SET r.system = 'UK', r.scale_type = 'letter', r.grade_value = 'A*', r.passed = true, r.academic_year = 2025, r.term = 'T4', r.created_at = datetime('2026-02-06T10:30:00Z');
MATCH (s:Student {student_id: 'STU-0005'}), (r:GradeRecord {record_id: 'GR-2025-0002'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2025-0002'}), (m:Subject {subject_key: 'SUB-HIST:UK'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2025-0002'}), (i:Institution {institution_id: 'INS-007'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0005'}), (i:Institution {institution_id: 'INS-007'}) MERGE (s)-[:ATTENDED {academic_year: 2025, term: 'T4', system: 'UK'}]->(i);
MATCH (s:Student {student_id: 'STU-0005'}), (m:Subject {subject_key: 'SUB-HIST:UK'}) MERGE (s)-[t:TOOK {record_id: 'GR-2025-0002'}]->(m) SET t.academic_year = 2025, t.term = 'T4', t.attempt = 1, t.passed = true, t.grade_value = 'A*';

MERGE (r:GradeRecord {record_id: 'GR-2025-0004'}) SET r.system = 'AR', r.scale_type = 'numeric_1_10', r.grade_value = '2', r.passed = false, r.academic_year = 2025, r.term = 'T3', r.created_at = datetime('2026-02-12T12:15:00Z');
MATCH (s:Student {student_id: 'STU-0002'}), (r:GradeRecord {record_id: 'GR-2025-0004'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2025-0004'}), (m:Subject {subject_key: 'SUB-CHEM:AR'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2025-0004'}), (i:Institution {institution_id: 'INS-003'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0002'}), (i:Institution {institution_id: 'INS-003'}) MERGE (s)-[:ATTENDED {academic_year: 2025, term: 'T3', system: 'AR'}]->(i);
MATCH (s:Student {student_id: 'STU-0002'}), (m:Subject {subject_key: 'SUB-CHEM:AR'}) MERGE (s)-[t:TOOK {record_id: 'GR-2025-0004'}]->(m) SET t.academic_year = 2025, t.term = 'T3', t.attempt = 1, t.passed = false, t.grade_value = '2';

MERGE (r:GradeRecord {record_id: 'GR-2025-0005'}) SET r.system = 'AR', r.scale_type = 'numeric_1_10', r.grade_value = '3', r.passed = false, r.academic_year = 2025, r.term = 'T2', r.created_at = datetime('2026-02-05T16:45:00Z');
MATCH (s:Student {student_id: 'STU-0002'}), (r:GradeRecord {record_id: 'GR-2025-0005'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2025-0005'}), (m:Subject {subject_key: 'SUB-CS:AR'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2025-0005'}), (i:Institution {institution_id: 'INS-008'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0002'}), (i:Institution {institution_id: 'INS-008'}) MERGE (s)-[:ATTENDED {academic_year: 2025, term: 'T2', system: 'AR'}]->(i);
MATCH (s:Student {student_id: 'STU-0002'}), (m:Subject {subject_key: 'SUB-CS:AR'}) MERGE (s)-[t:TOOK {record_id: 'GR-2025-0005'}]->(m) SET t.academic_year = 2025, t.term = 'T2', t.attempt = 1, t.passed = false, t.grade_value = '3';

MERGE (r:GradeRecord {record_id: 'GR-2025-0012'}) SET r.system = 'US', r.scale_type = 'letter_and_gpa', r.grade_value = 'A (GPA 4.0)', r.passed = true, r.academic_year = 2025, r.term = 'T1', r.created_at = datetime('2026-02-16T12:30:00Z');
MATCH (s:Student {student_id: 'STU-0006'}), (r:GradeRecord {record_id: 'GR-2025-0012'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2025-0012'}), (m:Subject {subject_key: 'SUB-BIO:US'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2025-0012'}), (i:Institution {institution_id: 'INS-007'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0006'}), (i:Institution {institution_id: 'INS-007'}) MERGE (s)-[:ATTENDED {academic_year: 2025, term: 'T1', system: 'US'}]->(i);
MATCH (s:Student {student_id: 'STU-0006'}), (m:Subject {subject_key: 'SUB-BIO:US'}) MERGE (s)-[t:TOOK {record_id: 'GR-2025-0012'}]->(m) SET t.academic_year = 2025, t.term = 'T1', t.attempt = 1, t.passed = true, t.grade_value = 'A (GPA 4.0)';

MERGE (r:GradeRecord {record_id: 'GR-2025-0016'}) SET r.system = 'UK', r.scale_type = 'letter', r.grade_value = 'C', r.passed = true, r.academic_year = 2025, r.term = 'T4', r.created_at = datetime('2026-02-14T09:45:00Z');
MATCH (s:Student {student_id: 'STU-0005'}), (r:GradeRecord {record_id: 'GR-2025-0016'}) MERGE (s)-[:HAS_RECORD]->(r);
MATCH (r:GradeRecord {record_id: 'GR-2025-0016'}), (m:Subject {subject_key: 'SUB-MATH:UK'}) MERGE (r)-[:FOR_SUBJECT]->(m);
MATCH (r:GradeRecord {record_id: 'GR-2025-0016'}), (i:Institution {institution_id: 'INS-008'}) MERGE (r)-[:AT_INSTITUTION]->(i);
MATCH (s:Student {student_id: 'STU-0005'}), (i:Institution {institution_id: 'INS-008'}) MERGE (s)-[:ATTENDED {academic_year: 2025, term: 'T4', system: 'UK'}]->(i);
MATCH (s:Student {student_id: 'STU-0005'}), (m:Subject {subject_key: 'SUB-MATH:UK'}) MERGE (s)-[t:TOOK {record_id: 'GR-2025-0016'}]->(m) SET t.academic_year = 2025, t.term = 'T4', t.attempt = 1, t.passed = true, t.grade_value = 'C';

// ---------- RF3 relationships: prerequisites (correlatividades) ----------
MATCH (a:Subject {subject_key: 'SUB-MATH:AR'}), (b:Subject {subject_key: 'SUB-PHY:AR'}) MERGE (a)-[r:PREREQUISITE_FOR]->(b) SET r.basis = 'curriculum', r.strong = true;
MATCH (a:Subject {subject_key: 'SUB-MATH:AR'}), (b:Subject {subject_key: 'SUB-CHEM:AR'}) MERGE (a)-[r:PREREQUISITE_FOR]->(b) SET r.basis = 'curriculum', r.strong = true;
MATCH (a:Subject {subject_key: 'SUB-MATH:AR'}), (b:Subject {subject_key: 'SUB-CS:AR'}) MERGE (a)-[r:PREREQUISITE_FOR]->(b) SET r.basis = 'curriculum', r.strong = true;
MATCH (a:Subject {subject_key: 'SUB-ENG:UK'}), (b:Subject {subject_key: 'SUB-HIST:UK'}) MERGE (a)-[r:PREREQUISITE_FOR]->(b) SET r.basis = 'curriculum', r.strong = true;
MATCH (a:Subject {subject_key: 'SUB-MATH:UK'}), (b:Subject {subject_key: 'SUB-CHEM:UK'}) MERGE (a)-[r:PREREQUISITE_FOR]->(b) SET r.basis = 'curriculum', r.strong = true;
MATCH (a:Subject {subject_key: 'SUB-CHEM:UK'}), (b:Subject {subject_key: 'SUB-CS:UK'}) MERGE (a)-[r:PREREQUISITE_FOR]->(b) SET r.basis = 'curriculum', r.strong = true;

// ---------- RF3 relationships: equivalences (direct + indirect traversal) ----------
MATCH (a:Subject {subject_key: 'SUB-CS:AR'}), (b:Subject {subject_key: 'SUB-CS:UK'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'full', r.normative_ref = 'NORM-ARUK-CS-2025';
MATCH (a:Subject {subject_key: 'SUB-CS:UK'}), (b:Subject {subject_key: 'SUB-CS:AR'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'full', r.normative_ref = 'NORM-ARUK-CS-2025';
MATCH (a:Subject {subject_key: 'SUB-CS:UK'}), (b:Subject {subject_key: 'SUB-CS:US'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'partial', r.coverage = 0.85, r.normative_ref = 'NORM-UKUS-CS-2024';
MATCH (a:Subject {subject_key: 'SUB-CS:US'}), (b:Subject {subject_key: 'SUB-CS:UK'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'partial', r.coverage = 0.85, r.normative_ref = 'NORM-UKUS-CS-2024';
MATCH (a:Subject {subject_key: 'SUB-ENG:AR'}), (b:Subject {subject_key: 'SUB-ENG:UK'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'partial', r.coverage = 0.9, r.normative_ref = 'NORM-ARUK-ENG-2024';
MATCH (a:Subject {subject_key: 'SUB-ENG:UK'}), (b:Subject {subject_key: 'SUB-ENG:AR'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'partial', r.coverage = 0.9, r.normative_ref = 'NORM-ARUK-ENG-2024';
MATCH (a:Subject {subject_key: 'SUB-ENG:UK'}), (b:Subject {subject_key: 'SUB-ENG:US'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'full', r.normative_ref = 'NORM-UKUS-ENG-2023';
MATCH (a:Subject {subject_key: 'SUB-ENG:US'}), (b:Subject {subject_key: 'SUB-ENG:UK'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'full', r.normative_ref = 'NORM-UKUS-ENG-2023';
MATCH (a:Subject {subject_key: 'SUB-CHEM:AR'}), (b:Subject {subject_key: 'SUB-CHEM:UK'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'full', r.normative_ref = 'NORM-ARUK-CHEM-2025';
MATCH (a:Subject {subject_key: 'SUB-CHEM:UK'}), (b:Subject {subject_key: 'SUB-CHEM:AR'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'full', r.normative_ref = 'NORM-ARUK-CHEM-2025';
MATCH (a:Subject {subject_key: 'SUB-MATH:AR'}), (b:Subject {subject_key: 'SUB-MATH:UK'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'full', r.normative_ref = 'NORM-ARUK-MATH-2025';
MATCH (a:Subject {subject_key: 'SUB-MATH:UK'}), (b:Subject {subject_key: 'SUB-MATH:AR'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'full', r.normative_ref = 'NORM-ARUK-MATH-2025';
MATCH (a:Subject {subject_key: 'SUB-MATH:UK'}), (b:Subject {subject_key: 'SUB-MATH:DE'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'full', r.normative_ref = 'NORM-UKDE-MATH-2023';
MATCH (a:Subject {subject_key: 'SUB-MATH:DE'}), (b:Subject {subject_key: 'SUB-MATH:UK'}) MERGE (a)-[r:EQUIVALENT_TO]->(b) SET r.type = 'full', r.normative_ref = 'NORM-UKDE-MATH-2023';

// ---------- RF3: convalidaciones / revalidations between GradeRecords (examples) ----------
MATCH (n:GradeRecord {record_id: 'GR-2024-0010'}), (o:GradeRecord {record_id: 'GR-2023-0009'}) MERGE (n)-[r:CONVALIDATES]->(o) SET r.type = 'partial', r.coverage = 0.8, r.reason = 'Movilidad académica: convalidación parcial de contenidos';
MATCH (n:GradeRecord {record_id: 'GR-2023-0019'}), (o:GradeRecord {record_id: 'GR-2023-0014'}) MERGE (n)-[r:CONVALIDATES]->(o) SET r.type = 'partial', r.coverage = 0.85, r.reason = 'Equivalencia internacional aplicada por normativa';
