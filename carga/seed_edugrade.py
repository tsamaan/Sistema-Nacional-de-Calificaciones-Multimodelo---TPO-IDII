import argparse
import json
import os
import random
import shlex
import hashlib
from datetime import datetime, timezone
from typing import Dict, Tuple, List

from pymongo import MongoClient, ASCENDING, DESCENDING
from pymongo.errors import CollectionInvalid

from cassandra.cluster import Cluster
from cassandra import ConsistencyLevel

import redis as redis_lib
from neo4j import GraphDatabase


# ---------------------------
# Defaults (Docker Compose)
# ---------------------------
DEFAULT_MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
DEFAULT_REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
DEFAULT_NEO4J_URI = os.getenv("NEO4J_URI", "neo4j://localhost:7687")
DEFAULT_NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
DEFAULT_NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "neo4j")
DEFAULT_CASSANDRA_HOSTS = os.getenv("CASSANDRA_HOSTS", "localhost").split(",")

DEFAULT_DB_NAME = os.getenv("MONGO_DB", "edugrade")

# Files you uploaded (keep same names if you want the script to read them)
DEFAULT_REDIS_FILE = os.getenv("REDIS_SEED_FILE", "levantar estructura en redis.txt")
DEFAULT_NEO4J_FILE = os.getenv("NEO4J_SEED_FILE", "levantar colecciones en neo.txt")


# ---------------------------
# Helpers
# ---------------------------
def now_ts() -> datetime:
    return datetime.now(timezone.utc)


