#!/bin/bash
cd "$(dirname "$0")"

echo "🔄 Cargando 10,000 calificaciones de muestra con agregados en Cassandra..."
echo ""

./venv/bin/python carga/seed_edugrade.py load \
  --mongo "mongodb://admin:admin123@localhost:27017" \
  --n 10000 \
  --batch 1000 \
  --with-rf4 \
  --with-rf5

echo ""
echo "✅ Carga completada!"
echo ""
echo "📊 Verificando datos cargados..."
echo ""

./venv/bin/python -c "
from pymongo import MongoClient

client = MongoClient('mongodb://admin:admin123@localhost:27017')
db = client['edugrade']

print('MongoDB - Base de datos: edugrade')
print('=' * 50)
for col in ['estudiantes', 'instituciones', 'materias', 'trayectorias', 'calificaciones']:
    count = db[col].count_documents({})
    print(f'  {col:20s}: {count:,} documentos')
print()
"
