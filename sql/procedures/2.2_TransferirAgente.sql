CREATE OR REPLACE PROCEDURE transferirAgente(
    p_id_agente NUMBER,
    p_nuevo_usuario VARCHAR2
)
AS
BEGIN

    INSERT INTO RECLAMA(
        id_usuario,
        id_agente,
        fechaReclamo,
        fechaAceptacion
    )
    VALUES(
        p_nuevo_usuario,
        p_id_agente,
        SYSDATE,
        SYSDATE
    );

    UPDATE AGENTE
    SET id_usuario = p_nuevo_usuario
    WHERE id = p_id_agente;

END;
/