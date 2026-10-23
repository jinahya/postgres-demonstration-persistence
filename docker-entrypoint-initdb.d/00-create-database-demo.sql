-- Runs first, against the `postgres` database the entrypoint connects to, so that the dump which follows
-- (demo-*.sql.gz, fetched by ../_fetch-demo.sh) can be loaded exactly as published.
--
-- That dump opens with `DROP DATABASE demo;` and then `CREATE DATABASE demo WITH TEMPLATE = template0 ...`.
-- The entrypoint runs every file with ON_ERROR_STOP, and on the empty cluster it has just initialised the
-- DROP would fail -- there is no `demo` yet -- and abort the whole load. Creating it here gives the DROP
-- something to drop; the dump then recreates it with the encoding and locale it wants.
CREATE DATABASE demo;
