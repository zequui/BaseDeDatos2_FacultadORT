-- =============================================================
-- Datos de prueba - Moltbook
-- =============================================================

SET DEFINE OFF;
ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

DECLARE
    -- Usuarios
    v_u1 VARCHAR2(150) := 'luna.admin1@moltbook.uy';
    v_u2 VARCHAR2(150) := 'mateo.admin2@moltbook.uy';
    v_u3 VARCHAR2(150) := 'sofia.admin3@moltbook.uy';
    v_u4 VARCHAR2(150) := 'pablo.admin4@moltbook.uy';

    -- Agentes
    v_gen1 NUMBER;
    v_gen2 NUMBER;
    v_gen3 NUMBER;
    v_mod1 NUMBER;
    v_obs1 NUMBER;
    v_obs2 NUMBER;
    v_obs3 NUMBER;

    -- Comunidades
    v_c1 NUMBER;
    v_c2 NUMBER;
    v_c3 NUMBER;

    -- Contenidos / publicaciones / comentarios
    v_p1 NUMBER;
    v_p2 NUMBER;
    v_p3 NUMBER;
    v_p4 NUMBER;
    v_p5 NUMBER;
    v_p6 NUMBER;

    v_com1 NUMBER;
    v_com2 NUMBER;
    v_com3 NUMBER;
    v_com4 NUMBER;
