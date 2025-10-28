-- =============================================
-- ETL PARTE 2: POBLACIÓN DE TABLA DE HECHOS
-- Datamart: Reportes Administrativos
-- Carga FACT_Factura con métricas calculadas
-- VERSIÓN CORREGIDA - Manejo correcto de rubro_id NULL
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '';
PRINT '========================================';
PRINT 'ETL - CARGANDO TABLA DE HECHOS';
PRINT '========================================';
PRINT '';
GO

-- =============================================
-- TABLA DE HECHOS: FACT_Factura
-- ? CORRECCIÓN: rubro_id puede ser NULL
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
    
    -- ? Rubro principal (el de mayor monto) - PUEDE SER NULL
    (SELECT TOP 1 df.rubro_id 
     FROM dbo.Detalle_factura df 
     WHERE df.factura_id = f.factura_id 
     ORDER BY df.monto_unitario * df.cantidad DESC) AS rubro_id,
    
    f.tramite_id,
    ef.estado_id,
    
    -- MÉTRICAS
    f.monto_base,
    f.recargo,
    f.intereses,
    f.monto_total,
    
    -- Cantidad de líneas
    (SELECT COUNT(*) 
     FROM dbo.Detalle_factura df 
     WHERE df.factura_id = f.factura_id) AS cantidad_lineas,
    
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
             AND f.estado_factura = 'Pendiente' 
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
             AND f.estado_factura = 'Pendiente'
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
DECLARE @count_sin_rubro INT;
SELECT @count_sin_rubro = COUNT(*) FROM DM.FACT_Factura WHERE rubro_id IS NULL;
IF @count_sin_rubro > 0
BEGIN
    PRINT '?? Advertencia: ' + CAST(@count_sin_rubro AS VARCHAR) + ' facturas sin rubro_id asignado';
    PRINT '   (Facturas sin detalles o en proceso de creación)';
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
    SUM(f.monto_total) AS monto_total,
    SUM(f.saldo_pendiente) AS saldo_pendiente
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
    SUM(f.monto_total) AS total,
    SUM(f.monto_pagado) AS pagado
FROM DM.FACT_Factura f
INNER JOIN DM.DIM_Rubro r ON f.rubro_id = r.rubro_id
WHERE f.rubro_id IS NOT NULL  -- ? Excluir facturas sin rubro
GROUP BY r.nombre
ORDER BY SUM(f.monto_total) DESC;
GO

PRINT '';
PRINT 'Facturas Vencidas:';
SELECT 
    COUNT(*) AS total_vencidas,
    SUM(monto_total) AS deuda_total,
    AVG(dias_mora) AS promedio_dias_mora,
    MAX(dias_mora) AS max_dias_mora
FROM DM.FACT_Factura
WHERE esta_vencida = 1;
GO

PRINT '';
PRINT '========================================';
PRINT 'TABLA DE HECHOS CARGADA EXITOSAMENTE';
PRINT '========================================';
PRINT '';
PRINT '? CORRECCIÓN APLICADA:';
PRINT '   El sistema maneja correctamente facturas sin rubro_id';
PRINT '';
GO