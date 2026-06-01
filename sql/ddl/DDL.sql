-- =============================================================
-- DDL MOLTBOOK - Bases de Datos 2 (ORT)
-- =============================================================

-- -------------------------------------------------------------
-- TABLA: USUARIO
-- -------------------------------------------------------------
CREATE TABLE USUARIO (
    mail VARCHAR2(150) NOT NULL,
    alias VARCHAR2(50) NOT NULL,
    nombreCompleto VARCHAR2(200) NOT NULL,
    pais VARCHAR2(100) NOT NULL,
    fechaRegistro DATE DEFAULT SYSDATE NOT NULL,
    activo VARCHAR2(10) DEFAULT 'Activo' NOT NULL,
    CONSTRAINT pk_usuario PRIMARY KEY (mail),
    CONSTRAINT uq_usuario_alias UNIQUE (alias),
    CONSTRAINT ck_usuario_activo CHECK (activo IN ('Activo', 'Suspendido'))
);
-- -------------------------------------------------------------
-- TABLA: TELEFONO_USUARIO
-- -------------------------------------------------------------
CREATE TABLE TELEFONO_USUARIO (
    mail VARCHAR2(150) NOT NULL,
    telefono VARCHAR2(30) NOT NULL,
    CONSTRAINT pk_telefono_usuario PRIMARY KEY (mail, telefono),
    CONSTRAINT fk_telef_usuario FOREIGN KEY (mail) REFERENCES USUARIO(mail)
);

-- -------------------------------------------------------------
-- TABLA: AGENTE
-- -------------------------------------------------------------
CREATE TABLE AGENTE (
    id NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre VARCHAR2(200) NOT NULL,
    fechaCreacion DATE DEFAULT SYSDATE NOT NULL,
    descripcion VARCHAR2(500),
    activo VARCHAR2(10) DEFAULT 'Activo' NOT NULL,
    tipo VARCHAR2(20) NOT NULL,
    id_usuario VARCHAR2(150) NOT NULL,
    CONSTRAINT pk_agente PRIMARY KEY (id),
    CONSTRAINT fk_agente_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(mail),
    CONSTRAINT ck_agente_activo CHECK (activo IN ('Activo', 'Suspendido')),
    CONSTRAINT ck_agente_tipo CHECK (tipo IN ('moderador', 'generador', 'observador'))
);

-- -------------------------------------------------------------
-- TABLA: CONFIGURACION
-- -------------------------------------------------------------
CREATE TABLE CONFIGURACION (
    id_agente NUMBER NOT NULL,
    version NUMBER NOT NULL,
    fechaAplicada DATE NOT NULL,
    descripcion VARCHAR2(500),
    configuracion VARCHAR2(10) NOT NULL,
    CONSTRAINT pk_configuracion PRIMARY KEY (id_agente, version),
    CONSTRAINT fk_config_agente FOREIGN KEY (id_agente) REFERENCES AGENTE(id),
    CONSTRAINT ck_config_tipo CHECK (configuracion IN ('Simple', 'Compuesta')),
    CONSTRAINT ck_config_version CHECK (version > 0),
    CONSTRAINT ck_config_fecha CHECK (
        fechaAplicada <= SYSDATE
    )
);

-- -------------------------------------------------------------
-- TABLA: COMUNIDAD
-- -------------------------------------------------------------
CREATE TABLE COMUNIDAD (
    id NUMBER GENERATED ALWAYS AS IDENTITY,
    nombre VARCHAR2(200) NOT NULL,
    descripcion VARCHAR2(500),
    fechaCreacion DATE DEFAULT SYSDATE NOT NULL,
    temaPrincipal VARCHAR2(200),
    archivada NUMBER(1) DEFAULT 0 NOT NULL,
    fechaArchivado DATE,
    CONSTRAINT pk_comunidad PRIMARY KEY (id),
    CONSTRAINT uq_comunidad_nombre UNIQUE (nombre),
    CONSTRAINT ck_comunidad_arch CHECK (archivada IN (0, 1))
    CONSTRAINT ck_comunidad_fechas CHECK (
        (archivada = 0 AND fechaArchivado IS NULL)
        OR
        (archivada = 1 AND fechaArchivado IS NOT NULL)
    )
);

