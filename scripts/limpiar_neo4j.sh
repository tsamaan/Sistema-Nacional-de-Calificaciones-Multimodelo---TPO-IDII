#!/bin/bash

# Script para limpiar completamente la base de datos Neo4j
# Elimina todos los nodos, relaciones, constraints e índices

CONTAINER="edugrade-neo4j"
NEO4J_USER="neo4j"
NEO4J_PASS="Neo4j2026!"

echo "========================================="
echo "  LIMPIANDO NEO4J COMPLETAMENTE"
echo "========================================="

# Verificar que el contenedor está corriendo
if ! docker ps | grep -q $CONTAINER; then
    echo "❌ El contenedor $CONTAINER no está corriendo"
    echo "   Ejecuta: cd docker && docker-compose up -d neo4j"
    exit 1
fi

echo "✅ Contenedor $CONTAINER encontrado"
echo ""

# 1. Eliminar todos los nodos y relaciones
echo "🗑️  Eliminando todos los nodos y relaciones..."
docker exec $CONTAINER cypher-shell -u $NEO4J_USER -p $NEO4J_PASS \
  "MATCH (n) DETACH DELETE n;" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Nodos y relaciones eliminados"
else
    echo "⚠️  No se pudieron eliminar nodos (puede ser que ya esté vacío)"
fi

echo ""

# 2. Eliminar todos los constraints
echo "🔓 Eliminando constraints..."
CONSTRAINTS=$(docker exec $CONTAINER cypher-shell -u $NEO4J_USER -p $NEO4J_PASS \
  "SHOW CONSTRAINTS;" 2>/dev/null | grep -v "constraintType" | grep -v "^$" | awk '{print $1}')

if [ ! -z "$CONSTRAINTS" ]; then
    while IFS= read -r constraint; do
        echo "   Eliminando constraint: $constraint"
        docker exec $CONTAINER cypher-shell -u $NEO4J_USER -p $NEO4J_PASS \
          "DROP CONSTRAINT $constraint IF EXISTS;" 2>/dev/null
    done <<< "$CONSTRAINTS"
    echo "✅ Constraints eliminados"
else
    echo "✅ No hay constraints para eliminar"
fi

echo ""

# 3. Eliminar todos los índices
echo "📇 Eliminando índices..."
INDEXES=$(docker exec $CONTAINER cypher-shell -u $NEO4J_USER -p $NEO4J_PASS \
  "SHOW INDEXES;" 2>/dev/null | grep -v "indexType" | grep -v "^$" | awk '{print $1}')

if [ ! -z "$INDEXES" ]; then
    while IFS= read -r index; do
        echo "   Eliminando índice: $index"
        docker exec $CONTAINER cypher-shell -u $NEO4J_USER -p $NEO4J_PASS \
          "DROP INDEX $index IF EXISTS;" 2>/dev/null
    done <<< "$INDEXES"
    echo "✅ Índices eliminados"
else
    echo "✅ No hay índices para eliminar"
fi

echo ""

# 4. Verificar que quedó vacío
echo "🔍 Verificando limpieza..."
NODE_COUNT=$(docker exec $CONTAINER cypher-shell -u $NEO4J_USER -p $NEO4J_PASS \
  "MATCH (n) RETURN count(n) AS total;" 2>/dev/null | grep -E "^[0-9]+$" | head -1)

REL_COUNT=$(docker exec $CONTAINER cypher-shell -u $NEO4J_USER -p $NEO4J_PASS \
  "MATCH ()-[r]->() RETURN count(r) AS total;" 2>/dev/null | grep -E "^[0-9]+$" | head -1)

echo ""
echo "========================================="
echo "  RESULTADOS"
echo "========================================="
echo "Nodos restantes:     $NODE_COUNT"
echo "Relaciones restantes: $REL_COUNT"
echo ""

if [ "$NODE_COUNT" -eq 0 ] && [ "$REL_COUNT" -eq 0 ]; then
    echo "✅ Neo4j limpiado exitosamente"
    echo "   La base está vacía y lista para cargar datos nuevos"
else
    echo "⚠️  Aún quedan elementos en la base"
    echo "   Puedes volver a ejecutar este script"
fi

echo "========================================="
