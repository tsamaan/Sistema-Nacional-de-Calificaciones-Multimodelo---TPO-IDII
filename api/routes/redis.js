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
});

/**
 * RF2 - Consulta 1 (Operativa): Búsqueda de regla activa
 * GET /api/redis/regla-activa?from=UK&to=US
 */
router.get('/regla-activa', async (req, res) => {
  try {
    const { from, to } = req.query;
    
    if (!from || !to) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: from y to' 
      });
    }

    const start = Date.now();
    
    // Obtener la regla activa
    const activeKey = `RULEACTIVE#${from}#${to}`;
    const activeRule = await client.hGetAll(activeKey);
    
    if (!activeRule || Object.keys(activeRule).length === 0) {
      return res.status(404).json({ 
        message: 'No se encontró regla activa para este par' 
      });
    }

    // Obtener la regla completa
    const ruleKey = `RULE#${from}#${to}#${activeRule.org}#${activeRule.version}`;
    const rule = await client.hGetAll(ruleKey);
    
    // Obtener metadata
    const metaKey = `RULEMETA#${from}#${to}#${activeRule.org}#${activeRule.version}`;
    const metadata = await client.hGetAll(metaKey);
    
    const latency = Date.now() - start;

    res.json({
      query: { from, to },
      latency_ms: latency,
      regla_activa: {
        key: ruleKey,
        conversiones: rule,
        metadata: metadata,
        updated_at: activeRule.updated_at
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * RF2 - Consulta 2 (Potencia): Validación de versión por fecha
 * GET /api/redis/regla-por-fecha?from=UK&to=US&org=MINEDU_ZA&fecha=2025-06-15
 */
router.get('/regla-por-fecha', async (req, res) => {
  try {
    const { from, to, org, fecha } = req.query;
    
    if (!from || !to || !org || !fecha) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: from, to, org, fecha (YYYY-MM-DD)' 
      });
    }

    // Buscar todas las versiones de esta regla
    const pattern = `RULEMETA#${from}#${to}#${org}#*`;
    const keys = await client.keys(pattern);
    
    let versionValida = null;
    const fechaBusqueda = new Date(fecha);

    for (const key of keys) {
      const meta = await client.hGetAll(key);
      const validFrom = new Date(meta.valid_from);
      const validTo = new Date(meta.valid_to);
      
      if (fechaBusqueda >= validFrom && fechaBusqueda <= validTo) {
        const version = key.split('#').pop();
        const ruleKey = `RULE#${from}#${to}#${org}#${version}`;
        const rule = await client.hGetAll(ruleKey);
        
        versionValida = {
          version,
          valid_from: meta.valid_from,
          valid_to: meta.valid_to,
          formula: rule,
          normative_ref: meta.normative_ref
        };
        break;
      }
    }

    if (!versionValida) {
      return res.status(404).json({ 
        message: 'No se encontró versión válida para la fecha especificada' 
      });
    }

    res.json({
      query: { from, to, org, fecha },
      version_valida: versionValida
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Listar todas las reglas disponibles
 * GET /api/redis/reglas
 */
router.get('/reglas', async (req, res) => {
  try {
    const keys = await client.keys('RULE#*');
    const metaKeys = keys.filter(k => k.includes('RULEMETA'));
    
    res.json({
      total_reglas: keys.length,
      reglas: keys.slice(0, 20)
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
