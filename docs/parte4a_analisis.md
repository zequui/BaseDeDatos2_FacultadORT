# Parte 4.a — Análisis de la solución (MongoDB)

## Por qué una sola colección

El enunciado permite hasta 2 colecciones. Evaluamos dos enfoques:

- **Una colección `eventos`**, con todos los eventos juntos y un campo `detalle` cuya forma cambia según el tipo de evento (patrón polimórfico).
- **Dos colecciones**: `eventos` + una colección de resumen/agregados por agente (contadores, último evento, etc.), pensada para acelerar lecturas como la del Requerimiento 5.2.

Optamos por **una sola colección `eventos`**, dejando la segunda sin usar. Motivos:

- Es el modelo más directo para lo que pide el enunciado: "un documento de evento por cada acción detectada".
- Evita el problema de mantener sincronizados dos lugares (evento + resumen) sin contar con transacciones multi-documento como las que sí existen en Oracle.
- Las consultas de la Parte 5 (incluida la 5.2, que pide proporciones) se resuelven con `aggregate()` sobre la única colección, sin necesidad de datos precalculados.

## Supuestos

- Cada evento queda asociado a un único agente (`agente_id`), identificado igual que en Oracle.
- `agente_id` se guarda como **referencia simple** al `id` de `AGENTE` en Oracle (mismo valor, mismo tipo `NUMBER`/entero). MongoDB no valida esta referencia de forma automática (no hay integridad referencial entre Mongo y Oracle); la consistencia depende del proceso de integración (Parte 4.c).
- Se desnormaliza el `nombre_agente` dentro de cada evento. Se decide copiar este dato al momento de generar el evento en lugar de mantener solo la referencia, para no depender de una consulta a Oracle cada vez que se necesite mostrar o filtrar eventos por nombre de agente. Como contrapartida, si el agente cambia de nombre en Oracle después de generado el evento, el evento histórico en Mongo conserva el nombre anterior — se acepta este trade-off porque el propósito de la colección es de auditoría/histórico, no de estado actual.
- `criticidad` toma uno de tres valores fijos: `alta`, `media`, `baja`, tal como lo especifica la letra del obligatorio.
- `id_comunidad` se incluye como referencia opcional (mismo criterio que `agente_id`) para los tipos de evento que ocurren dentro de una comunidad (publicaciones, votos, moderaciones). No todos los tipos de evento la tienen.
- El campo `detalle` no tiene una forma fija: varía según `tipo_evento`, y nuevos tipos de evento pueden incorporarse sin modificar la estructura de los documentos existentes ni la definición de la colección (más allá de, eventualmente, ampliar el validator).

## Modelado de la colección `eventos`

### Campos comunes (presentes en todo documento)

| Campo | Tipo | Descripción |
|---|---|---|
| `_id` | ObjectId | generado automáticamente por MongoDB |
| `agente_id` | int | referencia al `id` del agente en Oracle (`AGENTE.id`) |
| `nombre_agente` | string | dato desnormalizado, copiado al momento del evento |
| `tipo_evento` | string | determina la forma del campo `detalle` |
| `criticidad` | string | `alta` \| `media` \| `baja` |
| `fecha` | date | fecha y hora del evento |
| `id_comunidad` | int, opcional | referencia a la comunidad donde ocurrió el evento, si aplica |
| `detalle` | object | estructura variable según `tipo_evento` |

### Tipos de evento

Se definieron 8 tipos, en dos grupos:

- **Sintéticos** (`decision`, `interaccion_usuario`, `metrica_ejecucion`, `anomalia`, `accion`): representan información que no existe en ningún lugar de Oracle, porque el modelo relacional solo guarda el resultado de las acciones del agente, no su proceso interno (razonamiento, métricas de ejecución, comportamientos anómalos). `decision` e `interaccion_usuario` son obligatorios porque los requerimientos 5.1 y 5.3 de la Parte 5 consultan específicamente sobre ellos.
- **Reflejo de acciones ya registradas en Oracle** (`creacion_publicacion`, `creacion_comentario`, `voto`): cubren explícitamente la frase de la letra "acciones realizadas por los agentes (creación de publicaciones, comentarios, votos, etc.)". No se modela un tipo de evento por cada tabla de Oracle (por ejemplo, se descartó un tipo aparte para moderación o transferencia de agente) para no sobre-modelar; esos casos ya quedan cubiertos conceptualmente por `accion` y `decision`.

**`decision`** — decisión interna tomada por el agente antes de actuar (selección de contenido, generación de una respuesta, evaluación interna), no registrada en ningún lugar de Oracle porque el modelo relacional solo guarda el resultado final, no el razonamiento previo.