def sha256_hex(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


def read_text_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


# ---------------------------
# MongoDB: schema + indexes
# ---------------------------
def init_mongo(mongo_uri: str, db_name: str) -> None:
    client = MongoClient(mongo_uri)
    db = client[db_name]

    # --- estudiantes (según su DDL) ---
    estudiantes_validator = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["region", "full_name", "documento"],
            "properties": {
                "_id": {"bsonType": ["string", "objectId"]},
                "region": {"bsonType": "string"},
                "full_name": {"bsonType": "string"},
                "documento": {
                    "bsonType": "object",
                    "required": ["tipo", "numero"],
                    "properties": {
                        "tipo": {"bsonType": "string"},
                        "numero": {"bsonType": "string"},
                    },
                },
                "academic_history": {
                    "bsonType": "array",
                    "items": {
                        "bsonType": "object",
                        "required": ["country", "instance_type"],
                        "properties": {
                            "country": {"bsonType": "string"},
                            "instance_type": {"bsonType": "string"},
                            "board": {"bsonType": "string"},
                            "details": {"bsonType": "object"},
                        },
                    },
                },
                "created_at": {"bsonType": "date"},
                "updated_at": {"bsonType": "date"},
            },
        }
    }

    # --- instituciones (según su DDL) ---
    instituciones_validator = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["region", "pais", "codigo_sistema", "nombre"],
            "properties": {
                "_id": {"bsonType": ["string", "objectId"]},
                "region": {"bsonType": "string"},
                "pais": {"bsonType": "string"},
                "codigo_sistema": {"bsonType": "string"},
                "codigo_externo": {"bsonType": "string"},
                "nombre": {"bsonType": "string"},
                "metadata": {"bsonType": "object"},
                "created_at": {"bsonType": "date"},
                "updated_at": {"bsonType": "date"},
            },
        }
    }

    # --- materias (según su DDL) ---
    materias_validator = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["id_institucion", "nombre"],
            "properties": {
                "_id": {"bsonType": ["string", "objectId"]},
                "id_institucion": {"bsonType": ["string", "objectId"]},
                "nombre": {"bsonType": "string"},
                "codigo_sistema": {"bsonType": "string"},
                "codigo_externo": {"bsonType": "string"},
                "metadata": {"bsonType": "object"},
                "created_at": {"bsonType": "date"},
                "updated_at": {"bsonType": "date"},
            },
        }
    }

    # --- trayectorias (según su DDL) ---
    trayectorias_validator = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["id_estudiante", "id_institucion", "fecha_inicio", "estado"],
            "properties": {
                "_id": {"bsonType": ["string", "objectId"]},
                "id_estudiante": {"bsonType": ["string", "objectId"]},
                "id_institucion": {"bsonType": ["string", "objectId"]},
                "fecha_inicio": {"bsonType": "date"},
                "fecha_fin": {"bsonType": ["date", "null"]},
                "estado": {"bsonType": "string"},
                "detalles": {"bsonType": "object"},
                "created_at": {"bsonType": "date"},
                "updated_at": {"bsonType": "date"},
            },
        }
    }

    # --- calificaciones (mínimo viable para 1M + conversiones + inmutabilidad) ---
    calificaciones_validator = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": ["region", "id_estudiante", "id_institucion", "id_materia", "periodo", "original", "inmutabilidad"],
            "properties": {
                "_id": {"bsonType": ["string", "objectId"]},
                "region": {"bsonType": "string"},
                "id_estudiante": {"bsonType": "string"},
                "id_institucion": {"bsonType": "string"},
                "id_materia": {"bsonType": "string"},
                "periodo": {
                    "bsonType": "object",
                    "required": ["anio"],
                    "properties": {
                        "anio": {"bsonType": "int"},
                        "ciclo": {"bsonType": "string"},
                    },
                },
                "evaluacion": {
                    "bsonType": "object",
                    "properties": {
                        "tipo": {"bsonType": "string"},
                        "fecha": {"bsonType": "date"},
                    },
                },
                "original": {
                    "bsonType": "object",
                    "required": ["sistema", "valor_raw", "valor_num_za7"],
                    "properties": {
                        "sistema": {"bsonType": "string"},
                        "valor_raw": {},
                        "valor_num_za7": {"bsonType": ["double", "int"]},
                    },
                },
                "conversiones": {
                    "bsonType": "array",
                    "items": {"bsonType": "object"},
                },
                "auditoria": {
                    "bsonType": "object",
                    "properties": {
                        "id_actor": {"bsonType": "string"},
                        "ip": {"bsonType": "string"},
                        "timestamp": {"bsonType": "date"},
                    },
                },
                "inmutabilidad": {
                    "bsonType": "object",
                    "required": ["version", "hash", "timestamp"],
                    "properties": {
                        "version": {"bsonType": "int"},
                        "anterior": {"bsonType": ["string", "null"]},
                        "hash": {"bsonType": "string"},
                        "timestamp": {"bsonType": "date"},
                        "event_id": {"bsonType": "string"},
                    },
                },
                "created_at": {"bsonType": "date"},
                "updated_at": {"bsonType": "date"},
            },
        }
    }

    def ensure_collection(name: str, validator: dict) -> None:
        try:
            db.create_collection(
                name,
                validator=validator,
                validationLevel="strict",
                validationAction="error",
            )
        except CollectionInvalid:
            pass

    ensure_collection("estudiantes", estudiantes_validator)
    ensure_collection("instituciones", instituciones_validator)
    ensure_collection("materias", materias_validator)
    ensure_collection("trayectorias", trayectorias_validator)
    ensure_collection("calificaciones", calificaciones_validator)

    # Indexes (basados en su DDL + lo típico del doc técnico)
    db.estudiantes.create_index([("documento.tipo", ASCENDING), ("documento.numero", ASCENDING)], unique=True, name="uq_estudiantes_documento")
    db.estudiantes.create_index([("region", ASCENDING)], name="ix_estudiantes_region")

    db.instituciones.create_index([("codigo_sistema", ASCENDING), ("codigo_externo", ASCENDING)], name="ix_instituciones_codigos")
    db.instituciones.create_index([("region", ASCENDING)], name="ix_instituciones_region")

    db.materias.create_index([("id_institucion", ASCENDING), ("nombre", ASCENDING)], name="ix_materias_institucion_nombre")
    db.materias.create_index([("codigo_sistema", ASCENDING), ("codigo_externo", ASCENDING)], name="ix_materias_codigos")

    db.trayectorias.create_index([("id_estudiante", ASCENDING), ("fecha_inicio", DESCENDING)], name="ix_trayectorias_estudiante_fecha")
    db.trayectorias.create_index([("id_institucion", ASCENDING), ("estado", ASCENDING)], name="ix_trayectorias_institucion_estado")

    # Para consultas típicas de calificaciones (estudiante/año/fecha)
    db.calificaciones.create_index([("id_estudiante", ASCENDING), ("periodo.anio", DESCENDING), ("evaluacion.fecha", DESCENDING)], name="ix_calif_est_anio_fecha")
    db.calificaciones.create_index([("id_institucion", ASCENDING), ("periodo.anio", DESCENDING), ("id_materia", ASCENDING)], name="ix_calif_inst_anio_mat")

    print("[OK] MongoDB schema + indexes")


