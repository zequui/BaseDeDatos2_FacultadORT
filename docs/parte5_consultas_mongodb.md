# Parte 5 — Consultas MongoDB (Moltbook)

## Contexto general

Los eventos de actividad de los agentes se almacenan en la colección `eventos` de MongoDB. Cada documento representa una acción registrado para un agente, con un campo `detalle` de estructura variable según el `tipo_evento`.

**Colección utilizada:** `eventos`

**Campos comunes a todos los documentos:**

| Campo | Tipo | Descripción |
|---|---|---|
| `_id` | ObjectId | Generado automáticamente por MongoDB |
| `agente_id` | int | Referencia al `id` del agente en Oracle |
| `nombre_agente` | string | Nombre del agente, desnormalizado al momento del evento |
| `tipo_evento` | string | Tipo del evento (determina la estructura de `detalle`) |
| `criticidad` | string | `"alta"` \| `"media"` \| `"baja"` |
| `fecha` | Date | Fecha y hora del evento (ISODate UTC) |
| `id_comunidad` | int, opcional | Referencia a la comunidad, si aplica |
| `detalle` | object | Estructura variable según `tipo_evento` |

> **Nota sobre valores de `criticidad`:** En el schema real del proyecto, los valores son en **minúscula** (`"alta"`, `"media"`, `"baja"`).

---

## Requerimiento 5.1 — Historial de decisiones de un agente

### Descripción

Dado un `agente_id` y un rango de fechas (`fecha_desde`, `fecha_hasta`), retorna todos los eventos de tipo `"decision"` registrados para ese agente dentro del período, ordenados cronológicamente. Muestra la fecha del evento, el contexto operacional, los parámetros de entrada, las alternativas evaluadas y la alternativa elegida.

### Supuestos

- El `agente_id` recibido como parámetro es un entero, coherente con el tipo almacenado en el campo (`int`/`long`), tal como lo define el schema validator.
- Los valores de `fecha_desde` y `fecha_hasta` se interpretan como **ISODate UTC**. El límite inferior es inclusivo desde la medianoche (`T00:00:00Z`) y el límite superior es inclusivo hasta el último segundo del día (`T23:59:59Z`).
- El campo `fecha` es de tipo `Date` (no string), lo que permite comparaciones directas con operadores `$gte` / `$lte`.
- Para eventos de tipo `"decision"`, el `detalle` siempre incluye: `contexto_operacional`, `parametros_entrada`, `alternativas_evaluadas` y `alternativa_elegida`. Estos campos son parte del modelo definido en la Parte 4.a y son obligatorios para este tipo de evento.
- Si el agente no registró eventos de tipo `"decision"` en el período indicado, la consulta retorna un cursor vacío (sin error).
- La consulta utiliza `find()`, ya que no requiere agregaciones: solo filtra, proyecta y ordena.

### Query MongoDB

```javascript
// Parámetros de entrada:
//   agente_id   : entero (ej: 5)
//   fecha_desde : ISODate inicio del rango (inclusivo)
//   fecha_hasta : ISODate fin del rango (inclusivo)

db.eventos.find(
  // --- Filtro ---
  {
    agente_id: 5,                               // reemplazar con el agente_id deseado
    tipo_evento: "decision",
    fecha: {
      $gte: ISODate("2026-01-01T00:00:00Z"),    // reemplazar con fecha_desde
      $lte: ISODate("2026-12-31T23:59:59Z")     // reemplazar con fecha_hasta
    }
  },
  // --- Proyección ---
  {
    _id: 0,
    fecha: 1,
    "detalle.contexto_operacional": 1,
    "detalle.parametros_entrada":   1,
    "detalle.alternativas_evaluadas": 1,
    "detalle.alternativa_elegida":  1
  }
).sort({ fecha: 1 })  // orden cronológico ascendente
```

### Explicación paso a paso

1. **Filtro por `agente_id`**
   Restringe la búsqueda a los documentos del agente especificado. Es el primer discriminador y el más selectivo si existe un índice compuesto que lo incluya.

2. **Filtro por `tipo_evento: "decision"`**
   Descarta todos los eventos que no sean decisiones internas. Reduce significativamente el conjunto de documentos antes de aplicar el filtro de fechas.

