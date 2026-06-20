CREATE OR REPLACE PROCEDURE registrarAgente(
    p_nombre VARCHAR2,
    p_descripcion VARCHAR2,
    p_tipo VARCHAR2,
    p_id_usuario VARCHAR2,
    p_configuracion VARCHAR2
)
AS
    v_id_agente NUMBER;
    v_activo_usuario USUARIO.activo%TYPE;
BEGIN

    SELECT activo
    INTO v_activo_usuario
    FROM USUARIO
    WHERE mail = p_id_usuario;

    IF v_activo_usuario = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20205, 'El usuario está suspendido y no puede registrar nuevos agentes.');
    END IF;

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

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
