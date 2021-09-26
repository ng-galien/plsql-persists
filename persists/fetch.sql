DROP FUNCTION IF EXISTS persists.fetch(p_record ANYELEMENT, p_record_id BIGINT, p_check_null BOOLEAN);

CREATE OR REPLACE FUNCTION persists.fetch(
    INOUT p_record ANYELEMENT,
    IN p_record_id BIGINT,
    IN p_check_null BOOLEAN DEFAULT TRUE,
    IN p_info JSONB DEFAULT NULL) RETURNS ANYELEMENT AS
$$
DECLARE
    v_definition JSONB;
BEGIN

    IF p_record_id IS NULL OR p_record_id <= 0 THEN
        RAISE EXCEPTION 'Invalid record id ';
    END IF;

    v_definition = COALESCE(p_info, persists.get_info(p_record));

    EXECUTE FORMAT('SELECT * FROM %I.%I WHERE %I=%L',
                   v_definition ->> 'schema_name',
                   v_definition ->> 'table_name',
                   v_definition -> 'primary_key' ->> 'name',
                   p_record_id) INTO p_record;

    IF p_check_null AND NOT FOUND THEN
        RAISE EXCEPTION 'Record not found';
    END IF;
END;

$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION persists.fetch(p_record ANYELEMENT, p_record_id BIGINT, p_check_null BOOLEAN) IS
    'Fetch a row type with the primary key
      p_record::row_type
      p_record_id::bigint the value of the primary key
      p_check_null::boolean, when true raise an error if not found
      p_info::jsonb, optional info of the row type';