3. **Filtro por rango de `fecha`**
   Aplica `$gte` y `$lte` sobre el campo `fecha` (tipo `Date`). Recupera únicamente los eventos que caen dentro del período solicitado.

4. **Proyección**
   `_id: 0` excluye el identificador interno. El resto de los campos proyectados exponen exactamente los datos requeridos por el enunciado: fecha del evento, contexto operacional, parámetros de entrada, alternativas evaluadas y alternativa elegida. Al ser subfields de `detalle`, se acceden con notación de punto.

5. **`.sort({ fecha: 1 })`**
   Ordena los resultados de más antiguo a más reciente (orden cronológico ascendente). Si existe un índice que cubra `(agente_id, tipo_evento, fecha)`, este sort se resuelve sin un paso de ordenamiento adicional en memoria.

### Ejemplo de resultado esperado

```json
[
  {
    "fecha": "2026-03-15T09:12:00.000Z",
    "detalle": {
      "contexto_operacional": "seleccion_contenido_publicacion",
      "parametros_entrada": {
        "comunidad_id": 3,
        "tema": "inteligencia_artificial",
        "tokens_disponibles": 4096
      },
      "alternativas_evaluadas": [
        "publicar_resumen",
        "publicar_analisis_completo",
        "no_publicar"
      ],
      "alternativa_elegida": "publicar_analisis_completo"
    }
  },
  {
    "fecha": "2026-06-10T14:45:30.000Z",
    "detalle": {
      "contexto_operacional": "respuesta_comentario",
      "parametros_entrada": {
        "id_comentario_origen": 882,
        "sentimiento_detectado": "negativo"
      },
      "alternativas_evaluadas": [
        "ignorar",
        "responder_neutral",
        "escalar_moderador"
      ],
      "alternativa_elegida": "responder_neutral"
    }
  }
]
```

### Índices recomendados

```javascript
// Índice compuesto principal — cubre filtro + sort en un solo paso
db.eventos.createIndex(
  { agente_id: 1, tipo_evento: 1, fecha: 1 },
  { name: "idx_eventos_agente_tipo_fecha" }
)
```

**Justificación:** MongoDB puede usar este índice compuesto para resolver el filtro por `agente_id` y `tipo_evento` y, a continuación, recorrer el rango de `fecha` ya ordenado. Esto evita un `SORT` en memoria (*in-memory sort*) y minimiza la cantidad de documentos escaneados. Sin este índice, MongoDB realizaría un *collection scan* completo sobre `eventos`.

Un índice solo sobre `{ agente_id: 1 }` sería insuficiente porque igualmente habría que filtrar y ordenar por `fecha` luego. El orden de los campos en el índice compuesto sigue la regla de **Equality → Range → Sort** (ERS).

---

## Requerimiento 5.2 — Top 5 agentes con mayor cantidad de eventos de criticidad alta

### Descripción

Retorna los 5 agentes que registraron más eventos de criticidad `"alta"` en los últimos 7 días. Para cada agente muestra: `agente_id`, `nombre_agente`, `total_eventos` (en el período), `eventos_alta` y `proporcion_alta` (eventos de criticidad alta sobre el total de eventos del agente en el mismo período).

### Supuestos

- El período de los "últimos 7 días" se calcula tomando `new Date()` como referencia (UTC). No requiere parámetros de entrada.
- Se considera la criticidad `"alta"` (minúscula), coherente con los valores definidos en el validator del schema.
- `proporcion_alta` se calcula como `eventos_alta / total_eventos`. Si un agente tiene `total_eventos = 0` (situación imposible en la práctica dado el `$match` inicial, pero se maneja defensivamente), se retorna `0` para evitar división por cero.
- Solo se incluyen en el resultado agentes que tengan al menos 1 evento de criticidad `"alta"` en el período. Agentes activos pero sin eventos críticos no aparecen en el top.
- Se devuelven exactamente 5 agentes (o menos si no hay suficientes que cumplan la condición).
- El nombre del agente (`nombre_agente`) está desnormalizado en cada documento de evento. Se asume que el nombre no cambió durante el período de 7 días, o bien que se acepta el trade-off de usar el nombre histórico registrado al momento del evento (definido así en la Parte 4.a del proyecto).

