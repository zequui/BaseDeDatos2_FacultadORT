# Restricciones de Integridad — Moltbook

## Restricciones estructurales

| Restricción | Relación (tabla) | Tipo de restricción | Implementación | Comentarios |
|---|---|---|---|---|
| `mail` es clave primaria | USUARIO | Entidad | Estructural | `PRIMARY KEY (mail)` |
| `alias` no puede repetirse | USUARIO | Dominio | Estructural | `UNIQUE (alias)` |
| `activo` solo puede ser 'Activo' o 'Suspendido' | USUARIO | Dominio | Estructural | `CHECK (activo IN ('Activo','Suspendido'))` |
| `mail`, `telefono` forman la clave primaria | TELEFONO_USUARIO | Entidad | Estructural | `PRIMARY KEY (mail, telefono)` |
| `mail` referencia a USUARIO | TELEFONO_USUARIO | Referencial | Estructural | `FOREIGN KEY (mail) REFERENCES USUARIO(mail)` |
| `id` es clave primaria | AGENTE | Entidad | Estructural | `PRIMARY KEY (id)`, generado con IDENTITY |
| `id_usuario` referencia a USUARIO | AGENTE | Referencial | Estructural | `FOREIGN KEY (id_usuario) REFERENCES USUARIO(mail)` |
| `activo` solo puede ser 'Activo' o 'Suspendido' | AGENTE | Dominio | Estructural | `CHECK (activo IN ('Activo','Suspendido'))` |
| `tipo` solo puede ser 'moderador', 'generador' u 'observador' | AGENTE | Dominio | Estructural | `CHECK (tipo IN ('moderador','generador','observador'))` |
| `(id_agente, version)` forman la clave primaria | CONFIGURACION | Entidad | Estructural | `PRIMARY KEY (id_agente, version)` |
| `id_agente` referencia a AGENTE | CONFIGURACION | Referencial | Estructural | `FOREIGN KEY (id_agente) REFERENCES AGENTE(id)` |
| `configuracion` solo puede ser 'Simple' o 'Compuesta' | CONFIGURACION | Dominio | Estructural | `CHECK (configuracion IN ('Simple','Compuesta'))` |
| `version` debe ser mayor a 0 | CONFIGURACION | Dominio | Estructural | `CHECK (version > 0)` |
| `id` es clave primaria | COMUNIDAD | Entidad | Estructural | `PRIMARY KEY (id)`, generado con IDENTITY |
| `nombre` no puede repetirse | COMUNIDAD | Dominio | Estructural | `UNIQUE (nombre)` |
| `archivada` solo puede ser 0 o 1 | COMUNIDAD | Dominio | Estructural | `CHECK (archivada IN (0,1))` |
| `(id_agente, id_comunidad)` forman la clave primaria | PARTICIPA | Entidad | Estructural | `PRIMARY KEY (id_agente, id_comunidad)` |
| `id_agente` referencia a AGENTE | PARTICIPA | Referencial | Estructural | `FOREIGN KEY (id_agente) REFERENCES AGENTE(id)` |
| `id_comunidad` referencia a COMUNIDAD | PARTICIPA | Referencial | Estructural | `FOREIGN KEY (id_comunidad) REFERENCES COMUNIDAD(id)` |
| `tipo` solo puede ser 'pasivo' o 'activo' | PARTICIPA | Dominio | Estructural | `CHECK (tipo IN ('pasivo','activo'))` |
| `(id_usuario, id_agente, fechaReclamo)` forman la clave primaria | RECLAMA | Entidad | Estructural | `PRIMARY KEY (id_usuario, id_agente, fechaReclamo)` |
| `id_usuario` referencia a USUARIO | RECLAMA | Referencial | Estructural | `FOREIGN KEY (id_usuario) REFERENCES USUARIO(mail)` |
| `id_agente` referencia a AGENTE | RECLAMA | Referencial | Estructural | `FOREIGN KEY (id_agente) REFERENCES AGENTE(id)` |
| `id` es clave primaria | CONTENIDO | Entidad | Estructural | `PRIMARY KEY (id)`, generado con IDENTITY |
| `id_agente` referencia a AGENTE | CONTENIDO | Referencial | Estructural | `FOREIGN KEY (id_agente) REFERENCES AGENTE(id)` |
| `id_comunidad` referencia a COMUNIDAD | CONTENIDO | Referencial | Estructural | `FOREIGN KEY (id_comunidad) REFERENCES COMUNIDAD(id)` |
| `id` es clave primaria y referencia a CONTENIDO | PUBLICACION | Entidad / Referencial | Estructural | Herencia por PK compartida: `FOREIGN KEY (id) REFERENCES CONTENIDO(id)` |
| `contenido` no puede ser nulo | PUBLICACION | Dominio | Estructural | `NOT NULL` |
| `estado` solo puede ser 'eliminada', 'activa' o 'cerrada' | PUBLICACION | Dominio | Estructural | `CHECK (estado IN ('eliminada','activa','cerrada'))` |
| `id_agente_cierre` referencia a AGENTE | PUBLICACION | Referencial | Estructural | `FOREIGN KEY (id_agente_cierre) REFERENCES AGENTE(id)` |
| `id` es clave primaria y referencia a CONTENIDO | COMENTARIO | Entidad / Referencial | Estructural | Herencia por PK compartida: `FOREIGN KEY (id) REFERENCES CONTENIDO(id)` |
| `id_publicacion` referencia a PUBLICACION | COMENTARIO | Referencial | Estructural | `FOREIGN KEY (id_publicacion) REFERENCES PUBLICACION(id)` |
| `id_comentario_padre` referencia a COMENTARIO | COMENTARIO | Referencial | Estructural | `FOREIGN KEY (id_comentario_padre) REFERENCES COMENTARIO(id)` |
| Un comentario referencia a una publicación O a otro comentario, nunca ambos ni ninguno | COMENTARIO | Semántica | Estructural | `CHECK ((id_publicacion IS NOT NULL AND id_comentario_padre IS NULL) OR (id_publicacion IS NULL AND id_comentario_padre IS NOT NULL))` |
| `(id_pub_origen, id_pub_destino)` forman la clave primaria | CITA | Entidad | Estructural | `PRIMARY KEY (id_pub_origen, id_pub_destino)` |
| `id_pub_origen` referencia a PUBLICACION | CITA | Referencial | Estructural | `FOREIGN KEY (id_pub_origen) REFERENCES PUBLICACION(id)` |
| `id_pub_destino` referencia a PUBLICACION | CITA | Referencial | Estructural | `FOREIGN KEY (id_pub_destino) REFERENCES PUBLICACION(id)` |
| Una publicación no puede citarse a sí misma | CITA | Semántica | Estructural | `CHECK (id_pub_origen <> id_pub_destino)` |
| `(id_agente, id_publicacion)` forman la clave primaria | VOTA | Entidad | Estructural | Garantiza que un agente no vota más de una vez la misma publicación |
| `id_agente` referencia a AGENTE | VOTA | Referencial | Estructural | `FOREIGN KEY (id_agente) REFERENCES AGENTE(id)` |
| `id_publicacion` referencia a PUBLICACION | VOTA | Referencial | Estructural | `FOREIGN KEY (id_publicacion) REFERENCES PUBLICACION(id)` |
| `positivo` solo puede ser 0 o 1 | VOTA | Dominio | Estructural | `CHECK (positivo IN (0,1))` |
| `(id_agente, id_contenido, id_comunidad, fecha, hora)` forman la clave primaria | INTERVIENE | Entidad | Estructural | Permite múltiples intervenciones del mismo moderador sobre el mismo contenido en distintos momentos |
| `id_agente` referencia a AGENTE | INTERVIENE | Referencial | Estructural | `FOREIGN KEY (id_agente) REFERENCES AGENTE(id)` |
| `id_contenido` referencia a CONTENIDO | INTERVIENE | Referencial | Estructural | `FOREIGN KEY (id_contenido) REFERENCES CONTENIDO(id)` |
| `id_comunidad` referencia a COMUNIDAD | INTERVIENE | Referencial | Estructural | `FOREIGN KEY (id_comunidad) REFERENCES COMUNIDAD(id)` |
| `horaCreacion` debe tener formato HH24:MI:SS | CONTENIDO | Dominio | Estructural | `CHECK (REGEXP_LIKE(horaCreacion, '^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$'))` |
| `hora_cierre` debe tener formato HH24:MI:SS (si no es nula) | PUBLICACION | Dominio | Estructural | `CHECK (hora_cierre IS NULL OR REGEXP_LIKE(hora_cierre, '^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$'))` |
| `hora` debe tener formato HH24:MI:SS | VOTA | Dominio | Estructural | `CHECK (REGEXP_LIKE(hora, '^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$'))` |
| `hora` debe tener formato HH24:MI:SS | INTERVIENE | Dominio | Estructural | `CHECK (REGEXP_LIKE(hora, '^([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$'))` |
| Si `archivada=0` entonces `fechaArchivado` debe ser NULL; si `archivada=1` debe estar presente | COMUNIDAD | Semántica | Estructural | `CHECK ((archivada = 0 AND fechaArchivado IS NULL) OR (archivada = 1 AND fechaArchivado IS NOT NULL))` |
| `fechaAceptacion` no puede ser anterior a `fechaReclamo` | RECLAMA | Semántica | Estructural | `CHECK (fechaAceptacion IS NULL OR fechaAceptacion >= fechaReclamo)` |
| Si estado ≠ 'cerrada' entonces `fecha_cierre` y `hora_cierre` deben ser NULL; si estado = 'cerrada' ambos deben estar presentes | PUBLICACION | Semántica | Estructural | `CHECK ((estado <> 'cerrada' AND fecha_cierre IS NULL AND hora_cierre IS NULL) OR (estado = 'cerrada' AND fecha_cierre IS NOT NULL AND hora_cierre IS NOT NULL))` |

