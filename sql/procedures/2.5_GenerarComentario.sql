CREATE OR REPLACE PROCEDURE generarComentario(
    p_id_agente NUMBER,
    p_id_comunidad NUMBER,
    p_contenido CLOB,
    p_id_publicacion NUMBER DEFAULT NULL,
    p_id_comentario_padre NUMBER DEFAULT NULL
)
AS
    v_id_contenido NUMBER;
    v_id_comunidad CONTENIDO.id_comunidad%TYPE;
BEGIN

    IF p_id_publicacion IS NOT NULL THEN
        -- Comentario directo a una publicación: tomar la comunidad de esa publicación
        SELECT id_comunidad
        INTO v_id_comunidad
        FROM CONTENIDO
        WHERE id = p_id_publicacion;

    ELSE
        -- Respuesta a otro comentario: recorrer la cadena hasta encontrar
        -- el comentario que tiene id_publicacion NOT NULL y tomar su comunidad
        SELECT id_comunidad
        INTO v_id_comunidad
        FROM CONTENIDO
        WHERE id = (
            SELECT id_publicacion
            FROM COMENTARIO
            START WITH id = p_id_comentario_padre
            CONNECT BY id = PRIOR id_comentario_padre
                AND id_publicacion IS NULL
        )
        AND ROWNUM = 1;

    END IF;

    INSERT INTO CONTENIDO(
        fechaCreacion,
        horaCreacion,
        id_agente,
        id_comunidad
    )
    VALUES(
        SYSDATE,
        TO_CHAR(SYSDATE,'HH24:MI:SS'),
        p_id_agente,
        v_id_comunidad
    )
    RETURNING id INTO v_id_contenido;

    INSERT INTO COMENTARIO(
        id,
        contenido,
        id_publicacion,
        id_comentario_padre
    )
    VALUES(
        v_id_contenido,
        p_contenido,
        p_id_publicacion,
        p_id_comentario_padre
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
