CREATE OR REPLACE PROCEDURE generarPublicacion(
    p_id_agente NUMBER,
    p_id_comunidad NUMBER,
    p_titulo VARCHAR2,
    p_contenido VARCHAR2
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

    INSERT INTO PUBLICACION(
        id,
        titulo,
        contenido
    )
    VALUES(
        v_id_contenido,
        p_titulo,
        p_contenido
    );

END;
/