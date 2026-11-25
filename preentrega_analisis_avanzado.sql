--Pre-entrega 5 - Curso SQL Coder House
--El ejercicio fue realizado con el modelo de base de datos que compartieron los profesores y probado con el mismo la consulta funciona.

WITH ventas_mensuales AS (
-- El ejercicio dice usar la tabla "ventas" pero la base de datos que venimos usando no la tiene.
-- Por eso se realiza un join de 4 tablas (pedidos/detalle_pedidos/productos/categorias) para tener los datos necesarios
-- Los pedidos cancelados no se tienen en cuenta para las ventas mensuales en cualquier otro estado se toma como supuesto que se van a completar.
-- Se trunca la fecha para poder agrupar por mes
SELECT DATE_TRUNC('month', p.fecha_pedido) AS mes, c.nombre_categoria, SUM(dp.subtotal) AS importe_total
FROM pedidos p
JOIN detalle_pedidos dp ON p.pedido_id = dp.pedido_id
JOIN productos pr ON dp.producto_id = pr.producto_id
JOIN categorias c ON pr.categoria_id = c.categoria_id
WHERE p.estado <> 'Cancelado'
GROUP BY mes , c.nombre_categoria
),
metricas_ventana AS (
-- Esta CTE toma los datos mensuales y les agrega tres columnas calculadas con
-- funciones de ventana. No colapsan filas: cada fila de ventas_mensuales se mantiene.
SELECT mes, nombre_categoria,importe_total,
-- ranking_categoria: posición de la categoría dentro de cada mes según sus ventas
-- (1 = la más vendida). PARTITION BY mes hace que el ranking se reinicie cada mes.
-- Se usa RANK(): si dos categorías empatan, comparten posición y se salta la siguiente.
RANK() OVER (PARTITION BY mes ORDER BY importe_total DESC) AS ranking_categoria,
-- running_total: ventas acumuladas de la categoría a lo largo del tiempo.
-- PARTITION BY nombre_categoria lo reinicia en cada categoría, y ORDER BY mes
-- hace que cada fila sume todo lo vendido desde el primer mes hasta el actual.
SUM(importe_total) OVER (PARTITION BY nombre_categoria ORDER BY mes) AS running_total,
-- promedio_categoria: promedio mensual de ventas de la categoría en toda su historia.
-- Sin ORDER BY, la ventana abarca toda la categoría, por lo que el valor se repite
-- en todos sus meses. Solo considera meses con ventas (los meses sin ventas no tienen fila).
AVG(importe_total) OVER (PARTITION BY nombre_categoria) AS promedio_categoria
FROM ventas_mensuales
)
SELECT mes, nombre_categoria, importe_total, ranking_categoria, running_total, ROUND(promedio_categoria,2) AS promedio_categoria,
-- Se utiliza un case para analizar la venta de cada mes por categoria contra el promedio de la misma
-- Como criterio se toma mayor o igual como Exitoso
-- Se ordena por mes
CASE
	WHEN (importe_total>=promedio_categoria) THEN 'Exitoso'
	ELSE 'Bajo el promedio'
END AS resultado
FROM metricas_ventana
ORDER BY mes, ranking_categoria;