# ---------------------------
# Cassandra: schema
# ---------------------------
CQL_SCHEMA = """
CREATE KEYSPACE IF NOT EXISTS edugrade_analitica
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE KEYSPACE IF NOT EXISTS edugrade_auditoria
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE IF NOT EXISTS edugrade_analitica.promedio_por_region_anio (
  region text,
  anio int,
  codigo_sistema text,
  id_materia text,
  id_institucion text,
  n bigint,
  suma double,
  suma_cuadrados double,
  actualizado_en timestamp,
  PRIMARY KEY ((region, anio), codigo_sistema, id_materia, id_institucion)
) WITH CLUSTERING ORDER BY (codigo_sistema ASC, id_materia ASC, id_institucion ASC);

CREATE TABLE IF NOT EXISTS edugrade_auditoria.registro_auditoria_por_entidad_mes (
  id_entidad text,
  aaaamm text,
  marca_tiempo timestamp,
  tipo_entidad text,
  accion text,
  id_actor text,
  ip text,
  hash_anterior text,
  hash_nuevo text,
  carga_util text,
  PRIMARY KEY ((id_entidad, aaaamm), marca_tiempo)
) WITH CLUSTERING ORDER BY (marca_tiempo DESC);
"""


def init_cassandra(hosts: List[str]) -> None:
    cluster = Cluster(contact_points=[h.strip() for h in hosts if h.strip()])
    session = cluster.connect()

    # Ejecuta sentencias separadas por ';'
    for stmt in [s.strip() for s in CQL_SCHEMA.split(";") if s.strip()]:
        session.execute(stmt)

    print("[OK] Cassandra keyspaces + tables")


# ---------------------------
# Neo4j: constraints + indexes (desde archivo)
# ---------------------------
def init_neo4j(uri: str, user: str, password: str, neo_seed_file: str) -> None:
    driver = GraphDatabase.driver(uri, auth=(user, password))
    cypher = read_text_file(neo_seed_file)

    statements = []
    for chunk in cypher.split(";"):
        s = chunk.strip()
        if s:
            statements.append(s)

    with driver.session() as session:
        for s in statements:
            session.run(s)

    driver.close()
    print("[OK] Neo4j constraints + indexes")


# ---------------------------
# Redis: seed rules/demo (desde archivo)
# ---------------------------
def init_redis(redis_url: str, redis_seed_file: str) -> None:
    r = redis_lib.Redis.from_url(redis_url, decode_responses=True)

    raw = read_text_file(redis_seed_file).splitlines()

    def unquote(s: str) -> str:
        if len(s) >= 2 and ((s[0] == s[-1] == '"') or (s[0] == s[-1] == "'")):
            s = s[1:-1]
        # des-escapa \" -> "
        return s.replace('\\"', '"')

    for line in raw:
        line = line.strip()
        if not line:
            continue
        if line.startswith("-") or line.startswith("/") or line.startswith("Así es") or line[0].isdigit():
            continue
        if not (line.startswith("HSET ") or line.startswith("SETEX ") or line.startswith("SET ")):
            continue

        parts = shlex.split(line)
        cmd = parts[0].upper()

        if cmd == "HSET":
            key = parts[1]
            kv = parts[2:]
            if len(kv) % 2 != 0:
                raise ValueError(f"HSET inválido (cantidad impar de tokens): {line}")
            mapping = {}
            for i in range(0, len(kv), 2):
                field = kv[i]
                value = unquote(kv[i + 1])
                mapping[field] = value
            r.hset(key, mapping=mapping)

        elif cmd == "SET":
            key = parts[1]
            value = unquote(parts[2])
            r.set(key, value)

        elif cmd == "SETEX":
            key = parts[1]
            ttl = int(parts[2])
            value = unquote(parts[3])
            r.setex(key, ttl, value)

    print("[OK] Redis seed rules + demo cache")


# ---------------------------
# Data generation (1M grades)
# ---------------------------
REGIONS = ["AR-BA", "AR-CBA", "US-CA", "US-NY", "DE-BE", "DE-BY", "UK-ENG", "UK-SCT"]
SYSTEMS = ["AR", "US", "DE", "UK"]
YEARS = [2023, 2024, 2025, 2026]
EVAL_TYPES = ["PARCIAL", "FINAL", "RECUP", "EXTRA"]

