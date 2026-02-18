#!/bin/bash
cd "$(dirname "$0")"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 VERIFICACIÓN DE DATOS - Sistema EduGrade"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# MongoDB
echo "🍃 MongoDB (localhost:27017/edugrade)"
echo "────────────────────────────────────────────────────"
./venv/bin/python -c "
from pymongo import MongoClient

client = MongoClient('mongodb://admin:admin123@localhost:27017')
db = client['edugrade']

collections = {
    'estudiantes': '👤',
    'instituciones': '🏫',
    'materias': '📚',
    'trayectorias': '🛤️',
    'calificaciones': '📝'
}

for col, icon in collections.items():
    count = db[col].count_documents({})
    print(f'  {icon} {col:20s}: {count:>8,} documentos')

# Muestra una calificación de ejemplo
print()
print('📋 Ejemplo de calificación:')
calif = db.calificaciones.find_one()
if calif:
    print(f'  ID: {calif[\"_id\"]}')
    print(f'  Estudiante: {calif[\"id_estudiante\"]}')
    print(f'  Sistema: {calif[\"original\"][\"sistema\"]}')
    print(f'  Valor original: {calif[\"original\"][\"valor_raw\"]}')
    print(f'  Valor ZA7: {calif[\"original\"][\"valor_num_za7\"]}')
    print(f'  Región: {calif[\"region\"]}')
    print(f'  Año: {calif[\"periodo\"][\"anio\"]}')
"
echo ""

# Redis
echo "🔴 Redis (localhost:6379)"
echo "────────────────────────────────────────────────────"
./venv/bin/python -c "
import redis

r = redis.Redis(host='localhost', port=6379, password='redis123', decode_responses=True)

# Contar keys por tipo
rule_keys = len(r.keys('rule:*'))
cache_keys = len(r.keys('cache:*'))
total_keys = r.dbsize()

print(f'  🔧 Reglas de conversión: {rule_keys:>8} keys')
print(f'  💾 Cache entries:        {cache_keys:>8} keys')
print(f'  📊 Total keys:           {total_keys:>8} keys')

# Mostrar algunas reglas
print()
print('📋 Ejemplo de regla de conversión:')
example = r.hgetall('rule:AR_to_ZA7:v1')
if example:
    print(f'  Regla: AR → ZA7 (versión 1)')
    for k, v in list(example.items())[:3]:
        print(f'    {k}: {v}')
"
echo ""

# Cassandra
echo "🔵 Cassandra (localhost:9042)"
echo "────────────────────────────────────────────────────"
./venv/bin/python -c "
from cassandra.cluster import Cluster

cluster = Cluster(['localhost'])
session = cluster.connect()

# Analítica
session.set_keyspace('edugrade_analitica')
result = session.execute('SELECT COUNT(*) as total FROM promedio_por_region_anio')
analitica_count = result.one().total

# Auditoría
session.set_keyspace('edugrade_auditoria')
result = session.execute('SELECT COUNT(*) as total FROM registro_auditoria_por_entidad_mes')
auditoria_count = result.one().total

print(f'  📊 Agregados analíticos:  {analitica_count:>8,} registros')
print(f'  🔍 Registros auditoría:   {auditoria_count:>8,} registros')

# Ejemplo de agregado
session.set_keyspace('edugrade_analitica')
result = session.execute('SELECT * FROM promedio_por_region_anio LIMIT 1')
row = result.one()
if row:
    print()
    print('📋 Ejemplo de agregado analítico:')
    print(f'  Región: {row.region} | Año: {row.anio}')
    print(f'  Sistema: {row.codigo_sistema} | Materia: {row.id_materia}')
    print(f'  N={row.n}, Suma={row.suma:.2f}')
    promedio = row.suma / row.n if row.n > 0 else 0
    print(f'  Promedio: {promedio:.2f} (escala ZA7)')

cluster.shutdown()
"
echo ""

# Neo4j
echo "🟢 Neo4j (localhost:7687)"
echo "────────────────────────────────────────────────────"
./venv/bin/python -c "
from neo4j import GraphDatabase

driver = GraphDatabase.driver('neo4j://localhost:7687', auth=('neo4j', 'Neo4j2026!'))

with driver.session() as session:
    # Contar nodos
    result = session.run('MATCH (n) RETURN count(n) as total')
    nodes = result.single()['total']
    
    # Contar relaciones
    result = session.run('MATCH ()-[r]->() RETURN count(r) as total')
    rels = result.single()['total']
    
    # Constraints
    result = session.run('SHOW CONSTRAINTS')
    constraints = len(list(result))
    
    # Indexes
    result = session.run('SHOW INDEXES')
    indexes = len(list(result))
    
    print(f'  🔵 Nodos:                 {nodes:>8,} nodos')
    print(f'  ➡️  Relaciones:            {rels:>8,} relaciones')
    print(f'  🔒 Constraints:           {constraints:>8} definidos')
    print(f'  📇 Índices:               {indexes:>8} creados')

driver.close()
"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Verificación completada"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
