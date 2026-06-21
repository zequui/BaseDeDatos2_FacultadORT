CREATE OR REPLACE PROCEDURE generarPublicacion(
    p_id_agente NUMBER,
    p_id_comunidad NUMBER,
    p_titulo VARCHAR2,
    p_contenido VARCHAR2
)
AS
    v_id_contenido NUMBER;
BEGIN

    IF TRIM(p_titulo) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20401, 'El título de la publicación no puede estar vacío.');
    END IF;

    IF TRIM(p_contenido) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20402, 'El contenido de la publicación no puede estar vacío.');
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

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
