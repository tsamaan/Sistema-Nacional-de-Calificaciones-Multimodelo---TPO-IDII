#!/bin/bash
cd "$(dirname "$0")"
./venv/bin/python carga/seed_edugrade.py init \
  --mongo "mongodb://admin:admin123@localhost:27017" \
  --redis "redis://:redis123@localhost:6379/0" \
  --neo4j-pass "Neo4j2026!" \
  --redis-file "db/levantar estructura en redis.txt" \
  --neo4j-file "db/levantar colecciones en neo.txt"
