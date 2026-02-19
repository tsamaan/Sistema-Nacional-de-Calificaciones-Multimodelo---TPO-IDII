# EduGrade Global - API REST

API REST para consultar el Sistema Nacional de Calificaciones Multimodelo.

## 🚀 Inicio Rápido

### 1. Instalar dependencias

```bash
cd api
npm install
```

### 2. Configurar variables de entorno

El archivo `.env` ya está configurado con las credenciales de Docker.

### 3. Iniciar la API

```bash
npm start
```

O con auto-reload en desarrollo:

```bash
npm run dev  # Requiere instalar nodemon
```

La API estará disponible en: **http://localhost:3000**

## 📡 Endpoints Disponibles

### MongoDB (RF1) - Calificaciones Base

- **GET** `/api/mongodb/estudiante/:id/ficha-completa`
  - Obtener historial completo de un estudiante
  - Ejemplo: `/api/mongodb/estudiante/STU-0006/ficha-completa`

- **GET** `/api/mongodb/buscar-por-metadata`
  - Filtrar por metadatos locales
  - Ejemplos:
    - `?pais=AR&tipo=recuperacion`
    - `?pais=UK&board=IEB`

### Redis (RF2) - Reglas de Conversión

- **GET** `/api/redis/regla-activa?from=UK&to=US`
  - Obtener regla de conversión activa (latencia < 1ms)

- **GET** `/api/redis/regla-por-fecha?from=UK&to=US&org=MINEDU_ZA&fecha=2025-06-15`
  - Validar versión de regla según fecha

### Neo4j (RF3) - Grafos de Relaciones

- **GET** `/api/neo4j/camino-equivalencias?estudianteId=STU-0001&paisOrigen=UK&paisDestino=ZA`
  - Encontrar camino de equivalencias entre países

- **GET** `/api/neo4j/analisis-impacto?materiaId=SUB-MATH`
  - Analizar impacto de cambios en materias troncales

### Cassandra (RF4/RF5) - Reportes y Auditoría

- **GET** `/api/cassandra/reporte-regional?region=ZA-PTA&year=2025`
  - Reporte regional por año

- **GET** `/api/cassandra/auditoria-nota?recordId=GR-2025-0001&mes=2026-02`
  - Trazabilidad de auditoría por nota

## 📮 Usar con Postman

### Importar la colección

1. Abrir Postman
2. Click en **Import**
3. Seleccionar el archivo: `../postman/EduGrade-Multimodelo.postman_collection.json`
4. La colección incluye todas las consultas pre-configuradas

### Variable de entorno

La colección usa la variable `{{base_url}}` que por defecto es `http://localhost:3000`.

## 🔧 Estructura del Proyecto

```
api/
├── server.js           # Servidor principal Express
├── .env               # Configuración de bases de datos
├── package.json       # Dependencias Node.js
├── routes/
│   ├── mongodb.js     # Endpoints MongoDB
│   ├── redis.js       # Endpoints Redis
│   ├── neo4j.js       # Endpoints Neo4j
│   └── cassandra.js   # Endpoints Cassandra
└── README.md
```

## 📊 Ejemplos de Consultas

### MongoDB - Ficha completa

```bash
curl http://localhost:3000/api/mongodb/estudiante/STU-0006/ficha-completa
```

### Redis - Regla activa con medición de latencia

```bash
curl http://localhost:3000/api/redis/regla-activa?from=UK&to=US
```

### Neo4j - Camino de equivalencias

```bash
curl "http://localhost:3000/api/neo4j/camino-equivalencias?estudianteId=STU-0001&paisOrigen=UK&paisDestino=ZA"
```

### Cassandra - Reporte regional

```bash
curl "http://localhost:3000/api/cassandra/reporte-regional?region=ZA-PTA&year=2025"
```

## 🐛 Troubleshooting

### Error: Cannot connect to database

Verifica que todos los contenedores Docker estén corriendo:

```bash
docker ps
```

Deberías ver: `edugrade-mongo`, `edugrade-redis`, `edugrade-neo4j`, `edugrade-cassandra`

### Error: ECONNREFUSED

Verifica que los puertos estén correctamente mapeados en `docker-compose.yml`:
- MongoDB: 27017
- Redis: 6379
- Neo4j: 7474, 7687
- Cassandra: 9042



---


# notas:

📊 Consultas Disponibles en Postman:
MongoDB (RF1)
✅ Ficha completa de estudiante
✅ Filtro por metadata (Argentina - Recuperación)
✅ Filtro por metadata (UK - Board específico)
Redis (RF2)
✅ Regla activa UK→US (con medición de latencia)
✅ Regla activa AR→US
✅ Validación por fecha (2025)
✅ Validación por fecha (2026) - debe retornar versión diferente
Neo4j (RF3)
✅ Camino de equivalencias entre países
✅ Análisis de impacto en materias troncales
✅ Estadísticas del grafo
Cassandra (RF4/RF5)
✅ Reporte regional de Pretoria 2025
✅ Reporte regional con filtro por sistema
✅ Trazabilidad de auditoría por nota
✅ Reportes agregados
🎯 Ejemplo de uso:
Una vez que inicies la API y abras Postman, simplemente:

Selecciona cualquier consulta de la colección
Click en Send
Verás la respuesta JSON con los datos