### Query MongoDB

```javascript
// Sin parámetros de entrada — el período se calcula dinámicamente

db.eventos.aggregate([

  // Etapa 1: filtrar solo los eventos de los últimos 7 días
  {
    $match: {
      fecha: {
        $gte: new Date(new Date().getTime() - 7 * 24 * 60 * 60 * 1000)
      }
    }
  },

  // Etapa 2: agrupar por agente, contando totales y eventos de criticidad alta
  {
    $group: {
      _id: {
        agente_id:    "$agente_id",
        nombre_agente: "$nombre_agente"
      },
      total_eventos: { $sum: 1 },
      eventos_alta: {
        $sum: {
          $cond: [{ $eq: ["$criticidad", "alta"] }, 1, 0]
        }
      }
    }
  },

  // Etapa 3: calcular el campo derivado proporcion_alta y aplanar la salida
  {
    $project: {
      _id: 0,
      agente_id:     "$_id.agente_id",
      nombre_agente: "$_id.nombre_agente",
      total_eventos: 1,
      eventos_alta:  1,
      proporcion_alta: {
        $cond: [
          { $eq: ["$total_eventos", 0] },
          0,
          { $divide: ["$eventos_alta", "$total_eventos"] }
        ]
      }
    }
  },

  // Etapa 4: excluir agentes sin ningún evento de criticidad alta
  {
    $match: {
      eventos_alta: { $gt: 0 }
    }
  },

  // Etapa 5: ordenar de mayor a menor por cantidad de eventos críticos
  {
    $sort: { eventos_alta: -1 }
  },

  // Etapa 6: limitar al top 5
  {
    $limit: 5
  }

])
```

### Explicación paso a paso

1. **`$match` por fecha (Etapa 1)**
   Filtra todos los eventos que ocurrieron en los últimos 7 días, calculando el umbral como `ahora - 7 días en milisegundos`.

2. **`$group` por agente (Etapa 2)**
   Agrupa los documentos resultantes por la combinación `(agente_id, nombre_agente)`, que identifica unívocamente a cada agente. Se calculan dos acumuladores:
   - `total_eventos`: cuenta todos los eventos del agente en el período con `$sum: 1`.
   - `eventos_alta`: usa `$cond` para sumar solo los documentos donde `criticidad == "alta"`, equivalente a un `COUNT(*) FILTER (WHERE criticidad = 'alta')` en SQL.

3. **`$project` con campo calculado (Etapa 3)**
   Aplana la estructura (elimina `_id` con el subdocumento agrupador) y calcula `proporcion_alta` como la división de `eventos_alta` entre `total_eventos`. El `$cond` defensivo previene una división por cero para el caso borde de `total_eventos = 0`.

4. **`$match` de eventos_alta > 0 (Etapa 4)**
   Descarta agentes que no registraron ningún evento crítico en el período. Aunque la etapa 2 ya incluye todos los agentes con actividad, es posible que un agente tenga solo eventos de criticidad `"media"` o `"baja"`. Este filtro los excluye.

5. **`$sort` descendente (Etapa 5)**
   Ordena los agentes de mayor a menor por `eventos_alta`, para que los más críticos queden primero.

6. **`$limit: 5` (Etapa 6)**
   Retiene únicamente los 5 primeros documentos del resultado ordenado.

### Ejemplo de resultado esperado

```json
[
  {
    "agente_id": 12,
    "nombre_agente": "Agente-Nexus",
    "total_eventos": 45,
    "eventos_alta": 18,
    "proporcion_alta": 0.4
  },
  {
    "agente_id": 7,
    "nombre_agente": "Agente-Orion",
    "total_eventos": 30,
    "eventos_alta": 12,
    "proporcion_alta": 0.4
  },
  {
    "agente_id": 3,
    "nombre_agente": "Agente-Vega",
    "total_eventos": 60,
    "eventos_alta": 9,
    "proporcion_alta": 0.15
  },
  {
    "agente_id": 21,
    "nombre_agente": "Agente-Sirius",
    "total_eventos": 20,
    "eventos_alta": 7,
    "proporcion_alta": 0.35
  },
  {
    "agente_id": 9,
    "nombre_agente": "Agente-Atlas",
    "total_eventos": 14,
    "eventos_alta": 5,
    "proporcion_alta": 0.357
  }
]
```

