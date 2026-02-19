const express = require('express');
const { MongoClient } = require('mongodb');
const router = express.Router();

const client = new MongoClient(process.env.MONGO_URI);
let db;

// Conectar a MongoDB
client.connect().then(() => {
  db = client.db('edugrade');
  console.log('✅ MongoDB conectado');
});

/**
 * RF1 - Consulta 1 (Operativa): Obtener ficha completa de un alumno
 * GET /api/mongodb/estudiante/:id/ficha-completa
 */
router.get('/estudiante/:id/ficha-completa', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Buscar en calificaciones (donde está el historial embedded)
    const calificaciones = await db.collection('calificaciones')
      .find({ student_id: id })
      .toArray();
    
    if (calificaciones.length === 0) {
      return res.status(404).json({ message: 'Estudiante no encontrado' });
    }

    res.json({
      student_id: id,
      total_calificaciones: calificaciones.length,
      historial: calificaciones
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * RF1 - Consulta 2 (Potencia): Filtrar por metadato local
 * GET /api/mongodb/buscar-por-metadata?pais=AR&tipo=recuperacion
 * GET /api/mongodb/buscar-por-metadata?pais=UK&board=IEB
 */
router.get('/buscar-por-metadata', async (req, res) => {
  try {
    const { pais, tipo, board } = req.query;
    let query = {};

    if (pais === 'AR' && tipo === 'recuperacion') {
      query = {
        'metadata_local.pais': 'AR',
        'metadata_local.tipo_instancia': 'recuperacion'
      };
    } else if (pais === 'UK' && board) {
      query = {
        'metadata_local.pais': 'UK',
        'metadata_local.board': board
      };
    }

    const calificaciones = await db.collection('calificaciones')
      .find(query)
      .toArray();

    res.json({
      filtros: req.query,
      total_resultados: calificaciones.length,
      calificaciones
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * Obtener todas las calificaciones (útil para testing)
 * GET /api/mongodb/calificaciones
 */
router.get('/calificaciones', async (req, res) => {
  try {
    const calificaciones = await db.collection('calificaciones')
      .find({})
      .limit(50)
      .toArray();
    
    res.json({
      total: calificaciones.length,
      calificaciones
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
