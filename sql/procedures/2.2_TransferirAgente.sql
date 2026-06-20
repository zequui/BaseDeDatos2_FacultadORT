CREATE OR REPLACE PROCEDURE transferirAgente(
    p_id_agente NUMBER,
    p_nuevo_usuario VARCHAR2
)
AS
    v_activo_agente AGENTE.activo%TYPE;
    v_activo_usuario USUARIO.activo%TYPE;
BEGIN

    SELECT activo
    INTO v_activo_agente
    FROM AGENTE
    WHERE id = p_id_agente;

    IF v_activo_agente = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20301, 'El agente está suspendido y no puede ser transferido.');
    END IF;

    SELECT activo
    INTO v_activo_usuario
    FROM USUARIO
    WHERE mail = p_nuevo_usuario;

    IF v_activo_usuario = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20302, 'El usuario destino está suspendido y no puede recibir agentes.');
    END IF;

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

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