### Índices recomendados

```javascript
// Índice sobre fecha — cubre el $match inicial de la Etapa 1
db.eventos.createIndex(
  { fecha: 1 },
  { name: "idx_eventos_fecha" }
)

// Índice compuesto — más eficiente si la mayoría de consultas filtran
// primero por fecha y luego agrupan por criticidad
db.eventos.createIndex(
  { fecha: 1, criticidad: 1, agente_id: 1 },
  { name: "idx_eventos_fecha_criticidad_agente" }
)
```

**Justificación:** El `$match` de la Etapa 1 es el cuello de botella principal: sin índice, MongoDB escaneará toda la colección. Un índice sobre `{ fecha: 1 }` es el mínimo necesario. El índice compuesto `{ fecha, criticidad, agente_id }` es más eficiente porque permite que MongoDB resuelva tanto el filtro de fecha como el agrupamiento con accesos más dirigidos al índice B-tree, reduciendo la cantidad de documentos cargados en memoria para el `$group`.

> **Nota:** Los índices no pueden cubrir completamente un `$group` en MongoDB (a diferencia de un `GROUP BY` en SQL con índices cubrientes), pero sí reducen los documentos que entran al pipeline.

---

## Requerimiento 5.3 — Interacciones de un agente agrupadas por hora

### Descripción

Dado un `agente_id` y una franja horaria (`hora_inicio`, `hora_fin`, expresadas como enteros de 0 a 23), retorna los eventos de tipo `"interaccion_usuario"` del agente agrupados por hora, mostrando la cantidad de eventos registrados en cada hora.

### Supuestos

- `hora_inicio` y `hora_fin` son enteros en el rango `[0, 23]`
- La extracción de la hora se realiza con el operador `$hour` de MongoDB, que interpreta el campo `fecha` (tipo `Date`) en **UTC**. Se asume que los eventos se registran en UTC, coherente con el uso de `ISODate` en el resto del proyecto.
- Si una hora dentro de la franja no tiene ningún evento, esa hora **no aparece** en el resultado.
- La consulta no está limitada a un rango de fechas: examina todos los eventos históricos del agente. Si se necesitara restringir el análisis a un período, se podría agregar un filtro adicional sobre `fecha`.
- El `agente_id` recibido es un entero, coherente con el tipo almacenado en la colección.

### Query MongoDB

```javascript
// Parámetros de entrada:
//   agente_id   : entero (ej: 1)
//   hora_inicio : entero 0-23 (ej: 8)
//   hora_fin    : entero 0-23 (ej: 17)

db.eventos.aggregate([

  // Etapa 1: filtrar por agente y tipo de evento
  {
    $match: {
      agente_id:   1,                      // reemplazar con el agente_id deseado
      tipo_evento: "interaccion_usuario"
    }
  },

  // Etapa 2: extraer la hora del campo fecha (UTC)
  {
    $addFields: {
      hora: { $hour: "$fecha" }
    }
  },

  // Etapa 3: filtrar por la franja horaria solicitada
  {
    $match: {
      hora: {
        $gte: 8,   // reemplazar con hora_inicio
        $lte: 17   // reemplazar con hora_fin
      }
    }
  },

  // Etapa 4: agrupar por hora y contar eventos
  {
    $group: {
      _id: "$hora",
      cantidad_interacciones: { $sum: 1 }
    }
  },

  // Etapa 5: ordenar por hora ascendente
  {
    $sort: { _id: 1 }
  },

  // Etapa 6: proyección final — renombrar _id a hora
  {
    $project: {
      _id: 0,
      hora: "$_id",
      cantidad_interacciones: 1
    }
  }

])
```

### Explicación paso a paso

1. **`$match` por agente y tipo de evento (Etapa 1)**
   Primer filtro, el más restrictivo: selecciona solo los documentos del agente especificado y de tipo `"interaccion_usuario"`. Reduce el volumen de datos antes de cualquier transformación costosa.

