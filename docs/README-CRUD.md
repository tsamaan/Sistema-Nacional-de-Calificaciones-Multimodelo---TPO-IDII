# CRUD Multimodelo - EduGrade Global

Sistema CRUD completo que integra **4 bases de datos** para gestión de calificaciones académicas internacionales.

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    crud_multimodelo.py                       │
│              (Clase MultiModelCRUD única)                    │
└─────────────────────────────────────────────────────────────┘
         │              │              │              │
         ▼              ▼              ▼              ▼
    ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐
    │ MongoDB│    │ Neo4j  │    │ Redis  │    │Cassandra│
    │ Puerto │    │ Puerto │    │ Puerto │    │ Puerto │
    │  27017 │    │  7687  │    │  6379  │    │  9042  │
    └────────┘    └────────┘    └────────┘    └────────┘
        │              │              │              │
        ▼              ▼              ▼              ▼
   Fuente de      Grafo de       Cache de      Auditoría
     Verdad       Relaciones    Conversiones    y Logs
```

## 📋 Funcionalidades

### 🔵 MongoDB - Fuente de Verdad
- **CREATE**: Insertar calificaciones completas
- **READ**: Consultar por ID o estudiante
- **UPDATE**: Actualizar con versionado
- **DELETE**: Soft delete (marcado)
- **Persistencia**: Todas las conversiones se guardan en array `conversiones`

### 🔴 Neo4j - Grafo Académico
- **Nodos**: Student, Institution, Subject, GradeRecord
- **Relaciones**: HAS_RECORD, FOR_SUBJECT, AT_INSTITUTION, ATTENDED
- **Sincronización**: Automática al crear/actualizar calificaciones
- **Consultas**: Trayectorias, equivalencias, prerequisitos

### 🟠 Redis - Cache de Conversiones
- **Pattern**: `conv:{record_id}:{sistema}:1`
- **TTL**: 24 horas
- **Reglas**: `regla:{from}#{to}:MINISTERIO:SECUNDARIO:2025:{version}`
- **Invalidación**: Automática al actualizar calificaciones

### 🟢 Cassandra - Auditoría
- **Keyspace**: `edugrade_auditoria`
- **Tabla**: `registro_auditoria_por_entidad_mes`
- **Eventos**: GRADE_CREATED, GRADE_UPDATED, SYSTEM_CONVERSION, GRADE_DELETED
- **Consulta**: Por entidad + mes (YYYYMM)

## 🚀 Instalación

### 1. Instalar dependencias

```bash
pip install -r requirements-crud.txt
```

### 2. Levantar bases de datos

```bash
cd docker
docker-compose up -d

# Verificar que estén corriendo
docker ps
```

### 3. Cargar datos de prueba (opcional)

```bash
cd ../carga
python seed_edugrade.py
```

## 📖 Uso Básico

### Importar y conectar

```python
from crud_multimodelo import MultiModelCRUD

# Inicializar (conecta a las 4 bases)
crud = MultiModelCRUD()
```

### CREATE - Crear calificación

```python
nueva_calificacion = {
    'student_id': 'STU-0100',
    'zone': 'ZA-CPT',
    'student_snapshot': {
        'full_name': 'María González',
        'dob': '2005-03-15T00:00:00.000Z',
        'nationality': 'AR'
    },
    'institution_snapshot': {
        'institution_id': 'INS-AR-001',
        'name': 'Universidad de Buenos Aires',
        'country': 'AR',
        'region': 'BA'
    },
    'academic_context': {
        'academic_year': 2026,
        'term': 'T1',
        'level': 'post_secondary',
        'cycle': 'University'
    },
    'subject_snapshot': {
        'subject_id': 'SUB-MATH-101',
        'name': 'Matemática I',
        'course_code': 'MAT-101'
    },
    'evaluation': {
        'type': 'final',
        'date': '2026-02-15T10:00:00.000Z',
        'components': [
            {
                'component_type': 'exam',
                'weight': 1.0,
                'raw': {'grade': 8}
            }
        ]
    },
    'original_grade': {
        'system': 'AR',
        'scale_type': 'numeric',
        'value': 8,
        'passed': True,
        'details': {
            'qualification': 'Aprobado'
        }
    },
    'evidence': [],
    'actor': 'profesor_matematica'
}

# Crear (sincroniza en 4 bases automáticamente)
record_id = crud.crear_calificacion(nueva_calificacion)
print(f"✅ Creada: {record_id}")
```

### READ - Consultar calificación

```python
# Por ID
calificacion = crud.obtener_calificacion('GR-2025-0002')

# Historial de estudiante
historial = crud.obtener_historial_estudiante('STU-0001')

# Grafo académico
grafo = crud.consultar_relaciones_neo4j('STU-0001')

# Logs de auditoría
logs = crud.consultar_logs_auditoria('GR-2025-0002', '202602')
```

### UPDATE - Actualizar calificación

```python
# Actualizar (versiona + log + invalida cache)
crud.actualizar_calificacion(
    record_id='GR-2025-0002',
    updates={
        'original_grade.value': 9,
        'original_grade.details.corrected': True
    },
    actor='profesor_coordinador'
)
```