---

## Restricciones no estructurales (triggers)

| Restricción | Relación (tabla) | Tipo de restricción | Implementación | Trigger |
|---|---|---|---|---|
| Un agente suspendido no puede generar contenido | CONTENIDO | Semántica | No estructural | `trg_contenido_agente_activo` |
| El usuario administrador del agente debe estar Activo para que el agente opere (contenido) | CONTENIDO | Semántica | No estructural | `trg_contenido_agente_activo` |
| Un agente suspendido no puede votar | VOTA | Semántica | No estructural | `trg_vota_agente_activo` |
| El usuario administrador del agente debe estar Activo para que el agente vote | VOTA | Semántica | No estructural | `trg_vota_agente_activo` |
| Solo agentes de tipo OBSERVADOR pueden emitir votos | VOTA | Semántica | No estructural | `trg_vota_tipo` |
| Solo agentes de tipo GENERADOR pueden crear publicaciones y comentarios | CONTENIDO | Semántica | No estructural | `trg_publicacion_tipo_agente` |
| Si una comunidad está archivada no se permiten nuevas publicaciones | CONTENIDO | Semántica | No estructural | `trg_pub_comunidad_archivada` |
| Para publicar en una comunidad el agente debe ser miembro activo | CONTENIDO | Semántica | No estructural | `trg_pub_miembro_activo` |
| Un agente no puede comentar en una comunidad a la que no pertenece | CONTENIDO | Semántica | No estructural | `trg_comentario_comunidad` |
| Una publicación cerrada no admite nuevos comentarios | COMENTARIO | Semántica | No estructural | `trg_comentario_pub_cerrada` |
| La fecha de aplicación de una configuración no puede ser anterior a la fecha de creación del agente | CONFIGURACION | Semántica | No estructural | `trg_config_fecha` |
| Solo agentes MODERADORES pueden ejecutar acciones de moderación | INTERVIENE | Semántica | No estructural | `trg_interviene_moderador` |
| Solo los agentes MODERADORES de una comunidad pueden moderar contenido de esa comunidad | INTERVIENE | Semántica | No estructural | `trg_interviene_moderador` |
| Un agente GENERADOR o MODERADOR puede cerrar una publicación; el GENERADOR solo puede cerrar las propias | PUBLICACION | Semántica | No estructural | `trg_cierre_publicacion` |
| El puntaje de una publicación se actualiza automáticamente al registrar un voto | PUBLICACION | Semántica | No estructural | `trg_actualizar_puntaje` |
| Un agente no puede ser transferido a un usuario que ya lo administra | RECLAMA | Semántica | No estructural | `trg_reclama_no_mismo_usuario` |
| La fecha de aplicación de una configuración no puede ser futura | CONFIGURACION | Semántica | No estructural | `trg_config_fecha` |
