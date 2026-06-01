
-- =============================================================
-- RESTRICCIONES NO ESTRUCTURALES (TRIGGERS)
-- =============================================================

-- -------------------------------------------------------------
-- TRG 1: Agente suspendido no puede interactuar
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_contenido_agente_activo
BEFORE INSERT ON CONTENIDO
FOR EACH ROW
DECLARE
    v_activo AGENTE.activo%TYPE;
    v_usr_activo USUARIO.activo%TYPE;
BEGIN
    SELECT a.activo, u.activo
    INTO v_activo, v_usr_activo
    FROM AGENTE a JOIN USUARIO u ON a.id_usuario = u.mail
    WHERE a.id = :NEW.id_agente;

    IF v_activo = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20001, 'El agente está suspendido y no puede generar contenido.');
    END IF;
    IF v_usr_activo = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20002, 'El usuario administrador del agente está suspendido.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_vota_agente_activo
BEFORE INSERT ON VOTA
FOR EACH ROW
DECLARE
    v_activo AGENTE.activo%TYPE;
    v_usr_activo USUARIO.activo%TYPE;
BEGIN
    SELECT a.activo, u.activo
    INTO v_activo, v_usr_activo
    FROM AGENTE a JOIN USUARIO u ON a.id_usuario = u.mail
    WHERE a.id = :NEW.id_agente;

    IF v_activo = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20001, 'El agente está suspendido y no puede votar.');
    END IF;
    IF v_usr_activo = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20002, 'El usuario administrador del agente está suspendido.');
    END IF;
END;
/

-- -------------------------------------------------------------
-- TRG 2: Solo OBSERVADORES pueden votar
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_vota_tipo
BEFORE INSERT ON VOTA
FOR EACH ROW
DECLARE
    v_tipo AGENTE.tipo%TYPE;
BEGIN
    SELECT tipo INTO v_tipo FROM AGENTE WHERE id = :NEW.id_agente;
    IF v_tipo <> 'observador' THEN
        RAISE_APPLICATION_ERROR(-20010, 'Solo los agentes de tipo OBSERVADOR pueden emitir votos.');
    END IF;
END;
/

-- -------------------------------------------------------------
-- TRG 3: Solo GENERADORES pueden crear publicaciones y comentarios
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_publicacion_tipo_agente
BEFORE INSERT ON CONTENIDO
FOR EACH ROW
DECLARE
    v_tipo AGENTE.tipo%TYPE;
BEGIN
    SELECT tipo INTO v_tipo FROM AGENTE WHERE id = :NEW.id_agente;
    IF v_tipo <> 'generador' THEN
        RAISE_APPLICATION_ERROR(-20011,
            'Solo los agentes de tipo GENERADOR pueden crear publicaciones y comentarios.');
    END IF;
END;
/

-- -------------------------------------------------------------
-- TRG 4: Comunidad archivada no permite nuevas publicaciones
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_pub_comunidad_archivada
BEFORE INSERT ON CONTENIDO
FOR EACH ROW
DECLARE
    v_arch COMUNIDAD.archivada%TYPE;
BEGIN
    SELECT archivada INTO v_arch FROM COMUNIDAD WHERE id = :NEW.id_comunidad;
    IF v_arch = 1 THEN
        RAISE_APPLICATION_ERROR(-20020, 'La comunidad está archivada. No se permiten nuevas publicaciones.');
    END IF;
END;
/

-- -------------------------------------------------------------
-- TRG 5: Para publicar en una comunidad el agente debe ser miembro activo
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_pub_miembro_activo
BEFORE INSERT ON CONTENIDO
FOR EACH ROW
DECLARE
    v_tipo_part PARTICIPA.tipo%TYPE;
BEGIN
    BEGIN
        SELECT tipo INTO v_tipo_part
        FROM PARTICIPA
        WHERE id_agente = :NEW.id_agente
          AND id_comunidad = :NEW.id_comunidad;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20030,
                'El agente no pertenece a la comunidad y no puede publicar en ella.');
    END;

    IF v_tipo_part <> 'activo' THEN
        RAISE_APPLICATION_ERROR(-20031,
            'El agente debe ser miembro ACTIVO de la comunidad para generar una publicación.');
    END IF;
END;
/

-- -------------------------------------------------------------
-- TRG 6: Publicación cerrada no admite nuevos comentarios
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_comentario_pub_cerrada
BEFORE INSERT ON COMENTARIO
FOR EACH ROW
DECLARE
    v_estado PUBLICACION.estado%TYPE;
    v_pub_id NUMBER;
BEGIN
    IF :NEW.id_publicacion IS NOT NULL THEN
        v_pub_id := :NEW.id_publicacion;
    ELSE
        SELECT id_publicacion INTO v_pub_id
        FROM   COMENTARIO
        WHERE  id_publicacion IS NOT NULL
        START WITH id = :NEW.id_comentario_padre
        CONNECT BY id = PRIOR id_comentario_padre;  --busca recursivamente el padre
    END IF;

    SELECT estado INTO v_estado FROM PUBLICACION WHERE id = v_pub_id;
    IF v_estado = 'cerrada' THEN
        RAISE_APPLICATION_ERROR(-20040, 'La publicación está cerrada y no admite nuevos comentarios.');
    END IF;
