DROP FUNCTION IF EXISTS persists.create_info(p_record ANYELEMENT);

CREATE OR REPLACE FUNCTION persists.create_info(
    IN p_record ANYELEMENT) RETURNS JSONB AS
$$
DECLARE
    v_oid         INT4;
    v_table_name  TEXT;
    v_schema_name TEXT;
    v_js_result   JSONB;
BEGIN

    SELECT t_class.oid, t_namespace.nspname, t_class.relname
    FROM pg_class t_class
             JOIN pg_namespace t_namespace ON t_class.relnamespace = t_namespace.oid
    WHERE t_class.oid = ((PG_TYPEOF(p_record))::TEXT)::REGCLASS::OID
      AND t_class.relkind IN ('r', 'p')
    INTO v_oid, v_schema_name, v_table_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Element is not a table %', (PG_TYPEOF(p_record))::TEXT;
    END IF;

    v_js_result = JSONB_BUILD_OBJECT(
            'oid', v_oid,
            'schema_name', v_schema_name,
            'table_name', v_table_name,
            'primary_key', (SELECT JSONB_BUILD_OBJECT('name', t_attribute.attname,
                                                      'sequence',
                                                      (PG_GET_SERIAL_SEQUENCE(v_schema_name || '.' || v_table_name,
                                                                              t_attribute.attname)))
                            FROM pg_class t_class
                                     JOIN pg_attribute t_attribute ON t_attribute.attrelid = t_class.oid
                                     JOIN pg_constraint t_contraint
                                          ON t_contraint.conrelid = t_class.oid
                                              AND t_contraint.contype = 'p'
                                              AND
                                             t_attribute.attnum = ANY (t_contraint.conkey)

                            WHERE t_class.oid = v_oid
                              AND t_attribute.attnum > 0
                              AND t_attribute.atttypid > 0),
            'columns', (SELECT ARRAY_AGG(
                                       JSONB_BUILD_OBJECT(
                                               'name', t_attribute.attname,
                                               'nullable', NOT t_attribute.attnotnull,
                                               'foreign_key', CASE
                                                                  WHEN t_contraint.contype = 'f'
                                                                      THEN
                                                                      t_contraint.confrelid::BIGINT
                                                   END
                                           ))
                        FROM pg_class t_class
                                 JOIN pg_attribute t_attribute ON t_attribute.attrelid = t_class.oid
                                 LEFT JOIN pg_constraint t_contraint
                                           ON t_contraint.conrelid = t_class.oid
                                               AND t_contraint.contype = 'f'
                                               AND t_attribute.attnum = ANY (t_contraint.conkey)

                        WHERE t_class.oid = v_oid
                          AND t_attribute.attnum > 0
                          AND t_attribute.atttypid > 0
            )
        );

    IF json_is_null(v_js_result, 'primary_key')
        OR json_is_null(v_js_result -> 'primary_key', 'sequence') THEN
        RAISE EXCEPTION 'Invalid primary key for %', (PG_TYPEOF(p_record))::TEXT;
    END IF;
    RETURN v_js_result;

END
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION persists.create_info(p_record ANYELEMENT) IS
    'Return a jsonb of record definition, must be a table
        p_record::anyelement row type to inspect
    ';