-- -------------------------------------------------------------
-- TABLA: PARTICIPA
-- -------------------------------------------------------------
CREATE TABLE PARTICIPA (
    id_agente NUMBER NOT NULL,
    id_comunidad NUMBER NOT NULL,
    tipo VARCHAR2(10) NOT NULL,
    CONSTRAINT pk_participa PRIMARY KEY (id_agente, id_comunidad),
    CONSTRAINT fk_part_agente FOREIGN KEY (id_agente) REFERENCES AGENTE(id),
    CONSTRAINT fk_part_comunidad FOREIGN KEY (id_comunidad) REFERENCES COMUNIDAD(id),
    CONSTRAINT ck_participa_tipo CHECK (tipo IN ('pasivo', 'activo'))
);

-- -------------------------------------------------------------
-- TABLA: RECLAMA
-- -------------------------------------------------------------
CREATE TABLE RECLAMA (
    id_usuario VARCHAR2(150) NOT NULL,
    id_agente NUMBER NOT NULL,
    fechaReclamo DATE NOT NULL,
    fechaAceptacion DATE,
    CONSTRAINT pk_reclama PRIMARY KEY (id_usuario, id_agente, fechaReclamo),
    CONSTRAINT fk_reclama_usuario FOREIGN KEY (id_usuario) REFERENCES USUARIO(mail),
    CONSTRAINT fk_reclama_agente FOREIGN KEY (id_agente) REFERENCES AGENTE(id),
    CONSTRAINT ck_reclama_fechas CHECK (
        fechaAceptacion IS NULL
        OR
        fechaAceptacion >= fechaReclamo
    )
);

-- -------------------------------------------------------------
-- TABLA: CONTENIDO
-- -------------------------------------------------------------
CREATE TABLE CONTENIDO (
    id NUMBER GENERATED ALWAYS AS IDENTITY,
    fechaCreacion DATE NOT NULL,
    horaCreacion VARCHAR2(8) NOT NULL, --formato HH24:MI:SS
    id_agente NUMBER NOT NULL,
    id_comunidad NUMBER NOT NULL,
    CONSTRAINT pk_contenido PRIMARY KEY (id),
    CONSTRAINT fk_cont_agente FOREIGN KEY (id_agente) REFERENCES AGENTE(id),
    CONSTRAINT fk_cont_comunidad FOREIGN KEY (id_comunidad) REFERENCES COMUNIDAD(id)
    CONSTRAINT ck_cont_hora_formato CHECK (
        REGEXP_LIKE(
            horaCreacion,
            '^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$'
        )
    )
);

-- -------------------------------------------------------------
-- TABLA: PUBLICACION
-- -------------------------------------------------------------
CREATE TABLE PUBLICACION (
    id NUMBER NOT NULL,
    titulo VARCHAR2(300) NOT NULL,
    contenido CLOB NOT NULL,
    estado VARCHAR2(10) DEFAULT 'activa' NOT NULL,
    puntaje NUMBER DEFAULT 0 NOT NULL,
    id_agente_cierre NUMBER,
    fecha_cierre DATE,
    hora_cierre VARCHAR2(8), --formato HH24:MI:SS
    CONSTRAINT pk_publicacion PRIMARY KEY (id),
    CONSTRAINT fk_pub_contenido FOREIGN KEY (id) REFERENCES CONTENIDO(id),
    CONSTRAINT fk_pub_ag_cierre FOREIGN KEY (id_agente_cierre) REFERENCES AGENTE(id),
    CONSTRAINT ck_pub_estado CHECK (estado IN ('eliminada', 'activa', 'cerrada')),
    CONSTRAINT ck_pub_hora_cierre CHECK (
        hora_cierre IS NULL OR
        REGEXP_LIKE(
            hora_cierre,
            '^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$'
        )
    ),
    CONSTRAINT ck_pub_cierre CHECK (
        (estado <> 'cerrada' AND fecha_cierre IS NULL AND hora_cierre IS NULL)
        OR
        (estado = 'cerrada' AND fecha_cierre IS NOT NULL AND hora_cierre IS NOT NULL)
    )
);

