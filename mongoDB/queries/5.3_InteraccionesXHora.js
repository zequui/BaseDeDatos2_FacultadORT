db.eventos.aggregate([
{
    $match: {
        agente_id: 1,
        tipo_evento: "interaccion_usuario"
    }
},
{
    $addFields: {
        hora: {
            $hour: "$fecha"
        }
    }
},
{
    $match: {
        hora: {
            $gte: 8,
            $lte: 17
        }
    }
},
{
    $group: {
        _id: "$hora",
        cantidad_interacciones: {
            $sum: 1
        }
    }
},
{
    $sort: {
        _id: 1
    }
},
{
    $project: {
        _id: 0,
        hora: "$_id",
        cantidad_interacciones: 1
    }
}
])