CREATE OR REPLACE PROCEDURE generarComentario(
    p_id_agente NUMBER,
    p_id_comunidad NUMBER,
    p_contenido CLOB,
    p_id_publicacion NUMBER DEFAULT NULL,
    p_id_comentario_padre NUMBER DEFAULT NULL
)
AS
    v_id_contenido NUMBER;
BEGIN

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
        p_id_comunidad
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

END;
/