2. **`$addFields` — extracción de la hora (Etapa 2)**
   Añade un campo temporal `hora` al documento extrayendo la componente hora del campo `fecha` con `$hour`. El valor resultante es un entero de `0` a `23` (UTC). Este campo no existe persistentemente en el documento: se calcula en tiempo de ejecución del pipeline.

3. **`$match` por franja horaria (Etapa 3)**
   Aplica el filtro de rango sobre el campo `hora` recién calculado. Solo los documentos cuya hora extraída esté dentro de `[hora_inicio, hora_fin]` continúan al siguiente paso. Este `$match` debe ir después del `$addFields` porque `hora` no existe en los documentos almacenados.

4. **`$group` por hora (Etapa 4)**
   Agrupa los documentos filtrados por el valor de `hora` y cuenta cuántos eventos hay en cada hora con `$sum: 1`. El resultado es un documento por cada hora distinta que tenga al menos un evento.

5. **`$sort` por hora (Etapa 5)**
   Ordena los grupos de menor a mayor por `_id` (que en este punto contiene la hora). Esto garantiza que el resultado llegue al cliente en orden cronológico de la franja.

6. **`$project` final (Etapa 6)**
   Renombra `_id` al nombre semántico `hora` y elimina el `_id` del resultado, para que la salida sea más legible y no exponga el campo interno del agrupamiento.

### Ejemplo de resultado esperado

Franja horaria `[8, 17]` para `agente_id: 1`:

```json
[
  { "hora": 8,  "cantidad_interacciones": 3  },
  { "hora": 9,  "cantidad_interacciones": 7  },
  { "hora": 10, "cantidad_interacciones": 12 },
  { "hora": 11, "cantidad_interacciones": 5  },
  { "hora": 13, "cantidad_interacciones": 9  },
  { "hora": 14, "cantidad_interacciones": 4  },
  { "hora": 16, "cantidad_interacciones": 2  },
  { "hora": 17, "cantidad_interacciones": 6  }
]
```

> Las horas 12 y 15 no aparecen porque el agente no registró interacciones en esas horas. El resultado solo incluye horas con al menos un evento, como se estableció en los supuestos.

### Índices recomendados

```javascript
// Índice compuesto — cubre el $match de la Etapa 1
db.eventos.createIndex(
  { agente_id: 1, tipo_evento: 1 },
  { name: "idx_eventos_agente_tipo" }
)

// Índice compuesto extendido — útil si se agrega un filtro de fecha
// (ver supuesto sobre rango de fechas)
db.eventos.createIndex(
  { agente_id: 1, tipo_evento: 1, fecha: 1 },
  { name: "idx_eventos_agente_tipo_fecha" }
)
```

**Justificación:** El `$match` de la Etapa 1 se beneficia de un índice sobre `(agente_id, tipo_evento)`, que permite a MongoDB recuperar directamente los documentos relevantes sin escanear la colección completa. El campo `hora` se calcula en el pipeline con `$addFields` / `$hour` y no puede ser indexado directamente (no existe en el documento almacenado). El índice extendido con `fecha` es útil si en el futuro se agrega un filtro temporal a la consulta, y puede reutilizarse para el Requerimiento 5.1.

> El índice `idx_eventos_agente_tipo_fecha` definido para el Requerimiento 5.1 cubre también la Etapa 1 de esta consulta, por lo que ambos requerimientos comparten ese índice.

---

## Resumen de índices del proyecto

| Índice | Campos | Requerimientos que beneficia |
|---|---|---|
| `idx_eventos_agente_tipo_fecha` | `{ agente_id: 1, tipo_evento: 1, fecha: 1 }` | 5.1, 5.3 |
| `idx_eventos_fecha` | `{ fecha: 1 }` | 5.2 |
| `idx_eventos_fecha_criticidad_agente` | `{ fecha: 1, criticidad: 1, agente_id: 1 }` | 5.2 |
| `idx_eventos_agente_tipo` | `{ agente_id: 1, tipo_evento: 1 }` | 5.3 |

En la práctica, con los tres requerimientos de la Parte 5, los índices mínimos necesarios son `idx_eventos_agente_tipo_fecha` (cubre 5.1 y 5.3) e `idx_eventos_fecha` (cubre 5.2). Los índices adicionales son opcionales y útiles si el volumen de datos crece o si aparecen nuevas consultas con patrones similares.
