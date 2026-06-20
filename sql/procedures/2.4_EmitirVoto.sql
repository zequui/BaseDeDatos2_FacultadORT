CREATE OR REPLACE PROCEDURE emitirVoto(
    p_id_agente NUMBER,
    p_id_publicacion NUMBER,
    p_positivo NUMBER
)
AS
    v_estado PUBLICACION.estado%TYPE;
BEGIN

    SELECT estado
    INTO v_estado
    FROM PUBLICACION
    WHERE id = p_id_publicacion;

    IF v_estado <> 'activa' THEN
        RAISE_APPLICATION_ERROR(-20501, 'Solo se puede votar en publicaciones con estado activa. Estado actual: ' || v_estado || '.');
    END IF;

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
    -- El puntaje es actualizado automáticamente por TRG 11 (trg_actualizar_puntaje)

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
