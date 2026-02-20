#!/bin/bash

# Función para confirmar acción
confirmar() {
  local db_name=$1
  read -p "¿Limpiar $db_name? (s/n): " respuesta
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

echo "======================================================================"
echo " LIMPIANDO TODAS LAS BASES DE DATOS"
echo "======================================================================"

echo ""
echo "1️⃣  MONGODB"
echo "----------------------------------------------------------------------"
if confirmar "MongoDB"; then
  docker exec edugrade-mongo mongosh edugrade -u admin -p admin123 --authenticationDatabase admin --quiet --eval "
  print('Calificaciones:', db.calificaciones.deleteMany({}).deletedCount);
  print('Estudiantes:', db.estudiantes.deleteMany({}).deletedCount);
  print('Instituciones:', db.instituciones.deleteMany({}).deletedCount);
  print('Materias:', db.materias.deleteMany({}).deletedCount);
  print('Trayectorias:', db.trayectorias.deleteMany({}).deletedCount);
  "
  echo "   ✅ MongoDB limpio"
fi

echo ""
echo "2️⃣  REDIS"
echo "----------------------------------------------------------------------"
if confirmar "Redis"; then
  docker exec edugrade-redis redis-cli -a redis123 --no-auth-warning FLUSHALL
  echo "   ✅ Redis limpio"
fi

echo ""
echo "3️⃣  NEO4J"
echo "----------------------------------------------------------------------"
if confirmar "Neo4j"; then
  docker exec edugrade-neo4j bash -c 'echo "MATCH (n) DETACH DELETE n;" | cypher-shell -u neo4j -p "Neo4j2026!"' 2>&1 | grep -v "^$"
  echo "   ✅ Neo4j limpio"
fi

echo ""
echo "4️⃣  CASSANDRA"
echo "----------------------------------------------------------------------"
if confirmar "Cassandra"; then
  docker exec edugrade-cassandra cqlsh -u cassandra -p cassandra -e "TRUNCATE edugrade_analitica.promedio_por_region_anio;" 2>&1 | grep -v "^$" || echo "   ✅ promedio_por_region_anio truncada"
  docker exec edugrade-cassandra cqlsh -u cassandra -p cassandra -e "TRUNCATE edugrade.rf4_fact_grades_by_region_year_system;" 2>&1 | grep -v "^$" || echo "   ✅ rf4_fact_grades_by_region_year_system truncada"
  docker exec edugrade-cassandra cqlsh -u cassandra -p cassandra -e "TRUNCATE edugrade_auditoria.registro_auditoria_por_entidad_mes;" 2>&1 | grep -v "^$" || echo "   ✅ registro_auditoria_por_entidad_mes truncada"
  docker exec edugrade-cassandra cqlsh -u cassandra -p cassandra -e "TRUNCATE edugrade_auditoria.rf5_audit_timeline_by_entity_month;" 2>&1 | grep -v "^$" || echo "   ✅ rf5_audit_timeline_by_entity_month truncada"
  echo "   ✅ Cassandra limpio"
fi

echo ""
echo "======================================================================"
echo " ✅ LIMPIEZA COMPLETA"
echo "======================================================================"
