#!/usr/bin/env python3
"""
Script de carga: Seeds coherentes (10 registros)
- MongoDB: 5 colecciones desde edugrade_rf1_seed_10.json
- Neo4j: YA CARGADO (edugrade_rf3_neo4j_seed_10.cypher)
- Redis: YA CARGADO (edugrade_rf2_redis_seed_10.resp)  
- Cassandra: Pendiente (se carga después con datos de MongoDB)
"""

import json
import os
from datetime import datetime
from pymongo import MongoClient

# =========================
# CONFIGURACIÓN
# =========================

SEED_FILE = '../db/edugrade_rf1_seed_10.json'
MONGO_URI = 'mongodb://admin:admin123@localhost:27017/edugrade?authSource=admin'

print("=" * 70)
print(" CARGANDO SEEDS COHERENTES - EDUGRADE MULTIMODELO")
print("=" * 70)
print()

# =========================
# 1. CONECTAR A MONGODB
# =========================

print("📡 Conectando a MongoDB...")
try:
    mongo_client = MongoClient(MONGO_URI)
    db = mongo_client['edugrade']
    mongo_client.server_info()  # Verificar conexión
    print("   ✅ MongoDB conectado")
except Exception as e:
    print(f"   ❌ Error al conectar a MongoDB: {e}")
    exit(1)

print()

# =========================
# 2. LIMPIAR COLECCIONES EXISTENTES
# =========================

print("🧹 Limpiando colecciones existentes...")
colecciones = ['estudiantes', 'instituciones', 'materias', 'trayectorias', 'calificaciones']

for col in colecciones:
    count_antes = db[col].count_documents({})
    db[col].delete_many({})
    print(f"   ✅ {col}: {count_antes} documentos eliminados")

print()

# =========================
# 3. CARGAR SEED JSON
# =========================

print(f"📂 Cargando seed desde: {SEED_FILE}")

# Cambiar al directorio del script para rutas relativas
script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

# Leer archivo JSON
try:
    with open(SEED_FILE, 'r', encoding='utf-8') as f:
        seed_data = json.load(f)
    print("   ✅ Archivo JSON leído correctamente")
except Exception as e:
    print(f"   ❌ Error al leer archivo: {e}")
    exit(1)

print()

# =========================
# 4. INSERTAR EN MONGODB
# =========================

print("💾 Insertando documentos en MongoDB...")
print()

collections_data = seed_data.get('collections', {})

for col_name in colecciones:
    if col_name in collections_data:
        docs = collections_data[col_name]
        
        # Convertir fechas ISO a datetime de Python
        for doc in docs:
            for key, value in doc.items():
                if isinstance(value, str) and 'T' in value and 'Z' in value:
                    try:
                        doc[key] = datetime.fromisoformat(value.replace('Z', '+00:00'))
                    except:
                        pass  # Si no es fecha válida, dejar como string
        
        # Insertar documentos
        if docs:
            result = db[col_name].insert_many(docs)
            print(f"   ✅ {col_name}: {len(result.inserted_ids)} documentos insertados")
        else:
            print(f"   ⚠️  {col_name}: sin documentos en el seed")
    else:
        print(f"   ❌ {col_name}: no encontrado en el seed JSON")

print()

# =========================
# 5. VERIFICAR CONTEOS
# =========================

print("🔍 Verificando conteos finales...")
print()

totales = {}
for col in colecciones:
    count = db[col].count_documents({})
    totales[col] = count
    print(f"   {col}: {count} docs")

print()

# =========================
# 6. RESUMEN
# =========================

print("=" * 70)
print(" RESUMEN DE CARGA")
print("=" * 70)
print()
print(f"✅ MongoDB:")
print(f"   - Estudiantes:    {totales['estudiantes']}")
print(f"   - Instituciones:  {totales['instituciones']}")
print(f"   - Materias:       {totales['materias']}")
print(f"   - Trayectorias:   {totales['trayectorias']}")
print(f"   - Calificaciones: {totales['calificaciones']}")
print(f"   TOTAL:            {sum(totales.values())} documentos")
print()
print("ℹ️  Neo4j y Redis ya están cargados (aplicados manualmente).")
print()
print("📋 Próximos pasos:")
print("   1. Verificar datos en MongoDB")
print("   2. Cargar Cassandra (analítica + auditoría)")
print("   3. Validar consistencia entre bases")
print()
print("=" * 70)

# Cerrar conexión
mongo_client.close()