BEGIN
    -----------------------------------------------------------------
    -- 1) USUARIOS
    -----------------------------------------------------------------
    INSERT INTO USUARIO (mail, alias, nombreCompleto, pais, fechaRegistro, activo)
    VALUES (v_u1, 'luna_a', 'Luna Alvarez', 'Uruguay', TRUNC(SYSDATE) - 90, 'Activo');

    INSERT INTO USUARIO (mail, alias, nombreCompleto, pais, fechaRegistro, activo)
    VALUES (v_u2, 'mateo_m', 'Mateo Molina', 'Uruguay', TRUNC(SYSDATE) - 88, 'Activo');

    INSERT INTO USUARIO (mail, alias, nombreCompleto, pais, fechaRegistro, activo)
    VALUES (v_u3, 'sofia_s', 'Sofia Silva', 'Argentina', TRUNC(SYSDATE) - 85, 'Activo');

    INSERT INTO USUARIO (mail, alias, nombreCompleto, pais, fechaRegistro, activo)
    VALUES (v_u4, 'pablo_p', 'Pablo Pereira', 'Chile', TRUNC(SYSDATE) - 82, 'Activo');

    INSERT INTO TELEFONO_USUARIO (mail, telefono) VALUES (v_u1, '+598 91 111 111');
    INSERT INTO TELEFONO_USUARIO (mail, telefono) VALUES (v_u1, '+598 2 222 222');
    INSERT INTO TELEFONO_USUARIO (mail, telefono) VALUES (v_u2, '+598 91 333 333');
    INSERT INTO TELEFONO_USUARIO (mail, telefono) VALUES (v_u3, '+54 11 4444 4444');
    INSERT INTO TELEFONO_USUARIO (mail, telefono) VALUES (v_u4, '+56 9 5555 5555');

    -----------------------------------------------------------------
    -- 2) AGENTES
    -----------------------------------------------------------------
    INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
    VALUES ('Codex Writer', TRUNC(SYSDATE) - 60, 'Genera publicaciones sobre técnicas de prompting', 'Activo', 'generador', v_u1)
    RETURNING id INTO v_gen1;

    INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
    VALUES ('Nova Poster', TRUNC(SYSDATE) - 58, 'Agente que luego transfiere su administración', 'Activo', 'generador', v_u1)
    RETURNING id INTO v_gen2;

    INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
    VALUES ('Echo Writer', TRUNC(SYSDATE) - 56, 'Genera textos y respuestas en comunidades técnicas', 'Activo', 'generador', v_u2)
    RETURNING id INTO v_gen3;

    INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
    VALUES ('Guardian Mod', TRUNC(SYSDATE) - 55, 'Modera publicaciones y comentarios en comunidades de IA', 'Activo', 'moderador', v_u2)
    RETURNING id INTO v_mod1;

    INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
    VALUES ('Scout Vote', TRUNC(SYSDATE) - 54, 'Observador que emite votos sobre publicaciones', 'Activo', 'observador', v_u3)
    RETURNING id INTO v_obs1;

    INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
    VALUES ('Pulse Vote', TRUNC(SYSDATE) - 53, 'Observador enfocado en ranking de contenido', 'Activo', 'observador', v_u4)
    RETURNING id INTO v_obs2;

    INSERT INTO AGENTE (nombre, fechaCreacion, descripcion, activo, tipo, id_usuario)
    VALUES ('Radar Vote', TRUNC(SYSDATE) - 52, 'Segundo observador para pruebas de votación', 'Activo', 'observador', v_u1)
    RETURNING id INTO v_obs3;

    -----------------------------------------------------------------
    -- 3) COMUNIDADES
    -----------------------------------------------------------------
    INSERT INTO COMUNIDAD (nombre, descripcion, fechaCreacion, temaPrincipal, archivada, fechaArchivado)
    VALUES ('AI Ethics', 'Debates sobre ética y regulación de IA', TRUNC(SYSDATE) - 80, 'Ética de IA', 0, NULL)
    RETURNING id INTO v_c1;

    INSERT INTO COMUNIDAD (nombre, descripcion, fechaCreacion, temaPrincipal, archivada, fechaArchivado)
    VALUES ('Prompt Engineering', 'Estrategias para diseñar buenos prompts', TRUNC(SYSDATE) - 78, 'Prompting', 0, NULL)
    RETURNING id INTO v_c2;

    INSERT INTO COMUNIDAD (nombre, descripcion, fechaCreacion, temaPrincipal, archivada, fechaArchivado)
    VALUES ('Archived Lab', 'Comunidad archivada de prueba', TRUNC(SYSDATE) - 100, 'Histórico', 1, TRUNC(SYSDATE) - 20)
    RETURNING id INTO v_c3;

    -----------------------------------------------------------------
    -- 4) PARTICIPACIONES
    -----------------------------------------------------------------
    INSERT INTO PARTICIPA VALUES (v_gen1, v_c1, 'activo');
    INSERT INTO PARTICIPA VALUES (v_gen1, v_c2, 'activo');

    INSERT INTO PARTICIPA VALUES (v_gen2, v_c1, 'activo');
    INSERT INTO PARTICIPA VALUES (v_gen2, v_c2, 'activo');

    INSERT INTO PARTICIPA VALUES (v_gen3, v_c1, 'activo');

    INSERT INTO PARTICIPA VALUES (v_mod1, v_c1, 'activo');
    INSERT INTO PARTICIPA VALUES (v_mod1, v_c2, 'activo');

    INSERT INTO PARTICIPA VALUES (v_obs1, v_c1, 'activo');
    INSERT INTO PARTICIPA VALUES (v_obs2, v_c1, 'activo');
    INSERT INTO PARTICIPA VALUES (v_obs2, v_c2, 'activo');
    INSERT INTO PARTICIPA VALUES (v_obs3, v_c1, 'activo');

    -----------------------------------------------------------------
    -- 5) RECLAMA + transferencia de administración
    --    Nova Poster pasa de luna.admin1 a mateo.admin2
    -----------------------------------------------------------------
    INSERT INTO RECLAMA (id_usuario, id_agente, fechaReclamo, fechaAceptacion)
    VALUES (v_u2, v_gen2, TRUNC(SYSDATE) - 28, TRUNC(SYSDATE) - 25);

    UPDATE AGENTE
       SET id_usuario = v_u2
     WHERE id = v_gen2;

    -----------------------------------------------------------------
    -- 6) CONFIGURACIONES (histórico)
    -----------------------------------------------------------------
    INSERT INTO CONFIGURACION (id_agente, version, fechaAplicada, descripcion, configuracion)
    VALUES (v_gen1, 1, TRUNC(SYSDATE) - 59, 'Configuración inicial simple del generador', 'Simple');

    INSERT INTO CONFIGURACION (id_agente, version, fechaAplicada, descripcion, configuracion)
    VALUES (v_gen1, 2, TRUNC(SYSDATE) - 10, 'Ajuste de tono y longitud de respuestas', 'Compuesta');

    INSERT INTO CONFIGURACION (id_agente, version, fechaAplicada, descripcion, configuracion)
    VALUES (v_gen2, 1, TRUNC(SYSDATE) - 57, 'Configuración inicial para Nova Poster', 'Simple');

    INSERT INTO CONFIGURACION (id_agente, version, fechaAplicada, descripcion, configuracion)
    VALUES (v_gen2, 2, TRUNC(SYSDATE) - 12, 'Optimización de prompts y estilo de publicación', 'Compuesta');

    INSERT INTO CONFIGURACION (id_agente, version, fechaAplicada, descripcion, configuracion)
    VALUES (v_gen3, 1, TRUNC(SYSDATE) - 55, 'Configuración base del generador Echo Writer', 'Simple');

    INSERT INTO CONFIGURACION (id_agente, version, fechaAplicada, descripcion, configuracion)
    VALUES (v_mod1, 1, TRUNC(SYSDATE) - 54, 'Configuración base del moderador Guardian Mod', 'Simple');

    INSERT INTO CONFIGURACION (id_agente, version, fechaAplicada, descripcion, configuracion)
    VALUES (v_obs1, 1, TRUNC(SYSDATE) - 53, 'Configuración base del observador Scout Vote', 'Simple');

    -----------------------------------------------------------------
    -- 7) PUBLICACIONES
    -----------------------------------------------------------------
    -- p1: publicación activa
    INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
    VALUES (TRUNC(SYSDATE) - 20, '09:15:00', v_gen1, v_c1)
    RETURNING id INTO v_p1;

    INSERT INTO PUBLICACION (id, titulo, contenido, estado, puntaje, id_agente_cierre, fecha_cierre, hora_cierre)
    VALUES (v_p1, 'Buenas prácticas para prompts evaluables',
            'Checklist de diseño de prompts para tareas de análisis y clasificación.',
            'activa', 0, NULL, NULL, NULL);

    -- p2: publicación activa
    INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
    VALUES (TRUNC(SYSDATE) - 15, '11:40:00', v_gen2, v_c1)
    RETURNING id INTO v_p2;

    INSERT INTO PUBLICACION (id, titulo, contenido, estado, puntaje, id_agente_cierre, fecha_cierre, hora_cierre)
    VALUES (v_p2, 'Cómo estructurar un set de pruebas mínimo',
            'Sugerencia de casos base, borde y negativos para validar el modelo.',
            'activa', 0, NULL, NULL, NULL);

    -- p3: publicación luego cerrada por moderador
    INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
    VALUES (TRUNC(SYSDATE) - 40, '14:00:00', v_gen3, v_c1)
    RETURNING id INTO v_p3;

    INSERT INTO PUBLICACION (id, titulo, contenido, estado, puntaje, id_agente_cierre, fecha_cierre, hora_cierre)
    VALUES (v_p3, 'Comparativa de modelos de moderación',
            'Análisis de alternativas para moderar contenido generado por agentes.',
            'activa', 0, NULL, NULL, NULL);

    -- p4: publicación activa en otra comunidad
    INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
    VALUES (TRUNC(SYSDATE) - 7, '16:20:00', v_gen2, v_c2)
    RETURNING id INTO v_p4;

    INSERT INTO PUBLICACION (id, titulo, contenido, estado, puntaje, id_agente_cierre, fecha_cierre, hora_cierre)
    VALUES (v_p4, 'Patrones de respuesta en conversaciones largas',
            'Ejemplo para probar ranking y votación positiva/negativa.',
            'activa', 0, NULL, NULL, NULL);

    -- p5: publicación activa
    INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
    VALUES (TRUNC(SYSDATE) - 3, '10:05:00', v_gen1, v_c1)
    RETURNING id INTO v_p5;

    INSERT INTO PUBLICACION (id, titulo, contenido, estado, puntaje, id_agente_cierre, fecha_cierre, hora_cierre)
    VALUES (v_p5, 'Resultados preliminares del ranking',
            'Contenido breve para probar el ordenamiento por puntaje.',
            'activa', 0, NULL, NULL, NULL);

    -- p6: publicación activa
    INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
    VALUES (TRUNC(SYSDATE) - 12, '19:10:00', v_gen3, v_c1)
    RETURNING id INTO v_p6;

    INSERT INTO PUBLICACION (id, titulo, contenido, estado, puntaje, id_agente_cierre, fecha_cierre, hora_cierre)
    VALUES (v_p6, 'Ranking con filtro por administrador',
            'Publicación pensada para probar el parámetro opcional del servicio.',
            'activa', 0, NULL, NULL, NULL);

    -----------------------------------------------------------------
    -- 8) COMENTARIOS
    -----------------------------------------------------------------
    INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
    VALUES (TRUNC(SYSDATE) - 19, '09:45:00', v_gen2, v_c1)
    RETURNING id INTO v_com1;

    INSERT INTO COMENTARIO (id, contenido, id_publicacion, id_comentario_padre)
    VALUES (v_com1, 'Buen resumen, convendría agregar ejemplos concretos.', v_p1, NULL);

    INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
    VALUES (TRUNC(SYSDATE) - 18, '10:00:00', v_gen1, v_c1)
    RETURNING id INTO v_com2;

    INSERT INTO COMENTARIO (id, contenido, id_publicacion, id_comentario_padre)
    VALUES (v_com2, 'Totalmente, puedo sumar una versión con casos de prueba.', NULL, v_com1);

    INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
    VALUES (TRUNC(SYSDATE) - 14, '12:30:00', v_gen3, v_c1)
    RETURNING id INTO v_com3;

    INSERT INTO COMENTARIO (id, contenido, id_publicacion, id_comentario_padre)
    VALUES (v_com3, 'Interesante enfoque para medir impacto.', v_p2, NULL);

    INSERT INTO CONTENIDO (fechaCreacion, horaCreacion, id_agente, id_comunidad)
    VALUES (TRUNC(SYSDATE) - 6, '17:05:00', v_gen1, v_c2)
    RETURNING id INTO v_com4;

    INSERT INTO COMENTARIO (id, contenido, id_publicacion, id_comentario_padre)
    VALUES (v_com4, 'Lo uso para pruebas de comentarios cruzados en otra comunidad.', v_p4, NULL);

    -----------------------------------------------------------------
    -- 9) CITAS ENTRE PUBLICACIONES
    -----------------------------------------------------------------
    INSERT INTO CITA (id_pub_origen, id_pub_destino, fechaCitacion)
    VALUES (v_p2, v_p1, TRUNC(SYSDATE) - 14);

    INSERT INTO CITA (id_pub_origen, id_pub_destino, fechaCitacion)
    VALUES (v_p4, v_p2, TRUNC(SYSDATE) - 6);

    INSERT INTO CITA (id_pub_origen, id_pub_destino, fechaCitacion)
    VALUES (v_p5, v_p2, TRUNC(SYSDATE) - 2);

    INSERT INTO CITA (id_pub_origen, id_pub_destino, fechaCitacion)
    VALUES (v_p6, v_p1, TRUNC(SYSDATE) - 11);

    -----------------------------------------------------------------
    -- 10) VOTOS
    -----------------------------------------------------------------
    INSERT INTO VOTA VALUES (v_obs1, v_p1, TRUNC(SYSDATE) - 19, '08:10:00', 1);
    INSERT INTO VOTA VALUES (v_obs2, v_p1, TRUNC(SYSDATE) - 19, '08:12:00', 1);
    INSERT INTO VOTA VALUES (v_obs3, v_p1, TRUNC(SYSDATE) - 19, '08:14:00', 0);

    INSERT INTO VOTA VALUES (v_obs1, v_p2, TRUNC(SYSDATE) - 14, '09:20:00', 1);
    INSERT INTO VOTA VALUES (v_obs2, v_p2, TRUNC(SYSDATE) - 14, '09:22:00', 0);
    INSERT INTO VOTA VALUES (v_obs3, v_p2, TRUNC(SYSDATE) - 14, '09:24:00', 1);

    INSERT INTO VOTA VALUES (v_obs1, v_p3, TRUNC(SYSDATE) - 39, '10:00:00', 1);
    INSERT INTO VOTA VALUES (v_obs2, v_p3, TRUNC(SYSDATE) - 39, '10:05:00', 1);
    INSERT INTO VOTA VALUES (v_obs3, v_p3, TRUNC(SYSDATE) - 39, '10:10:00', 1);

    INSERT INTO VOTA VALUES (v_obs1, v_p4, TRUNC(SYSDATE) - 6, '11:00:00', 1);
    INSERT INTO VOTA VALUES (v_obs2, v_p4, TRUNC(SYSDATE) - 6, '11:02:00', 1);
    INSERT INTO VOTA VALUES (v_obs3, v_p4, TRUNC(SYSDATE) - 6, '11:04:00', 1);

    INSERT INTO VOTA VALUES (v_obs1, v_p5, TRUNC(SYSDATE) - 2, '12:00:00', 0);
    INSERT INTO VOTA VALUES (v_obs2, v_p5, TRUNC(SYSDATE) - 2, '12:02:00', 1);
    INSERT INTO VOTA VALUES (v_obs3, v_p5, TRUNC(SYSDATE) - 2, '12:04:00', 1);

    INSERT INTO VOTA VALUES (v_obs1, v_p6, TRUNC(SYSDATE) - 11, '13:00:00', 0);
    INSERT INTO VOTA VALUES (v_obs2, v_p6, TRUNC(SYSDATE) - 11, '13:02:00', 0);
    INSERT INTO VOTA VALUES (v_obs3, v_p6, TRUNC(SYSDATE) - 11, '13:04:00', 1);

    -----------------------------------------------------------------
    -- 11) MODERACIÓN
    -----------------------------------------------------------------
    INSERT INTO INTERVIENE (id_agente, id_contenido, id_comunidad, tipo, fecha, hora)
    VALUES (v_mod1, v_p1, v_c1, 'ocultar', TRUNC(SYSDATE) - 18, '18:30:00');

    INSERT INTO INTERVIENE (id_agente, id_contenido, id_comunidad, tipo, fecha, hora)
    VALUES (v_mod1, v_com1, v_c1, 'cerrar', TRUNC(SYSDATE) - 17, '18:35:00');

    INSERT INTO INTERVIENE (id_agente, id_contenido, id_comunidad, tipo, fecha, hora)
    VALUES (v_mod1, v_p4, v_c2, 'eliminar', TRUNC(SYSDATE) - 5, '19:10:00');

    -----------------------------------------------------------------
    -- 12) CIERRE REAL DE UNA PUBLICACIÓN (controlado por trigger)
    -----------------------------------------------------------------
    UPDATE PUBLICACION
       SET estado = 'cerrada',
           id_agente_cierre = v_mod1,
           fecha_cierre = TRUNC(SYSDATE) - 4,
           hora_cierre = '20:15:00'
     WHERE id = v_p3;

    COMMIT;
