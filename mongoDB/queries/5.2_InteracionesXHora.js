db.eventos.aggregate([
{
    $match: {
        fecha: {
            $gte: new Date(
                new Date().getTime() - 7 * 24 * 60 * 60 * 1000
            )
        }
    }
},
{
    $group: {
        _id: {
            agente_id: "$agente_id",
            nombre_agente: "$nombre_agente"
        },
        total_eventos: { $sum: 1 },
        eventos_alta: {
            $sum: {
                $cond: [
                    { $eq: ["$criticidad", "alta"] },
                    1,
                    0
                ]
            }
        }
    }
},
{
    $project: {
        _id: 0,
        agente_id: "$_id.agente_id",
        nombre_agente: "$_id.nombre_agente",
        total_eventos: 1,
        eventos_alta: 1,
        proporcion_alta: {
            $cond: [
                { $eq: ["$total_eventos", 0] },
                0,
                {
                    $divide: [
                        "$eventos_alta",
                        "$total_eventos"
                    ]
                }
            ]
        }
    }
},
{
    $match: {
        eventos_alta: { $gt: 0 }
    }
},
{
    $sort: {
        eventos_alta: -1
    }
},
{
    $limit: 5
}
])