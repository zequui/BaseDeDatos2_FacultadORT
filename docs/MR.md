# MR - Pasaje a tablas

*USUARIO* (mail PK, alias UNIQUE, nombreCompleto, pais, fechaRegistro, activo)

*AGENTE* (id PK, nombre, fechaCreacion, descripcion, activo, tipo, id_usuario FK→USUARIO)

*TELEFONO_USUARIO* (mail FK→USUARIO, telefono, PK(mail, telefono))

*CONFIGURACION* (id_agente FK→AGENTE, version, fechaAplicada, descripcion, configuracion, PK(id_agente, version))

*COMUNIDAD* (id PK, nombre UNIQUE, descripcion, fechaCreacion, temaPrincipal, archivada, fechaArchivado)

*PARTICIPA* (id_agente FK→AGENTE, id_comunidad FK→COMUNIDAD, tipo, PK(id_agente, id_comunidad))

*RECLAMA* (id_usuario FK→USUARIO, id_agente FK→AGENTE, fechaReclamo, fechaAceptacion, PK(id_usuario, id_agente, fechaReclamo))

*CONTENIDO* (id PK, fechaCreacion, horaCreacion, id_agente FK→AGENTE, id_comunidad FK→COMUNIDAD)

*PUBLICACION* (id FK→CONTENIDO PK, titulo, contenido NOT NULL, estado, puntaje, id_agente_cierre FK→AGENTE, fecha_cierre, hora_cierre)

*COMENTARIO* (id FK→CONTENIDO PK, contenido, id_publicacion FK→PUBLICACION, id_comentario_padre FK→COMENTARIO)

*CITA* (id_pub_origen FK→PUBLICACION, id_pub_destino FK→PUBLICACION, fechaCitacion, PK(id_pub_origen, id_pub_destino))

*VOTA* (id_agente FK→AGENTE, id_publicacion FK→PUBLICACION, fecha, hora, positivo, PK(id_agente, id_publicacion))

*INTERVIENE* (id_agente FK→AGENTE, id_contenido FK→CONTENIDO, id_comunidad FK→COMUNIDAD, tipo, fecha, hora, PK(id_agente, id_contenido, id_comunidad, fecha, hora))