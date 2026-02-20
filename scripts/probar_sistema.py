#!/usr/bin/env python3
"""
Script para cambiar el sistema educativo de un estudiante
Flujo: MongoDB → Redis (conversión) → MongoDB (guardado) → Neo4j (relaciones) → Cassandra (auditoría)
"""
import sys
import json
import hashlib
from datetime import datetime, timezone
from pymongo import MongoClient
import redis
from neo4j import GraphDatabase
from cassandra.cluster import Cluster

# ============================================================================
# COLORES PARA TERMINAL
# ============================================================================
class Color:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    MAGENTA = '\033[95m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

def print_header(texto):
    print(f"\n{Color.BOLD}{Color.CYAN}{'='*70}{Color.END}")
    print(f"{Color.BOLD}{Color.CYAN}{texto.center(70)}{Color.END}")
    print(f"{Color.BOLD}{Color.CYAN}{'='*70}{Color.END}\n")

def print_success(texto):
    print(f"{Color.GREEN}✅ {texto}{Color.END}")

def print_error(texto):
    print(f"{Color.RED}❌ {texto}{Color.END}")

def print_info(texto):
    print(f"{Color.BLUE}ℹ️  {texto}{Color.END}")

def print_warning(texto):
    print(f"{Color.YELLOW}⚠️  {texto}{Color.END}")

# ============================================================================
# PASO 1: CONECTAR A LAS 4 BASES DE DATOS
# ============================================================================
print_header("SISTEMA DE CONVERSIÓN DE CALIFICACIONES MULTIBASE")
print_info("Conectando a las bases de datos...")

try:
    # MongoDB - Almacenamiento principal
    mongo_client = MongoClient('mongodb://admin:admin123@localhost:27017/edugrade?authSource=admin')
    db = mongo_client['edugrade']
    mongo_client.server_info()
    print_success("MongoDB conectado")
except Exception as e:
    print_error(f"Error MongoDB: {e}")
    exit(1)

try:
    # Redis - Conversiones en memoria
    redis_client = redis.Redis(host='localhost', port=6379, password='redis123', decode_responses=True)
    redis_client.ping()
    print_success("Redis conectado")
except Exception as e:
    print_error(f"Error Redis: {e}")
    exit(1)

try:
    # Neo4j - Grafo de relaciones
    neo4j_driver = GraphDatabase.driver("bolt://localhost:7687", auth=("neo4j", "Neo4j2026!"))
    print_success("Neo4j conectado")
except Exception as e:
    print_error(f"Error Neo4j: {e}")
    print_warning("Si el error persiste, reinicie Neo4j: docker restart edugrade-neo4j")
    exit(1)

try:
    # Cassandra - Auditoría inmutable
    cassandra_cluster = Cluster(['localhost'])
    cassandra_session_auditoria = cassandra_cluster.connect('edugrade_auditoria')
    print_success("Cassandra conectado")
except Exception as e:
    print_error(f"Error Cassandra: {e}")
    exit(1)

# ============================================================================
# FUNCIONES AUXILIARES PARA MENÚ
# ============================================================================

def mostrar_trayectoria(student_id):
    """Muestra la trayectoria académica del estudiante desde MongoDB"""
    print_header("TRAYECTORIA ACADÉMICA")
    
    trayectoria = db.trayectorias.find_one({'student_id': student_id})
    
    if not trayectoria:
        print_error("No se encontró trayectoria para este estudiante")
        input(f"\n{Color.CYAN}Presione ENTER para continuar...{Color.END}")
        return
    
    print(f"  ┌────────────────────────────────────────────────────────────────────┐")
    print(f"  │ {Color.BOLD}{Color.CYAN}TRAYECTORIA ACADÉMICA{Color.END}                                            │")
    print(f"  ├────────────────────────────────────────────────────────────────────┤")
    print(f"  │  🆔 Student ID:         {Color.YELLOW}{trayectoria['student_id']}{Color.END:<47}│")
    print(f"  │  📊 Estado:             {trayectoria.get('status', 'N/A'):<48}│")
    print(f"  │  🎯 Promedio General:   {trayectoria.get('overall_avg', 'N/A'):<48}│")
    print(f"  │  📚 Total Registros:    {trayectoria.get('total_records', 0):<48}│")
    print(f"  │  ✅ Materias Aprobadas: {trayectoria.get('passed_subjects', 0):<48}│")
    print(f"  │  ❌ Materias Reprobadas: {trayectoria.get('failed_subjects', 0):<48}│")
    print(f"  └────────────────────────────────────────────────────────────────────┘")
    
    # Instituciones asistidas
    if 'institutions_attended' in trayectoria:
        print(f"\n  {Color.BOLD}Instituciones asistidas:{Color.END}")
        for inst_id in trayectoria['institutions_attended']:
            inst = db.instituciones.find_one({'institution_id': inst_id})
            if inst:
                print(f"    • {inst['name']} ({inst['codigo_sistema']}) - {inst['country']}")
    
    print()
    input(f"{Color.CYAN}Presione ENTER para continuar...{Color.END}")

