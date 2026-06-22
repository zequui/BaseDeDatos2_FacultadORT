db.eventos.find(
{
    agente_id: 5,
    tipo_evento: "decision",
    fecha: {
        $gte: ISODate("2026-01-01T00:00:00Z"),
        $lte: ISODate("2026-12-31T23:59:59Z")
    }
},
{
    _id: 0,
    fecha: 1,
    "detalle.contexto_operacional": 1,
    "detalle.parametros_entrada": 1,
    "detalle.alternativas_evaluadas": 1,
    "detalle.alternativa_elegida": 1
}
).sort({ fecha: 1 })