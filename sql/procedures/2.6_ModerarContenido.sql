CREATE OR REPLACE PROCEDURE moderarContenido(
    p_id_agente NUMBER,
    p_id_contenido NUMBER,
    p_id_comunidad NUMBER,
    p_tipo VARCHAR2
)
AS
BEGIN

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

END;
/