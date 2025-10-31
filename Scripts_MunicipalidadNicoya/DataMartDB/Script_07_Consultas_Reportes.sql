-- =============================================
-- CONSULTAS EJEMPLO - REPORTES ADMINISTRATIVOS
-- Base de datos: MunicipalidadNicoyaDataMart
-- =============================================

USE MunicipalidadNicoyaDataMart;
GO

-- REPORTE 1: Recaudación por año
SELECT 
    t.anio AS 'Año',
    COUNT(f.fact_factura_id) AS 'Total Facturas',
    FORMAT(SUM(f.monto_base), 'C', 'es-CR') AS 'Monto Base',
    FORMAT(SUM(f.recargo), 'C', 'es-CR') AS 'Recargos',
    FORMAT(SUM(f.intereses), 'C', 'es-CR') AS 'Intereses',
    FORMAT(SUM(f.monto_total), 'C', 'es-CR') AS 'Monto Total',
    FORMAT(SUM(f.monto_pagado), 'C', 'es-CR') AS 'Monto Pagado',
    FORMAT(SUM(f.saldo_pendiente), 'C', 'es-CR') AS 'Saldo Pendiente',
    CAST(SUM(f.monto_pagado) * 100.0 / NULLIF(SUM(f.monto_total), 0) AS DECIMAL(5,2)) AS '% Recaudado'
FROM DM.FACT_Factura f
INNER JOIN DM.DIM_Tiempo t ON f.tiempo_emision_id = t.tiempo_id
GROUP BY t.anio
ORDER BY t.anio DESC;
GO

-- REPORTE 2: Recaudación por trimestre (año actual)
SELECT 
    t.anio AS 'Año',
    t.trimestre AS 'Trimestre',
    COUNT(f.fact_factura_id) AS 'Facturas',
    FORMAT(SUM(f.monto_total), 'C', 'es-CR') AS 'Monto Total',
    FORMAT(SUM(f.monto_pagado), 'C', 'es-CR') AS 'Recaudado',
    FORMAT(SUM(f.saldo_pendiente), 'C', 'es-CR') AS 'Pendiente'
FROM DM.FACT_Factura f
INNER JOIN DM.DIM_Tiempo t ON f.tiempo_emision_id = t.tiempo_id
WHERE t.anio = YEAR(GETDATE())
GROUP BY t.anio, t.trimestre
ORDER BY t.trimestre;
GO

-- REPORTE 3: Recaudación por mes (últimos 12 meses)
SELECT 
    t.anio AS 'Año',
    t.mes_nombre AS 'Mes',
    COUNT(f.fact_factura_id) AS 'Facturas',
    FORMAT(SUM(f.monto_total), 'C', 'es-CR') AS 'Monto Total',
    FORMAT(SUM(f.monto_pagado), 'C', 'es-CR') AS 'Recaudado'
FROM DM.FACT_Factura f
INNER JOIN DM.DIM_Tiempo t ON f.tiempo_emision_id = t.tiempo_id
WHERE t.fecha >= DATEADD(MONTH, -12, GETDATE())
GROUP BY t.anio, t.mes, t.mes_nombre
ORDER BY t.anio DESC, t.mes DESC;
GO

-- REPORTE 4: Recaudación por tipo de rubro
SELECT 
    r.nombre AS 'Rubro',
    r.periodicidad AS 'Periodicidad',
    COUNT(f.fact_factura_id) AS 'Cantidad Facturas',
    FORMAT(SUM(f.monto_base), 'C', 'es-CR') AS 'Monto Base',
    FORMAT(SUM(f.recargo), 'C', 'es-CR') AS 'Recargos',
    FORMAT(SUM(f.intereses), 'C', 'es-CR') AS 'Intereses',
    FORMAT(SUM(f.monto_total), 'C', 'es-CR') AS 'Total Facturado',
    FORMAT(SUM(f.monto_pagado), 'C', 'es-CR') AS 'Total Recaudado',
    CAST(SUM(f.monto_pagado) * 100.0 / NULLIF(SUM(f.monto_total), 0) AS DECIMAL(5,2)) AS '% Efectividad'
FROM DM.FACT_Factura f
INNER JOIN DM.DIM_Rubro r ON f.rubro_id = r.rubro_id
WHERE f.rubro_id IS NOT NULL
GROUP BY r.nombre, r.periodicidad
ORDER BY SUM(f.monto_total) DESC;
GO

-- REPORTE 5: Resumen general de morosidad
SELECT 
    'RESUMEN DE MOROSIDAD' AS 'Indicador',
    COUNT(CASE WHEN esta_vencida = 1 THEN 1 END) AS 'Facturas Vencidas',
    FORMAT(SUM(CASE WHEN esta_vencida = 1 THEN saldo_pendiente ELSE 0 END), 'C', 'es-CR') AS 'Monto en Mora',
    AVG(CASE WHEN esta_vencida = 1 THEN dias_mora END) AS 'Promedio Días Mora',
    MAX(dias_mora) AS 'Máximo Días Mora'
FROM DM.FACT_Factura;
GO

-- REPORTE 6: Top 10 contribuyentes morosos
SELECT TOP 10
    c.nombre AS 'Contribuyente',
    c.tipo_contribuyente AS 'Tipo',
    c.cedula AS 'Cédula',
    COUNT(f.fact_factura_id) AS 'Facturas Vencidas',
    FORMAT(SUM(f.saldo_pendiente), 'C', 'es-CR') AS 'Deuda Total',
    AVG(f.dias_mora) AS 'Promedio Días Mora'
