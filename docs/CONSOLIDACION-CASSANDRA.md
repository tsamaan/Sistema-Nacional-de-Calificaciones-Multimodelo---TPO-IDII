# 🔄 Consolidación de Cassandra - Guía de Aplicación

## 📋 Cambios Realizados

### ✅ Estructura Anterior (3 keyspaces)
```
❌ edugrade                  → Tablas rf4_* y rf5_* (SIN USO en la API)
⚠️  edugrade_analitica       → Solo promedio_por_region_anio (sin fact tables)
✅ edugrade_auditoria        → registro_auditoria_por_entidad_mes
```

### ✅ Estructura Nueva (2 keyspaces)
```
✅ edugrade_analitica        → RF4 (Analítica completa)
   ├── rf4_fact_grades_by_region_year_system     (fact table dimensional)
   ├── rf4_report_by_region_year_system          (agregados por sistema)
   ├── rf4_report_by_region_year                 (agregados cross-system)
   └── promedio_por_region_anio                  (agregados simplificados)

✅ edugrade_auditoria        → RF5 (Auditoría)
   └── registro_auditoria_por_entidad_mes        (timeline inmutable)
```

---

## 🚀 Cómo Aplicar la Consolidación

### Paso 1: Detener servicios
```bash
cd docker
docker-compose down
```

### Paso 2: Eliminar volúmenes de Cassandra (opcional, para limpieza completa)
```bash
docker volume ls | grep cassandra
docker volume rm <nombre_del_volumen>
```

### Paso 3: Levantar servicios
```bash
docker-compose up -d
```

### Paso 4: Esperar que Cassandra esté listo (~30 segundos)
```bash
docker-compose logs -f cassandra
# Esperar mensaje: "Starting listening for CQL clients..."
```

### Paso 5: Aplicar el seed consolidado
```bash
# Desde el directorio raíz del proyecto
docker exec -it cassandra cqlsh -f /tmp/cassandra_seed_consolidado.cql
```

O manualmente:
```bash
docker exec -it cassandra cqlsh

# Luego copiar y pegar el contenido del archivo db/cassandra_seed_consolidado.cql
```

### Paso 6: Verificar la estructura
```bash
docker exec -it cassandra cqlsh

# Verificar keyspaces
DESCRIBE KEYSPACES;
# Debería mostrar solo: edugrade_analitica y edugrade_auditoria

# Verificar tablas RF4
USE edugrade_analitica;
DESCRIBE TABLES;
# Debería mostrar: promedio_por_region_anio, rf4_fact_grades_by_region_year_system, 
#                  rf4_report_by_region_year, rf4_report_by_region_year_system

# Verificar tablas RF5
USE edugrade_auditoria;
DESCRIBE TABLES;
# Debería mostrar: registro_auditoria_por_entidad_mes

# Contar registros
SELECT COUNT(*) FROM edugrade_analitica.rf4_fact_grades_by_region_year_system;
# Debería retornar: 20

SELECT COUNT(*) FROM edugrade_analitica.promedio_por_region_anio;
# Debería retornar: 6

SELECT COUNT(*) FROM edugrade_auditoria.registro_auditoria_por_entidad_mes;
# Debería retornar: 10
```

### Paso 7: Cargar datos completos con el script MVP
```bash
# Desde el directorio raíz
python3 cargar_mvp.py
```

Esto cargará:
- MongoDB: estudiantes, instituciones, materias, calificaciones, trayectorias
- Neo4j: nodos y relaciones
- **Cassandra RF4**: fact tables + agregados (NUEVO)
- **Cassandra RF5**: logs de auditoría

---

## 🔍 Nuevos Endpoints de la API

### RF4 - Analítica

#### 1. Promedios por región/año (existente, mejorado)
```bash
GET /api/cassandra/analitica/promedio?region=ZA-PTA&anio=2023&sistema=UK
```

#### 2. Fact Table (NUEVO)
```bash
GET /api/cassandra/analitica/facts?region=ZA-PTA&anio=2023&sistema=UK
```
Retorna calificaciones individuales con toda la información dimensional.

#### 3. Reportes Agregados por Sistema (NUEVO)
```bash
GET /api/cassandra/analitica/reportes?region=ZA-PTA&anio=2023&sistema=UK
```
Retorna estadísticas agregadas (promedio, min, max, tasa de aprobación) por institución/materia.

