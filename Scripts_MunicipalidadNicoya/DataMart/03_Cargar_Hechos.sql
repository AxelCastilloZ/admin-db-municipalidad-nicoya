-- =============================================
-- ETL PARTE 2: POBLACIÓN DE TABLA DE HECHOS
-- Datamart: Reportes Administrativos
-- Carga FACT_Factura con métricas calculadas
-- VERSIÓN CORREGIDA - Asignación correcta de rubro_id
-- =============================================

USE MunicipalidadNicoya;
GO

TRUNCATE TABLE DM.FACT_Factura;
GO

PRINT '';
PRINT '========================================';
PRINT 'ETL - CARGANDO TABLA DE HECHOS';
PRINT '========================================';
PRINT '';
GO

-- =============================================
-- TABLA DE HECHOS: FACT_Factura
-- ✅ CORRECCIÓN: rubro_id asignado correctamente desde Detalle_factura
-- =============================================

PRINT 'Poblando FACT_Factura...';
PRINT '';
GO

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
    
    -- Contribuyente desde el trámite o inmueble
    COALESCE(
        (SELECT contribuyente_id 
         FROM dbo.Tramite t 
         WHERE t.tramite_id = f.tramite_id),
        (SELECT TOP 1 ci.contribuyente_id
         FROM dbo.Contribuyente_Inmueble ci
         WHERE ci.inmueble_id = f.inmueble_id)
    ) AS contribuyente_id,
    
    f.inmueble_id,
    
    -- ✅ CORRECCIÓN: Rubro del detalle con mayor monto (considerando descuento)
    (SELECT TOP 1 df.rubro_id 
     FROM dbo.Detalle_factura df 
     WHERE df.factura_id = f.factura_id 
     ORDER BY (df.monto_unitario * df.cantidad - df.descuento_linea) DESC) AS rubro_id,
    
    f.tramite_id,
    ef.estado_id,
    
    -- MÉTRICAS
    f.monto_base,
    f.recargo,
    f.intereses,
    f.monto_total,
    
    -- Cantidad de líneas
    ISNULL((SELECT COUNT(*) 
            FROM dbo.Detalle_factura df 
            WHERE df.factura_id = f.factura_id), 0) AS cantidad_lineas,
    
    -- Monto pagado
    ISNULL((SELECT SUM(p.monto_pagado) 
            FROM dbo.Pago p 
            WHERE p.factura_id = f.factura_id), 0) AS monto_pagado,
    
    -- Saldo pendiente
    f.monto_total - ISNULL((SELECT SUM(p.monto_pagado) 
                            FROM dbo.Pago p 
                            WHERE p.factura_id = f.factura_id), 0) AS saldo_pendiente,
    
    -- Esta vencida
    CASE 
        WHEN f.fecha_vencimiento < CAST(GETDATE() AS DATE) 
             AND f.estado_factura IN ('Pendiente', 'Vencida')
        THEN 1 
        ELSE 0 
    END AS esta_vencida,
    
    -- Esta pagada
    CASE 
        WHEN f.estado_factura = 'Pagada' THEN 1 
        ELSE 0 
    END AS esta_pagada,
    
    -- Días de mora
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

DECLARE @count_hechos INT;
SELECT @count_hechos = COUNT(*) FROM DM.FACT_Factura;
PRINT 'Registros cargados: ' + CAST(@count_hechos AS VARCHAR);
PRINT '';

-- Verificar cuántas facturas tienen rubro_id NULL
DECLARE @count_sin_rubro INT, @count_con_rubro INT;
SELECT 
    @count_sin_rubro = COUNT(CASE WHEN rubro_id IS NULL THEN 1 END),
    @count_con_rubro = COUNT(CASE WHEN rubro_id IS NOT NULL THEN 1 END)
FROM DM.FACT_Factura;

PRINT '✅ Facturas con rubro asignado: ' + CAST(@count_con_rubro AS VARCHAR);

IF @count_sin_rubro > 0
BEGIN
    PRINT '⚠️ Advertencia: ' + CAST(@count_sin_rubro AS VARCHAR) + ' facturas sin rubro_id asignado';
    PRINT '   (Facturas sin detalles o en proceso de creación)';
    PRINT '';
END
ELSE
BEGIN
    PRINT '✅ Todas las facturas tienen rubro asignado';
    PRINT '';
END

GO

-- =============================================
-- ESTADÍSTICAS
-- =============================================

PRINT '========================================';
PRINT 'ESTADÍSTICAS DEL DATAMART';
PRINT '========================================';
PRINT '';
GO

PRINT 'Facturas por Estado:';
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

PRINT '';
PRINT 'Recaudación por Rubro (Top 5):';
SELECT TOP 5
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

PRINT '';
PRINT 'Facturas Vencidas:';
SELECT 
    COUNT(*) AS total_vencidas,
    FORMAT(SUM(monto_total), 'C', 'es-CR') AS deuda_total,
    AVG(dias_mora) AS promedio_dias_mora,
    MAX(dias_mora) AS max_dias_mora
FROM DM.FACT_Factura
WHERE esta_vencida = 1;
GO

PRINT '';
PRINT 'Resumen por Rubro (todos):';
SELECT 
    CASE 
        WHEN ff.rubro_id IS NULL THEN '⚠️ SIN RUBRO ASIGNADO'
        ELSE r.nombre 
    END AS rubro,
    COUNT(*) AS cantidad_facturas,
    FORMAT(SUM(ff.monto_total), 'C', 'es-CR') AS monto_total,
    FORMAT(SUM(ff.monto_pagado), 'C', 'es-CR') AS monto_pagado,
    FORMAT(SUM(ff.saldo_pendiente), 'C', 'es-CR') AS saldo_pendiente
FROM DM.FACT_Factura ff
LEFT JOIN DM.DIM_Rubro r ON ff.rubro_id = r.rubro_id
GROUP BY ff.rubro_id, r.nombre
ORDER BY SUM(ff.monto_total) DESC;
GO

PRINT '';
PRINT '========================================';
PRINT 'TABLA DE HECHOS CARGADA EXITOSAMENTE';
PRINT '========================================';
PRINT '';
PRINT '✅ CORRECCIÓN APLICADA:';
PRINT '   El rubro_id se asigna correctamente desde Detalle_factura';
PRINT '   considerando el detalle con mayor monto';
PRINT '';
PRINT 'Siguiente paso: Probar endpoint de Recaudación por Rubro';
PRINT 'GET /api/Reporte/recaudacionPorRubro';
PRINT '';
GO