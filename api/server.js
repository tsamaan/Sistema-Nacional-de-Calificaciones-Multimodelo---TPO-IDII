const express = require('express');
const cors = require('cors');
require('dotenv').config();

const mongoRoutes = require('./routes/mongodb');
const redisRoutes = require('./routes/redis');
const neo4jRoutes = require('./routes/neo4j');
const cassandraRoutes = require('./routes/cassandra');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/', (req, res) => {
  res.json({
    message: 'EduGrade Global API - Sistema Multimodelo',
    version: '1.0.0',
    endpoints: {
      mongodb: '/api/mongodb/*',
      redis: '/api/redis/*',
      neo4j: '/api/neo4j/*',
      cassandra: '/api/cassandra/*'
    }
  });
});

// Routes
app.use('/api/mongodb', mongoRoutes);
app.use('/api/redis', redisRoutes);
app.use('/api/neo4j', neo4jRoutes);
app.use('/api/cassandra', cassandraRoutes);

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: err.message });
});

app.listen(PORT, () => {
  console.log(`🚀 EduGrade API corriendo en http://localhost:${PORT}`);
  console.log(`📊 Conectado a 4 bases de datos: MongoDB, Redis, Neo4j, Cassandra`);
});
