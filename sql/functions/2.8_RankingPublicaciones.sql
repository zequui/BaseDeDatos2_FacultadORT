CREATE OR REPLACE FUNCTION rankingPublicaciones(
    p_id_comunidad NUMBER,
    p_usuario VARCHAR2 DEFAULT NULL
)
RETURN SYS_REFCURSOR
AS
    v_cursor SYS_REFCURSOR;
    v_existe NUMBER;
BEGIN

    SELECT COUNT(*)
    INTO v_existe
    FROM COMUNIDAD
    WHERE id = p_id_comunidad;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20801, 'La comunidad con id ' || p_id_comunidad || ' no existe.');
    END IF;

    IF p_usuario IS NOT NULL THEN
        SELECT COUNT(*)
        INTO v_existe
        FROM USUARIO
        WHERE mail = p_usuario;

        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20802, 'El usuario ' || p_usuario || ' no existe.');
        END IF;
    END IF;

    OPEN v_cursor FOR

    SELECT
        p.puntaje,
        p.titulo,
        c.fechaCreacion,
        a.nombre AS agente,
        u.alias AS administrador
    FROM PUBLICACION p
        JOIN CONTENIDO c
            ON p.id = c.id
        JOIN AGENTE a
            ON c.id_agente = a.id
        JOIN USUARIO u
            ON a.id_usuario = u.mail
    WHERE
        c.id_comunidad = p_id_comunidad
        AND p.estado = 'activa'
        AND c.fechaCreacion >= SYSDATE - 30
        AND (
            p_usuario IS NULL
            OR a.id_usuario = p_usuario
        )
    ORDER BY p.puntaje DESC
    FETCH FIRST 10 ROWS ONLY;

    RETURN v_cursor;

END;
/