#### 4. Comparación Cross-System (NUEVO)
```bash
GET /api/cassandra/analitica/cross-system?region=ZA-PTA&anio=2023
```
Compara métricas de todos los sistemas educativos en una región/año específico.

#### 5. Keys de Analítica (existente)
```bash
GET /api/cassandra/analitica/keys?region=ZA-PTA&anio=2023
```

### RF5 - Auditoría (sin cambios)

#### Eventos de Auditoría
```bash
GET /api/cassandra/auditoria?id_entidad=NOTE#GR-2025-0001&aaaamm=202602
```

---

## 📊 Ejemplos de Consultas CQL

### Consulta 1: Ver todas las calificaciones de UK en ZA-PTA (2023)
```sql
USE edugrade_analitica;

SELECT * FROM rf4_fact_grades_by_region_year_system
WHERE region = 'ZA-PTA' 
  AND academic_year = 2023 
  AND system = 'UK';
```

### Consulta 2: Ver agregados de todas las instituciones en una región
```sql
SELECT * FROM rf4_report_by_region_year_system
WHERE region = 'ZA-PTA' 
  AND academic_year = 2023 
  AND system = 'UK';
```

### Consulta 3: Comparar sistemas educativos en una región
```sql
SELECT system, institution_id, subject_id, avg_norm_0_100, pass_rate
FROM rf4_report_by_region_year
WHERE region = 'ZA-BFN' 
  AND academic_year = 2023;
```

### Consulta 4: Auditoría de una calificación específica
```sql
USE edugrade_auditoria;

SELECT marca_tiempo, accion, id_actor, hash_nuevo
FROM registro_auditoria_por_entidad_mes
WHERE id_entidad = 'NOTE#GR-2025-0001' 
  AND aaaamm = '202602'
ORDER BY marca_tiempo DESC;
```

---

## 🧪 Testing

### Test 1: Verificar que los keyspaces antiguos no existen
```bash
docker exec -it cassandra cqlsh -e "DESCRIBE KEYSPACE edugrade"
# Debería retornar error: "Keyspace 'edugrade' does not exist"
```

### Test 2: Probar endpoint de facts
```bash
curl "http://localhost:3000/api/cassandra/analitica/facts?region=ZA-PTA&anio=2023&sistema=UK"
```

### Test 3: Probar endpoint cross-system
```bash
curl "http://localhost:3000/api/cassandra/analitica/cross-system?region=ZA-PTA&anio=2023"
```

---

## 📁 Archivos Modificados

1. **`db/cassandra_seed_consolidado.cql`** (NUEVO)
   - Seed completo con DROP de keyspaces antiguos
   - Crea 2 keyspaces limpios
   - 4 tablas en `edugrade_analitica`
   - 1 tabla en `edugrade_auditoria`
   - Estructura vacía lista para carga de datos

2. **`api/routes/cassandra.js`** (ACTUALIZADO)
   - 3 endpoints nuevos para RF4
   - Mantiene endpoints existentes
   - Total: 6 endpoints

3. **`cargar_mvp.py`** (ACTUALIZADO)
   - Conecta a ambos keyspaces
   - Carga fact tables en RF4
   - Calcula y carga agregados
   - Mantiene carga de auditoría en RF5

---

## 🔄 Rollback (si algo sale mal)

Si necesitas volver a la estructura anterior:

1. Usar el archivo original:
   ```bash
   docker exec -it cassandra cqlsh -f /tmp/edugrade_rf4_rf5_cassandra_seed_20.cql
   ```

2. Revertir cambios en la API y cargar_mvp.py usando git:
   ```bash
   git checkout api/routes/cassandra.js
   git checkout cargar_mvp.py
   ```

---

## ✅ Checklist de Verificación

- [ ] Keyspace `edugrade` eliminado
- [ ] Keyspace `edugrade_analitica` con 4 tablas
- [ ] Keyspace `edugrade_auditoria` con 1 tabla
- [ ] API responde en endpoint `/api/cassandra/analitica/facts`
- [ ] API responde en endpoint `/api/cassandra/analitica/reportes`
- [ ] API responde en endpoint `/api/cassandra/analitica/cross-system`
- [ ] Script `cargar_mvp.py` ejecuta sin errores
- [ ] Datos visibles en DBeaver en ambos keyspaces

---

**Fecha:** 20 de febrero de 2026  
**Versión:** 2.0 Consolidado