```javascript
detalle: {
  contexto_operacional: "...",   // ej: "seleccion_contenido_publicacion"
  parametros_entrada: { ... },   // objeto libre: datos con los que contaba el agente al decidir
  alternativas_evaluadas: ["..."],
  alternativa_elegida: "..."
}
```
El requerimiento 5.1 exige explícitamente que cada evento de este tipo incluya el contexto operacional y los parámetros de entrada utilizados, por lo que ambos campos son obligatorios dentro de `detalle`.

**`interaccion_usuario`** — contacto entre un agente y el usuario humano que lo administra (por ejemplo, consultas de estado o uso del panel de administración). El requerimiento 5.3 solo exige poder agrupar estos eventos por hora, lo cual se resuelve con el campo común `fecha`; por eso el `detalle` se mantiene simple.

```javascript
detalle: {
  id_usuario: "...",   // mail del usuario humano (USUARIO.mail en Oracle)
  canal: "..."         // ej: "consulta_estado", "panel_admin"
}
```

**`accion`** — acciones del agente que ya están registradas en Oracle (publicar, comentar, votar, moderar), reflejadas también como evento de auditoría en Mongo.

```javascript
detalle: {
  tipo_accion: "...",   // "publicacion" | "comentario" | "voto" | "moderacion"
  id_contenido: ...     // referencia al contenido/publicación en Oracle, si aplica
}
```

**`metrica_ejecucion`** — métricas de desempeño del agente al ejecutar una tarea, mencionadas explícitamente en la letra ("tiempos de respuesta, uso de recursos, cantidad de tokens procesados").

```javascript
detalle: {
  tiempo_respuesta_ms: ...,
  tokens_procesados: ...
}
```

**`anomalia`** — comportamiento anómalo o patrón relevante detectado en la actividad del agente, también mencionado explícitamente en la letra.

```javascript
detalle: {
  patron_detectado: "...",   // ej: "alta_frecuencia", "acceso_no_autorizado"
  descripcion: "..."
}
```

**`creacion_publicacion`** — refleja como evento de auditoría la creación de una publicación, acción que en Oracle ya queda registrada en `PUBLICACION` (Requerimiento 2.3). Cubre la frase de la letra "acciones realizadas por los agentes (creación de publicaciones...)".

```javascript
detalle: {
  id_publicacion: ...,
  titulo: "...",
  estado: "..."   // 'activa' | 'cerrada' | 'eliminada', mismo dominio que PUBLICACION.estado en Oracle
}
```

**`creacion_comentario`** — refleja como evento la creación de un comentario, ya registrado en Oracle en `COMENTARIO` (Requerimiento 2.5). Un comentario responde a una publicación o a otro comentario, nunca ambos a la vez (mismo criterio que la restricción `ck_com_referencia` del DDL de Oracle).

```javascript
detalle: {
  id_comentario: ...,
  id_publicacion: ...,         // si responde directo a una publicación
  id_comentario_padre: ...     // si responde a otro comentario
}
```

**`voto`** — refleja la emisión de un voto sobre una publicación, ya registrado en Oracle en `VOTA` (Requerimiento 2.4).

```javascript
detalle: {
  id_publicacion: ...,
  positivo: true   // true | false
}
```

**`creacion_publicacion`** — refleja como evento de auditoría una publicación ya registrada en Oracle (`PUBLICACION`). Cubre la mención explícita de la letra a "acciones realizadas por los agentes (creación de publicaciones...)".

```javascript
detalle: {
  id_publicacion: ...,   // referencia a PUBLICACION.id en Oracle
  titulo: "...",
  estado: "..."          // 'activa' | 'cerrada' | 'eliminada', igual que en Oracle
}
```

**`creacion_comentario`** — refleja como evento de auditoría un comentario ya registrado en Oracle (`COMENTARIO`), ya sea sobre una publicación o como respuesta a otro comentario.

```javascript
detalle: {
  id_comentario: ...,
  id_publicacion: ...,        // presente si el comentario responde directo a una publicación
  id_comentario_padre: ...    // presente si el comentario responde a otro comentario
}
```

**`voto`** — refleja como evento de auditoría un voto ya registrado en Oracle (`VOTA`).

```javascript
detalle: {
  id_publicacion: ...,
  positivo: true   // mismo criterio que VOTA.positivo en Oracle
}
```

## Pendiente

- Definir el schema validator (`$jsonSchema`) que traduzca estas reglas a MongoDB (punto b de la Parte 4).
- Definir el proceso de generación de datos de prueba y el script de integración Oracle → MongoDB (punto c).
