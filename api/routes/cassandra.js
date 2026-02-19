const express = require('express');
const cassandra = require('cassandra-driver');
const router = express.Router();

const client = new cassandra.Client({
  contactPoints: [process.env.CASSANDRA_HOSTS],
  localDataCenter: process.env.CASSANDRA_DATACENTER,
  keyspace: process.env.CASSANDRA_KEYSPACE
});

client.connect().then(() => {
  console.log('✅ Cassandra conectado');
});

/**
 * RF4 - Consulta 1 (Operativa): Reporte regional
 * GET /api/cassandra/reporte-regional?region=ZA-PTA&year=2025
 */
router.get('/reporte-regional', async (req, res) => {
  try {
    const { region, year, system } = req.query;
    
    if (!region || !year) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: region, year. Opcional: system' 
      });
    }

    let query, params;
    
    if (system) {
      // Query específica por sistema
      query = `
        SELECT * FROM rf4_fact_grades_by_region_year_system
        WHERE region = ? AND academic_year = ? AND system = ?
      `;
      params = [region, parseInt(year), system];
    } else {
      // Query solo por región y año (más amplia pero menos óptima)
      query = `
        SELECT * FROM rf4_report_by_region_year
        WHERE region = ? AND academic_year = ?
      `;
      params = [region, parseInt(year)];
    }

    const result = await client.execute(query, params, { prepare: true });
    
    // Calcular estadísticas
    let totalCalificaciones = 0;
    let sumaNotas = 0;
    
    result.rows.forEach(row => {
      if (row.n_records) {
        totalCalificaciones += row.n_records;
        sumaNotas += row.avg_norm_0_100 * row.n_records;
      } else {
        totalCalificaciones++;
        sumaNotas += row.grade_norm_0_100;
      }
    });

    const promedioGeneral = totalCalificaciones > 0 
      ? (sumaNotas / totalCalificaciones).toFixed(2) 
      : 0;

    res.json({
      filtros: { region, year, system: system || 'todos' },
      total_registros: result.rows.length,
      promedio_general: parseFloat(promedioGeneral),
      datos: result.rows.map(row => ({
        institution_id: row.institution_id,
        subject_id: row.subject_id,
        system: row.system,
        avg_norm: row.avg_norm_0_100 || row.grade_norm_0_100,
        n_records: row.n_records || 1,
        pass_rate: row.pass_rate,
        event_ts: row.event_ts
      }))
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * RF5 - Consulta 2 (Potencia): Trazabilidad de auditoría
 * GET /api/cassandra/auditoria-nota?recordId=GR-2025-0001&mes=2026-02
 */
router.get('/auditoria-nota', async (req, res) => {
  try {
    const { recordId, mes } = req.query;
    
    if (!recordId || !mes) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: recordId (ej: GR-2025-0001), mes (ej: 2026-02)' 
      });
    }

    const entityId = `NOTE#${recordId}`;
    
    const query = `
      SELECT * FROM rf5_audit_timeline_by_entity_month
      WHERE entity_id = ? AND month_bucket = ?
      ORDER BY ts DESC
    `;

    const result = await client.execute(query, [entityId, mes], { prepare: true });

    const eventos = result.rows.map(row => ({
      timestamp: row.ts,
      event_type: row.event_type,
      actor: row.actor,
      ip: row.ip,
      record_id: row.record_id,
      details: row.details_json ? JSON.parse(row.details_json) : null,
      integrity_hash: row.integrity_hash_sha256
    }));

    res.json({
      entity_id: entityId,
      mes_consultado: mes,
      total_eventos: eventos.length,
      eventos
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Obtener reportes agregados por región y año
 * GET /api/cassandra/reportes?region=ZA-CPT&year=2025
 */
router.get('/reportes', async (req, res) => {
  try {
    const { region, year } = req.query;
    
    if (!region || !year) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: region, year' 
      });
    }

    const query = `
      SELECT * FROM rf4_report_by_region_year_system
      WHERE region = ? AND academic_year = ?
    `;

    const result = await client.execute(query, [region, parseInt(year)], { prepare: true });

    res.json({
      region,
      year: parseInt(year),
      reportes: result.rows.map(row => ({
        system: row.system,
        institution_id: row.institution_id,
        subject_id: row.subject_id,
        n_records: row.n_records,
        avg_norm_0_100: row.avg_norm_0_100,
        min_norm_0_100: row.min_norm_0_100,
        max_norm_0_100: row.max_norm_0_100,
        pass_rate: row.pass_rate,
        updated_at: row.updated_at
      }))
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