UK_GRADES = ["A*", "A", "B", "C", "D", "E", "F"]
US_GRADES = ["A", "B", "C", "D", "F"]


def to_za7(system: str, raw_val) -> int:
    # Conversión simple para analítica (demo). Redis guarda reglas versionadas en runtime.
    if system == "UK":
        mapping = {"A*": 7, "A": 6, "B": 5, "C": 4, "D": 3, "E": 2, "F": 1}
        return mapping.get(raw_val, 1)

    if system == "US":
        mapping = {"A": 7, "B": 5, "C": 4, "D": 3, "F": 1}
        return mapping.get(raw_val, 1)

    if system == "DE":
        # 1.0 mejor, 6.0 peor
        x = float(raw_val)
        if x <= 1.5:
            return 7
        if x <= 2.5:
            return 6
        if x <= 3.0:
            return 5
        if x <= 4.0:
            return 4
        if x <= 5.0:
            return 3
        if x <= 5.5:
            return 2
        return 1

    # AR: 1-10
    x = int(raw_val)
    if x >= 10:
        return 7
    if x >= 9:
        return 6
    if x >= 8:
        return 6
    if x >= 7:
        return 5
    if x >= 6:
        return 4
    if x >= 5:
        return 3
    if x >= 4:
        return 2
    return 1


def ensure_base_entities(db) -> Tuple[List[str], List[str], List[str]]:
    """
    Crea un set chico y estable de estudiantes/instituciones/materias para que 1M no explote en cardinalidad.
    """
    students = [f"stu_{i:06d}" for i in range(1, 20001)]  # 20k
    instituciones = []
    materias = []

    # instituciones: 10 por sistema
    for sys in SYSTEMS:
        for i in range(1, 11):
            instituciones.append(f"inst_{sys}_{i:02d}")

    # materias: 20 globales
    for i in range(1, 21):
        materias.append(f"mat_{i:03d}")

    # Insert base docs si faltan
    now = now_ts()

    # estudiantes
    existing = set(doc["_id"] for doc in db.estudiantes.find({}, {"_id": 1}))
    to_insert = []
    for sid in students:
        if sid in existing:
            continue
        to_insert.append({
            "_id": sid,
            "region": random.choice(REGIONS),
            "full_name": f"Student {sid}",
            "documento": {"tipo": "DNI", "numero": sid},
            "academic_history": [],
            "created_at": now,
            "updated_at": now,
        })
    if to_insert:
        db.estudiantes.insert_many(to_insert, ordered=False)

    # instituciones
    existing = set(doc["_id"] for doc in db.instituciones.find({}, {"_id": 1}))
    to_insert = []
    for iid in instituciones:
        if iid in existing:
            continue
        sys = iid.split("_")[1]  # inst_AR_01 -> AR
        region = random.choice([r for r in REGIONS if r.startswith(sys)])
        to_insert.append({
            "_id": iid,
            "region": region,
            "pais": sys,
            "codigo_sistema": sys,
            "codigo_externo": iid,
            "nombre": f"Institucion {iid}",
            "metadata": {},
            "created_at": now,
            "updated_at": now,
        })
    if to_insert:
        db.instituciones.insert_many(to_insert, ordered=False)

    # materias (asignadas random a una institución)
    existing = set(doc["_id"] for doc in db.materias.find({}, {"_id": 1}))
    inst_ids = instituciones
    to_insert = []
    for mid in materias:
        if mid in existing:
            continue
        iid = random.choice(inst_ids)
        sys = iid.split("_")[1]
        to_insert.append({
            "_id": mid,
            "id_institucion": iid,
            "nombre": f"Materia {mid}",
            "codigo_sistema": sys,
            "codigo_externo": mid,
            "metadata": {},
            "created_at": now,
            "updated_at": now,
        })
    if to_insert:
        db.materias.insert_many(to_insert, ordered=False)

    return students, instituciones, materias


