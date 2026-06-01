# Análisis de la solución propuesta — Moltbook

## 1. Descripción general del modelo

El sistema Moltbook es una red social orientada a agentes de Inteligencia Artificial. Los agentes son los actores principales: generan contenido, comentan, votan y pueden ser moderados. Los usuarios humanos cumplen un rol administrativo: crean agentes, los supervisan y pueden reclamar su administración. El modelo relacional fue diseñado para capturar estas interacciones con integridad y trazabilidad.

---

## 2. Decisiones de diseño

### 2.1 Herencia de CONTENIDO → PUBLICACION y COMENTARIO

El enunciado distingue dos tipos de contenido: publicaciones y comentarios. Ambos comparten atributos comunes (id, fecha, hora, agente, comunidad) pero tienen atributos y relaciones propias.

Se optó por una herencia con **tabla padre compartida** (CONTENIDO) y dos tablas hijas (PUBLICACION y COMENTARIO) que comparten la misma clave primaria. Esto permite:
- Evitar repetición de atributos comunes.
- Mantener la integridad referencial entre contenido, agentes y comunidades en un solo lugar.
- Referenciar cualquier tipo de contenido desde INTERVIENE sin necesidad de dos claves foráneas distintas.

### 2.2 Hora almacenada como VARCHAR2

Oracle no dispone de un tipo `TIME` puro equivalente al estándar SQL. El tipo `DATE` en Oracle incluye fecha y hora, lo que genera ambigüedad si se quiere almacenar solo la hora. Se optó por guardar la hora como `VARCHAR2(8)` en formato `HH24:MI:SS`, lo que permite claridad en la lectura y compatibilidad con funciones de string y conversión de Oracle. Las columnas afectadas son: `horaCreacion` en CONTENIDO, `hora` en VOTA e INTERVIENE, y `hora_cierre` en PUBLICACION.

### 2.3 Puntaje almacenado en PUBLICACION

El enunciado requiere mostrar el puntaje total de votos de cada publicación. Para evitar calcular este valor mediante una agregación sobre la tabla VOTA en cada consulta, se decidió almacenar el atributo `puntaje` en la tabla PUBLICACION. Su valor se actualiza automáticamente mediante el trigger `trg_actualizar_puntaje` cada vez que se registra un voto. Esta solución mejora el rendimiento de las consultas que muestran publicaciones, manteniendo la consistencia de los datos a través del trigger.


### 2.4 RECLAMA como historial de transferencias

El proceso de transferencia de un agente entre usuarios se modela mediante la tabla RECLAMA, cuya clave primaria es `(id_usuario, id_agente, fechaReclamo)`. Esto permite conservar el historial completo de reclamos, no solo el estado actual. La columna `fechaAceptacion` es nullable: un reclamo puede existir sin haber sido aceptado aún. Cuando se acepta, se actualiza el `id_usuario` en AGENTE al nuevo administrador.

### 2.5 PARTICIPA distingue miembros activos y pasivos

Los agentes pueden pertenecer a una comunidad como miembros pasivos (solo visualizan) o activos (pueden publicar). Esta distinción se modela con el atributo `tipo` en PARTICIPA (`'pasivo'` o `'activo'`). El trigger `trg_pub_miembro_activo` garantiza que solo los miembros activos puedan publicar.

### 2.6 INTERVIENE referencia a CONTENIDO, no a PUBLICACION ni COMENTARIO

Las acciones de moderación pueden aplicarse tanto a publicaciones como a comentarios. Para evitar duplicar la FK (una a PUBLICACION y otra a COMENTARIO), se referencia directamente a CONTENIDO, que es el padre común de ambos. Esto es consistente con el modelo de herencia adoptado.

### 2.7 CITA es una relación entre publicaciones

Una publicación puede citar a otra. Esto se modela con la tabla CITA, con claves foráneas `id_pub_origen` e `id_pub_destino`, ambas apuntando a PUBLICACION. Se incluye un CHECK para evitar que una publicación se cite a sí misma.

### 2.8 Estado de publicación como ciclo de vida

El atributo `estado` en PUBLICACION maneja tres valores: `'activa'`, `'cerrada'` y `'eliminada'`. Las publicaciones eliminadas no se borran físicamente del sistema, lo cual es un requerimiento explícito del enunciado. El trigger `trg_cierre_publicacion` controla quién puede cambiar el estado a `'cerrada'`.

---

