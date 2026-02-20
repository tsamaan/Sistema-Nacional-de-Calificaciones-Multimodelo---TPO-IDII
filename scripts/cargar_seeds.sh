#!/bin/bash

# ==========================================================================
# SCRIPT: Cargar seeds en todas las bases de datos
# Sistema EduGrade Multimodelo - 10 registros coherentes
# ==========================================================================

# Función para confirmar acción
confirmar() {
  local db_name=$1
  read -p "¿Cargar datos en $db_name? (s/n): " respuesta
  case "$respuesta" in
    [sS]|[sS][iI])
      return 0
      ;;
    *)
      echo "   ⏭️  Saltando $db_name"
      return 1
      ;;
  esac
}

# Obtener directorio del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DB_DIR="$PROJECT_ROOT/db"

echo "==========================================================================="
echo " CARGANDO SEEDS - EDUGRADE MULTIMODELO"
echo "==========================================================================="
echo ""
echo "📂 Directorio proyecto: $PROJECT_ROOT"
echo "📂 Directorio seeds: $DB_DIR"
echo ""

# Verificar que existan los archivos seed
echo "🔍 Verificando archivos seed..."
echo "---------------------------------------------------------------------------"

SEED_FILES=(
  "$DB_DIR/edugrade_rf1_seed_10.json"
  "$DB_DIR/edugrade_rf2_redis_seed_10.resp"
  "$DB_DIR/edugrade_rf3_neo4j_seed_10.cypher"
  "$DB_DIR/edugrade_rf4_rf5_cassandra_seed_10.cql"
)

ALL_EXISTS=true
for file in "${SEED_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "   ✅ $(basename "$file")"
  else
    echo "   ❌ No encontrado: $file"
    ALL_EXISTS=false
  fi
done

echo ""

if [ "$ALL_EXISTS" = false ]; then
  echo "❌ No se encontraron todos los archivos seed necesarios."
  exit 1
fi

# ==========================================================================
# 1. MONGODB
# ==========================================================================

echo "1️⃣  MONGODB"
echo "---------------------------------------------------------------------------"
if confirmar "MongoDB"; then
  echo "   📥 Cargando edugrade_rf1_seed_10.json..."
  
  # Copiar el seed al contenedor
  docker cp "$DB_DIR/edugrade_rf1_seed_10.json" edugrade-mongo:/tmp/seed.json 2>/dev/null
  
  # Cargar usando mongosh con script inline
  docker exec edugrade-mongo mongosh edugrade -u admin -p admin123 \
    --authenticationDatabase admin --quiet --eval "
    // Leer el archivo JSON
    const fs = require('fs');
    const seedData = JSON.parse(fs.readFileSync('/tmp/seed.json', 'utf8'));
    const collections = seedData.collections;
    
    // Colecciones a procesar
    const collectionNames = ['estudiantes', 'instituciones', 'materias', 'trayectorias', 'calificaciones'];
    
    let totalDocs = 0;
    
    collectionNames.forEach(colName => {
      if (collections[colName]) {
        // Limpiar colección
        db[colName].deleteMany({});
        
        // Insertar documentos
        const docs = collections[colName];
        if (docs.length > 0) {
          db[colName].insertMany(docs);
          totalDocs += docs.length;
          print('✓ ' + colName + ': ' + docs.length + ' docs');
        }
      }
    });
    
    print('Total: ' + totalDocs + ' documentos insertados');
  " 2>&1 | grep -E "(✓|Total)"
  
  echo "   ✅ MongoDB cargado"
else
  echo ""
fi

# ==========================================================================
# 2. REDIS
# ==========================================================================

echo ""
echo "2️⃣  REDIS"
echo "---------------------------------------------------------------------------"
if confirmar "Redis"; then
  echo "   📥 Cargando edugrade_rf2_redis_seed_10.resp..."
  
  cat "$DB_DIR/edugrade_rf2_redis_seed_10.resp" | \
    grep -v "^#" | grep -v "^$" | \
    docker exec -i edugrade-redis redis-cli -a redis123 --pipe 2>&1 | \
    grep -E "(errors|replies)" || true
  
  # Verificar keys cargadas
  KEYS_COUNT=$(docker exec edugrade-redis redis-cli -a redis123 --no-auth-warning DBSIZE | awk '{print $2}')
  echo "   ✅ Redis cargado ($KEYS_COUNT keys)"
else
  echo ""
fi

# ==========================================================================
# 3. NEO4J
# ==========================================================================