def load_grades(
    mongo_uri: str,
    db_name: str,
    cassandra_hosts: List[str],
    n: int,
    batch: int,
    seed: int,
    with_cassandra_rf4: bool,
    with_cassandra_rf5: bool,
) -> None:
    random.seed(seed)

    # Mongo
    client = MongoClient(mongo_uri)
    db = client[db_name]
    calif = db.calificaciones

    students, instituciones, materias = ensure_base_entities(db)

    # Cassandra (optional)
    cass_session = None
    upd_agg = None
    ins_audit = None
    if with_cassandra_rf4 or with_cassandra_rf5:
        cluster = Cluster(contact_points=[h.strip() for h in cassandra_hosts if h.strip()])
        cass_session = cluster.connect()

        if with_cassandra_rf4:
            cass_session.set_keyspace("edugrade_analitica")
            cass_session.default_consistency_level = ConsistencyLevel.ONE
            upd_agg = cass_session.prepare("""
                UPDATE promedio_por_region_anio
                SET n = ?, suma = ?, suma_cuadrados = ?, actualizado_en = ?
                WHERE region = ? AND anio = ? AND codigo_sistema = ? AND id_materia = ? AND id_institucion = ?;
            """)

        if with_cassandra_rf5:
            cass_session.set_keyspace("edugrade_auditoria")
            cass_session.default_consistency_level = ConsistencyLevel.QUORUM
            ins_audit = cass_session.prepare("""
                INSERT INTO registro_auditoria_por_entidad_mes
                (id_entidad, aaaamm, marca_tiempo, tipo_entidad, accion, id_actor, ip, hash_anterior, hash_nuevo, carga_util)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """)

    # In-memory aggregates for RF4
    # key: (region, anio, codigo_sistema, id_materia, id_institucion) -> (n, suma, suma_sq)
    aggs: Dict[Tuple[str, int, str, str, str], Tuple[int, float, float]] = {}

    def pick_raw(system: str):
        if system == "AR":
            return random.randint(1, 10)
        if system == "US":
            return random.choice(US_GRADES)
        if system == "DE":
            return round(random.uniform(1.0, 6.0), 1)
        return random.choice(UK_GRADES)

    inserted = 0
    docs = []

    start = datetime.now(timezone.utc)

    for i in range(1, n + 1):
        grade_id = f"grd_{i:09d}"
        sid = random.choice(students)
        iid = random.choice(instituciones)
        mid = random.choice(materias)

        system = iid.split("_")[1]  # AR/US/DE/UK
        region = random.choice([r for r in REGIONS if r.startswith(system)])
        year = random.choice(YEARS)
        eval_type = random.choice(EVAL_TYPES)

        raw_val = pick_raw(system)
        za7 = to_za7(system, raw_val)

        event_id = f"evt_{grade_id}"
        payload_for_hash = f"{grade_id}|{sid}|{iid}|{mid}|{year}|{system}|{raw_val}|{za7}|{event_id}"
        base_hash = sha256_hex(payload_for_hash)

        doc = {
            "_id": grade_id,
            "region": region,
            "id_estudiante": sid,
            "id_institucion": iid,
            "id_materia": mid,
            "periodo": {"anio": year, "ciclo": "ANUAL"},
            "evaluacion": {"tipo": eval_type, "fecha": datetime(year, random.randint(1, 12), random.randint(1, 28), tzinfo=timezone.utc)},
            "original": {"sistema": system, "valor_raw": raw_val, "valor_num_za7": float(za7)},
            "conversiones": [
                {
                    "to": "ZA7",
                    "version_regla": 1,
                    "resultado": {"za_1_7": za7},
                    "timestamp": now_ts(),
                }
            ],
            "auditoria": {"id_actor": "user_demo", "ip": "127.0.0.1", "timestamp": now_ts()},
            "inmutabilidad": {"version": 1, "anterior": None, "hash": base_hash, "timestamp": now_ts(), "event_id": event_id},
            "created_at": now_ts(),
            "updated_at": now_ts(),
        }

        docs.append(doc)

        # RF4 agg
        if with_cassandra_rf4:
            key = (region, year, system, mid, iid)
            prev = aggs.get(key, (0, 0.0, 0.0))
            new_n = prev[0] + 1
            new_sum = prev[1] + float(za7)
            new_sq = prev[2] + float(za7) * float(za7)
            aggs[key] = (new_n, new_sum, new_sq)

        # RF5 audit (insert per grade)
        if with_cassandra_rf5 and ins_audit is not None:
            aaaamm = f"{year}{random.randint(1,12):02d}"  # demo
            hash_prev = "0"  # solo create en demo
            hash_new = sha256_hex(hash_prev + json.dumps({"id": grade_id, "event": "GRADE_CREATED"}, sort_keys=True))
            cass_session.execute(
                ins_audit,
                (
                    grade_id,
                    aaaamm,
                    now_ts(),
                    "GRADE",
                    "GRADE_CREATED",
                    "user_demo",
                    "127.0.0.1",
                    hash_prev,
                    hash_new,
                    json.dumps({"id_calificacion": grade_id, "sistema": system, "valor_raw": raw_val, "za7": za7}),
                ),
            )

        # flush Mongo batch
        if len(docs) >= batch:
            calif.insert_many(docs, ordered=False)
            inserted += len(docs)
            docs = []
            if inserted % (batch * 10) == 0:
                elapsed = (datetime.now(timezone.utc) - start).total_seconds()
                print(f"[LOAD] Mongo inserted: {inserted}/{n} (elapsed {elapsed:.1f}s)")

    # final flush
    if docs:
        calif.insert_many(docs, ordered=False)
        inserted += len(docs)

    # flush RF4 aggregates (upsert totals)
    if with_cassandra_rf4 and upd_agg is not None:
        cass_session.set_keyspace("edugrade_analitica")
        for (region, year, system, mid, iid), (cnt, s, sq) in aggs.items():
            cass_session.execute(
                upd_agg,
                (int(cnt), float(s), float(sq), now_ts(), region, int(year), system, mid, iid),
            )
        print(f"[OK] Cassandra RF4 aggregates upserted: {len(aggs)} keys")

    print(f"[OK] Mongo calificaciones inserted total: {inserted}")