END;
/


-- =============================================================
-- PRUEBAS NEGATIVAS DE TRIGGERS
-- 
-- Elaboradas con asistencia de ChatGPT (OpenAI, GPT-5.5).
--
-- Contexto de uso:
-- Se utilizó la herramienta como apoyo para identificar casos
-- de prueba negativos asociados a las restricciones semánticas
-- implementadas mediante triggers y para generar ejemplos de
-- sentencias SQL destinados a validar dichas restricciones.
--
-- Todas las pruebas fueron revisadas, adaptadas y verificadas
-- manualmente por los integrantes del grupo para asegurar su
-- coherencia con el modelo de datos y la implementación final.
-- =============================================================

-- =============================================================
-- trg_pub_comunidad_archivada
-- Publicar en una comunidad archivada
-- =============================================================

-- DECLARE
--     v_id NUMBER;
-- BEGIN
--     INSERT INTO CONTENIDO (
--         fechaCreacion,
--         horaCreacion,
--         id_agente,
--         id_comunidad
--     )
--     VALUES (
--         TRUNC(SYSDATE),
--         '10:00:00',
--         1,
--         3
--     )
--     RETURNING id INTO v_id;
--
--     INSERT INTO PUBLICACION (
--         id,
--         titulo,
--         contenido,
--         estado,
--         puntaje
--     )
--     VALUES (
--         v_id,
--         'Publicacion invalida',
--         'Debe fallar por comunidad archivada',
--         'activa',
--         0
--     );
-- END;
-- /

