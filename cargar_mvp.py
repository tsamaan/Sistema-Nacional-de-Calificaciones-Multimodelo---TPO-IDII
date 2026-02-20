#!/usr/bin/env python3
"""
MVP - Carga de datos inicial
- 10 estudiantes en MongoDB
- 5 instituciones en MongoDB
- 10 materias en MongoDB
- Calificaciones de los 10 estudiantes en MongoDB
- Trayectorias en MongoDB
- Replicación de estudiantes en Neo4j con conexiones
- Analítica en Cassandra (RF4: fact tables + agregados)
- Auditoría en Cassandra (RF5: logs inmutables)
"""

import os
from datetime import datetime, timezone
from pymongo import MongoClient
from neo4j import GraphDatabase
from cassandra.cluster import Cluster
import hashlib
import json
import random

# =========================
# CONEXIONES
# =========================

print("=" * 70)
print(" CARGANDO MVP - SISTEMA EDUGRADE")
print("=" * 70)

# MongoDB
mongo_client = MongoClient('mongodb://admin:admin123@localhost:27017/edugrade?authSource=admin')
db = mongo_client['edugrade']

# Neo4j
neo4j_driver = GraphDatabase.driver('bolt://localhost:7687', auth=('neo4j', 'Neo4j2026!'))

# Cassandra (dos sesiones: una para auditoría, otra para analítica)
cassandra_cluster = Cluster(['localhost'])
cassandra_session_auditoria = cassandra_cluster.connect()
cassandra_session_auditoria.set_keyspace('edugrade_auditoria')
cassandra_session_analitica = cassandra_cluster.connect()
cassandra_session_analitica.set_keyspace('edugrade_analitica')

print("✅ Conexiones establecidas\n")

# =========================
# DATOS BASE
# =========================

REGIONES = ['AR-BA', 'AR-CO', 'US-NY', 'US-CA', 'UK-LON']
SISTEMAS = ['AR', 'US', 'UK']
CICLOS = ['Cuatrimestre 1', 'Cuatrimestre 2', 'Semestre 1', 'Semestre 2']

# 5 Instituciones
INSTITUCIONES = [
    {'id_institucion': 'INS-001', 'nombre': 'Universidad de Buenos Aires', 'pais': 'AR', 'region': 'AR-BA', 'tipo': 'universidad'},
    {'id_institucion': 'INS-002', 'nombre': 'Universidad Nacional de Córdoba', 'pais': 'AR', 'region': 'AR-CO', 'tipo': 'universidad'},
    {'id_institucion': 'INS-003', 'nombre': 'Harvard University', 'pais': 'US', 'region': 'US-CA', 'tipo': 'universidad'},
    {'id_institucion': 'INS-004', 'nombre': 'MIT', 'pais': 'US', 'region': 'US-CA', 'tipo': 'universidad'},
    {'id_institucion': 'INS-005', 'nombre': 'Oxford University', 'pais': 'UK', 'region': 'UK-LON', 'tipo': 'universidad'},
]

# 10 Materias
MATERIAS = [
    {'id_materia': 'MAT-001', 'nombre': 'Matemática I', 'codigo': 'MATH-101', 'nivel': 'universitario'},
    {'id_materia': 'MAT-002', 'nombre': 'Física I', 'codigo': 'PHYS-101', 'nivel': 'universitario'},
    {'id_materia': 'MAT-003', 'nombre': 'Programación I', 'codigo': 'CS-101', 'nivel': 'universitario'},
    {'id_materia': 'MAT-004', 'nombre': 'Química General', 'codigo': 'CHEM-101', 'nivel': 'universitario'},
    {'id_materia': 'MAT-005', 'nombre': 'Historia', 'codigo': 'HIST-101', 'nivel': 'universitario'},
    {'id_materia': 'MAT-006', 'nombre': 'Literatura', 'codigo': 'LIT-101', 'nivel': 'universitario'},
    {'id_materia': 'MAT-007', 'nombre': 'Cálculo Avanzado', 'codigo': 'MATH-201', 'nivel': 'universitario'},
    {'id_materia': 'MAT-008', 'nombre': 'Algoritmos', 'codigo': 'CS-201', 'nivel': 'universitario'},
    {'id_materia': 'MAT-009', 'nombre': 'Estadística', 'codigo': 'STAT-101', 'nivel': 'universitario'},
    {'id_materia': 'MAT-010', 'nombre': 'Inglés Técnico', 'codigo': 'ENG-101', 'nivel': 'universitario'},
]

