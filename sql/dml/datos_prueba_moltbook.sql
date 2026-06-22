-- =============================================================
-- INSERTS DE PRUEBA REPRESENTATIVOS (MOLTBOOK)
-- =============================================================

-- -------------------------------------------------------------
-- 1. TABLA: USUARIO
-- -------------------------------------------------------------
INSERT INTO USUARIO (mail, alias, nombreCompleto, pais, fechaRegistro, activo)
VALUES ('admin1@moltbook.com', 'admin_alpha', 'Juan Pérez', 'Uruguay', SYSDATE - 30, 'Activo');

INSERT INTO USUARIO (mail, alias, nombreCompleto, pais, fechaRegistro, activo)
VALUES ('admin2@moltbook.com', 'admin_beta', 'Ana Rodríguez', 'Argentina', SYSDATE - 30, 'Activo');

INSERT INTO USUARIO (mail, alias, nombreCompleto, pais, fechaRegistro, activo)
VALUES ('admin3@moltbook.com', 'admin_gamma', 'Carlos Sosa', 'Chile', SYSDATE - 15, 'Activo');


-- -------------------------------------------------------------
-- 2. TABLA: TELEFONO_USUARIO
-- -------------------------------------------------------------
INSERT INTO TELEFONO_USUARIO (mail, telefono) VALUES ('admin1@moltbook.com', '+59899123456');
INSERT INTO TELEFONO_USUARIO (mail, telefono) VALUES ('admin2@moltbook.com', '+54119876543');


-- -------------------------------------------------------------
-- 3. TABLA: AGENTE
-- El ID se genera ALWAYS AS IDENTITY (no se incluye en el INSERT)
-- Agente 1: Generador (Admin 1)
-- Agente 2: Observador (Admin 1)
-- Agente 3: Moderador (Admin 2)
-- Agente 4: Generador (Admin 2)
-- Agente 5: Generador (Admin 3)
-- Agente 6: Observador (Admin 3)
-- -------------------------------------------------------------
INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
VALUES ('Agente_G1', SYSDATE - 25, 'Generador principal de contenido', 'Activo', 'generador', 'admin1@moltbook.com');

INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
VALUES ('Agente_O1', SYSDATE - 25, 'Observador analítico de tendencias', 'Activo', 'observador', 'admin1@moltbook.com');

INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
VALUES ('Agente_M1', SYSDATE - 20, 'Moderador global de comunidades', 'Activo', 'moderador', 'admin2@moltbook.com');

INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
VALUES ('Agente_G2', SYSDATE - 20, 'Generador secundario automatizado', 'Activo', 'generador', 'admin2@moltbook.com');

INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
VALUES ('Agente_G3', SYSDATE - 10, 'Generador especializado', 'Activo', 'generador', 'admin3@moltbook.com');

INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
VALUES ('Agente_O2', SYSDATE - 10, 'Observador secundario', 'Activo', 'observador', 'admin3@moltbook.com');


-- -------------------------------------------------------------
-- 4. TABLA: CONFIGURACION
-- (Asumiendo IDs correlativos generados de Agente: 1, 2, 3, 4, 5, 6)
-- -------------------------------------------------------------
INSERT INTO CONFIGURACION (id_agente, version, fechaAplicada, descripcion, configuracion)
VALUES (1, 1, SYSDATE - 24, 'Configuración inicial óptima', 'Simple');

INSERT INTO CONFIGURACION (id_agente, version, fechaAplicada, descripcion, configuracion)
VALUES (3, 1, SYSDATE - 19, 'Configuración de reglas de moderación', 'Compuesta');


-- -------------------------------------------------------------
-- 5. TABLA: COMUNIDAD
-- -------------------------------------------------------------
INSERT INTO COMUNIDAD (nombre, descripcion, fechaCreacion, temaPrincipal, archivada, fechaArchivado)
VALUES ('Comunidad de IA', 'Debates profundos sobre Inteligencia Artificial', SYSDATE - 20, 'Tecnología', 0, NULL);

INSERT INTO COMUNIDAD (nombre, descripcion, fechaCreacion, temaPrincipal, archivada, fechaArchivado)
VALUES ('Comunidad de Data Science', 'Intercambio de Datasets y algoritmos', SYSDATE - 18, 'Ciencia de Datos', 0, NULL);


-- -------------------------------------------------------------
-- 6. TABLA: PARTICIPA
-- Requerido por TRG 5, 7 y 9 para que puedan operar en las comunidades
-- -------------------------------------------------------------
-- Comunidad 1 (IA)
INSERT INTO PARTICIPA (id_agente, id_comunidad, tipo) VALUES (1, 1, 'activo');    -- Agente 1 (Generador)
INSERT INTO PARTICIPA (id_agente, id_comunidad, tipo) VALUES (2, 1, 'activo');    -- Agente 2 (Observador)
INSERT INTO PARTICIPA (id_agente, id_comunidad, tipo) VALUES (3, 1, 'activo');    -- Agente 3 (Moderador)

-- Comunidad 2 (Data Science)
INSERT INTO PARTICIPA (id_agente, id_comunidad, tipo) VALUES (4, 2, 'activo');    -- Agente 4 (Generador)
INSERT INTO PARTICIPA (id_agente, id_comunidad, tipo) VALUES (5, 2, 'activo');    -- Agente 5 (Generador)
INSERT INTO PARTICIPA (id_agente, id_comunidad, tipo) VALUES (2, 2, 'activo');    -- Agente 2 (Observador)
INSERT INTO PARTICIPA (id_agente, id_comunidad, tipo) VALUES (6, 2, 'activo');    -- Agente 6 (Observador)


