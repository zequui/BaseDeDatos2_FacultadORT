SELECT 
    C.nombre AS comunidad,
    A.nombre AS agente_moderador,
    U.alias AS usuario_administrador,
    I.tipo AS tipo_accion,
    EXTRACT(YEAR FROM I.fecha) AS anio,
    EXTRACT(MONTH FROM I.fecha) AS mes,
    COUNT(*) AS total_intervenciones
FROM INTERVIENE I
JOIN AGENTE A ON A.id = I.id_agente
JOIN COMUNIDAD C ON C.id = I.id_comunidad
JOIN USUARIO U ON U.mail = A.id_usuario
GROUP BY C.nombre, A.nombre, U.alias, I.tipo, EXTRACT(YEAR FROM I.fecha), EXTRACT(MONTH FROM I.fecha)
ORDER BY anio, mes, total_intervenciones DESC;