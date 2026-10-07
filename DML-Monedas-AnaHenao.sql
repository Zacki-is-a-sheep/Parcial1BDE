USE Monedas
GO

WITH Datos AS (
    SELECT
        m.Id,
        m.Moneda,
        m.Sigla,
 
        (SELECT COUNT(*)
         FROM Pais p
         WHERE p.IdMoneda = m.Id) AS TotalPaises,
 
        (SELECT MAX(c.Fecha)
         FROM CambioMoneda c
         WHERE c.IdMoneda = m.Id) AS UltimaFecha,
 
        (SELECT c.Cambio
         FROM CambioMoneda c
         WHERE c.IdMoneda = m.Id
           AND c.Fecha = (SELECT MAX(c2.Fecha)
                          FROM CambioMoneda c2
                          WHERE c2.IdMoneda = m.Id)) AS UltimoCambio,
 
        (SELECT AVG(c.Cambio)
         FROM CambioMoneda c
         WHERE c.IdMoneda = m.Id
           AND c.Fecha > DATEADD(DAY, -30, (SELECT MAX(Fecha) FROM CambioMoneda))) AS Promedio30Dias,
 
        (SELECT STDEV(c.Cambio)
         FROM CambioMoneda c
         WHERE c.IdMoneda = m.Id
           AND c.Fecha > DATEADD(DAY, -30, (SELECT MAX(Fecha) FROM CambioMoneda))) AS Desv30Dias
    FROM Moneda m
)
SELECT
    d1.Id,
    d1.Moneda,
    d1.Sigla,
    d1.TotalPaises,
    d1.UltimaFecha,
    d1.UltimoCambio,
    d1.Promedio30Dias,
    CASE
        WHEN d1.Desv30Dias / d1.Promedio30Dias * 100 > 1 THEN 'Volatil'
        ELSE 'Estable'
    END AS Volatilidad,
    (SELECT COUNT(*) + 1
     FROM Datos d2
     WHERE d2.TotalPaises > d1.TotalPaises) AS RankingUso
FROM Datos d1
ORDER BY RankingUso, d1.Moneda;
GO