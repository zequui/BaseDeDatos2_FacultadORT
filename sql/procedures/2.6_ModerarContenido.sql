CREATE OR REPLACE PROCEDURE moderarContenido(
    p_id_agente NUMBER,
    p_id_contenido NUMBER,
    p_id_comunidad NUMBER,
    p_tipo VARCHAR2
)
AS
    v_id_comunidad_contenido CONTENIDO.id_comunidad%TYPE;
BEGIN

    IF TRIM(p_tipo) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20601, 'El tipo de moderación no puede estar vacío.');
    END IF;

    SELECT id_comunidad
    INTO v_id_comunidad_contenido
    FROM CONTENIDO
    WHERE id = p_id_contenido;

    IF v_id_comunidad_contenido <> p_id_comunidad THEN
        RAISE_APPLICATION_ERROR(-20602, 'El contenido indicado no pertenece a la comunidad especificada.');
    END IF;

    INSERT INTO INTERVIENE(
        id_agente,
        id_contenido,
        id_comunidad,
        tipo,
        fecha,
        hora
    )
    VALUES(
        p_id_agente,
        p_id_contenido,
        p_id_comunidad,
        p_tipo,
        SYSDATE,
        TO_CHAR(SYSDATE,'HH24:MI:SS')
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/