def ver_calificaciones(student_id):
    """Muestra las calificaciones del estudiante desde MongoDB"""
    print_header("CALIFICACIONES REGISTRADAS")
    
    calificaciones = list(db.calificaciones.find({'student_id': student_id}).sort('created_at', -1))
    
    if not calificaciones:
        print_error("Este estudiante no tiene calificaciones registradas")
        input(f"\n{Color.CYAN}Presione ENTER para continuar...{Color.END}")
        return
    
    # Tabla con bordes bonitos
    print(f"  ┌─────────────────┬───────────────────────────┬──────────┬─────────────────────────┬────────────┬────────────┐")
    print(f"  │ {Color.BOLD}ID Registro{Color.END}     │ {Color.BOLD}Institución{Color.END}               │ {Color.BOLD}Sistema{Color.END}  │ {Color.BOLD}Materia{Color.END}                 │ {Color.BOLD}Nota{Color.END}       │ {Color.BOLD}Estado{Color.END}     │")
    print(f"  ├─────────────────┼───────────────────────────┼──────────┼─────────────────────────┼────────────┼────────────┤")
    
    for cal in calificaciones:
        institucion = cal['institution_snapshot']['name'][:25]
        sistema = cal['institution_snapshot']['system']
        materia_nombre = cal['subject_snapshot']['name'][:23]
        nota = cal['evaluation']['grade_value']
        
        # Color según estado
        if cal['evaluation']['passed']:
            estado = f"{Color.GREEN}✅ Aprobó{Color.END}"
            nota_display = f"{Color.GREEN}{nota}{Color.END}"
        else:
            estado = f"{Color.RED}❌ Desaprobó{Color.END}"
            nota_display = f"{Color.RED}{nota}{Color.END}"
        
        # Color según sistema
        sistema_colors = {
            'AR': Color.CYAN,
            'US': Color.BLUE,
            'ZA7': Color.YELLOW,
            'UK': Color.MAGENTA,
            'DE': Color.GREEN
        }
        sistema_color = sistema_colors.get(sistema, '')
        sistema_display = f"{sistema_color}{sistema}{Color.END}" if sistema_color else sistema
        
        print(f"  │ {cal['record_id']:<15} │ {institucion:<25} │ {sistema_display:<17} │ {materia_nombre:<23} │ {nota_display:<19} │ {estado:<19} │")
    
    print(f"  └─────────────────┴───────────────────────────┴──────────┴─────────────────────────┴────────────┴────────────┘")
    print(f"\n  {Color.BOLD}Total: {len(calificaciones)} calificación(es){Color.END}\n")
    input(f"{Color.CYAN}Presione ENTER para continuar...{Color.END}")