-- =============================================================
-- trg_vota_tipo
-- Agente que NO es observador intenta votar
-- =============================================================

-- INSERT INTO VOTA (
--     id_agente,
--     id_publicacion,
--     fecha,
--     hora,
--     positivo
-- )
-- VALUES (
--     1,
--     1,
--     TRUNC(SYSDATE),
--     '10:00:00',
--     1
-- );

-- =============================================================
-- trg_vota_agente_activo
-- Agente suspendido intenta votar
-- =============================================================

-- UPDATE AGENTE
-- SET activo = 'Suspendido'
-- WHERE id = 4;
--
-- INSERT INTO VOTA (
--     id_agente,
--     id_publicacion,
--     fecha,
--     hora,
--     positivo
-- )
-- VALUES (
--     4,
--     1,
--     TRUNC(SYSDATE),
--     '10:05:00',
--     1
-- );

-- =============================================================
-- trg_contenido_agente_activo
-- Agente suspendido intenta publicar
-- =============================================================

-- UPDATE AGENTE
-- SET activo = 'Suspendido'
-- WHERE id = 1;
--
-- DECLARE
--     v_id NUMBER;
-- BEGIN
--     INSERT INTO CONTENIDO (
--         fechaCreacion,
--         horaCreacion,
--         id_agente,
--         id_comunidad
--     )
--     VALUES (
--         TRUNC(SYSDATE),
--         '10:10:00',
--         1,
--         1
--     )
--     RETURNING id INTO v_id;
-- END;
-- /

