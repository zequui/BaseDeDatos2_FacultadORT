CREATE OR REPLACE PROCEDURE actualizarConfiguracion(
    p_id_agente NUMBER,
    p_descripcion VARCHAR2,
    p_configuracion VARCHAR2
)
AS
    v_version NUMBER;
    v_activo_agente AGENTE.activo%TYPE;
BEGIN

    SELECT activo
    INTO v_activo_agente
    FROM AGENTE
    WHERE id = p_id_agente;

    IF v_activo_agente = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20701, 'El agente está suspendido y no puede actualizar su configuración.');
    END IF;

    SELECT NVL(MAX(version),0)
    INTO v_version
    FROM CONFIGURACION
    WHERE id_agente = p_id_agente;

    INSERT INTO CONFIGURACION(
        id_agente,
        version,
        fechaAplicada,
        descripcion,
        configuracion
    )
    VALUES(
        p_id_agente,
        v_version + 1,
        SYSDATE,
        p_descripcion,
        p_configuracion
    );

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
