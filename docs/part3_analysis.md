# Parte 3 — Análisis de consulta SQL

## Pregunta de negocio

¿Cuántas intervenciones de moderación se realizaron por comunidad, tipo de acción y mes, y qué agente moderador las ejecutó?

Esta consulta permite identificar comunidades con mayor actividad de moderación, detectar patrones de comportamiento y monitorear qué agentes moderadores son más activos a lo largo del tiempo.

---

## Consulta

```sql
SELECT 
    C.nombre                        AS comunidad,
    A.nombre                        AS agente_moderador,
    U.alias                         AS usuario_administrador,
    I.tipo                          AS tipo_accion,
    EXTRACT(YEAR FROM I.fecha)      AS anio,
    EXTRACT(MONTH FROM I.fecha)     AS mes,
    COUNT(*)                        AS total_intervenciones
FROM INTERVIENE I
JOIN AGENTE    A ON A.id   = I.id_agente
JOIN COMUNIDAD C ON C.id   = I.id_comunidad
JOIN USUARIO   U ON U.mail = A.id_usuario
GROUP BY 
    C.nombre, A.nombre, U.alias, I.tipo,
    EXTRACT(YEAR FROM I.fecha), EXTRACT(MONTH FROM I.fecha)
ORDER BY anio, mes, total_intervenciones DESC;
```

**Tablas involucradas:** INTERVIENE, AGENTE, COMUNIDAD, USUARIO.

---

## Operaciones principales del plan de ejecución

Al analizar el plan de ejecución de esta consulta, se identifican las siguientes operaciones:

- **Full Scan (TABLE ACCESS FULL en Oracle):** Oracle lee todas las filas de INTERVIENE de principio a fin, ya que no hay un filtro previo que reduzca el conjunto de datos antes del join.
- **Hash Join:** Para combinar las tablas, Oracle utiliza Hash Join. Construye una tabla de hash en memoria con la tabla más pequeña y la recorre buscando coincidencias al escanear la más grande. Este proceso se encadena para cada join de la consulta.
- **Hash Group By:** El `GROUP BY` con `COUNT(*)` se resuelve construyendo una tabla de hash interna donde se acumulan los conteos por cada combinación de atributos del grupo.
- **Sort Order By:** El `ORDER BY` final obliga a materializar y ordenar el resultado antes de devolverlo.

---

## Relación con algoritmos estudiados

El algoritmo más relevante que aparece en este plan es el **Hash Join**, que es exactamente el estudiado en clase. El motor divide la tabla menor en particiones que intenta mantener en los buffers de memoria disponibles, construye una tabla de hash sobre el atributo de join y luego recorre la tabla mayor para encontrar coincidencias. Si las particiones entran en memoria, el costo es relativamente bajo; si no entran, Oracle aplica el Hash Join recursivo, que requiere múltiples pasadas sobre los datos y resulta significativamente más costoso.

El **Sort Order By** se comporta como el Merge Sort externo visto en clase: si el resultado no cabe en memoria, Oracle lo escribe parcialmente a disco, ordena cada parte y luego las fusiona. Por eso es conveniente evitar `ORDER BY` en consultas analíticas cuando no es estrictamente necesario.

El **Full Scan** corresponde directamente al algoritmo estudiado en clase: Oracle lee todos los bloques de la tabla secuencialmente. Es la operación base cuando no hay índices aplicables, y su costo escala linealmente con el tamaño de la tabla.

---

## Similitudes entre el plan de ejecución y los algoritmos estudiados

El plan de ejecución generado por Oracle sigue la misma lógica que se analiza teóricamente en clase. En particular:

- Los joins se resuelven de a pares, materializando el resultado de cada uno para usarlo como entrada del siguiente, tal como se estudia al construir el plan físico.
- Oracle elige Hash Join sobre Nested Loops porque las tablas no tienen un orden preexistente en los atributos de join y no hay índices secundarios sobre las claves foráneas de INTERVIENE. En clase se vio que Nested Loops es conveniente cuando la tabla interna es pequeña o tiene un índice disponible; en este caso no se dan esas condiciones.
- La proyección de los atributos del SELECT se ejecuta en modo pipelined junto con los joins, sin agregar un paso separado de materialización, lo cual es consistente con lo visto en clase para la operación π.

---

## Eficiencia y posibles mejoras

La consulta actualmente hace un Full Scan sobre INTERVIENE, lo que puede ser costoso si esa tabla crece con el tiempo dado que registra cada acción de moderación del sistema. Algunas mejoras posibles:

- **Índice sobre `INTERVIENE.fecha`:** Si en el futuro se filtra por rango de fechas (por ejemplo, últimos 3 meses), un índice permitiría evitar leer toda la tabla.
- **Índice sobre `INTERVIENE.id_comunidad`:** Útil si la consulta se parametriza para una comunidad específica, reduciendo el volumen de datos que entra al join.
- **Vista materializada:** Si este reporte se ejecuta con frecuencia, una vista materializada con refresco periódico evitaría recalcular los joins y agregaciones en cada ejecución.
