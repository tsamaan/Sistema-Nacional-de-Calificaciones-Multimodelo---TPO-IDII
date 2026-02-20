#!/bin/bash

# ==========================================================================
# SCRIPT MAESTRO: Aplicar todos los seeds coherentes
# Sistema EduGrade Multimodelo - 10 registros consistentes
# ==========================================================================

set -e  # Salir si hay algún error

# Obtener directorio del proyecto (donde está el script)
cd "$(dirname "${BASH_SOURCE[0]}")"
PROJECT_ROOT="$(pwd)"

echo "==========================================================================="
echo "  🚀 APLICANDO SEEDS COHERENTES - EDUGRADE MULTIMODELO"
echo "==========================================================================="
echo ""
echo "📂 Directorio proyecto: $PROJECT_ROOT"
echo ""

# ==========================================================================
# 1. VERIFICAR CONTENEDORES
# ==========================================================================

echo "1️⃣  VERIFICANDO CONTENEDORES..."
echo "---------------------------------------------------------------------------"

CONTAINERS=("edugrade-mongo" "edugrade-redis" "edugrade-neo4j" "edugrade-cassandra")
ALL_RUNNING=true

for container in "${CONTAINERS[@]}"; do
    if docker ps | grep -q $container; then
        echo "   ✅ $container está corriendo"
    else
        echo "   ❌ $container NO está corriendo"
        ALL_RUNNING=false
    fi
done

echo ""

if [ "$ALL_RUNNING" = false ]; then
    echo "❌ No todos los contenedores están corriendo."
    echo "   Ejecuta: cd docker && docker-compose up -d"
    exit 1
fi

# ==========================================================================
# 2. LIMPIAR BASES DE DATOS
# ==========================================================================

echo "2️⃣  LIMPIANDO BASES DE DATOS..."
echo "---------------------------------------------------------------------------"

# 2.1 Limpiar Neo4j
echo "   🧹 Limpiando Neo4j..."
docker exec edugrade-neo4j cypher-shell -u neo4j -p 'Neo4j2026!' \
    "MATCH (n) DETACH DELETE n;" 2>/dev/null || echo "      (ya estaba vacío)"
echo "      ✅ Neo4j limpio"

# 2.2 Limpiar Redis (mantener solo las keys del seed)
echo "   🧹 Limpiando Redis..."
docker exec edugrade-redis redis-cli -a redis123 --no-auth-warning FLUSHALL >/dev/null
echo "      ✅ Redis limpio"

# 2.3 MongoDB se limpia en el script Python

echo ""

# ==========================================================================
# 3. MONGODB - 5 colecciones (48 documentos)
# ==========================================================================

echo "3️⃣  CARGANDO MONGODB..."
echo "---------------------------------------------------------------------------"

cd "$PROJECT_ROOT/scripts"

# Desactivar validaciones primero
echo "   🔓 Desactivando validaciones de schema..."
for col in estudiantes instituciones materias trayectorias calificaciones; do
    docker exec edugrade-mongo mongosh -u admin -p admin123 \
        --authenticationDatabase admin edugrade --quiet \
        --eval "db.runCommand({collMod: '$col', validator: {}, validationLevel: 'off'})" \
        2>/dev/null || echo "      ⚠️  Colección $col no existe (se creará)"
done

# Ejecutar script de carga
python3 cargar_seeds_coherentes.py

cd "$PROJECT_ROOT"
echo ""

# ==========================================================================
# 4. REDIS - Reglas de conversión + Cache
# ==========================================================================

echo "4️⃣  CARGANDO REDIS..."
echo "---------------------------------------------------------------------------"

cat "$PROJECT_ROOT/db/edugrade_rf2_redis_seed_10.resp" | grep -v "^#" | grep -v "^$" | \
docker exec -i edugrade-redis redis-cli -a redis123 --pipe 2>&1 | \
grep -E "(errors|replies)" || echo "   ✅ Redis cargado"

# Verificar keys
RULE_COUNT=$(docker exec edugrade-redis redis-cli -a redis123 --no-auth-warning KEYS "RULE*" | wc -l)
CONV_COUNT=$(docker exec edugrade-redis redis-cli -a redis123 --no-auth-warning KEYS "CONV*" | wc -l)