END;
/

-- -------------------------------------------------------------
-- TRG 7: Un agente no puede comentar en una comunidad a la que no pertenece
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_comentario_comunidad
BEFORE INSERT ON CONTENIDO
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM   PARTICIPA
    WHERE  id_agente = :NEW.id_agente
      AND  id_comunidad = :NEW.id_comunidad;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20050,
            'El agente no pertenece a la comunidad y no puede comentar en ella.');
    END IF;
END;
/

-- -------------------------------------------------------------
-- TRG 8: Fecha de configuración no puede ser anterior a la creación del agente
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_config_fecha
BEFORE INSERT ON CONFIGURACION
FOR EACH ROW
DECLARE
    v_fechaCreacion AGENTE.fechaCreacion%TYPE;
BEGIN
    SELECT fechaCreacion INTO v_fechaCreacion FROM AGENTE WHERE id = :NEW.id_agente;
    IF :NEW.fechaAplicada < v_fechaCreacion THEN
        RAISE_APPLICATION_ERROR(-20060,
            'La fecha de aplicación de la configuración no puede ser anterior a la creación del agente.');
    END IF;
END;
/

-- -------------------------------------------------------------
-- TRG 9: Solo MODERADORES pueden intervenir; además deben ser moderadores de ESA comunidad
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_interviene_moderador
BEFORE INSERT ON INTERVIENE
FOR EACH ROW
DECLARE
    v_tipo AGENTE.tipo%TYPE;
    v_tipo_part PARTICIPA.tipo%TYPE;
    v_count NUMBER;
BEGIN
    SELECT tipo INTO v_tipo FROM AGENTE WHERE id = :NEW.id_agente;
    IF v_tipo <> 'moderador' THEN
        RAISE_APPLICATION_ERROR(-20070,
            'Solo los agentes de tipo MODERADOR pueden ejecutar acciones de moderación.');
    END IF;

    BEGIN
        SELECT tipo INTO v_tipo_part
        FROM   PARTICIPA
        WHERE  id_agente = :NEW.id_agente
          AND  id_comunidad = :NEW.id_comunidad;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20071,
                'El agente moderador no pertenece a la comunidad sobre la que intenta intervenir.');
    END;
END;
/

-- -------------------------------------------------------------
-- TRG 10: Cierre de publicación - solo GENERADOR (sus propias) o MODERADOR
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_cierre_publicacion
BEFORE UPDATE OF estado ON PUBLICACION
FOR EACH ROW
DECLARE
    v_tipo AGENTE.tipo%TYPE;
    v_id_agente CONTENIDO.id_agente%TYPE;
BEGIN
    IF :NEW.estado = 'cerrada' AND :NEW.id_agente_cierre IS NOT NULL THEN
        SELECT tipo INTO v_tipo FROM AGENTE WHERE id = :NEW.id_agente_cierre;

        IF v_tipo = 'generador' THEN
            -- El generador solo puede cerrar sus propias publicaciones
            SELECT id_agente INTO v_id_agente FROM CONTENIDO WHERE id = :NEW.id;
            IF v_id_agente <> :NEW.id_agente_cierre THEN
                RAISE_APPLICATION_ERROR(-20080,
                    'Un agente GENERADOR solo puede cerrar sus propias publicaciones.');
            END IF;
        ELSIF v_tipo <> 'moderador' THEN
            RAISE_APPLICATION_ERROR(-20081,
                'Solo agentes GENERADOR (propias) o MODERADOR pueden cerrar publicaciones.');
        END IF;
    END IF;
END;
/

-- -------------------------------------------------------------
-- TRG 11: Actualizar puntaje de publicación al registrar un voto
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_actualizar_puntaje
AFTER INSERT ON VOTA
FOR EACH ROW
BEGIN
    IF :NEW.positivo = 1 THEN
        UPDATE PUBLICACION SET puntaje = puntaje + 1 WHERE id = :NEW.id_publicacion;
    ELSE
        UPDATE PUBLICACION SET puntaje = puntaje - 1 WHERE id = :NEW.id_publicacion;
    END IF;
END;
/

-- -------------------------------------------------------------
-- TRG 12: Transferencia - un agente no puede ser transferido
--          a un usuario que ya lo administra
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_reclama_no_mismo_usuario
BEFORE INSERT ON RECLAMA
FOR EACH ROW
DECLARE
    v_admin VARCHAR2(150);
BEGIN
    SELECT id_usuario INTO v_admin FROM AGENTE WHERE id = :NEW.id_agente;
    IF v_admin = :NEW.id_usuario THEN
        RAISE_APPLICATION_ERROR(-20090,
            'Un agente no puede ser transferido a un usuario que ya lo administra.');
    END IF;
END;
/

-- -------------------------------------------------------------
-- TRG 13: Fecha de aplicación no puede ser futura
-- -------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_config_fecha_futura
BEFORE INSERT OR UPDATE ON CONFIGURACION
FOR EACH ROW
BEGIN
    IF :NEW.fechaAplicada > SYSDATE THEN
        RAISE_APPLICATION_ERROR(
            -20100,
            'La fecha de aplicación de la configuración no puede ser futura.'
        );
    END IF;
END;
/