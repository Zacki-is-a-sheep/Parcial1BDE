USE Monedas; 
GO  

;WITH 
-- 1 Contar la cantidad de países que usan cada moneda
PaisesPorMoneda AS (
    SELECT IdMoneda, COUNT(*) AS CantidadPaises
    FROM pais
    GROUP BY IdMoneda
),

-- 2 Encontrar la fecha del último cambio registrado para cada moneda
UltimaFechaCambio AS (
    SELECT IdMoneda, MAX(Fecha) AS FechaUltimoCambio
    FROM cambiomoneda
    GROUP BY IdMoneda
),

-- 3 Obtener el valor del último cambio usando la fecha máxima anterior
UltimoCambioValor AS (
    SELECT C.IdMoneda, C.Cambio AS ValorUltimoCambio
    FROM cambiomoneda C
    INNER JOIN UltimaFechaCambio U ON C.IdMoneda = U.IdMoneda AND C.Fecha = U.FechaUltimoCambio
),

-- 4 Calcular el promedio de cambio en los últimos 30 días
Promedio30Dias AS (
    SELECT IdMoneda, AVG(Cambio) AS PromedioCambio30D
    FROM cambiomoneda
    WHERE Fecha >= DATEADD(day, -30, (SELECT MAX(Fecha) FROM cambiomoneda))
    GROUP BY IdMoneda
),

-- 5 Clasificación de volatilidad 
VolatilidadMoneda AS (
    SELECT IdMoneda, 
           STDEV(Cambio) AS DesviacionEstandar,
           CASE 
               WHEN STDEV(Cambio) < 0.05 THEN 'Baja volatilidad'
               WHEN STDEV(Cambio) >= 0.05 AND STDEV(Cambio) < 0.15 THEN 'Media volatilidad'
               WHEN STDEV(Cambio) >= 0.15 THEN 'Alta volatilidad'
               ELSE 'Estable'
           END AS ClasificacionVolatilidad
    FROM cambiomoneda
    WHERE Fecha >= DATEADD(day, -30, (SELECT MAX(Fecha) FROM cambiomoneda))
    GROUP BY IdMoneda
)

-- Consulta principal que une todo el modelo de datos
SELECT 
    m.Id AS IdMoneda,
    m.Moneda,
    m.Sigla,
    ISNULL(p.CantidadPaises, 0) AS CantidadPaises,
    u.FechaUltimoCambio,
    uv.ValorUltimoCambio,
    p30.PromedioCambio30D,
    ISNULL(v.ClasificacionVolatilidad, 'Sin datos recientes') AS ClasificacionVolatilidad
FROM moneda m
LEFT JOIN PaisesPorMoneda p ON m.Id = p.IdMoneda
LEFT JOIN UltimaFechaCambio u ON m.Id = u.IdMoneda
LEFT JOIN UltimoCambioValor uv ON m.Id = uv.IdMoneda
LEFT JOIN Promedio30Dias p30 ON m.Id = p30.IdMoneda
LEFT JOIN VolatilidadMoneda v ON m.Id = v.IdMoneda;