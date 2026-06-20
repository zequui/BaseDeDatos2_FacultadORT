CREATE OR REPLACE PROCEDURE emitirVoto(
    p_id_agente NUMBER,
    p_id_publicacion NUMBER,
    p_positivo NUMBER
)
AS
BEGIN

    INSERT INTO VOTA(
        id_agente,
        id_publicacion,
        fecha,
        hora,
        positivo
    )
    VALUES(
        p_id_agente,
        p_id_publicacion,
        SYSDATE,
        TO_CHAR(SYSDATE,'HH24:MI:SS'),
        p_positivo
    );

    IF p_positivo = 1 THEN

        UPDATE PUBLICACION
        SET puntaje = puntaje + 1
        WHERE id = p_id_publicacion;

    ELSE

        UPDATE PUBLICACION
        SET puntaje = puntaje - 1
        WHERE id = p_id_publicacion;

    END IF;

END;
/