# 10 Estudiantes
ESTUDIANTES = [
    {'id_estudiante': 'EST-001', 'nombre': 'Juan Pérez', 'nacionalidad': 'AR', 'fecha_nacimiento': '2003-05-15'},
    {'id_estudiante': 'EST-002', 'nombre': 'María González', 'nacionalidad': 'AR', 'fecha_nacimiento': '2002-08-22'},
    {'id_estudiante': 'EST-003', 'nombre': 'Carlos Rodríguez', 'nacionalidad': 'AR', 'fecha_nacimiento': '2003-11-10'},
    {'id_estudiante': 'EST-004', 'nombre': 'Ana Martínez', 'nacionalidad': 'AR', 'fecha_nacimiento': '2004-02-18'},
    {'id_estudiante': 'EST-005', 'nombre': 'John Smith', 'nacionalidad': 'US', 'fecha_nacimiento': '2003-07-05'},
    {'id_estudiante': 'EST-006', 'nombre': 'Emily Johnson', 'nacionalidad': 'US', 'fecha_nacimiento': '2002-12-30'},
    {'id_estudiante': 'EST-007', 'nombre': 'Michael Brown', 'nacionalidad': 'US', 'fecha_nacimiento': '2003-03-25'},
    {'id_estudiante': 'EST-008', 'nombre': 'Sarah Williams', 'nacionalidad': 'UK', 'fecha_nacimiento': '2004-06-14'},
    {'id_estudiante': 'EST-009', 'nombre': 'James Davis', 'nacionalidad': 'UK', 'fecha_nacimiento': '2003-09-08'},
    {'id_estudiante': 'EST-010', 'nombre': 'Laura Wilson', 'nacionalidad': 'UK', 'fecha_nacimiento': '2002-04-20'},
]

# =========================
# 1. CARGAR INSTITUCIONES
# =========================

print("1️⃣  CARGANDO INSTITUCIONES EN MONGODB")
print("-" * 70)

for inst in INSTITUCIONES:
    doc = {
        'id_institucion': inst['id_institucion'],
        'nombre': inst['nombre'],
        'pais': inst['pais'],
        'region': inst['region'],
        'tipo': inst['tipo'],
        'created_at': datetime.now(timezone.utc)
    }
    db.instituciones.insert_one(doc)
    print(f"   ✅ {inst['id_institucion']}: {inst['nombre']}")

print()

# =========================
# 2. CARGAR MATERIAS
# =========================

print("2️⃣  CARGANDO MATERIAS EN MONGODB")
print("-" * 70)

for mat in MATERIAS:
    doc = {
        'id_materia': mat['id_materia'],
        'nombre': mat['nombre'],
        'codigo': mat['codigo'],
        'nivel': mat['nivel'],
        'created_at': datetime.now(timezone.utc)
    }
    db.materias.insert_one(doc)
    print(f"   ✅ {mat['id_materia']}: {mat['nombre']}")

print()

# =========================
# 3. CARGAR ESTUDIANTES
# =========================

print("3️⃣  CARGANDO ESTUDIANTES EN MONGODB")
print("-" * 70)

for est in ESTUDIANTES:
    doc = {
        'id_estudiante': est['id_estudiante'],
        'nombre_completo': est['nombre'],
        'nacionalidad': est['nacionalidad'],
        'fecha_nacimiento': est['fecha_nacimiento'],
        'created_at': datetime.now(timezone.utc)
    }
    db.estudiantes.insert_one(doc)
    print(f"   ✅ {est['id_estudiante']}: {est['nombre']}")

print()

# =========================
# 4. CARGAR CALIFICACIONES
# =========================

print("4️⃣  CARGANDO CALIFICACIONES EN MONGODB")
print("-" * 70)

calificaciones_creadas = []

