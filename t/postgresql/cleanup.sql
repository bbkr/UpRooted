SET client_min_messages = warning;
SET session_replication_role = replica;

DROP VIEW IF EXISTS "v1";

-- t1 cascade drop should be enough
-- but explicitly drop every table just in case
DROP TABLE IF EXISTS "t1" CASCADE;
DROP TABLE IF EXISTS "t2" CASCADE;
DROP TABLE IF EXISTS "t3" CASCADE;
DROP TABLE IF EXISTS "t4" CASCADE;
DROP TABLE IF EXISTS "t5" CASCADE;
DROP TABLE IF EXISTS "t6" CASCADE;
DROP TABLE IF EXISTS "t7" CASCADE;
DROP TABLE IF EXISTS "t8" CASCADE;
DROP TABLE IF EXISTS "t9" CASCADE;
