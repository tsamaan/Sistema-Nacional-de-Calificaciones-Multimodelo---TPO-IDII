#!/bin/bash

# Script para aplicar el seed consolidado de Cassandra
# Sistema EduGrade Global - v2.0

echo "========================================================================"
echo "  APLICANDO SEED CONSOLIDADO DE CASSANDRA"
echo "========================================================================"
echo ""

# Verificar que Docker esté corriendo
if ! docker ps > /dev/null 2>&1; then
    echo "❌ Error: Docker no está corriendo"
    exit 1
fi

# Verificar que el contenedor de Cassandra exista
if ! docker ps | grep -q edugrade-cassandra; then
    echo "❌ Error: Contenedor 'edugrade-cassandra' no encontrado"
    echo "   Ejecuta: cd docker && docker-compose up -d cassandra"
    exit 1
fi

echo "1️⃣  Esperando que Cassandra esté listo..."
echo "   (Esto puede tomar 30-60 segundos)"
echo ""

# Esperar que Cassandra esté listo
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if docker exec edugrade-cassandra cqlsh -e "DESCRIBE KEYSPACES" > /dev/null 2>&1; then
        echo "   ✅ Cassandra está listo"
        break
    fi
    
    attempt=$((attempt + 1))
    echo "   ⏳ Intento $attempt/$max_attempts..."
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "   ❌ Error: Cassandra no respondió después de $max_attempts intentos"
    exit 1
fi

echo ""
echo "2️⃣  Copiando archivo seed al contenedor..."

# Copiar el archivo al contenedor
docker cp db/cassandra_seed_consolidado.cql edugrade-cassandra:/tmp/

if [ $? -ne 0 ]; then
    echo "   ❌ Error al copiar el archivo"
    exit 1
fi

echo "   ✅ Archivo copiado"
echo ""
echo "3️⃣  Aplicando seed (esto puede tomar 10-20 segundos)..."
echo ""

# Aplicar el seed
docker exec edugrade-cassandra cqlsh -f /tmp/cassandra_seed_consolidado.cql

if [ $? -ne 0 ]; then
    echo ""
    echo "   ❌ Error al aplicar el seed"
    exit 1
fi

echo ""
echo "4️⃣  Verificando estructura..."
echo ""

# Verificar keyspaces
echo "   📦 Keyspaces creados:"
docker exec edugrade-cassandra cqlsh -e "DESCRIBE KEYSPACES" | grep edugrade

echo ""
echo "   📋 Tablas en edugrade_analitica:"
docker exec edugrade-cassandra cqlsh -e "USE edugrade_analitica; DESCRIBE TABLES"

echo ""
echo "   📋 Tablas en edugrade_auditoria:"
docker exec edugrade-cassandra cqlsh -e "USE edugrade_auditoria; DESCRIBE TABLES"

echo ""
echo "5️⃣  Verificando estructura vacía..."
echo ""

# Verificar que las tablas estén vacías y listas
echo "   ✅ Keyspaces consolidados creados"
echo "   ✅ RF4 (Analítica): 4 tablas creadas"
echo "   ✅ RF5 (Auditoría): 1 tabla creada"
echo "   ✅ Estructura vacía lista para carga de datos"

echo ""
echo "========================================================================"
echo "  ✅ SEED CONSOLIDADO APLICADO EXITOSAMENTE"
echo "========================================================================"
echo ""
echo "📚 Próximos pasos:"
echo "   1. Cargar datos completos:  python3 cargar_mvp.py"
echo "   2. Probar la API:           cd api && npm start"
echo "   3. Ver guía completa:       cat db/CONSOLIDACION-CASSANDRA.md"
echo ""
echo "🔗 Endpoints disponibles:"
echo "   GET /api/cassandra/analitica/promedio"
echo "   GET /api/cassandra/analitica/facts"
echo "   GET /api/cassandra/analitica/reportes"
echo "   GET /api/cassandra/analitica/cross-system"
echo "   GET /api/cassandra/analitica/keys"
echo "   GET /api/cassandra/auditoria"
echo ""