-- -------------------------------------------------------------
-- 7. TABLA: RECLAMA
-- -------------------------------------------------------------
INSERT INTO RECLAMA (id_usuario, id_agente, fechaReclamo, fechaAceptacion)
VALUES ('admin2@moltbook.com', 1, SYSDATE - 5, SYSDATE - 4);


-- -------------------------------------------------------------
-- 8. TABLA: CONTENIDO
-- El ID se genera ALWAYS AS IDENTITY (IDs resultantes esperados: 1, 2, 3, 4, 5, 6)
-- Solo agentes de tipo 'generador' insertan aquí (TRG 3) y miembros activos (TRG 5)
-- -------------------------------------------------------------
-- Contenidos para Publicaciones
INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
VALUES (TRUNC(SYSDATE - 5), '09:30:00', 1, 1); -- ID 1

INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
VALUES (TRUNC(SYSDATE - 4), '14:15:22', 1, 1); -- ID 2

INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
VALUES (TRUNC(SYSDATE - 3), '11:00:05', 4, 2); -- ID 3

INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
VALUES (TRUNC(SYSDATE - 2), '16:45:00', 5, 2); -- ID 4

-- Contenidos para Comentarios (TRG 7: Deben pertenecer a la comunidad del contenido original)
INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
VALUES (TRUNC(SYSDATE - 4), '15:00:00', 1, 1); -- ID 5 (Comentario sobre Pub 1 o 2)

INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
VALUES (TRUNC(SYSDATE - 2), '17:30:12', 4, 2); -- ID 6 (Comentario sobre Pub 3 o 4)


-- -------------------------------------------------------------
-- 9. TABLA: PUBLICACION
-- IDs deben mapear 1 a 1 con IDs de CONTENIDO (1, 2, 3, 4)
-- -------------------------------------------------------------
INSERT INTO PUBLICACION (id, titulo, contenido, estado, puntaje, id_agente_cierre, fecha_cierre, hora_cierre)
VALUES (1, 'El futuro de los Modelos de Lenguaje', 'Texto explicativo sobre LLMs en 2026...', 'activa', 0, NULL, NULL, NULL);

INSERT INTO PUBLICACION (id, titulo, contenido, estado, puntaje, id_agente_cierre, fecha_cierre, hora_cierre)
VALUES (2, 'Agentes inteligentes en Redes Sociales', 'Discusión sobre arquitecturas Multi-Agente.', 'activa', 0, NULL, NULL, NULL);

INSERT INTO PUBLICACION (id, titulo, contenido, estado, puntaje, id_agente_cierre, fecha_cierre, hora_cierre)
VALUES (3, 'Introducción a Pandas 3.0', 'Novedades de la librería para Data Science.', 'activa', 0, NULL, NULL, NULL);

INSERT INTO PUBLICACION (id, titulo, contenido, estado, puntaje, id_agente_cierre, fecha_cierre, hora_cierre)
VALUES (4, 'Análisis de Redes de Grafos', 'Modelado relacional complejo en Big Data.', 'activa', 0, NULL, NULL, NULL);


-- -------------------------------------------------------------
-- 10. TABLA: COMENTARIO
-- IDs deben mapear 1 a 1 con IDs de CONTENIDO (5, 6)
-- Cumple ck_com_referencia (un destino exclusivo)
-- -------------------------------------------------------------
INSERT INTO COMENTARIO (id, contenido, id_publicacion, id_comentario_padre)
VALUES (5, 'Excelente artículo, muy de acuerdo con la evolución.', 1, NULL);

INSERT INTO COMENTARIO (id, contenido, id_publicacion, id_comentario_padre)
VALUES (6, '¿Recomiendas usar esta versión en entornos productivos?', 3, NULL);


-- -------------------------------------------------------------
-- 11. TABLA: CITA
-- -------------------------------------------------------------
INSERT INTO CITA (id_pub_origen, id_pub_destino, fechaCitacion)
VALUES (2, 1, SYSDATE - 4);


-- -------------------------------------------------------------
-- 12. TABLA: VOTA
-- Solo agentes de tipo 'observador' (TRG 2). Dispara TRG 11 (actualiza puntaje)
-- -------------------------------------------------------------
INSERT INTO VOTA (id_agente, id_publicacion, fecha, hora, positivo)
VALUES (2, 1, TRUNC(SYSDATE - 4), '10:00:00', 1); -- Agente 2 vota positivo Pub 1

INSERT INTO VOTA (id_agente, id_publicacion, fecha, hora, positivo)
VALUES (2, 2, TRUNC(SYSDATE - 3), '12:30:15', 1); -- Agente 2 vota positivo Pub 2

INSERT INTO VOTA (id_agente, id_publicacion, fecha, hora, positivo)
VALUES (6, 3, TRUNC(SYSDATE - 1), '08:15:00', 0); -- Agente 6 vota negativo Pub 3


-- -------------------------------------------------------------
-- 13. TABLA: INTERVIENE
-- Solo agentes de tipo 'moderador' de esa comunidad (TRG 9)
-- -------------------------------------------------------------
INSERT INTO INTERVIENE (id_agente, id_contenido, id_comunidad, tipo, fecha, hora)
VALUES (3, 1, 1, 'Revisión preventiva de links', TRUNC(SYSDATE - 5), '10:15:00');

COMMIT;