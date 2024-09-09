#!/bin/bash

ORIGIN_SERVER=origin
ORIGIN_SCHEMA=origin_${SCHEMA}

psql ${POSTGRES_DB} -U ${POSTGRES_USER}  << EOF
  CREATE SCHEMA IF NOT EXISTS ${SCHEMA};
  CREATE SCHEMA IF NOT EXISTS ${ORIGIN_SCHEMA};

  ALTER ROLE CURRENT_USER SET search_path TO ${SCHEMA};

  CREATE EXTENSION IF NOT EXISTS postgres_fdw;

  CREATE SERVER ${ORIGIN_SERVER}
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host '${REMOTE_HOST}', dbname '${POSTGRES_DB}', port '${REMOTE_PORT}');

  CREATE USER MAPPING FOR ${POSTGRES_USER}
  SERVER ${ORIGIN_SERVER}
  OPTIONS (user '${REMOTE_USER}', password '${REMOTE_PASS}');

  IMPORT FOREIGN SCHEMA ${SCHEMA}
  FROM SERVER ${ORIGIN_SERVER}
  INTO ${ORIGIN_SCHEMA};

  DO \$\$
  DECLARE
      r RECORD;
  BEGIN
      FOR r IN (
          SELECT c.relname AS tablename
          FROM pg_foreign_table ft
          JOIN pg_class c ON ft.ftrelid = c.oid
          JOIN pg_namespace n ON c.relnamespace = n.oid
          WHERE n.nspname = '${ORIGIN_SCHEMA}'
      ) LOOP
          EXECUTE 'ALTER FOREIGN TABLE ${ORIGIN_SCHEMA}.' || quote_ident(r.tablename) || ' OPTIONS (ADD updatable ''false'')';
          EXECUTE 'CREATE VIEW ${SCHEMA}.' || quote_ident(r.tablename) || ' AS SELECT * FROM ${ORIGIN_SCHEMA}.' || quote_ident(r.tablename);
      END LOOP;
  END \$\$;
EOF
