DROP SCHEMA IF EXISTS persists CASCADE;
CREATE SCHEMA IF NOT EXISTS persists;
CREATE SCHEMA IF NOT EXISTS unit_test;

DROP TABLE IF EXISTS persists.definition;

CREATE TABLE IF NOT EXISTS persists.definition
(

    id         BIGSERIAL PRIMARY KEY,
    identifier BIGINT NOT NULL UNIQUE,
    info       JSONB  NOT NULL
);

CREATE SCHEMA IF NOT EXISTS tap;
CREATE EXTENSION pgtap SCHEMA tap;