def cambio_sistema_educativo(student_id, estudiante_completo):
    """Realiza el proceso de conversión y migración a otro sistema educativo"""
    print_header("CAMBIO DE SISTEMA EDUCATIVO")
    
    # Obtener calificaciones actuales
    calificaciones = list(db.calificaciones.find({'student_id': student_id}).sort('created_at', -1))
    
    if not calificaciones:
        print_error("Este estudiante no tiene calificaciones para convertir")
        input(f"\n{Color.CYAN}Presione ENTER para continuar...{Color.END}")
        return
    
    # Identificar sistema actual
    ultima_calificacion = calificaciones[0]
    sistema_actual = ultima_calificacion['institution_snapshot']['system']
    institucion_actual = ultima_calificacion['institution_snapshot']['name']
    institucion_actual_id = ultima_calificacion['institution_snapshot']['institution_id']
    
    print_info(f"Sistema actual: {sistema_actual} ({institucion_actual})")
    print()
    
    # Submenú: Elegir institución destino (INS-001 o INS-002)
    print(f"{Color.BOLD}Instituciones de destino disponibles:{Color.END}\n")
    print(f"  1. INS-001 - Western Cape High School (ZA7, Sudáfrica)")
    print(f"  2. INS-002 - Gauteng Secondary School (ZA7, Sudáfrica)")
    print(f"  3. Volver atrás")
    print()
    
    while True:
        try:
            seleccion = input(f"{Color.CYAN}Seleccione una opción: {Color.END}")
            if seleccion == '3':
                return  # Volver al menú anterior
            elif seleccion in ['1', '2']:
                nueva_institucion_id = 'INS-001' if seleccion == '1' else 'INS-002'
                break
            else:
                print_error("Seleccione 1, 2 o 3")
        except KeyboardInterrupt:
            print("\n")
            return
    
    # Obtener datos de la nueva institución
    nueva_institucion = db.instituciones.find_one({'institution_id': nueva_institucion_id})
    
    if not nueva_institucion:
        print_error(f"No se encontró la institución {nueva_institucion_id}")
        return
    
    nuevo_sistema = nueva_institucion['codigo_sistema']
    nueva_institucion_nombre = nueva_institucion['name']
    
    print_success(f"Destino: {nuevo_sistema} - {nueva_institucion_nombre}\n")
    
    # Confirmar antes de continuar
    print_warning("Esta operación creará NUEVOS registros con calificaciones convertidas.")
    print_warning("Los registros originales NO se modificarán.\n")
    respuesta = input(f"{Color.CYAN}¿Continuar con la conversión? (s/n): {Color.END}").lower()
    if respuesta not in ['s', 'si', 'sí', 'y', 'yes']:
        print("\nOperación cancelada")
        return
    
    # ========================================================================
    # CONVERSIÓN EN REDIS
    # ========================================================================
    print_header("CONVERSIÓN DE CALIFICACIONES")
    
    # Buscar regla de conversión en Redis
    regla_key = f"regla:{sistema_actual}#ZA7:MINISTERIO:SECUNDARIO:2025:1"
    print_info(f"Buscando regla: {regla_key}")
    
    regla_existe = redis_client.exists(regla_key)
    
    if not regla_existe:
        print_error(f"No existe regla de conversión {sistema_actual} → ZA7 en Redis")
        print_warning("Asegúrese de que el seed de Redis esté cargado correctamente")
        return
    
    print_success("Regla de conversión encontrada en Redis\n")
    
    # Obtener mapping de la regla
    mapping_json = redis_client.hget(regla_key, 'mapping')
    if not mapping_json:
        print_error("La regla no tiene mapping definido")
        return
    
    mapping = json.loads(mapping_json)
    
    print(f"  {Color.BOLD}Convirtiendo calificaciones:{Color.END}\n")
    print(f"  ┌──────────────────────────┬─────────────────────┬──────┬─────────────────────┐")
    print(f"  │ {Color.BOLD}Materia{Color.END}                  │ {Color.BOLD}Original{Color.END}            │ {Color.BOLD}→{Color.END}    │ {Color.BOLD}Convertida{Color.END}          │")
    print(f"  ├──────────────────────────┼─────────────────────┼──────┼─────────────────────┤")
    
    calificaciones_convertidas = []
    
    for cal in calificaciones:
        nota_original = cal['evaluation']['grade_value']
        nota_numerica = cal['evaluation']['numeric_value']
        sistema_original = cal['institution_snapshot']['system']
        
        # Solo convertir si el sistema coincide con el actual
        if sistema_original == sistema_actual:
            # Buscar en el mapping
            nota_convertida = None
            
            # Intentar conversión directa
            if str(nota_numerica) in mapping:
                nota_convertida = int(mapping[str(nota_numerica)])
            elif str(int(nota_numerica)) in mapping:
                nota_convertida = int(mapping[str(int(nota_numerica))])
            elif nota_original in mapping:
                nota_convertida = int(mapping[nota_original])
            else:
                # Conversión por aproximación (para sistemas decimales)
                print_warning(f"Valor {nota_original} no encontrado en mapping, usando aproximación")
                nota_convertida = 4  # Valor por defecto
            
            nota_convertida_str = str(nota_convertida)
            passed = nota_convertida >= 4  # ZA7: 4 es aprobado
            
            # Cachear conversión en Redis (TTL 24h)
            conv_key = f"conv:{cal['record_id']}:ZA7:1"
            conv_data = json.dumps({
                'za7': nota_convertida,
                'from_system': sistema_actual,
                'from_value': nota_original,
                'to_system': 'ZA7',
                'to_value': nota_convertida,
                'rule_version': 1,
                'converted_at': datetime.now(timezone.utc).isoformat()
            })
            redis_client.setex(conv_key, 86400, conv_data)
            
            calificaciones_convertidas.append({
                'record_id_original': cal['record_id'],
                'subject_id_original': cal['subject_snapshot']['subject_id'],
                'subject_name': cal['subject_snapshot']['name'],
                'nota_original': nota_numerica,
                'nota_original_str': nota_original,
                'nota_convertida': nota_convertida,
                'nota_convertida_str': nota_convertida_str,
                'passed': passed,
                'materia_data': cal['academic_context']
            })
            
            # Formatear salida en tabla bonita
            materia_display = cal['subject_snapshot']['name'][:24]
            original_display = f"{nota_original} ({sistema_actual})"
            convertida_display = f"{nota_convertida_str} (ZA7)"
            
            print(f"  │ {materia_display:<24} │ {Color.YELLOW}{original_display:>19}{Color.END} │ {Color.BOLD}→{Color.END}    │ {Color.GREEN}{convertida_display:>19}{Color.END} │")
    
    print(f"  └──────────────────────────┴─────────────────────┴──────┴─────────────────────┘")
    print_success(f"\n{len(calificaciones_convertidas)} calificaciones convertidas y cacheadas en Redis\n")
    
    # Confirmar guardado
    print_warning(f"Se crearán {len(calificaciones_convertidas)} nuevos registros en:")
    print(f"  • MongoDB (nuevas calificaciones)")
    print(f"  • Neo4j (nuevas relaciones)")
    print(f"  • Cassandra (auditoría)")
    print()
    
    respuesta = input(f"{Color.CYAN}¿Confirmar y guardar cambios? (s/n): {Color.END}").lower()
    if respuesta not in ['s', 'si', 'sí', 'y', 'yes']:
        print("\n❌ Operación cancelada. No se guardaron cambios.")
        return
    
    # ========================================================================
    # GUARDAR EN MONGODB
    # ========================================================================
    print_header("GUARDANDO EN MONGODB")
    
    timestamp_actual = datetime.now(timezone.utc)
    anio_actual = timestamp_actual.year
    nuevos_record_ids = []
    
    try:
        for i, conv in enumerate(calificaciones_convertidas):
            # Generar nuevo record_id
            nuevo_record_id = f"GR-{anio_actual}-{int(timestamp_actual.timestamp())}-{i:03d}"
            nuevos_record_ids.append(nuevo_record_id)
            
            # Crear nuevo documento de calificación
            nuevo_documento = {
                'record_id': nuevo_record_id,
                'student_id': student_id,
                'zone': nueva_institucion.get('region', 'UNKNOWN'),
                'student_snapshot': {
                    'full_name': estudiante_completo['full_name'],
                    'dob': estudiante_completo['dob'],
                    'nationality': estudiante_completo['nationality'],
                    'documento': estudiante_completo['documento']['numero']
                },
                'institution_snapshot': {
                    'institution_id': nueva_institucion_id,
                    'name': nueva_institucion_nombre,
                    'country': nueva_institucion['country'],
                    'region': nueva_institucion['region'],
                    'system': nuevo_sistema
                },
                'academic_context': {
                    'academic_year': anio_actual,
                    'term': 'T1',
                    'level': conv['materia_data'].get('level', 'Unknown'),
                    'subject_id': conv['subject_id_original'].replace(f'-{sistema_actual}', '-ZA'),
                    'subject_name': conv['subject_name'],
                    'course_code': conv['materia_data'].get('course_code', '').replace(sistema_actual, 'ZA'),
                    'credits': conv['materia_data'].get('credits', 3)
                },
                'subject_snapshot': {
                    'subject_id': conv['subject_id_original'].replace(f'-{sistema_actual}', '-ZA'),
                    'name': conv['subject_name'],
                    'system': nuevo_sistema,
                    'course_code': conv['materia_data'].get('course_code', '').replace(sistema_actual, 'ZA')
                },
                'evaluation': {
                    'scale_type': 'numeric_scale',
                    'grade_value': conv['nota_convertida_str'],
                    'numeric_value': conv['nota_convertida'],
                    'passed': conv['passed'],
                    'passing_threshold': 4.0,
                    'evaluation_date': timestamp_actual.strftime('%Y-%m-%d'),
                    'evaluator': 'Sistema de Conversión'
                },
                'original_grade': {
                    'system': nuevo_sistema,
                    'value': conv['nota_convertida_str'],
                    'scale': '1-7',
                    'range': '1-7'
                },
                'evidence': [],
                'immutability': {
                    'locked': True,
                    'locked_at': timestamp_actual,
                    'locked_by': 'sistema_conversion'
                },
                'history': [
                    {
                        'action': 'CONVERSION',
                        'prev_record_id': conv['record_id_original'],
                        'prev_system': sistema_actual,
                        'prev_institution': institucion_actual_id,
                        'prev_grade': conv['nota_original_str'],
                        'converted_at': timestamp_actual
                    }
                ],
                'created_at': timestamp_actual,
                'updated_at': timestamp_actual
            }
            
            # Insertar en MongoDB
            db.calificaciones.insert_one(nuevo_documento)
            print_success(f"Creado registro {nuevo_record_id}: {conv['subject_name']} - {conv['nota_convertida_str']}")
        
        # Actualizar trayectoria del estudiante
        db.trayectorias.update_one(
            {'student_id': student_id},
            {
                '$addToSet': {'institutions_attended': nueva_institucion_id},
                '$inc': {'total_records': len(calificaciones_convertidas)},
                '$set': {'updated_at': timestamp_actual}
            },
            upsert=True
        )
        
        print_success(f"\n{len(calificaciones_convertidas)} nuevos registros guardados en MongoDB\n")
        
    except Exception as e:
        print_error(f"Error al guardar en MongoDB: {e}")
        return
    
    # ========================================================================
    # ACTUALIZAR NEO4J
    # ========================================================================
    print_header("CREANDO RELACIONES EN NEO4J")
    
    try:
        with neo4j_driver.session() as session:
            # Crear relación ASISTIO entre estudiante e institución
            session.run("""
                MATCH (e:Estudiante {student_id: $student_id})
                MATCH (i:Institucion {institution_id: $institution_id})
                MERGE (e)-[a:ASISTIO {
                    system: $sistema,
                    desde: $fecha
                }]->(i)
            """, student_id=student_id, 
                 institution_id=nueva_institucion_id,
                 fecha=timestamp_actual.strftime('%Y-%m-%d'),
                 sistema=nuevo_sistema)
            
            print_success("Relación ASISTIO creada")
            
            # Crear nodos de Calificacion y sus relaciones
            for i, conv in enumerate(calificaciones_convertidas):
                nuevo_record_id = nuevos_record_ids[i]
                
                session.run("""
                    MATCH (e:Estudiante {student_id: $student_id})
                    CREATE (c:Calificacion {
                        record_id: $record_id,
                        grade_value: $grade_value,
                        system: $system,
                        passed: $passed,
                        created_at: datetime($created_at)
                    })
                    CREATE (e)-[:TIENE_REGISTRO]->(c)
                """, student_id=student_id,
                     record_id=nuevo_record_id,
                     grade_value=conv['nota_convertida_str'],
                     system=nuevo_sistema,
                     passed=conv['passed'],
                     created_at=timestamp_actual.isoformat())
        
        print_success(f"{len(calificaciones_convertidas)} nodos y relaciones creados en Neo4j\n")
        
    except Exception as e:
        print_error(f"Error en Neo4j: {e}")
    
    # ========================================================================
    # REGISTRAR EN CASSANDRA
    # ========================================================================
    print_header("REGISTRANDO AUDITORÍA EN CASSANDRA")
    
    try:
        # Obtener último hash de la cadena
        ultimo_evento = cassandra_session_auditoria.execute(
            "SELECT hash_nuevo FROM registro_auditoria_por_entidad_mes LIMIT 1"
        ).one()
        
        hash_anterior = ultimo_evento.hash_nuevo if ultimo_evento else ''
        
        # Crear eventos de auditoría
        for i, conv in enumerate(calificaciones_convertidas):
            nuevo_record_id = nuevos_record_ids[i]
            aaaamm = timestamp_actual.strftime('%Y%m')
            
            # Payload del evento
            payload = {
                'action': 'SYSTEM_CONVERSION',
                'student_id': student_id,
                'prev_record_id': conv['record_id_original'],
                'new_record_id': nuevo_record_id,
                'prev_system': sistema_actual,
                'new_system': nuevo_sistema,
                'prev_institution': institucion_actual_id,
                'new_institution': nueva_institucion_id,
                'prev_grade': conv['nota_original_str'],
                'new_grade': conv['nota_convertida_str'],
                'subject': conv['subject_name']
            }
            payload_json = json.dumps(payload, ensure_ascii=False)
            
            # Calcular hash blockchain
            hash_data = f"{hash_anterior}{payload_json}{timestamp_actual.isoformat()}"
            hash_nuevo = hashlib.sha256(hash_data.encode()).hexdigest()
            
            # Insertar en Cassandra (estructura correcta de la tabla)
            cassandra_session_auditoria.execute("""
                INSERT INTO registro_auditoria_por_entidad_mes (
                    id_entidad, aaaamm, marca_tiempo, tipo_entidad,
                    accion, id_actor, ip, hash_anterior, hash_nuevo, carga_util
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (nuevo_record_id, aaaamm, timestamp_actual, 'CALIFICACION',
                  'SYSTEM_CONVERSION', 'SYSTEM', 'N/A', hash_anterior, hash_nuevo, payload_json))
            
            hash_anterior = hash_nuevo  # Siguiente en la cadena
        
        print_success(f"{len(calificaciones_convertidas)} eventos de auditoría registrados en Cassandra\n")
        
    except Exception as e:
        print_error(f"Error en Cassandra: {e}")
    
    # ========================================================================
    # RESUMEN FINAL
    # ========================================================================
    print_header("RESUMEN DE CONVERSIÓN")
    
    print(f"  ┌────────────────────────────────────────────────────────────────────┐")
    print(f"  │ {Color.BOLD}{Color.GREEN}✅ CONVERSIÓN EXITOSA{Color.END}                                             │")
    print(f"  ├────────────────────────────────────────────────────────────────────┤")
    print(f"  │  👤 Estudiante:    {Color.BOLD}{estudiante_completo['full_name']:<48}{Color.END}│")
    print(f"  │  📍 Origen:        {Color.YELLOW}{sistema_actual}{Color.END} - {institucion_actual[:40]:<40}│")
    print(f"  │  📍 Destino:       {Color.GREEN}{nuevo_sistema}{Color.END} - {nueva_institucion_nombre[:40]:<40}│")
    print(f"  │  📊 Calificaciones: {Color.BOLD}{len(calificaciones_convertidas)}{Color.END} convertidas y guardadas                │")
    print(f"  └────────────────────────────────────────────────────────────────────┘")
    print()
    
    input(f"{Color.CYAN}Presione ENTER para continuar...{Color.END}")

# ============================================================================
# LOOP PRINCIPAL: SELECCIÓN DE ESTUDIANTE Y MENÚ
# ============================================================================

while True:  # Loop principal para selección de estudiante
    print_header("PASO 1: SELECCIONAR ESTUDIANTE")
    
    # Obtener lista de estudiantes desde MongoDB
    estudiantes = list(db.estudiantes.find({}, {
        'student_id': 1, 
        'full_name': 1, 
        'nationality': 1
    }).sort('student_id', 1))
    
    if not estudiantes:
        print_error("No hay estudiantes en la base de datos")
        exit(1)
    
    print(f"{Color.BOLD}Estudiantes disponibles:{Color.END}\n")
    for i, est in enumerate(estudiantes, 1):
        print(f"  {i}. {Color.BOLD}{est['student_id']}{Color.END} - {est['full_name']} ({est['nationality']})")
    
    print()
    while True:
        try:
            seleccion = input(f"{Color.CYAN}Seleccione el número del estudiante (0 para salir): {Color.END}")
            
            if seleccion == '0':
                print_success("\n¡Hasta luego!")
                mongo_client.close()
                redis_client.close()
                neo4j_driver.close()
                cassandra_cluster.shutdown()
                exit(0)
            
            idx = int(seleccion) - 1
            if 0 <= idx < len(estudiantes):
                estudiante_seleccionado = estudiantes[idx]
                break
            else:
                print_error(f"Ingrese un número entre 0 y {len(estudiantes)}")
        except ValueError:
            print_error("Ingrese un número válido")
        except KeyboardInterrupt:
            print("\n\nOperación cancelada")
            mongo_client.close()
            redis_client.close()
            neo4j_driver.close()
            cassandra_cluster.shutdown()
            exit(0)
    
    student_id = estudiante_seleccionado['student_id']
    print_success(f"Estudiante seleccionado: {student_id} - {estudiante_seleccionado['full_name']}")
    
    # ========================================================================
    # PASO 2: MOSTRAR DATOS ACTUALES (SOLO INFORMACIÓN PERSONAL)
    # ========================================================================
    print_header("PASO 2: DATOS DEL ESTUDIANTE")
    
    # Obtener información completa del estudiante
    estudiante_completo = db.estudiantes.find_one({'student_id': student_id})
    
    print(f"  ┌────────────────────────────────────────────────────────────────────┐")
    print(f"  │ {Color.BOLD}{Color.CYAN}INFORMACIÓN PERSONAL{Color.END}                                              │")
    print(f"  ├────────────────────────────────────────────────────────────────────┤")
    print(f"  │  👤 Nombre:        {Color.BOLD}{estudiante_completo['full_name']:<48}{Color.END}│")
    print(f"  │  🎂 Nacimiento:    {estudiante_completo['dob']:<48}│")
    print(f"  │  🌍 Nacionalidad:  {estudiante_completo['nationality']:<48}│")
    print(f"  │  📋 Documento:     {estudiante_completo['documento']['tipo']} {estudiante_completo['documento']['numero']:<43}│")
    print(f"  │  🆔 Student ID:    {Color.YELLOW}{student_id}{Color.END:<58}│")
    print(f"  └────────────────────────────────────────────────────────────────────┘")
    
    # ========================================================================
    # PASO 3: MENÚ DE OPCIONES (SEGÚN NACIONALIDAD)
    # ========================================================================
    
    es_za = estudiante_seleccionado['nationality'] == 'ZA'
    
    while True:  # Loop del menú de opciones
        print_header("PASO 3: MENÚ DE OPCIONES")
        
        if es_za:
            # Menú para estudiantes ZA (solo 3 opciones)
            print(f"{Color.BOLD}¿Qué desea hacer?{Color.END}\n")
            print(f"  1. Mostrar trayectoria")
            print(f"  2. Ver calificaciones")
            print(f"  3. Volver atrás")
            print()
            
            opciones_validas = ['1', '2', '3']
        else:
            # Menú para estudiantes AR, UK, DE, US (4 opciones)
            print(f"{Color.BOLD}¿Qué desea hacer?{Color.END}\n")
            print(f"  1. Mostrar trayectoria")
            print(f"  2. Ver calificaciones")
            print(f"  3. Cambio de sistema educativo")
            print(f"  4. Volver atrás")
            print()
            
            opciones_validas = ['1', '2', '3', '4']
        
        try:
            opcion = input(f"{Color.CYAN}Seleccione una opción: {Color.END}")
            
            if opcion not in opciones_validas:
                print_error(f"Seleccione una opción válida: {', '.join(opciones_validas)}")
                continue
            
            if opcion == '1':
                # Mostrar trayectoria
                mostrar_trayectoria(student_id)
            
            elif opcion == '2':
                # Ver calificaciones
                ver_calificaciones(student_id)
            
            elif opcion == '3':
                if es_za:
                    # Volver atrás (estudiantes ZA)
                    break
                else:
                    # Cambio de sistema educativo (estudiantes no-ZA)
                    cambio_sistema_educativo(student_id, estudiante_completo)
            
            elif opcion == '4':
                # Volver atrás (estudiantes no-ZA)
                break
        
        except KeyboardInterrupt:
            print("\n")
            break

# Este punto nunca se alcanza debido al while True, pero por seguridad:
mongo_client.close()
redis_client.close()
neo4j_driver.close()
cassandra_cluster.shutdown()
