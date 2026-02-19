const express = require('express');
const neo4j = require('neo4j-driver');
const router = express.Router();

const driver = neo4j.driver(
  process.env.NEO4J_URI,
  neo4j.auth.basic(process.env.NEO4J_USER, process.env.NEO4J_PASSWORD)
);

driver.getServerInfo().then(() => {
  console.log('✅ Neo4j conectado');
}).catch(err => {
  console.error('❌ Error conectando a Neo4j:', err);
});

/**
 * RF3 - Consulta 1: Buscar equivalencias entre materias
 * GET /api/neo4j/equivalencias?materia_origen=Math101_US&pais_destino=AR
 */
router.get('/equivalencias', async (req, res) => {
  const session = driver.session();
  try {
    const { materia_origen, pais_destino } = req.query;
    
    if (!materia_origen || !pais_destino) {
      return res.status(400).json({ 
        error: 'Parámetros requeridos: materia_origen, pais_destino' 
      });
    }

    const query = `
      MATCH (m1:Materia {id_materia: $materia_origen})
      MATCH (m1)-[e:EQUIVALENTE_A]-(m2:Materia)
      WHERE m2.pais = $pais_destino
      RETURN m1.id_materia as origen_id,
             m1.nombre as origen_nombre,
             m1.pais as origen_pais,
             m2.id_materia as destino_id,
             m2.nombre as destino_nombre,
             m2.pais as destino_pais,
             e.organismo as organismo,
             e.tipo as tipo_equivalencia,
             e.vigente_desde as vigente_desde,
             e.vigente_hasta as vigente_hasta,
             e.version_regla as version
    `;

    const result = await session.run(query, {
      materia_origen,
      pais_destino
    });

    const equivalencias = result.records.map(record => ({
      origen: {
        id: record.get('origen_id'),
        nombre: record.get('origen_nombre'),
        pais: record.get('origen_pais')
      },
      destino: {
        id: record.get('destino_id'),
        nombre: record.get('destino_nombre'),
        pais: record.get('destino_pais')
      },
      relacion: {
        organismo: record.get('organismo'),
        tipo: record.get('tipo_equivalencia'),
        vigente_desde: record.get('vigente_desde'),
        vigente_hasta: record.get('vigente_hasta'),
        version: record.get('version')
      }
    }));

    res.json({
      materia_origen,
      pais_destino,
      equivalencias_encontradas: equivalencias.length,
      equivalencias
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  } finally {
    await session.close();
  }
});

/**
 * RF3 - Consulta 2: Historial de notas de un estudiante con materias
 * GET /api/neo4j/estudiante/:id/notas
 */
router.get('/estudiante/:id/notas', async (req, res) => {
  const session = driver.session();
  try {
    const { id } = req.params;

    const query = `
      MATCH (e:Estudiante {id_estudiante: $id})
      OPTIONAL MATCH (e)-[:CURSO]->(i:Institucion)
      OPTIONAL MATCH (e)-[:OBTUVO]->(gr:GradeRecord)-[:EN_MATERIA]->(m:Materia)
      RETURN e.id_estudiante as estudiante_id,
             e.nombre as estudiante_nombre,
             collect(DISTINCT {
               record_id: gr.id_record,
               materia_id: m.id_materia,
               materia_nombre: m.nombre,
               sistema: gr.sistema,
               valor: gr.valor
             }) as notas,
             i.nombre as institucion
    `;

    const result = await session.run(query, { id });

    if (result.records.length === 0) {
      return res.status(404).json({ error: 'Estudiante no encontrado en el grafo' });
    }

    const record = result.records[0];
    
    res.json({
      estudiante: {
        id: record.get('estudiante_id'),
        nombre: record.get('estudiante_nombre'),
        institucion: record.get('institucion')
      },
      total_notas: record.get('notas').length,
      notas: record.get('notas').filter(n => n.record_id !== null)
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  } finally {
    await session.close();
  }
});

/**
 * RF3 - Consulta 3: Buscar prerequisitos de una materia
 * GET /api/neo4j/materia/:id/prerequisitos
 */
router.get('/materia/:id/prerequisitos', async (req, res) => {
  const session = driver.session();
  try {
    const { id } = req.params;

    const query = `
      MATCH (m:Materia {id_materia: $id})
      OPTIONAL MATCH (prereq:Materia)-[:PREREQUISITO_DE]->(m)
      RETURN m.id_materia as materia_id,
             m.nombre as materia_nombre,
             m.nivel as nivel,
             collect(DISTINCT {
               id: prereq.id_materia,
               nombre: prereq.nombre,
               nivel: prereq.nivel
             }) as prerequisitos
    `;

    const result = await session.run(query, { id });

    if (result.records.length === 0) {
      return res.status(404).json({ error: 'Materia no encontrada en el grafo' });
    }

    const record = result.records[0];
    const prereqs = record.get('prerequisitos').filter(p => p.id !== null);

    res.json({
      materia: {
        id: record.get('materia_id'),
        nombre: record.get('materia_nombre'),
        nivel: record.get('nivel')
      },
      prerequisitos: prereqs,
      total_prerequisitos: prereqs.length
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
    // Contar nodos por tipo
    const nodesQuery = `
      MATCH (n)
      RETURN labels(n)[0] as tipo, count(*) as cantidad
      ORDER BY cantidad DESC
    `;

    const nodesResult = await session.run(nodesQuery);
    const nodos = nodesResult.records.map(record => ({
      tipo: record.get('tipo'),
      cantidad: record.get('cantidad').toNumber()
    }));

    // Contar relaciones por tipo
    const relsQuery = `
      MATCH ()-[r]->()
      RETURN type(r) as tipo, count(*) as cantidad
      ORDER BY cantidad DESC
    `;

    const relsResult = await session.run(relsQuery);
    const relaciones = relsResult.records.map(record => ({
      tipo: record.get('tipo'),
      cantidad: record.get('cantidad').toNumber()
    }));

    const totalRelaciones = relaciones.reduce((sum, r) => sum + r.cantidad, 0);
    const totalNodos = nodos.reduce((sum, n) => sum + n.cantidad, 0);

    res.json({
      total_nodos: totalNodos,
      total_relaciones: totalRelaciones,
      nodos_por_tipo: nodos,
      relaciones_por_tipo: relaciones
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  } finally {
    await session.close();
  }
});

module.exports = router;
