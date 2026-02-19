const express = require('express');
const neo4j = require('neo4j-driver');
const router = express.Router();

const driver = neo4j.driver(
  process.env.NEO4J_URI,
  neo4j.auth.basic(process.env.NEO4J_USER, process.env.NEO4J_PASSWORD)
);

driver.getServerInfo().then(() => {
  console.log('✅ Neo4j conectado');
});

/**
 * RF3 - Consulta 1 (Operativa): Camino de equivalencias
 * GET /api/neo4j/camino-equivalencias?estudianteId=STU-0001&paisOrigen=UK&paisDestino=ZA
 */
router.get('/camino-equivalencias', async (req, res) => {
  const session = driver.session();
  try {
    const { estudianteId, paisOrigen, paisDestino } = req.query;
    
    if (!estudianteId || !paisOrigen || !paisDestino) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: estudianteId, paisOrigen, paisDestino' 
      });
    }

    const query = `
      MATCH (e:Student {student_id: $estudianteId})
      MATCH (e)-[:HAS_RECORD]->(gr:GradeRecord)-[:FOR_SUBJECT]->(m:Subject)
      MATCH path = shortestPath((m)-[:EQUIVALENT_TO*1..5]-(m2:Subject))
      WHERE m2.system = $paisDestino
      RETURN m.name as materia_origen, 
             m.system as sistema_origen,
             m2.name as materia_destino,
             m2.system as pais_destino,
             length(path) as distancia,
             [node in nodes(path) | node.name] as ruta
      ORDER BY distancia
      LIMIT 10
    `;

    const result = await session.run(query, {
      estudianteId,
      paisDestino
    });

    const caminos = result.records.map(record => ({
      materia_origen: record.get('materia_origen'),
      sistema_origen: record.get('sistema_origen'),
      materia_destino: record.get('materia_destino'),
      pais_destino: record.get('pais_destino'),
      distancia: record.get('distancia').toNumber(),
      ruta: record.get('ruta')
    }));

    res.json({
      estudiante: estudianteId,
      caminos_encontrados: caminos.length,
      caminos
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  } finally {
    await session.close();
  }
});

/**
 * RF3 - Consulta 2 (Potencia): Análisis de impacto
 * GET /api/neo4j/analisis-impacto?materiaId=SUB-MATH
 */
router.get('/analisis-impacto', async (req, res) => {
  const session = driver.session();
  try {
    const { materiaId } = req.query;
    
    if (!materiaId) {
      return res.status(400).json({ 
        error: 'Parámetro requerido: materiaId' 
      });
    }

    const query = `
      MATCH (m:Subject {subject_id: $materiaId})
      MATCH (m)-[:PREREQUISITE_FOR*1..3]->(materias_afectadas)
      RETURN DISTINCT materias_afectadas.name as materia,
             materias_afectadas.subject_id as id,
             labels(materias_afectadas)[0] as tipo
      
      UNION
      
      MATCH (m:Subject {subject_id: $materiaId})
      MATCH (m)-[:EQUIVALENT_TO]-(equivalentes)
      RETURN DISTINCT equivalentes.name as materia,
             equivalentes.subject_id as id,
             labels(equivalentes)[0] as tipo
      
      UNION
      
      MATCH (m:Subject {subject_id: $materiaId})
      MATCH (gr:GradeRecord)-[:FOR_SUBJECT]->(m)
      MATCH (estudiantes:Student)-[:HAS_RECORD]->(gr)
      RETURN DISTINCT estudiantes.full_name as materia,
             estudiantes.student_id as id,
             'Estudiante Afectado' as tipo
    `;

    const result = await session.run(query, { materiaId });

    const impactos = result.records.map(record => ({
      elemento: record.get('materia'),
      id: record.get('id'),
      tipo: record.get('tipo')
    }));

    res.json({
      materia_analizada: materiaId,
      total_afectados: impactos.length,
      elementos_afectados: impactos
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  } finally {
    await session.close();
  }
});

/**
 * Obtener estadísticas del grafo
 * GET /api/neo4j/stats
 */
router.get('/stats', async (req, res) => {
  const session = driver.session();
  try {
    const query = `
      MATCH (n)
      RETURN labels(n)[0] as tipo, count(*) as cantidad
      ORDER BY cantidad DESC
    `;

    const result = await session.run(query);
    const stats = result.records.map(record => ({
      tipo: record.get('tipo'),
      cantidad: record.get('cantidad').toNumber()
    }));

    const relQuery = `MATCH ()-[r]->() RETURN count(r) as total`;
    const relResult = await session.run(relQuery);
    const totalRelaciones = relResult.records[0].get('total').toNumber();

    res.json({
      nodos_por_tipo: stats,
      total_relaciones: totalRelaciones
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  } finally {
    await session.close();
  }
});

module.exports = router;