### DELETE - Eliminar (soft delete)

```python
# Soft delete: marca como eliminado, no borra físicamente
crud.eliminar_calificacion(
    record_id='GR-2025-0002',
    actor='admin'
)
```

### CONVERTIR - Cambio de sistema (UK → AR → ZA7)

```python
# Conversión con flujo completo:
# 1. Verifica cache Redis
# 2. Si no existe, calcula con regla
# 3. Cachea en Redis (24h)
# 4. Persiste en MongoDB (array conversiones)
# 5. Log en Cassandra (SYSTEM_CONVERSION)

conversion = crud.convertir_calificacion(
    record_id='GR-2025-0002',
    sistema_destino='ZA7',
    actor='sistema_conversiones',
    force_recalc=False  # True para ignorar cache
)

print(f"UK 'A' → ZA7 {conversion['valor_convertido']}")
```

## 🔄 Flujo de Conversión Completo

Cuando llamas a `convertir_calificacion()` sucede esto:

```
1. 📖 Obtener calificación original desde MongoDB
   └─> sistema_origen: UK, valor: A

2. 🔍 Buscar en cache Redis
   └─> Key: conv:GR-2025-0002:ZA7:1
   └─> Si existe: devolver (cache hit)
   └─> Si no existe: continuar...

3. 📏 Obtener regla de conversión activa
   └─> regla_activa:UK#ZA7:MINISTERIO:SECUNDARIO:2025 → "1"
   └─> regla:UK#ZA7:MINISTERIO:SECUNDARIO:2025:1 → {mapping...}

4. 🔄 Aplicar conversión
   └─> Según mapping: UK 'A' = 6 en ZA7

5. 💾 Cachear en Redis (TTL: 24h)
   └─> SET conv:GR-2025-0002:ZA7:1 = {resultado...} EX 86400

6. 📝 Persistir en MongoDB
   └─> PUSH al array "conversiones": {to: ZA7, valor: 6, ...}

7. 📋 Log en Cassandra
   └─> INSERT INTO edugrade_auditoria.registro_auditoria_por_entidad_mes
   └─> Acción: SYSTEM_CONVERSION
   └─> Carga útil: {from: UK, to: ZA7, original: A, converted: 6}

8. ✅ Retornar resultado
   └─> {sistema_origen: UK, valor_original: A, sistema_destino: ZA7, valor_convertido: 6}
```

## 🧪 Testing

### Ejecutar tests sobre datos existentes

```bash
python test_crud.py
```

Este script ejecuta:
- **Test 1**: Consultar calificación existente
- **Test 2**: Historial de estudiante
- **Test 3**: Convertir UK → ZA7
- **Test 4**: Consultar grafo académico
- **Test 5**: Consultar auditoría
- **Test 6**: Crear nueva calificación + conversión completa

### Tests individuales

```python
from crud_multimodelo import MultiModelCRUD

crud = MultiModelCRUD()

# Test 1: Consultar existente
cal = crud.obtener_calificacion('GR-2025-0002')

# Test 2: Convertir
conv = crud.convertir_calificacion('GR-2025-0002', 'ZA7')

# Test 3: Verificar cache
cached = crud.redis_client.get('conv:GR-2025-0002:ZA7:1')

# Test 4: Ver logs
logs = crud.consultar_logs_auditoria('GR-2025-0002', '202602')

crud.close()
```

## 📊 Mapeos de Conversión

### UK → ZA7 (escala 1-7)
```
A* → 7
A  → 6
B  → 5
C  → 4
D  → 3
E  → 2
F  → 1
```

### US → ZA7
```
A → 7
B → 6
C → 5
D → 4
F → 1
```

### AR → ZA7 (escala 1-10)
```
10 → 7
9  → 6
8  → 5
7  → 4
6  → 3
5  → 2
4  → 1
1-3 → 1
```

### DE → ZA7 (escala 1.0-6.0)
```
1.0      → 7
1.5      → 6
2.0      → 5
2.5      → 4
3.0      → 3
3.5      → 2
4.0-6.0  → 1
```

## 🔧 Configuración

Variables de entorno (opcional, usa defaults si no se definen):

```bash
# MongoDB
export MONGO_URI="mongodb://admin:admin123@localhost:27017/edugrade?authSource=admin"

# Neo4j
export NEO4J_URI="bolt://localhost:7687"
export NEO4J_USER="neo4j"
export NEO4J_PASSWORD="Neo4j2026!"

# Redis
export REDIS_HOST="localhost"
export REDIS_PORT="6379"
export REDIS_PASSWORD="redis123"

# Cassandra
export CASSANDRA_HOSTS="localhost"
```

## 📐 Estructura de Datos

### MongoDB - Calificación completa

