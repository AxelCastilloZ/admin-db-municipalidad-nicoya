-- =============================================
-- ETL PARTE 2: POBLACIÓN DE TABLA DE HECHOS
-- Datamart: Reportes Administrativos
-- =============================================

USE MunicipalidadNicoya;
GO

-- Carga de hechos: FACT_Factura
INSERT INTO DM.FACT_Factura (
    factura_id,
    tiempo_emision_id,
    tiempo_vencimiento_id,
    contribuyente_id,
    inmueble_id,
    rubro_id,
    tramite_id,
    estado_factura_id,
    monto_base,
    recargo,
    intereses,
    monto_total,
    cantidad_lineas,
    monto_pagado,
    saldo_pendiente,
    esta_vencida,
    esta_pagada,
    dias_mora
)
SELECT 
    f.factura_id,
    dt_emision.tiempo_id,
    dt_venc.tiempo_id,
    COALESCE(
        (SELECT contribuyente_id 
         FROM dbo.Tramite t 
         WHERE t.tramite_id = f.tramite_id),
        (SELECT TOP 1 ci.contribuyente_id
         FROM dbo.Contribuyente_Inmueble ci
         WHERE ci.inmueble_id = f.inmueble_id)
    ) AS contribuyente_id,
    f.inmueble_id,
    (SELECT TOP 1 df.rubro_id 
     FROM dbo.Detalle_factura df 
     WHERE df.factura_id = f.factura_id 
     ORDER BY (df.monto_unitario * df.cantidad - df.descuento_linea) DESC) AS rubro_id,
    f.tramite_id,
    ef.estado_id,
    f.monto_base,
    f.recargo,
    f.intereses,
    f.monto_total,
    ISNULL((SELECT COUNT(*) 
            FROM dbo.Detalle_factura df 
            WHERE df.factura_id = f.factura_id), 0) AS cantidad_lineas,
    ISNULL((SELECT SUM(p.monto_pagado) 
            FROM dbo.Pago p 
            WHERE p.factura_id = f.factura_id), 0) AS monto_pagado,
    f.monto_total - ISNULL((SELECT SUM(p.monto_pagado) 
                            FROM dbo.Pago p 
                            WHERE p.factura_id = f.factura_id), 0) AS saldo_pendiente,
    CASE 
        WHEN f.fecha_vencimiento < CAST(GETDATE() AS DATE) 
             AND f.estado_factura IN ('Pendiente', 'Vencida')
        THEN 1 
        ELSE 0 
    END AS esta_vencida,
    CASE 
        WHEN f.estado_factura = 'Pagada' THEN 1 
        ELSE 0 
    END AS esta_pagada,
    CASE 
        WHEN f.fecha_vencimiento < CAST(GETDATE() AS DATE) 
             AND f.estado_factura IN ('Pendiente', 'Vencida')
        THEN DATEDIFF(DAY, f.fecha_vencimiento, GETDATE())
        ELSE NULL
    END AS dias_mora
FROM dbo.Factura f
INNER JOIN DM.DIM_Tiempo dt_emision ON CAST(f.fecha_emision AS DATE) = dt_emision.fecha
INNER JOIN DM.DIM_Tiempo dt_venc ON f.fecha_vencimiento = dt_venc.fecha
INNER JOIN DM.DIM_Estado_Factura ef ON f.estado_factura = ef.estado;
GO

-- Verificación de rubros asignados
DECLARE @count_sin_rubro INT, @count_con_rubro INT;
SELECT 
    @count_sin_rubro = COUNT(CASE WHEN rubro_id IS NULL THEN 1 END),
    @count_con_rubro = COUNT(CASE WHEN rubro_id IS NOT NULL THEN 1 END)
FROM DM.FACT_Factura;
GO

-- Estadísticas: Facturas por Estado
SELECT 
    ef.estado,
    COUNT(*) AS cantidad,
    FORMAT(SUM(f.monto_total), 'C', 'es-CR') AS monto_total,
    FORMAT(SUM(f.saldo_pendiente), 'C', 'es-CR') AS saldo_pendiente
FROM DM.FACT_Factura f
INNER JOIN DM.DIM_Estado_Factura ef ON f.estado_factura_id = ef.estado_id
GROUP BY ef.estado
ORDER BY cantidad DESC;
GO

-- Estadísticas: Recaudación por Rubro
SELECT 
    r.nombre,
    COUNT(*) AS cantidad,
    FORMAT(SUM(f.monto_total), 'C', 'es-CR') AS total,
    FORMAT(SUM(f.monto_pagado), 'C', 'es-CR') AS pagado,
    CAST(SUM(f.monto_pagado) * 100.0 / NULLIF(SUM(f.monto_total), 0) AS DECIMAL(5,2)) AS porcentaje_efectividad
FROM DM.FACT_Factura f
INNER JOIN DM.DIM_Rubro r ON f.rubro_id = r.rubro_id
WHERE f.rubro_id IS NOT NULL
GROUP BY r.nombre
ORDER BY SUM(f.monto_total) DESC;
GO

-- Estadísticas: Recaudación por Distrito
SELECT 
    c.distrito AS Distrito,
    COUNT(DISTINCT f.contribuyente_id) AS Contribuyentes,
    COUNT(f.fact_factura_id) AS 'Total Facturas',
    FORMAT(SUM(f.monto_total), 'C', 'es-CR') AS 'Monto Total',
    FORMAT(SUM(f.monto_pagado), 'C', 'es-CR') AS 'Recaudado',
    FORMAT(SUM(f.saldo_pendiente), 'C', 'es-CR') AS 'Pendiente',
    CAST(SUM(f.monto_pagado) * 100.0 / NULLIF(SUM(f.monto_total), 0) AS DECIMAL(5,2)) AS '% Recaudación'
FROM DM.FACT_Factura f
INNER JOIN DM.DIM_Contribuyente c ON f.contribuyente_id = c.contribuyente_id
GROUP BY c.distrito
ORDER BY SUM(f.monto_total) DESC;
GO

-- Estadísticas: Facturas Vencidas
SELECT 
    COUNT(*) AS total_vencidas,
    FORMAT(SUM(monto_total), 'C', 'es-CR') AS deuda_total,
    AVG(dias_mora) AS promedio_dias_mora,
    MAX(dias_mora) AS max_dias_mora
FROM DM.FACT_Factura
WHERE esta_vencida = 1;
GO

-- Fin de carga de hechos