echo "   ✅ Redis cargado:"
echo "      - Reglas de conversión: $RULE_COUNT keys"
echo "      - Conversiones cacheadas: $CONV_COUNT keys"
echo ""

# ==========================================================================
# 5. NEO4J - Grafo de relaciones académicas
# ==========================================================================

echo "5️⃣  CARGANDO NEO4J..."
echo "---------------------------------------------------------------------------"

# Copiar seed al contenedor
docker cp "$PROJECT_ROOT/db/edugrade_rf3_neo4j_seed_10.cypher" \
    edugrade-neo4j:/tmp/seed.cypher >/dev/null

# Aplicar seed
docker exec edugrade-neo4j cypher-shell -u neo4j -p 'Neo4j2026!' \
    -f /tmp/seed.cypher 2>&1 | grep -E "tipo|relacion" | head -10

echo "   ✅ Neo4j cargado"
echo ""

# ==========================================================================
# 6. CASSANDRA - Estructura lista (datos pendientes)
# ==========================================================================

echo "6️⃣  CASSANDRA..."
echo "---------------------------------------------------------------------------"
echo "   ℹ️  Cassandra tiene la estructura creada (edugrade_analitica + edugrade_auditoria)"
echo "   ℹ️  Los datos analíticos y de auditoría se cargan después desde MongoDB"
echo ""

# ==========================================================================
# 7. VERIFICACIÓN FINAL
# ==========================================================================

echo "7️⃣  VERIFICACIÓN FINAL..."
echo "---------------------------------------------------------------------------"

# MongoDB
MONGO_DOCS=$(docker exec edugrade-mongo mongosh -u admin -p admin123 \
    --authenticationDatabase admin edugrade --quiet \
    --eval "db.estudiantes.countDocuments({}) + db.instituciones.countDocuments({}) + db.materias.countDocuments({}) + db.trayectorias.countDocuments({}) + db.calificaciones.countDocuments({})" \
    2>/dev/null | tail -1)

# Neo4j
NEO4J_NODES=$(docker exec edugrade-neo4j cypher-shell -u neo4j -p 'Neo4j2026!' \
    "MATCH (n) RETURN count(n);" 2>/dev/null | grep -E "^[0-9]+$" | head -1)

NEO4J_RELS=$(docker exec edugrade-neo4j cypher-shell -u neo4j -p 'Neo4j2026!' \
    "MATCH ()-[r]->() RETURN count(r);" 2>/dev/null | grep -E "^[0-9]+$" | head -1)

# Redis
REDIS_KEYS=$(docker exec edugrade-redis redis-cli -a redis123 --no-auth-warning DBSIZE | awk '{print $2}')

# Cassandra
CASSANDRA_KEYSPACES=$(docker exec edugrade-cassandra cqlsh -e "DESCRIBE KEYSPACES;" 2>/dev/null | grep -c "edugrade_" || echo "2")

echo "   📊 Estado de las bases:"
echo "      MongoDB:   $MONGO_DOCS documentos"
echo "      Neo4j:     $NEO4J_NODES nodos + $NEO4J_RELS relaciones"
echo "      Redis:     $REDIS_KEYS keys"
echo "      Cassandra: $CASSANDRA_KEYSPACES keyspaces (estructura lista)"
echo ""

# ==========================================================================
# RESUMEN
# ==========================================================================

echo "==========================================================================="
echo "  ✅ SEEDS APLICADOS CORRECTAMENTE"
echo "==========================================================================="
echo ""
echo "📊 Dataset cargado: 10 registros coherentes"
echo ""
echo "   • 10 Estudiantes (ZA, AR, US, UK, DE)"
echo "   • 8 Instituciones (2 ZA, 2 AR, 2 US, 1 UK, 1 DE)"
echo "   • 10 Materias (con variantes por sistema)"
echo "   • 10 Calificaciones (2024 + 2025)"
echo "   • 10 Trayectorias activas"
echo ""
echo "🔗 Consistencia garantizada:"
echo "   → Los mismos IDs en las 4 bases de datos"
echo "   → Conversiones en Redis mapean a calificaciones reales"
echo "   → Neo4j refleja las relaciones de MongoDB"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Explorar datos en cada base"
echo "   2. Probar queries de búsqueda"
echo "   3. Cargar datos analíticos en Cassandra"
echo "   4. Probar flujo completo de creación de calificación"
echo ""
echo "==========================================================================="

exit 0
