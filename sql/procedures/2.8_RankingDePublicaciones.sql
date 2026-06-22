CREATE OR REPLACE PROCEDURE rankingPublicaciones(
    p_id_comunidad IN NUMBER,
    p_usuario_admin IN VARCHAR2 DEFAULT NULL,
    p_resultado OUT SYS_REFCURSOR
)
AS
    v_existe NUMBER;
BEGIN
    -- 1. Validación de existencia de la Comunidad
    SELECT COUNT(*)
    INTO v_existe
    FROM COMUNIDAD
    WHERE id = p_id_comunidad;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20801, 'La comunidad con id ' || p_id_comunidad || ' no existe.');
    END IF;

    -- 2. Validación de existencia del Usuario Administrador (si se envía)
    IF p_usuario_admin IS NOT NULL THEN
        SELECT COUNT(*)
        INTO v_existe
        FROM USUARIO
        WHERE mail = p_usuario_admin;

        IF v_existe = 0 THEN
            RAISE_APPLICATION_ERROR(-20802, 'El usuario administrador ' || p_usuario_admin || ' no existe.');
        END IF;
    END IF;

    -- 3. Apertura del cursor de salida con las 10 mejores publicaciones
    OPEN p_resultado FOR
        SELECT
            p.puntaje AS puntaje_total,
            p.titulo AS titulo_publicacion,
            c.fechaCreacion AS fecha_publicacion,
            a.nombre AS nombre_agente_autor,
            u.mail AS usuario_administrador
        FROM PUBLICACION p
        JOIN CONTENIDO c ON c.id = p.id
        JOIN AGENTE a    ON a.id = c.id_agente
        JOIN USUARIO u   ON u.mail = a.id_usuario
        WHERE c.id_comunidad = p_id_comunidad
          AND p.estado = 'activa'
          AND c.fechaCreacion >= TRUNC(SYSDATE) - 30 -- Evaluación de días completos
          AND (p_usuario_admin IS NULL OR u.mail = p_usuario_admin)
        ORDER BY p.puntaje DESC, c.fechaCreacion DESC -- Desempate por fecha más reciente
        FETCH FIRST 10 ROWS ONLY;
END;
/