FROM DM.FACT_Factura f
INNER JOIN DM.DIM_Contribuyente c ON f.contribuyente_id = c.contribuyente_id
WHERE f.esta_vencida = 1
GROUP BY c.nombre, c.tipo_contribuyente, c.cedula
ORDER BY SUM(f.saldo_pendiente) DESC;
GO

-- REPORTE 7: Recaudación por distrito
SELECT 
    ISNULL(c.distrito, 'Sin Distrito') AS 'Distrito',
    COUNT(DISTINCT f.contribuyente_id) AS 'Contribuyentes',
    COUNT(f.fact_factura_id) AS 'Total Facturas',
    FORMAT(SUM(f.monto_total), 'C', 'es-CR') AS 'Monto Total Facturado',
    FORMAT(SUM(f.monto_pagado), 'C', 'es-CR') AS 'Monto Recaudado',
    FORMAT(SUM(f.saldo_pendiente), 'C', 'es-CR') AS 'Saldo Pendiente',
    CAST(SUM(f.monto_pagado) * 100.0 / NULLIF(SUM(f.monto_total), 0) AS DECIMAL(5,2)) AS '% Recaudación'
FROM DM.FACT_Factura f
LEFT JOIN DM.DIM_Contribuyente c ON f.contribuyente_id = c.contribuyente_id
GROUP BY c.distrito
ORDER BY SUM(f.monto_total) DESC;
GO

-- REPORTE 8: Análisis de trámites
SELECT 
    t.tipo_tramite AS 'Tipo de Trámite',
    t.estado_tramite AS 'Estado',
    COUNT(f.fact_factura_id) AS 'Cantidad',
    FORMAT(SUM(f.monto_total), 'C', 'es-CR') AS 'Monto Total',
    FORMAT(AVG(f.monto_total), 'C', 'es-CR') AS 'Monto Promedio',
    AVG(t.dias_resolucion) AS 'Días Resolución Promedio'
FROM DM.FACT_Factura f
INNER JOIN DM.DIM_Tramite t ON f.tramite_id = t.tramite_id
GROUP BY t.tipo_tramite, t.estado_tramite
ORDER BY COUNT(f.fact_factura_id) DESC;
GO

-- REPORTE 9: Indicadores clave (KPIs)
SELECT 
    'Total Facturado' AS 'Indicador',
    FORMAT(SUM(monto_total), 'C', 'es-CR') AS 'Valor'
FROM DM.FACT_Factura

UNION ALL
SELECT 'Total Recaudado', FORMAT(SUM(monto_pagado), 'C', 'es-CR') FROM DM.FACT_Factura

UNION ALL
SELECT 'Saldo Pendiente', FORMAT(SUM(saldo_pendiente), 'C', 'es-CR') FROM DM.FACT_Factura

UNION ALL
SELECT '% Efectividad Recaudación', CAST(SUM(monto_pagado) * 100.0 / NULLIF(SUM(monto_total), 0) AS VARCHAR(10)) + '%' FROM DM.FACT_Factura

UNION ALL
SELECT 'Facturas Totales', CAST(COUNT(*) AS VARCHAR) FROM DM.FACT_Factura

UNION ALL
SELECT 'Facturas Pagadas', CAST(COUNT(*) AS VARCHAR) FROM DM.FACT_Factura WHERE esta_pagada = 1

UNION ALL
SELECT 'Facturas Vencidas', CAST(COUNT(*) AS VARCHAR) FROM DM.FACT_Factura WHERE esta_vencida = 1

UNION ALL
SELECT 'Deuda en Mora', FORMAT(SUM(saldo_pendiente), 'C', 'es-CR') FROM DM.FACT_Factura WHERE esta_vencida = 1

UNION ALL
SELECT 'Contribuyentes Activos', CAST(COUNT(DISTINCT contribuyente_id) AS VARCHAR) FROM DM.FACT_Factura

UNION ALL
SELECT 'Monto Promedio por Factura', FORMAT(AVG(monto_total), 'C', 'es-CR') FROM DM.FACT_Factura;
GO

-- REPORTE 10: Comparativo año actual vs anterior
WITH RecaudacionAnual AS (
    SELECT 
        t.anio,
        t.mes,
        t.mes_nombre,
        SUM(f.monto_total) AS monto_total,
        SUM(f.monto_pagado) AS monto_pagado
    FROM DM.FACT_Factura f
    INNER JOIN DM.DIM_Tiempo t ON f.tiempo_emision_id = t.tiempo_id
    WHERE t.anio IN (YEAR(GETDATE()), YEAR(GETDATE()) - 1)
    GROUP BY t.anio, t.mes, t.mes_nombre
)
SELECT 
    a.mes_nombre AS Mes,
    FORMAT(a.monto_pagado, 'C', 'es-CR') AS Anio_Anterior,
    FORMAT(b.monto_pagado, 'C', 'es-CR') AS Anio_Actual,
    FORMAT(b.monto_pagado - a.monto_pagado, 'C', 'es-CR') AS Diferencia,
    CASE 
        WHEN ISNULL(a.monto_pagado, 0) = 0 THEN 0
        ELSE CAST((b.monto_pagado - a.monto_pagado) * 100.0 / a.monto_pagado AS DECIMAL(18,2))
    END AS Porcentaje_Variacion
FROM RecaudacionAnual a
LEFT JOIN RecaudacionAnual b ON a.mes = b.mes AND b.anio = YEAR(GETDATE())
WHERE a.anio = YEAR(GETDATE()) - 1
ORDER BY a.mes;
GO