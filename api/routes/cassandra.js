const express = require('express');
const cassandra = require('cassandra-driver');
const router = express.Router();

const client = new cassandra.Client({
  contactPoints: [process.env.CASSANDRA_HOSTS],
  localDataCenter: process.env.CASSANDRA_DATACENTER
});

client.connect().then(() => {
  console.log('✅ Cassandra conectado');
}).catch(err => {
  console.error('❌ Error conectando a Cassandra:', err);
});

/**
 * RF4 - Consulta 1: Promedio por región y año
 * GET /api/cassandra/analitica/promedio?region=AR-BA&anio=2025&sistema=AR
 */
router.get('/analitica/promedio', async (req, res) => {
  try {
    const { region, anio, sistema } = req.query;
    
    if (!region || !anio) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: region, anio. Opcional: sistema' 
      });
    }

    let query, params;
    
    if (sistema) {
      query = `
        SELECT * FROM edugrade_analitica.promedio_por_region_anio
        WHERE region = ? AND anio = ? AND codigo_sistema = ?
      `;
      params = [region, parseInt(anio), sistema];
    } else {
      query = `
        SELECT * FROM edugrade_analitica.promedio_por_region_anio
        WHERE region = ? AND anio = ?
      `;
      params = [region, parseInt(anio)];
    }

    const result = await client.execute(query, params, { prepare: true });
    
    // Calcular estadísticas agregadas
    let total_n = 0;
    let suma_total = 0;
    
    const registros = result.rows.map(row => {
      const n = parseInt(row.n) || 0;
      const suma = parseFloat(row.suma) || 0;
      const avg = n > 0 ? (suma / n).toFixed(2) : 0;
      
      total_n += n;
      suma_total += suma;
      
      return {
        region: row.region,
        anio: row.anio,
        codigo_sistema: row.codigo_sistema,
        id_materia: row.id_materia,
        id_institucion: row.id_institucion,
        cantidad_notas: n,
        suma: suma,
        suma_cuadrados: parseFloat(row.suma_cuadrados) || 0,
        promedio: parseFloat(avg),
        actualizado_en: row.actualizado_en
      };
    });

    const promedio_general = total_n > 0 ? (suma_total / total_n).toFixed(2) : 0;

    res.json({
      filtros: { region, anio: parseInt(anio), sistema: sistema || 'todos' },
      total_registros: result.rows.length,
      total_calificaciones: total_n,
      promedio_general_za7: parseFloat(promedio_general),
      registros
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * RF5 - Consulta 2: Auditoría por entidad y mes
 * GET /api/cassandra/auditoria?id_entidad=grd_000001&aaaamm=202501
 */
router.get('/auditoria', async (req, res) => {
  try {
    const { id_entidad, aaaamm } = req.query;
    
    if (!id_entidad || !aaaamm) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: id_entidad (ej: grd_000001), aaaamm (ej: 202501)' 
      });
    }

    const query = `
      SELECT * FROM edugrade_auditoria.registro_auditoria_por_entidad_mes
      WHERE id_entidad = ? AND aaaamm = ?
      ORDER BY marca_tiempo DESC
    `;

    const result = await client.execute(query, [id_entidad, aaaamm], { prepare: true });

    const eventos = result.rows.map(row => ({
      id_entidad: row.id_entidad,
      mes: row.aaaamm,
      timestamp: row.marca_tiempo,
      tipo_entidad: row.tipo_entidad,
      accion: row.accion,
      actor: row.id_actor,
      ip: row.ip,
      hash_anterior: row.hash_anterior,
      hash_nuevo: row.hash_nuevo,
      payload: row.carga_util ? JSON.parse(row.carga_util) : null
    }));

    res.json({
      id_entidad,
      mes: aaaamm,
      total_eventos: eventos.length,
      eventos
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Obtener todas las keys de analítica (útil para testing)
 * GET /api/cassandra/analitica/keys?region=AR-BA&anio=2025
 */
router.get('/analitica/keys', async (req, res) => {
  try {
    const { region, anio } = req.query;
    
    if (!region || !anio) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: region, anio' 
      });
    }

    const query = `
      SELECT region, anio, codigo_sistema, id_materia, id_institucion, n, actualizado_en
      FROM edugrade_analitica.promedio_por_region_anio
      WHERE region = ? AND anio = ?
    `;

    const result = await client.execute(query, [region, parseInt(anio)], { prepare: true });

    res.json({
      region,
      anio: parseInt(anio),
      total_keys: result.rows.length,
      keys: result.rows.map(row => ({
        region: row.region,
        anio: row.anio,
        sistema: row.codigo_sistema,
        materia: row.id_materia,
        institucion: row.id_institucion,
        cantidad_registros: parseInt(row.n) || 0,
        ultima_actualizacion: row.actualizado_en
      }))
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * RF4 - Consulta 3: Fact Table (Calificaciones individuales por región/año/sistema)
 * GET /api/cassandra/analitica/facts?region=ZA-PTA&anio=2023&sistema=UK
 */
router.get('/analitica/facts', async (req, res) => {
  try {
    const { region, anio, sistema } = req.query;
    
    if (!region || !anio || !sistema) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: region, anio (academic_year), sistema (system code)' 
      });
    }

    const query = `
      SELECT * FROM edugrade_analitica.rf4_fact_grades_by_region_year_system
      WHERE region = ? AND academic_year = ? AND system = ?
    `;

    const result = await client.execute(query, [region, parseInt(anio), sistema], { prepare: true });

    const registros = result.rows.map(row => ({
      region: row.region,
      academic_year: row.academic_year,
      system: row.system,
      institution_id: row.institution_id,
      subject_id: row.subject_id,
      record_id: row.record_id,
      student_id: row.student_id,
      grade_raw: row.grade_raw,
      grade_norm: parseFloat(row.grade_norm_0_100) || 0,
      passed: row.passed,
      event_ts: row.event_ts
    }));

    res.json({
      filtros: { region, anio: parseInt(anio), sistema },
      total_registros: registros.length,
      registros
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * RF4 - Consulta 4: Reportes Agregados por Sistema
 * GET /api/cassandra/analitica/reportes?region=ZA-PTA&anio=2023&sistema=UK
 */
router.get('/analitica/reportes', async (req, res) => {
  try {
    const { region, anio, sistema } = req.query;
    
    if (!region || !anio || !sistema) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: region, anio, sistema' 
      });
    }

    const query = `
      SELECT * FROM edugrade_analitica.rf4_report_by_region_year_system
      WHERE region = ? AND academic_year = ? AND system = ?
    `;

    const result = await client.execute(query, [region, parseInt(anio), sistema], { prepare: true });

    const reportes = result.rows.map(row => ({
      region: row.region,
      academic_year: row.academic_year,
      system: row.system,
      institution_id: row.institution_id,
      subject_id: row.subject_id,
      n_records: row.n_records,
      avg_norm: parseFloat(row.avg_norm_0_100).toFixed(2),
      min_norm: parseFloat(row.min_norm_0_100).toFixed(2),
      max_norm: parseFloat(row.max_norm_0_100).toFixed(2),
      pass_rate: parseFloat(row.pass_rate).toFixed(2),
      updated_at: row.updated_at
    }));

    res.json({
      filtros: { region, anio: parseInt(anio), sistema },
      total_reportes: reportes.length,
      reportes
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * RF4 - Consulta 5: Comparación Cross-System (todos los sistemas de una región/año)
 * GET /api/cassandra/analitica/cross-system?region=ZA-PTA&anio=2023
 */
router.get('/analitica/cross-system', async (req, res) => {
  try {
    const { region, anio } = req.query;
    
    if (!region || !anio) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: region, anio' 
      });
    }

    const query = `
      SELECT * FROM edugrade_analitica.rf4_report_by_region_year
      WHERE region = ? AND academic_year = ?
    `;

    const result = await client.execute(query, [region, parseInt(anio)], { prepare: true });

    // Agrupar por sistema
    const porSistema = {};
    result.rows.forEach(row => {
      const sistema = row.system;
      if (!porSistema[sistema]) {
        porSistema[sistema] = {
          sistema,
          total_registros: 0,
          promedio_general: 0,
          suma_notas: 0,
          reportes: []
        };
      }
      
      porSistema[sistema].total_registros += row.n_records;
      porSistema[sistema].suma_notas += row.avg_norm_0_100 * row.n_records;
      porSistema[sistema].reportes.push({
        institution_id: row.institution_id,
        subject_id: row.subject_id,
        n_records: row.n_records,
        avg_norm: parseFloat(row.avg_norm_0_100).toFixed(2),
        pass_rate: parseFloat(row.pass_rate).toFixed(2)
      });
    });

    // Calcular promedios generales
    Object.keys(porSistema).forEach(sistema => {
      const datos = porSistema[sistema];
      datos.promedio_general = datos.total_registros > 0 
        ? (datos.suma_notas / datos.total_registros).toFixed(2)
        : 0;
      delete datos.suma_notas; // No necesitamos mostrar esto
    });

    res.json({
      filtros: { region, anio: parseInt(anio) },
      total_sistemas: Object.keys(porSistema).length,
      por_sistema: porSistema
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