for est in ESTUDIANTES:
    # Cada estudiante tiene entre 3 y 5 materias
    num_materias = random.randint(3, 5)
    materias_estudiante = random.sample(MATERIAS, num_materias)
    
    # Institución del estudiante (basada en su nacionalidad)
    if est['nacionalidad'] == 'AR':
        institucion = random.choice([INSTITUCIONES[0], INSTITUCIONES[1]])
        sistema = 'AR'
        notas_posibles = [6, 7, 8, 9, 10]
    elif est['nacionalidad'] == 'US':
        institucion = random.choice([INSTITUCIONES[2], INSTITUCIONES[3]])
        sistema = 'US'
        notas_posibles = ['A', 'B', 'C']
    else:  # UK
        institucion = INSTITUCIONES[4]
        sistema = 'UK'
        notas_posibles = ['A*', 'A', 'B', 'C']
    
    for materia in materias_estudiante:
        nota = random.choice(notas_posibles)
        
        # Convertir a ZA7 (simplificado)
        if sistema == 'AR':
            valor_za7 = {6: 3, 7: 4, 8: 5, 9: 6, 10: 7}.get(nota, 4)
        elif sistema == 'US':
            valor_za7 = {'A': 7, 'B': 6, 'C': 5}.get(nota, 4)
        else:  # UK
            valor_za7 = {'A*': 7, 'A': 6, 'B': 5, 'C': 4}.get(nota, 4)
        
        # Documento de calificación
        calificacion = {
            'region': institucion['region'],
            'id_estudiante': est['id_estudiante'],
            'id_institucion': institucion['id_institucion'],
            'id_materia': materia['id_materia'],
            'periodo': {
                'anio': 2026,
                'ciclo': random.choice(CICLOS)
            },
            'evaluacion': {
                'tipo': random.choice(['parcial', 'final', 'trabajo_practico']),
                'fecha': datetime(2026, random.randint(1, 12), random.randint(1, 28))
            },
            'original': {
                'sistema': sistema,
                'valor_raw': nota,
                'valor_num_za7': valor_za7
            },
            'conversiones': [],
            'auditoria': {
                'id_actor': 'sistema_carga_mvp',
                'ip': '127.0.0.1',
                'timestamp': datetime.now(timezone.utc)
            },
            'inmutabilidad': {
                'version': 1,
                'anterior': None,
                'hash': hashlib.sha256(f"{est['id_estudiante']}{materia['id_materia']}{nota}".encode()).hexdigest(),
                'timestamp': datetime.now(timezone.utc),
                'event_id': f"EVT-{est['id_estudiante'][-3:]}-{materia['id_materia'][-3:]}"
            },
            'created_at': datetime.now(timezone.utc),
            'updated_at': datetime.now(timezone.utc)
        }
        
        db.calificaciones.insert_one(calificacion)
        calificaciones_creadas.append(calificacion)
        print(f"   ✅ {est['id_estudiante']} - {materia['id_materia']}: {nota} ({sistema})")

print(f"\n   Total calificaciones: {len(calificaciones_creadas)}")
print()

# =========================
# 5. CARGAR TRAYECTORIAS
# =========================

print("5️⃣  CARGANDO TRAYECTORIAS EN MONGODB")
print("-" * 70)

for est in ESTUDIANTES:
    # Obtener calificaciones del estudiante
    cals_estudiante = [c for c in calificaciones_creadas if c['id_estudiante'] == est['id_estudiante']]
    
    trayectoria = {
        'id_estudiante': est['id_estudiante'],
        'instituciones': list(set([c['id_institucion'] for c in cals_estudiante])),
        'materias_cursadas': [
            {
                'id_materia': c['id_materia'],
                'anio': c['periodo']['anio'],
                'nota': c['original']['valor_raw'],
                'aprobada': True
            }
            for c in cals_estudiante
        ],
        'promedio_general': sum([c['original']['valor_num_za7'] for c in cals_estudiante]) / len(cals_estudiante),
        'created_at': datetime.now(timezone.utc)
    }
    
    db.trayectorias.insert_one(trayectoria)
    print(f"   ✅ {est['id_estudiante']}: {len(cals_estudiante)} materias, promedio {trayectoria['promedio_general']:.2f}")

print()

# =========================
# 6. REPLICAR EN NEO4J
# =========================

print("6️⃣  REPLICANDO EN NEO4J")
print("-" * 70)

