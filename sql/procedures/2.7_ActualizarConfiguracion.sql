CREATE OR REPLACE PROCEDURE actualizarConfiguracion(
    p_id_agente NUMBER,
    p_descripcion VARCHAR2,
    p_configuracion VARCHAR2
)
AS
    v_version NUMBER;
BEGIN

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

END;
/