# ---------------------------
# CLI
# ---------------------------
def main() -> None:
    p = argparse.ArgumentParser("seed_edugrade")
    sub = p.add_subparsers(dest="cmd", required=True)

    p_init = sub.add_parser("init", help="Crea estructuras y seed inicial")
    p_init.add_argument("--mongo", default=DEFAULT_MONGO_URI)
    p_init.add_argument("--db", default=DEFAULT_DB_NAME)
    p_init.add_argument("--redis", default=DEFAULT_REDIS_URL)
    p_init.add_argument("--redis-file", default=DEFAULT_REDIS_FILE)
    p_init.add_argument("--neo4j", default=DEFAULT_NEO4J_URI)
    p_init.add_argument("--neo4j-user", default=DEFAULT_NEO4J_USER)
    p_init.add_argument("--neo4j-pass", default=DEFAULT_NEO4J_PASSWORD)
    p_init.add_argument("--neo4j-file", default=DEFAULT_NEO4J_FILE)
    p_init.add_argument("--cassandra-hosts", default=",".join(DEFAULT_CASSANDRA_HOSTS))

    p_load = sub.add_parser("load", help="Carga masiva (default 1M calificaciones)")
    p_load.add_argument("--mongo", default=DEFAULT_MONGO_URI)
    p_load.add_argument("--db", default=DEFAULT_DB_NAME)
    p_load.add_argument("--cassandra-hosts", default=",".join(DEFAULT_CASSANDRA_HOSTS))
    p_load.add_argument("--n", type=int, default=1_000_000)
    p_load.add_argument("--batch", type=int, default=1000)
    p_load.add_argument("--seed", type=int, default=42)
    p_load.add_argument("--with-rf4", action="store_true", help="Además upsertea agregados en Cassandra RF4")
    p_load.add_argument("--with-rf5", action="store_true", help="Además inserta auditoría en Cassandra RF5")

    args = p.parse_args()

    if args.cmd == "init":
        init_mongo(args.mongo, args.db)
        init_cassandra(args.cassandra_hosts.split(","))
        init_neo4j(args.neo4j, args.neo4j_user, args.neo4j_pass, args.neo4j_file)
        init_redis(args.redis, args.redis_file)

    elif args.cmd == "load":
        load_grades(
            mongo_uri=args.mongo,
            db_name=args.db,
            cassandra_hosts=args.cassandra_hosts.split(","),
            n=args.n,
            batch=args.batch,
            seed=args.seed,
            with_cassandra_rf4=args.with_rf4,
            with_cassandra_rf5=args.with_rf5,
        )


if __name__ == "__main__":
    main()