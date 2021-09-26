CREATE OR REPLACE FUNCTION unit_test.test_persists_create_info() RETURNS SETOF TEXT
AS
$$
DECLARE
    v_info_js        JSONB;
    v_foreign_key_id BIGINT;
BEGIN

    DEALLOCATE ALL;
    SET SEARCH_PATH = tap, public;

    RETURN NEXT tap.plan(29);

    DROP TYPE IF EXISTS unit_test.SAMPLE_TYPE;
    CREATE TYPE unit_test.SAMPLE_TYPE AS
    (
        id BIGINT
    );

    PREPARE stmt AS SELECT *
                    FROM persists.create_info(NULL::unit_test.SAMPLE_TYPE);
    RETURN NEXT tap.throws_ok('stmt', 'P0001', 'Element is not a table unit_test.sample_type', 'Not a table');

    DEALLOCATE stmt;

    DROP TABLE IF EXISTS unit_test.sample_table_1;
    CREATE TABLE unit_test.sample_table_1
    (
        id BIGINT
    );

    PREPARE stmt AS SELECT *
                    FROM persists.create_info(NULL::unit_test.SAMPLE_TABLE_1);
    RETURN NEXT tap.throws_ok('stmt', 'P0001', 'Invalid primary key for unit_test.sample_table_1', 'No primary key');
    DEALLOCATE stmt;

    DROP TABLE IF EXISTS unit_test.sample_table_2;
    CREATE TABLE unit_test.sample_table_2
    (
        id            BIGSERIAL PRIMARY KEY,
        some_text     TEXT,
        not_null_text TEXT NOT NULL
    );

    DROP TABLE IF EXISTS unit_test.sample_table_3;
    CREATE TABLE unit_test.sample_table_3
    (
        id             BIGSERIAL PRIMARY KEY,
        some_reference BIGINT REFERENCES unit_test.sample_table_2
    );

    PREPARE stmt AS SELECT *
                    FROM persists.create_info(NULL::unit_test.SAMPLE_TABLE_2);

    RETURN NEXT tap.lives_ok('stmt', 'Create info success');
    DEALLOCATE stmt;

    SELECT *
    FROM persists.create_info(NULL::unit_test.SAMPLE_TABLE_2)
    INTO v_info_js;

    RETURN NEXT tap.ok(v_info_js ->> 'oid' IS NOT NULL, 'OID');
    RETURN NEXT tap.is(v_info_js ->> 'schema_name', 'unit_test', 'Schema name');
    RETURN NEXT tap.is(v_info_js ->> 'table_name', 'sample_table_2', 'Table name');
    RETURN NEXT tap.is(v_info_js -> 'primary_key' ->> 'name', 'id', 'Primary key name');
    RETURN NEXT tap.is(v_info_js -> 'primary_key' ->> 'sequence', 'unit_test.sample_table_2_id_seq',
                       'Primary key sequence');
    RETURN NEXT tap.is(JSONB_ARRAY_LENGTH(v_info_js -> 'columns'), 3, 'Columns length');

    RETURN NEXT tap.is(v_info_js -> 'columns' -> 0 ->> 'name', 'id', 'Columns #1 name');
    RETURN NEXT tap.is((v_info_js -> 'columns' -> 0 ->> 'foreign_key')::BIGINT, NULL, 'Columns #0 foreign key');
    RETURN NEXT tap.is((v_info_js -> 'columns' -> 0 ->> 'nullable')::BOOLEAN, FALSE, 'Columns #0 nullable');

    RETURN NEXT tap.is(v_info_js -> 'columns' -> 1 ->> 'name', 'some_text', 'Columns #1 name');
    RETURN NEXT tap.is((v_info_js -> 'columns' -> 1 ->> 'foreign_key')::BIGINT, NULL, 'Columns #1 foreign key');
    RETURN NEXT tap.is((v_info_js -> 'columns' -> 1 ->> 'nullable')::BOOLEAN, TRUE, 'Columns #1 nullable');

    RETURN NEXT tap.is(v_info_js -> 'columns' -> 2 ->> 'name', 'not_null_text', 'Columns #2 name');
    RETURN NEXT tap.is((v_info_js -> 'columns' -> 2 ->> 'foreign_key')::BIGINT, NULL, 'Columns #2 foreign key');
    RETURN NEXT tap.is((v_info_js -> 'columns' -> 2 ->> 'nullable')::BOOLEAN, FALSE, 'Columns #2 nullable');

    v_foreign_key_id = (v_info_js ->> 'oid')::BIGINT;

    SELECT *
    FROM persists.create_info(NULL::unit_test.SAMPLE_TABLE_3)
    INTO v_info_js;

    RETURN NEXT tap.is(v_info_js ->> 'schema_name', 'unit_test', 'Schema name');
    RETURN NEXT tap.is(v_info_js ->> 'table_name', 'sample_table_3', 'Table name');
    RETURN NEXT tap.is(v_info_js -> 'primary_key' ->> 'name', 'id', 'Primary key name');
    RETURN NEXT tap.is(v_info_js -> 'primary_key' ->> 'sequence', 'unit_test.sample_table_3_id_seq',
                       'Primary key sequence');
    RETURN NEXT tap.is(JSONB_ARRAY_LENGTH(v_info_js -> 'columns'), 2, 'Columns length');

    RETURN NEXT tap.is(v_info_js -> 'columns' -> 0 ->> 'name', 'id', 'Columns #1 name');
    RETURN NEXT tap.is((v_info_js -> 'columns' -> 0 ->> 'foreign_key')::BIGINT, NULL, 'Columns #0 foreign key');
    RETURN NEXT tap.is((v_info_js -> 'columns' -> 0 ->> 'nullable')::BOOLEAN, FALSE, 'Columns #0 nullable');

    RETURN NEXT tap.is(v_info_js -> 'columns' -> 1 ->> 'name', 'some_reference', 'Columns #1 name');
    RETURN NEXT tap.is((v_info_js -> 'columns' -> 1 ->> 'foreign_key')::BIGINT, v_foreign_key_id, 'Columns #1 foreign key');
    RETURN NEXT tap.is((v_info_js -> 'columns' -> 1 ->> 'nullable')::BOOLEAN, TRUE, 'Columns #1 nullable');


    RETURN NEXT tap.finish();
    RETURN;
END;
$$ LANGUAGE plpgsql;

SELECT *
FROM unit_test.test_persists_create_info();
ROLLBACK;