echo ""
echo "3️⃣  NEO4J"
echo "---------------------------------------------------------------------------"
if confirmar "Neo4j"; then
  echo "   📥 Cargando edugrade_rf3_neo4j_seed_10.cypher..."
  
  # Copiar seed al contenedor
  docker cp "$DB_DIR/edugrade_rf3_neo4j_seed_10.cypher" \
    edugrade-neo4j:/tmp/seed.cypher 2>/dev/null
  
  # Aplicar seed usando cypher-shell
  docker exec edugrade-neo4j cypher-shell -u neo4j -p 'Neo4j2026!' \
    --file /tmp/seed.cypher 2>&1 | \
    grep -E "(Added|Set|Created)" | head -5 || true
  
  # Contar nodos
  NODES=$(docker exec edugrade-neo4j cypher-shell -u neo4j -p 'Neo4j2026!' \
    "MATCH (n) RETURN count(n) as total" --format plain 2>/dev/null | \
    tail -1 | awk '{print $1}')
  
  echo "   ✅ Neo4j cargado ($NODES nodos)"
else
  echo ""
fi

# ==========================================================================
# 4. CASSANDRA
# ==========================================================================

echo ""
echo "4️⃣  CASSANDRA"
echo "---------------------------------------------------------------------------"
if confirmar "Cassandra"; then
  echo "   📥 Cargando edugrade_rf4_rf5_cassandra_seed_10.cql..."
  
  # Esperar a que Cassandra esté listo
  echo "   ⏳ Verificando conexión con Cassandra..."
  docker exec edugrade-cassandra cqlsh -u cassandra -p cassandra \
    -e "DESCRIBE KEYSPACES;" >/dev/null 2>&1
  
  if [ $? -eq 0 ]; then
    # Copiar seed al contenedor
    docker cp "$DB_DIR/edugrade_rf4_rf5_cassandra_seed_10.cql" \
      edugrade-cassandra:/tmp/seed.cql 2>/dev/null
    
    # Ejecutar seed
    echo "   📊 Cargando datos en Cassandra (puede tomar unos segundos)..."
    docker exec edugrade-cassandra cqlsh -u cassandra -p cassandra \
      --file /tmp/seed.cql 2>&1 | \
      grep -E "(Truncate|rows)" | head -3 || true
    
    echo "   ✅ Cassandra cargado"
  else
    echo "   ⚠️  Cassandra no está disponible, saltando..."
  fi
else
  echo ""
fi

# ==========================================================================
# VERIFICACIÓN FINAL
# ==========================================================================

echo ""
echo "==========================================================================="
echo " VERIFICACIÓN DE CARGA"
echo "==========================================================================="
echo ""

# MongoDB
MONGO_COUNT=$(docker exec edugrade-mongo mongosh edugrade -u admin -p admin123 \
  --authenticationDatabase admin --quiet --eval "
  const total = db.estudiantes.countDocuments({}) +
                db.instituciones.countDocuments({}) +
                db.materias.countDocuments({}) +
                db.trayectorias.countDocuments({}) +
                db.calificaciones.countDocuments({});
  print(total);
" 2>/dev/null | tail -1)

# Redis
REDIS_COUNT=$(docker exec edugrade-redis redis-cli -a redis123 --no-auth-warning DBSIZE 2>/dev/null | awk '{print $2}')

# Neo4j
NEO4J_COUNT=$(docker exec edugrade-neo4j cypher-shell -u neo4j -p 'Neo4j2026!' \
  "MATCH (n) RETURN count(n) as total" --format plain 2>/dev/null | \
  tail -1 | awk '{print $1}')

# Cassandra
CASSANDRA_COUNT=$(docker exec edugrade-cassandra cqlsh -u cassandra -p cassandra \
  -e "SELECT COUNT(*) FROM edugrade_analitica.rf4_fact_grades_by_region_year_system;" 2>/dev/null | \
  grep -E "^\s*[0-9]+" | awk '{print $1}')

echo "📊 Estado de las bases de datos:"
echo "   MongoDB:   ${MONGO_COUNT:-0} documentos"
echo "   Redis:     ${REDIS_COUNT:-0} keys"
echo "   Neo4j:     ${NEO4J_COUNT:-0} nodos"
echo "   Cassandra: ${CASSANDRA_COUNT:-0} registros (fact table)"
echo ""

echo "==========================================================================="
echo " ✅ CARGA COMPLETADA"
echo "==========================================================================="
echo ""
echo "💡 Tip: Usa las APIs REST para verificar que los datos se cargaron correctamente"
echo ""
