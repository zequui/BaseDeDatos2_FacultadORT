CREATE OR REPLACE PROCEDURE generarComentario(
    p_id_agente NUMBER,
    p_contenido VARCHAR2,
    p_id_publicacion NUMBER DEFAULT NULL,
    p_id_comentario_padre NUMBER DEFAULT NULL
)
AS
    v_id_contenido NUMBER;
    v_id_comunidad CONTENIDO.id_comunidad%TYPE;
BEGIN

    IF p_id_publicacion IS NOT NULL THEN
        SELECT id_comunidad
        INTO v_id_comunidad
        FROM CONTENIDO
        WHERE id = p_id_publicacion;

    ELSE
        SELECT id_comunidad
        INTO v_id_comunidad
        FROM CONTENIDO
        WHERE id = p_id_comentario_padre;
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