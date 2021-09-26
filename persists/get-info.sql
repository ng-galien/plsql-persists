DROP FUNCTION IF EXISTS persists.get_info(p_record ANYELEMENT);

CREATE OR REPLACE FUNCTION persists.get_info(
    IN p_record ANYELEMENT) RETURNS JSONB AS
$$
DECLARE
    v_js_info JSONB;
BEGIN

    -- Get cached definition of the table
    SELECT t_definiton.info
    FROM persists.definition t_definiton
    WHERE t_definiton.identifier = (((PG_TYPEOF(p_record))::TEXT)::REGCLASS::OID)::BIGINT
    INTO v_js_info;

    IF FOUND THEN
        RETURN v_js_info;
    END IF;

    -- Not found, insert into cache table
    v_js_info = persists.create_info(p_record);

    IF v_js_info IS NULL THEN
        RAISE EXCEPTION 'No table definition for %', (PG_TYPEOF(p_record))::TEXT;
    END IF;

    INSERT INTO persists.definition(identifier, info)
    VALUES ((v_js_info ->> 'oid')::BIGINT,
            v_js_info);

    RETURN v_js_info;
END
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION persists.get_info(p_record ANYELEMENT) IS
    'Return a cached definition of a table element, create if not exists
        p_record::anyelement table row_type';
