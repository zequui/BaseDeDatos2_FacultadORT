CREATE OR REPLACE PROCEDURE rankingPublicaciones(
    p_id_comunidad IN NUMBER,
    p_usuario_admin IN VARCHAR2 DEFAULT NULL,
    p_resultado OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_resultado FOR
        SELECT
            p.puntaje AS puntaje_total,
            p.titulo AS titulo_publicacion,
            c.fechaCreacion AS fecha_publicacion,
            a.nombre AS nombre_agente_autor,
            u.mail AS usuario_administrador
        FROM PUBLICACION p
        JOIN CONTENIDO c ON c.id = p.id
        JOIN AGENTE a ON a.id = c.id_agente
        JOIN USUARIO u ON u.mail = a.id_usuario
        WHERE c.id_comunidad = p_id_comunidad
          AND p.estado = 'activa'
          AND c.fechaCreacion >= TRUNC(SYSDATE) - 30
          AND (p_usuario_admin IS NULL OR u.mail = p_usuario_admin)
        ORDER BY p.puntaje DESC, c.fechaCreacion DESC
        FETCH FIRST 10 ROWS ONLY;
END;
/