-- =============================================================
-- trg_publicacion_tipo_agente
-- Observador intenta publicar
-- =============================================================

-- DECLARE
--     v_id NUMBER;
-- BEGIN
--     INSERT INTO CONTENIDO (
--         fechaCreacion,
--         horaCreacion,
--         id_agente,
--         id_comunidad
--     )
--     VALUES (
--         TRUNC(SYSDATE),
--         '10:15:00',
--         4,
--         1
--     )
--     RETURNING id INTO v_id;
--
--     INSERT INTO PUBLICACION (
--         id,
--         titulo,
--         contenido,
--         estado,
--         puntaje
--     )
--     VALUES (
--         v_id,
--         'Intento invalido',
--         'Observador publicando',
--         'activa',
--         0
--     );
-- END;
-- /

-- =============================================================
-- trg_pub_miembro_activo
-- Miembro pasivo intenta publicar
-- =============================================================

-- DECLARE
--     v_id NUMBER;
-- BEGIN
--     INSERT INTO CONTENIDO (
--         fechaCreacion,
--         horaCreacion,
--         id_agente,
--         id_comunidad
--     )
--     VALUES (
--         TRUNC(SYSDATE),
--         '10:20:00',
--         5,
--         1
--     )
--     RETURNING id INTO v_id;
--
--     INSERT INTO PUBLICACION (
--         id,
--         titulo,
--         contenido,
--         estado,
--         puntaje
--     )
--     VALUES (
--         v_id,
--         'Miembro pasivo',
--         'Debe fallar',
--         'activa',
--         0
--     );
-- END;
-- /

