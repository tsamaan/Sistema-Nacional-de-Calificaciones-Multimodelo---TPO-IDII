const express = require('express');
const redis = require('redis');
const router = express.Router();

const client = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT
  },
  password: process.env.REDIS_PASSWORD
});

client.connect().then(() => {
  console.log('✅ Redis conectado');
}).catch(err => {
  console.error('❌ Error conectando a Redis:', err);
});

client.on('error', (err) => console.error('Redis error:', err));

/**
 * RF2 - Consulta 1: Obtener regla activa de conversión
 * GET /api/redis/regla-activa?from=AR&to=ZA7&organismo=MINISTERIO&nivel=SECUNDARIO&anio=2025
 */
router.get('/regla-activa', async (req, res) => {
  try {
    const { from, to, organismo = 'MINISTERIO', nivel = 'SECUNDARIO', anio = '2025' } = req.query;
    
    if (!from || !to) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: from, to. Opcionales: organismo, nivel, anio' 
      });
    }

    const start = Date.now();
    
    // Buscar versión activa
    const activeKey = `regla_activa:${from}#${to}:${organismo}:${nivel}:${anio}`;
    const version = await client.get(activeKey);
    
    if (!version) {
      return res.status(404).json({ 
        message: 'No se encontró regla activa para estos parámetros',
        key_buscada: activeKey
      });
    }

    // Obtener la regla completa
    const ruleKey = `regla:${from}#${to}:${organismo}:${nivel}:${anio}:${version}`;
    const rule = await client.hGetAll(ruleKey);
    
    if (!rule || Object.keys(rule).length === 0) {
      return res.status(404).json({ 
        message: 'Versión activa encontrada pero regla no existe',
        version,
        key_buscada: ruleKey
      });
    }
    
    const latency = Date.now() - start;

    res.json({
      query: { from, to, organismo, nivel, anio },
      latency_ms: latency,
      version_activa: version,
      regla: {
        key: ruleKey,
        from: rule.from,
        to: rule.to,
        version: rule.version,
        organismo: rule.organismo,
        nivel: rule.nivel,
        anio: rule.anio,
        metodo: rule.metodo,
        vigencia_desde: rule.vigencia_desde,
        vigencia_hasta: rule.vigencia_hasta,
        mapping: rule.mapping ? JSON.parse(rule.mapping) : null
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * RF2 - Consulta 2: Obtener conversión cacheada
 * GET /api/redis/conversion/:id_calificacion?to=ZA7&version=1
 */
router.get('/conversion/:id_calificacion', async (req, res) => {
  try {
    const { id_calificacion } = req.params;
    const { to = 'ZA7', version = '1' } = req.query;

    const cacheKey = `conv:${id_calificacion}:${to}:${version}`;
    const cached = await client.get(cacheKey);
    
    if (!cached) {
      return res.status(404).json({ 
        message: 'No hay conversión cacheada',
        key_buscada: cacheKey,
        sugerencia: 'Esta conversión aún no ha sido calculada o el TTL expiró'
      });
    }

    res.json({
      id_calificacion,
      to,
      version,
      cache_key: cacheKey,
      resultado: JSON.parse(cached),
      cache_hit: true
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * RF2 - Consulta 3: Listar todas las reglas disponibles
 * GET /api/redis/reglas
 */
router.get('/reglas', async (req, res) => {
  try {
    const pattern = 'regla:*';
    const keys = [];
    
    // Escanear todas las reglas
    for await (const key of client.scanIterator({ MATCH: pattern, COUNT: 100 })) {
      keys.push(key);
    }
    
    // Obtener detalles de las primeras 20 reglas
    const reglas = [];
    for (const key of keys.slice(0, 20)) {
      const rule = await client.hGetAll(key);
      if (rule && Object.keys(rule).length > 0) {
        reglas.push({
          key,
          from: rule.from,
          to: rule.to,
          version: rule.version,
          organismo: rule.organismo,
          nivel: rule.nivel,
          anio: rule.anio,
          metodo: rule.metodo
        });
      }
    }

    res.json({
      total_reglas: keys.length,
      mostrando: reglas.length,
      reglas
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Obtener todas las conversiones cacheadas
 * GET /api/redis/conversiones-cache
 */
router.get('/conversiones-cache', async (req, res) => {
  try {
    const pattern = 'conv:*';
    const keys = [];
    
    for await (const key of client.scanIterator({ MATCH: pattern, COUNT: 100 })) {
      keys.push(key);
    }

    const conversiones = [];
    for (const key of keys.slice(0, 20)) {
      const value = await client.get(key);
      const ttl = await client.ttl(key);
      conversiones.push({
        key,
        ttl_segundos: ttl,
        datos: value ? JSON.parse(value) : null
      });
    }

    res.json({
      total_conversiones_cache: keys.length,
      mostrando: conversiones.length,
      conversiones
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
