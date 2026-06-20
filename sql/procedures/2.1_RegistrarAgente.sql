CREATE OR REPLACE PROCEDURE registrarAgente(
    p_nombre VARCHAR2,
    p_descripcion VARCHAR2,
    p_tipo VARCHAR2,
    p_id_usuario VARCHAR2,
    p_configuracion VARCHAR2
)
AS
    v_id_agente NUMBER;
BEGIN

    INSERT INTO AGENTE(
        nombre,
        descripcion,
        tipo,
        id_usuario
    )
    VALUES(
        p_nombre,
        p_descripcion,
        p_tipo,
        p_id_usuario
    )
    RETURNING id INTO v_id_agente;

    INSERT INTO CONFIGURACION(
        id_agente,
        version,
        fechaAplicada,
        descripcion,
        configuracion
    )
    VALUES(
        v_id_agente,
        1,
        SYSDATE,
        'Configuración inicial',
        p_configuracion
    );

END;
/