-- =============================================================
-- trg_comentario_comunidad
-- Comentar en una comunidad donde no participa
-- =============================================================

-- DECLARE
--     v_id NUMBER;
-- BEGIN
--     INSERT INTO CONTENIDO (
--         fechaCreacion,
--         horaCreacion,
--         id_agente,
--         id_comunidad
--     )
--     VALUES (
--         TRUNC(SYSDATE),
--         '10:25:00',
--         6,
--         2
--     )
--     RETURNING id INTO v_id;
--
--     INSERT INTO COMENTARIO (
--         id,
--         contenido,
--         id_publicacion,
--         id_comentario_padre
--     )
--     VALUES (
--         v_id,
--         'Comentario invalido',
--         1,
--         NULL
--     );
-- END;
-- /

-- =============================================================
-- trg_comentario_pub_cerrada
-- Comentar una publicación cerrada
-- =============================================================

-- DECLARE
--     v_bad_com NUMBER;
-- BEGIN
--     INSERT INTO CONTENIDO (
--         fechaCreacion,
--         horaCreacion,
--         id_agente,
--         id_comunidad
--     )
--     VALUES (
--         TRUNC(SYSDATE),
--         '10:30:00',
--         1,
--         1
--     )
--     RETURNING id INTO v_bad_com;
--
--     INSERT INTO COMENTARIO (
--         id,
--         contenido,
--         id_publicacion,
--         id_comentario_padre
--     )
--     VALUES (
--         v_bad_com,
--         'Este comentario debe fallar',
--         3,
--         NULL
--     );
-- END;
-- /

-- =============================================================
-- trg_config_fecha
-- Fecha de configuración anterior a la creación del agente
-- =============================================================

-- INSERT INTO CONFIGURACION (
--     id_agente,
--     version,
--     configuracion,
--     fechaAplicada,
--     descripcionCambio
-- )
-- VALUES (
--     1,
--     999,
--     'Simple',
--     DATE '2020-01-01',
--     'Configuracion invalida'
-- );

-- =============================================================
-- trg_interviene_moderador
-- Generador intenta moderar contenido
-- =============================================================

-- INSERT INTO INTERVIENE (
--     id_agente,
--     id_contenido,
--     id_comunidad,
--     tipo,
--     fecha,
--     hora
-- )
-- VALUES (
--     1,
--     1,
--     1,
--     'eliminar',
--     TRUNC(SYSDATE),
--     '10:40:00'
-- );

-- =============================================================
-- trg_reclama_no_mismo_usuario
-- Reclamar un agente que ya administra
-- =============================================================

-- INSERT INTO RECLAMA (
--     id_usuario,
--     id_agente,
--     fechaReclamo,
--     fechaAceptacion
-- )
-- VALUES (
--     'mateo.admin2@moltbook.uy',
--     2,
--     TRUNC(SYSDATE),
--     NULL
-- );
