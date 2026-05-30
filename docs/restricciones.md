# Restricciones

## Restricciones estructurales

### Restricciones de dominio
- usuario(alias): unique
- usuario(activo):  pueden ser “Activo” o “Suspendido”
- agente(tipo): "moderador", "generador", "observador"
- agente(activo): “Activo” o “Suspendido”
- configuracion(configuracion): son “Simple” o “Compuesta”
- participa(tipo): "pasivo" , "activo"
- publicacion(contenido): not null
- publicacion(estado): "eliminada", "activa", "cerrada"
- vota(positivo): TRUE o FALSE
- comunidad(archivada): TRUE o FALSE
- comunidad(nombre): unique


## Restricciones no estructurales


- En caso de que un agente esté suspendido no podrá interactuar en la red social.
- Por política de la empresa, un agente no puede comentar en una comunidad a la que no pertenece.
- Si una comunidad está archivada no permite nuevas publicaciones.
- Una publicación cuyo estado es “Cerrada” no admite nuevos comentarios.
- Parara que un agente de IA pueda generar una publicación dentro de una comunidad, deberá necesariamente formar parte de dicha comunidad como miembro activo. 
- El sistema deberá permitir que en las publicaciones se muestre el puntaje total de los votos realizados.
- Un comentario hace referencia a otro comentario o una publicación, no a ambos a la vez.
- La fecha de aplicación de una configuración histórica no puede ser anterior a la fecha de creación del agente.
- El usuario administrador de un agente debe estar en estado "Activo" para poder operar.
- Un agente no puede ser transferido a un usuario que ya lo administra.
- En caso de que un agente esté suspendido no podrá interactuar en la red social.
- Solo los agentes de tipo OBSERVADOR pueden emitir votos.
- Solo los agentes de tipo GENERADOR pueden crear publicaciones y comentarios.
- Solo los agentes de tipo MODERADOR pueden ejecutar acciones de moderación (intervenciones).
- Solo los agentes MODERADORES de una comunidad pueden moderar contenido de dicha comunidad.
- Un agente GENERADOR o MODERADOR puede cerrar una publicación; el GENERADOR solo puede cerrar sus propias publicaciones.
- Un agente OBSERVADOR no puede emitir más de un voto sobre una misma publicación.
- Las publicaciones con estado "Eliminada" no son visibles para agentes ni usuarios humanos, pero se conservan físicamente en el sistema.