with neo4j_driver.session() as session:
    # Crear nodos de Estudiantes
    for est in ESTUDIANTES:
        session.run("""
            CREATE (e:Estudiante {
                id_estudiante: $id,
                nombre: $nombre,
                nacionalidad: $nacionalidad,
                fecha_nacimiento: $fecha_nac
            })
        """, id=est['id_estudiante'], nombre=est['nombre'], 
             nacionalidad=est['nacionalidad'], fecha_nac=est['fecha_nacimiento'])
        print(f"   ✅ Nodo Estudiante: {est['id_estudiante']}")
    
    # Crear nodos de Instituciones
    for inst in INSTITUCIONES:
        session.run("""
            CREATE (i:Institucion {
                id_institucion: $id,
                nombre: $nombre,
                pais: $pais,
                region: $region
            })
        """, id=inst['id_institucion'], nombre=inst['nombre'], 
             pais=inst['pais'], region=inst['region'])
        print(f"   ✅ Nodo Institución: {inst['id_institucion']}")
    
    # Crear nodos de Materias
    for mat in MATERIAS:
        session.run("""
            CREATE (m:Materia {
                id_materia: $id,
                nombre: $nombre,
                codigo: $codigo,
                nivel: $nivel
            })
        """, id=mat['id_materia'], nombre=mat['nombre'], 
             codigo=mat['codigo'], nivel=mat['nivel'])
        print(f"   ✅ Nodo Materia: {mat['id_materia']}")
    
    # Crear relaciones basadas en las calificaciones
    for cal in calificaciones_creadas:
        # ESTUDIANTE -[ASISTIO]-> INSTITUCIÓN
        session.run("""
            MATCH (e:Estudiante {id_estudiante: $est})
            MATCH (i:Institucion {id_institucion: $inst})
            MERGE (e)-[:ASISTIO {anio: $anio}]->(i)
        """, est=cal['id_estudiante'], inst=cal['id_institucion'], anio=cal['periodo']['anio'])
        
        # INSTITUCIÓN -[OFRECE]-> MATERIA
        session.run("""
            MATCH (i:Institucion {id_institucion: $inst})
            MATCH (m:Materia {id_materia: $mat})
            MERGE (i)-[:OFRECE]->(m)
        """, inst=cal['id_institucion'], mat=cal['id_materia'])
        
        # ESTUDIANTE -[CURSO]-> MATERIA
        session.run("""
            MATCH (e:Estudiante {id_estudiante: $est})
            MATCH (m:Materia {id_materia: $mat})
            CREATE (e)-[:CURSO {
                anio: $anio,
                nota: $nota,
                sistema: $sistema,
                valor_za7: $za7
            }]->(m)
        """, est=cal['id_estudiante'], mat=cal['id_materia'], 
             anio=cal['periodo']['anio'], nota=str(cal['original']['valor_raw']),
             sistema=cal['original']['sistema'], za7=cal['original']['valor_num_za7'])

print(f"   ✅ Total relaciones creadas: {len(calificaciones_creadas) * 3}")
print()

# =========================
# 7. ANALÍTICA EN CASSANDRA (RF4)
# =========================

print("7️⃣  CARGANDO ANALÍTICA EN CASSANDRA (RF4)")
print("-" * 70)

# Insertar en fact table (rf4_fact_grades_by_region_year_system)
query_fact = """
INSERT INTO edugrade_analitica.rf4_fact_grades_by_region_year_system
(region, academic_year, system, institution_id, subject_id, event_ts, record_id, student_id, 
 grade_raw, grade_norm_0_100, passed)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
"""

for cal in calificaciones_creadas:
    # Convertir valor ZA7 (1-7) a escala 0-100
    grade_norm = (cal['original']['valor_num_za7'] / 7.0) * 100.0
    passed = cal['original']['valor_num_za7'] >= 4  # Aprobar con 4 o más
    
    # Generar un record_id único
    record_id = f"REC-{cal['id_estudiante'][-3:]}-{cal['id_materia'][-3:]}-{cal['periodo']['anio']}"
    
    cassandra_session_analitica.execute(query_fact, (
        cal['region'],
        cal['periodo']['anio'],
        cal['original']['sistema'],
        cal['id_institucion'],
        cal['id_materia'],
        cal['evaluacion']['fecha'],
        record_id,
        cal['id_estudiante'],
        str(cal['original']['valor_raw']),
        grade_norm,
        passed
    ))

print(f"   ✅ Fact table: {len(calificaciones_creadas)} registros")

# Calcular y cargar agregados (promedio_por_region_anio)
from collections import defaultdict

agregados = defaultdict(lambda: {'n': 0, 'suma': 0.0, 'suma_cuadrados': 0.0})