-- -------------------------------------------------------------
-- TABLA: COMENTARIO
-- -------------------------------------------------------------
CREATE TABLE COMENTARIO (
    id NUMBER NOT NULL,
    contenido CLOB,
    id_publicacion NUMBER,
    id_comentario_padre NUMBER,
    CONSTRAINT pk_comentario PRIMARY KEY (id),
    CONSTRAINT fk_com_contenido FOREIGN KEY (id) REFERENCES CONTENIDO(id),
    CONSTRAINT fk_com_publicacion FOREIGN KEY (id_publicacion) REFERENCES PUBLICACION(id),
    CONSTRAINT fk_com_padre FOREIGN KEY (id_comentario_padre) REFERENCES COMENTARIO(id),
    CONSTRAINT ck_com_referencia CHECK (
        (id_publicacion IS NOT NULL AND id_comentario_padre IS NULL) OR
        (id_publicacion IS NULL AND id_comentario_padre IS NOT NULL)
    )
);

-- -------------------------------------------------------------
-- TABLA: CITA
-- -------------------------------------------------------------
CREATE TABLE CITA (
    id_pub_origen NUMBER NOT NULL,
    id_pub_destino NUMBER NOT NULL,
    fechaCitacion DATE NOT NULL,
    CONSTRAINT pk_cita PRIMARY KEY (id_pub_origen, id_pub_destino),
    CONSTRAINT fk_cita_origen FOREIGN KEY (id_pub_origen) REFERENCES PUBLICACION(id),
    CONSTRAINT fk_cita_destino FOREIGN KEY (id_pub_destino) REFERENCES PUBLICACION(id),
    CONSTRAINT ck_cita_no_autoref CHECK (id_pub_origen <> id_pub_destino)
);

-- -------------------------------------------------------------
-- TABLA: VOTA
-- -------------------------------------------------------------
CREATE TABLE VOTA (
    id_agente NUMBER NOT NULL,
    id_publicacion NUMBER NOT NULL,
    fecha DATE NOT NULL,
    hora VARCHAR2(8) NOT NULL, --formato HH24:MI:SS
    positivo NUMBER(1) NOT NULL,
    CONSTRAINT pk_vota PRIMARY KEY (id_agente, id_publicacion),
    CONSTRAINT fk_vota_agente FOREIGN KEY (id_agente) REFERENCES AGENTE(id),
    CONSTRAINT fk_vota_publicacion FOREIGN KEY (id_publicacion) REFERENCES PUBLICACION(id),
    CONSTRAINT ck_vota_positivo CHECK (positivo IN (0, 1)),
    CONSTRAINT ck_vota_hora CHECK (
        REGEXP_LIKE(
            hora,
            '^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$'
        )
    )
);

-- -------------------------------------------------------------
-- TABLA: INTERVIENE
-- -------------------------------------------------------------
CREATE TABLE INTERVIENE (
    id_agente NUMBER NOT NULL,
    id_contenido NUMBER NOT NULL,
    id_comunidad NUMBER NOT NULL,
    tipo VARCHAR2(50) NOT NULL,
    fecha DATE NOT NULL,
    hora VARCHAR2(8) NOT NULL,  --formato HH24:MI:SS
    CONSTRAINT pk_interviene PRIMARY KEY (id_agente, id_contenido, id_comunidad, fecha, hora),
    CONSTRAINT fk_int_agente FOREIGN KEY (id_agente) REFERENCES AGENTE(id),
    CONSTRAINT fk_int_contenido FOREIGN KEY (id_contenido) REFERENCES CONTENIDO(id),
    CONSTRAINT fk_int_comunidad FOREIGN KEY (id_comunidad) REFERENCES COMUNIDAD(id),
    CONSTRAINT ck_interviene_hora CHECK (
        REGEXP_LIKE(
            hora,
            '^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$'
        )
    )   
);