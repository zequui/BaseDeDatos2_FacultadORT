db.createCollection("eventos", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["agente_id", "nombre_agente", "tipo_evento", "criticidad", "fecha", "detalle"],
      properties: {
        agente_id: {
          bsonType: "int",
          description: "Obligatorio. Entero, referencia a AGENTE.id en Oracle"
        },
        nombre_agente: {
          bsonType: "string",
          description: "Obligatorio. Nombre del agente, desnormalizado desde Oracle"
        },
        tipo_evento: {
          enum: [
            "decision",
            "interaccion_usuario",
            "accion",
            "metrica_ejecucion",
            "anomalia",
            "creacion_publicacion",
            "creacion_comentario",
            "voto"
          ],
          description: "Obligatorio. Debe ser uno de los 8 tipos de evento definidos (5 sintéticos + 3 reflejo de Oracle)"
        },
        criticidad: {
          enum: ["alta", "media", "baja"],
          description: "Obligatorio. Debe ser alta, media o baja"
        },
        fecha: {
          bsonType: "date",
          description: "Obligatorio. Fecha y hora del evento"
        },
        id_comunidad: {
          bsonType: ["int", "null"],
          description: "Opcional. Referencia a COMUNIDAD.id en Oracle, si el evento ocurre dentro de una comunidad. Puede ser null cuando el evento no tiene comunidad asociada."
        },
        detalle: {
          bsonType: "object",
          description: "Obligatorio. Estructura interna variable según tipo_evento (no validada en detalle para permitir extensibilidad)"
        }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});