for cal in calificaciones_creadas:
    key = (
        cal['region'],
        cal['periodo']['anio'],
        cal['original']['sistema'],
        cal['id_materia'],
        cal['id_institucion']
    )
    
    grade_norm = (cal['original']['valor_num_za7'] / 7.0) * 100.0
    agregados[key]['n'] += 1
    agregados[key]['suma'] += grade_norm
    agregados[key]['suma_cuadrados'] += grade_norm ** 2

# Insertar agregados
query_agg = """
INSERT INTO edugrade_analitica.promedio_por_region_anio
(region, anio, codigo_sistema, id_materia, id_institucion, n, suma, suma_cuadrados, actualizado_en)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
"""

timestamp = datetime.now(timezone.utc)
for key, valores in agregados.items():
    region, anio, sistema, materia, institucion = key
    cassandra_session_analitica.execute(query_agg, (
        region,
        anio,
        sistema,
        materia,
        institucion,
        valores['n'],
        valores['suma'],
        valores['suma_cuadrados'],
        timestamp
    ))

print(f"   ✅ Agregados: {len(agregados)} registros")
print()

# =========================
# 8. AUDITORÍA EN CASSANDRA (RF5)
# =========================

print("8️⃣  GUARDANDO LOGS EN CASSANDRA (RF5)")
print("-" * 70)

# Log por cada estudiante creado
for est in ESTUDIANTES:
    timestamp = datetime.now(timezone.utc)
    mes = timestamp.strftime('%Y%m')
    
    query = """
    INSERT INTO edugrade_auditoria.registro_auditoria_por_entidad_mes
    (id_entidad, aaaamm, marca_tiempo, tipo_entidad, accion, id_actor, ip, hash_anterior, hash_nuevo, carga_util)
    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    cassandra_session_auditoria.execute(query, (
        est['id_estudiante'],
        mes,
        timestamp,
        'ESTUDIANTE',
        'ESTUDIANTE_CREADO',
        'sistema_carga_mvp',
        '127.0.0.1',
        '0',
        hashlib.sha256(est['id_estudiante'].encode()).hexdigest(),
        json.dumps({'id_estudiante': est['id_estudiante'], 'nombre': est['nombre']})
    ))
    print(f"   ✅ Log: {est['id_estudiante']} creado")

# Log por cada calificación
for cal in calificaciones_creadas:
    timestamp = datetime.now(timezone.utc)
    mes = timestamp.strftime('%Y%m')
    
    cassandra_session_auditoria.execute(query, (
        cal['id_estudiante'],
        mes,
        timestamp,
        'CALIFICACION',
        'CALIFICACION_CREADA',
        'sistema_carga_mvp',
        '127.0.0.1',
        '0',
        cal['inmutabilidad']['hash'],
        json.dumps({
            'id_estudiante': cal['id_estudiante'],
            'id_materia': cal['id_materia'],
            'nota': str(cal['original']['valor_raw']),
            'sistema': cal['original']['sistema']
        })
    ))

print(f"   ✅ Total logs: {len(ESTUDIANTES) + len(calificaciones_creadas)}")
print()

# =========================
# RESUMEN
# =========================

print("=" * 70)
print(" ✅ CARGA MVP COMPLETA")
print("=" * 70)
print(f"""
📊 RESUMEN:
-----------
• Instituciones:     {len(INSTITUCIONES)} en MongoDB
• Materias:          {len(MATERIAS)} en MongoDB
• Estudiantes:       {len(ESTUDIANTES)} en MongoDB
• Calificaciones:    {len(calificaciones_creadas)} en MongoDB
• Trayectorias:      {len(ESTUDIANTES)} en MongoDB

• Nodos Neo4j:       {len(ESTUDIANTES) + len(INSTITUCIONES) + len(MATERIAS)}
• Relaciones Neo4j:  ~{len(calificaciones_creadas) * 3}

• Facts Cassandra:   {len(calificaciones_creadas)} registros (RF4)
• Agregados:         {len(agregados)} registros (RF4)
• Logs Cassandra:    {len(ESTUDIANTES) + len(calificaciones_creadas)} eventos (RF5)
""")

# Cerrar conexiones
mongo_client.close()
neo4j_driver.close()
cassandra_cluster.shutdown()

print("🔌 Conexiones cerradas")
print("=" * 70)