## 3. Supuestos efectuados

### Sobre usuarios y agentes

- Se asume que el mail del usuario es inmutable una vez registrado, dado que actúa como clave primaria y es referenciado por AGENTE y RECLAMA.
- Se asume que un agente tiene exactamente un usuario administrador en todo momento (el `id_usuario` en AGENTE refleja el administrador actual). El historial de transferencias queda en RECLAMA.
- Se asume que la `fechaAceptacion` en RECLAMA puede quedar nula si el reclamo fue iniciado pero no aceptado. El proceso de aceptación (UPDATE sobre AGENTE.id_usuario y UPDATE sobre RECLAMA.fechaAceptacion) se delega al procedimiento del Requerimiento 2.2.
- Se asume que un usuario puede tener cero o más teléfonos (la tabla TELEFONO_USUARIO admite filas múltiples por mail).

### Sobre configuraciones

- Se asume que la versión de configuración es un entero incremental por agente, comenzando en 1. El sistema no restringe estructuralmente el incremento, pero el procedimiento del Requerimiento 2.7 debe encargarse de calcular la próxima versión.
- Se asume que la "configuración activa" del agente no se almacena redundantemente en AGENTE, sino que se obtiene consultando el registro de CONFIGURACION con la versión más alta para ese agente. Esto evita inconsistencias entre AGENTE y CONFIGURACION.
- Se asume que la fecha de aplicación de una configuración no puede ser futura. Esta restricción se implementa mediante el trigger `trg_config_fecha`, ya que Oracle no permite utilizar `SYSDATE` dentro de restricciones CHECK.

### Sobre contenido

- Se asume que tanto PUBLICACION como COMENTARIO heredan el `id` de CONTENIDO. No existe un ID independiente para publicaciones o comentarios: el identificador es el mismo que el del contenido padre.
- Se asume que la comunidad donde se publica queda registrada en CONTENIDO (no en PUBLICACION), ya que es un atributo del contenido en general y no específico de las publicaciones.
- Se asume que un comentario siempre referencia exactamente una publicación o exactamente un comentario padre, nunca ambos. Esto queda reforzado estructuralmente por el CHECK `ck_com_referencia`.
- Se asume que la búsqueda de la publicación raíz de un hilo de comentarios puede requerir recorrido recursivo (implementado con `CONNECT BY` en el trigger `trg_comentario_pub_cerrada`).

### Sobre votos

- Se asume que un voto positivo equivale a `positivo = 1` y un voto negativo a `positivo = 0`, representados como `NUMBER(1)`.
- Se asume que el puntaje puede ser negativo (si hay más votos negativos que positivos).
- La unicidad del voto por agente y publicación queda garantizada por la PK de VOTA, lo que además cumple la restricción de que un observador no puede votar más de una vez la misma publicación.

### Sobre moderación

- Se asume que el tipo de acción de moderación (`tipo` en INTERVIENE) es texto libre con ejemplos como 'ocultar', 'cerrar', 'eliminar', ya que el enunciado no define un conjunto cerrado de valores.
- - Se asume que un agente moderador debe pertenecer a la comunidad sobre la que realiza acciones de moderación. Esta restricción es controlada por el trigger `trg_interviene_moderador`.
- Se asume que una misma publicación puede recibir múltiples intervenciones del mismo moderador en distintos momentos, razón por la cual `fecha` y `hora` forman parte de la clave primaria de INTERVIENE.
- Se asume que la comunidad registrada en INTERVIENE coincide con la comunidad a la que pertenece el contenido intervenido. Esta coherencia no se valida estructuralmente mediante claves foráneas ni mediante triggers, por lo que constituye un supuesto del sistema.

### Sobre comunidades

- Se asume que `archivada` es un flag booleano representado como `NUMBER(1)` (0 = no archivada, 1 = archivada), dado que Oracle no tiene tipo BOOLEAN nativo en SQL (solo en PL/SQL).
- Se asume que `fechaArchivado` puede ser nula si la comunidad nunca fue archivada.

### Sobre la hora en Oracle

- Dado que Oracle no posee un tipo de dato `TIME` puro, se decidió almacenar la hora como `VARCHAR2(8)` con formato `HH24:MI:SS` en las columnas `horaCreacion` (CONTENIDO), `hora` (VOTA, INTERVIENE) y `hora_cierre` (PUBLICACION). Esto permite comparaciones y filtros mediante funciones de string o `TO_DATE`.
