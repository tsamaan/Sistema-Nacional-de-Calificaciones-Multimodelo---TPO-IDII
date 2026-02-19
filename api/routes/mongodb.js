const express = require('express');
const { MongoClient } = require('mongodb');
const router = express.Router();

const client = new MongoClient(process.env.MONGO_URI);
let db;

// Conectar a MongoDB
client.connect().then(() => {
  db = client.db('edugrade');
  console.log('✅ MongoDB conectado');
}).catch(err => {
  console.error('❌ Error conectando a MongoDB:', err);
});

/**
 * RF1 - Consulta 1: Obtener historial completo de un estudiante
 * GET /api/mongodb/estudiante/:id/historial
 */
router.get('/estudiante/:id/historial', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Buscar estudiante
    const estudiante = await db.collection('estudiantes').findOne({ _id: id });
    
    if (!estudiante) {
      return res.status(404).json({ error: 'Estudiante no encontrado' });
    }

    // Buscar todas sus calificaciones
    const calificaciones = await db.collection('calificaciones')
      .find({ id_estudiante: id })
      .sort({ 'periodo.anio': -1, 'evaluacion.fecha': -1 })
      .toArray();
    
    // Buscar trayectorias
    const trayectorias = await db.collection('trayectorias')
      .find({ id_estudiante: id })
      .sort({ fecha_inicio: -1 })
      .toArray();

    res.json({
      estudiante: {
        id: estudiante._id,
        nombre: estudiante.full_name,
        documento: estudiante.documento,
        region: estudiante.region
      },
      total_calificaciones: calificaciones.length,
      calificaciones: calificaciones.map(c => ({
        id: c._id,
        materia: c.id_materia,
        institucion: c.id_institucion,
        periodo: c.periodo,
        sistema: c.original.sistema,
        valor_original: c.original.valor_raw,
        valor_za7: c.original.valor_num_za7,
        conversiones: c.conversiones
      })),
      trayectorias: trayectorias.length
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * RF1 - Consulta 2: Filtrar calificaciones por región y año
 * GET /api/mongodb/calificaciones/filtrar?region=AR-BA&anio=2025&sistema=AR
 */
router.get('/calificaciones/filtrar', async (req, res) => {
  try {
    const { region, anio, sistema, estudiante } = req.query;
    let query = {};

    if (region) query.region = region;
    if (anio) query['periodo.anio'] = parseInt(anio);
    if (sistema) query['original.sistema'] = sistema;
    if (estudiante) query.id_estudiante = estudiante;

    const calificaciones = await db.collection('calificaciones')
      .find(query)
      .sort({ 'evaluacion.fecha': -1 })
      .limit(100)
      .toArray();

    res.json({
      filtros: req.query,
      total_resultados: calificaciones.length,
      calificaciones: calificaciones.map(c => ({
        id: c._id,
        estudiante: c.id_estudiante,
        materia: c.id_materia,
        institucion: c.id_institucion,
        region: c.region,
        periodo: c.periodo,
        sistema: c.original.sistema,
        valor: c.original.valor_raw,
        za7: c.original.valor_num_za7,
        fecha: c.evaluacion?.fecha,
        conversiones: c.conversiones?.length || 0
      }))
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * RF1 - Consulta 3: Obtener calificación por ID con conversiones
 * GET /api/mongodb/calificacion/:id
 */
router.get('/calificacion/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const calificacion = await db.collection('calificaciones').findOne({ _id: id });
    
    if (!calificacion) {
      return res.status(404).json({ error: 'Calificación no encontrada' });
    }

    res.json({
      id: calificacion._id,
      estudiante: calificacion.id_estudiante,
      materia: calificacion.id_materia,
      institucion: calificacion.id_institucion,
      region: calificacion.region,
      periodo: calificacion.periodo,
      evaluacion: calificacion.evaluacion,
      original: calificacion.original,
      conversiones: calificacion.conversiones,
      inmutabilidad: calificacion.inmutabilidad,
      auditoria: calificacion.auditoria
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Obtener estadísticas generales
 * GET /api/mongodb/stats
 */
router.get('/stats', async (req, res) => {
  try {
    const estudiantes = await db.collection('estudiantes').countDocuments();
    const instituciones = await db.collection('instituciones').countDocuments();
    const materias = await db.collection('materias').countDocuments();
    const calificaciones = await db.collection('calificaciones').countDocuments();
    const trayectorias = await db.collection('trayectorias').countDocuments();
    
    res.json({
      estudiantes,
      instituciones,
      materias,
      calificaciones,
      trayectorias
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
