#!/bin/bash

echo "======================================================================"
echo " LIMPIANDO TODAS LAS BASES DE DATOS"
echo "======================================================================"

echo ""
echo "1️⃣  MONGODB"
echo "----------------------------------------------------------------------"
docker exec edugrade-mongo mongosh edugrade -u admin -p admin123 --authenticationDatabase admin --quiet --eval "
print('Calificaciones:', db.calificaciones.deleteMany({}).deletedCount);
print('Estudiantes:', db.estudiantes.deleteMany({}).deletedCount);
print('Instituciones:', db.instituciones.deleteMany({}).deletedCount);
print('Materias:', db.materias.deleteMany({}).deletedCount);
print('Trayectorias:', db.trayectorias.deleteMany({}).deletedCount);
"

echo ""
echo "2️⃣  REDIS"
echo "----------------------------------------------------------------------"
docker exec edugrade-redis redis-cli -a redis123 --no-auth-warning FLUSHALL
echo "   ✅ Redis limpio"

echo ""
echo "3️⃣  NEO4J"
echo "----------------------------------------------------------------------"
docker exec edugrade-neo4j bash -c 'echo "MATCH (n) DETACH DELETE n;" | cypher-shell -u neo4j -p "Neo4j2026!"' 2>&1 | grep -v "^$"
echo "   ✅ Neo4j limpio"

echo ""
echo "4️⃣  CASSANDRA"
echo "----------------------------------------------------------------------"
docker exec edugrade-cassandra cqlsh -u cassandra -p cassandra -e "TRUNCATE edugrade_analitica.promedio_por_region_anio;" 2>&1 | grep -v "^$" || echo "   ✅ promedio_por_region_anio truncada"
docker exec edugrade-cassandra cqlsh -u cassandra -p cassandra -e "TRUNCATE edugrade.rf4_fact_grades_by_region_year_system;" 2>&1 | grep -v "^$" || echo "   ✅ rf4_fact_grades_by_region_year_system truncada"
docker exec edugrade-cassandra cqlsh -u cassandra -p cassandra -e "TRUNCATE edugrade_auditoria.registro_auditoria_por_entidad_mes;" 2>&1 | grep -v "^$" || echo "   ✅ registro_auditoria_por_entidad_mes truncada"
docker exec edugrade-cassandra cqlsh -u cassandra -p cassandra -e "TRUNCATE edugrade_auditoria.rf5_audit_timeline_by_entity_month;" 2>&1 | grep -v "^$" || echo "   ✅ rf5_audit_timeline_by_entity_month truncada"

echo ""
echo "======================================================================"
echo " ✅ LIMPIEZA COMPLETA"
echo "======================================================================"
