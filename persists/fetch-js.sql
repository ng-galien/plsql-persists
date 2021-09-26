DROP FUNCTION IF EXISTS persists.fetch_record_js(p_record ANYELEMENT, p_js JSONB, p_check_null BOOLEAN);

CREATE OR REPLACE FUNCTION persists.fetch_record_js(
    INOUT p_record ANYELEMENT,
    IN p_js JSONB,
    IN p_check_null BOOLEAN DEFAULT TRUE) RETURNS ANYELEMENT AS
$$
DECLARE
    v_definition JSONB;
BEGIN

    v_definition = persists.get_info(p_record);

    IF p_js IS NULL OR json_is_null(p_js, v_definition -> 'primary_key' ->> 'name') THEN
        RAISE EXCEPTION 'Record id not found';
    END IF;

    PERFORM persists.fetch(p_record := p_record,
                           p_record_id := (JSONB_EXTRACT_PATH_TEXT(p_js, v_definition -> 'primary_key' ->> 'name'))::BIGINT,
                           p_check_null := p_check_null);

END;

$$ LANGUAGE plpgsql STABLE;