```json
{
  "record_id": "GR-2025-0002",
  "student_id": "STU-0001",
  "zone": "ZA-CPT",
  "student_snapshot": { ... },
  "institution_snapshot": { ... },
  "academic_context": { ... },
  "subject_snapshot": { ... },
  "evaluation": { ... },
  "original_grade": {
    "system": "UK",
    "scale_type": "letter",
    "value": "A",
    "passed": true
  },
  "immutability": {
    "created_at": "2026-02-19T...",
    "immutable_id": "IMM-...",
    "integrity_hash_sha256": "abc123..."
  },
  "history": [],
  "conversiones": [
    {
      "to": "ZA7",
      "valor": 6,
      "version_regla": "1",
      "timestamp": "2026-02-19T...",
      "actor": "sistema"
    }
  ]
}
```

### Neo4j - Nodos y relaciones

```cypher
(Student)-[:HAS_RECORD]->(GradeRecord)-[:FOR_SUBJECT]->(Subject)
(GradeRecord)-[:AT_INSTITUTION]->(Institution)
(Student)-[:ATTENDED]->(Institution)
```

### Redis - Keys

```
# Regla activa
regla_activa:UK#ZA7:MINISTERIO:SECUNDARIO:2025 = "1"

# Regla completa (HASH)
regla:UK#ZA7:MINISTERIO:SECUNDARIO:2025:1 = {
  from: UK,
  to: ZA7,
  version: 1,
  mapping: {...}
}

# Conversión cacheada (STRING con TTL)
conv:GR-2025-0002:ZA7:1 = {resultado...}  [TTL: 86400s]
```

### Cassandra - Auditoría

```sql
CREATE TABLE edugrade_auditoria.registro_auditoria_por_entidad_mes (
    id_entidad text,
    aaaamm text,
    marca_tiempo timestamp,
    tipo_entidad text,
    accion text,
    id_actor text,
    ip text,
    hash_anterior text,
    hash_nuevo text,
    carga_util text,
    PRIMARY KEY ((id_entidad, aaaamm), marca_tiempo)
) WITH CLUSTERING ORDER BY (marca_tiempo DESC);
```

## 🎯 Casos de Uso

### 1. Registrar calificación de estudiante extranjero
```python
# Estudiante UK con nota 'A' en Oxford
record_id = crud.crear_calificacion({
    'student_id': 'STU-UK-001',
    'original_grade': {'system': 'UK', 'value': 'A'},
    ...
})

# Convertir a sistema nacional ZA7
conversion = crud.convertir_calificacion(record_id, 'ZA7')
# Resultado: A → 6 en escala 1-7
```

### 2. Consultar trayectoria académica
```python
# Ver todas las calificaciones
historial = crud.obtener_historial_estudiante('STU-0001')

# Ver relaciones en grafo
grafo = crud.consultar_relaciones_neo4j('STU-0001')
# materias, instituciones, calificaciones interconectadas
```

### 3. Auditar cambios
```python
# Ver todos los eventos de febrero 2026
logs = crud.consultar_logs_auditoria('GR-2025-0002', '202602')

# Eventos registrados:
# - GRADE_CREATED
# - SYSTEM_CONVERSION (UK → ZA7)
# - GRADE_UPDATED
```

### 4. Actualizar con versionado
```python
# Actualizar nota (se versionan automáticamente)
crud.actualizar_calificacion(
    'GR-2025-0002',
    {'original_grade.value': 'A*'},
    actor='coordinador'
)

# Se registra en history[] con:
# - timestamp, actor, cambios, hash anterior
```

## 🐛 Troubleshooting

### Error de conexión a MongoDB
```bash
# Verificar que Docker esté corriendo
docker ps | grep edugrade-mongo

# Ver logs
docker logs edugrade-mongo
```

### Error de conexión a Neo4j
```bash
# Verificar contraseña en docker-compose.yml
# Debe ser: Neo4j2026!

docker exec -it edugrade-neo4j cypher-shell -u neo4j -p Neo4j2026!
```

### Cache Redis no funciona
```bash
# Verificar conexión
docker exec -it edugrade-redis redis-cli -a redis123 PING
# Debe responder: PONG

# Ver keys actuales
docker exec -it edugrade-redis redis-cli -a redis123 KEYS "conv:*"
```

### No hay reglas de conversión
```bash
# Verificar reglas en Redis
docker exec -it edugrade-redis redis-cli -a redis123 KEYS "regla:*"

# Cargar datos de prueba
cd carga && python seed_edugrade.py
```

## 📚 Documentación Relacionada

- [FLUJO-DE-DATOS.md](./FLUJO-DE-DATOS.md) - Arquitectura y flujo de datos
- [ESTRUCTURAS-BASE-DE-DATOS.md](./ESTRUCTURAS-BASE-DE-DATOS.md) - Esquemas completos
- [docker/docker-compose.yml](./docker/docker-compose.yml) - Configuración de bases de datos
- [api/README.md](./api/README.md) - API REST (si aplica)

## 🤝 Contribuir

Para agregar nuevos sistemas de calificación:

1. Agregar mapping en `_aplicar_conversion()`
2. Cargar reglas en Redis con `seed_edugrade.py`
3. Actualizar esta documentación

## 📄 Licencia

Proyecto académico - TPO IDII - UADE 2026

---

**Autor**: Sistema EduGrade Global  
**Versión**: 1.0.0  
**Fecha**: Febrero 2026
