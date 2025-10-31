-- =============================================
-- ETL PARTE 2: POBLACIÓN DE TABLA DE HECHOS
-- Datamart: Reportes Administrativos
-- Base de datos: MunicipalidadNicoyaDataMart
-- Origen: MunicipalidadNicoya
-- =============================================

USE MunicipalidadNicoyaDataMart;
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
    COALESCE(
        (SELECT contribuyente_id 
         FROM MunicipalidadNicoya.dbo.Tramite t 
         WHERE t.tramite_id = f.tramite_id),
        (SELECT TOP 1 ci.contribuyente_id
         FROM MunicipalidadNicoya.dbo.Contribuyente_Inmueble ci
         WHERE ci.inmueble_id = f.inmueble_id)
    ) AS contribuyente_id,
    f.inmueble_id,
    (SELECT TOP 1 df.rubro_id 
     FROM MunicipalidadNicoya.dbo.Detalle_factura df 
     WHERE df.factura_id = f.factura_id 
     ORDER BY (df.monto_unitario * df.cantidad - df.descuento_linea) DESC) AS rubro_id,
    f.tramite_id,
    ef.estado_id,
    f.monto_base,
    f.recargo,
    f.intereses,
    f.monto_total,
    ISNULL((SELECT COUNT(*) 
            FROM MunicipalidadNicoya.dbo.Detalle_factura df 
            WHERE df.factura_id = f.factura_id), 0) AS cantidad_lineas,
    ISNULL((SELECT SUM(p.monto_pagado) 
            FROM MunicipalidadNicoya.dbo.Pago p 
            WHERE p.factura_id = f.factura_id), 0) AS monto_pagado,
    f.monto_total - ISNULL((SELECT SUM(p.monto_pagado) 
                            FROM MunicipalidadNicoya.dbo.Pago p 
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
FROM MunicipalidadNicoya.dbo.Factura f
INNER JOIN DM.DIM_Tiempo dt_emision ON CAST(f.fecha_emision AS DATE) = dt_emision.fecha
INNER JOIN DM.DIM_Tiempo dt_venc ON f.fecha_vencimiento = dt_venc.fecha
INNER JOIN DM.DIM_Estado_Factura ef ON f.estado_factura = ef.estado;
GO

SELECT 
    COUNT(CASE WHEN rubro_id IS NULL THEN 1 END) AS facturas_sin_rubro,
    COUNT(CASE WHEN rubro_id IS NOT NULL THEN 1 END) AS facturas_con_rubro,
    COUNT(*) AS total_facturas
FROM DM.FACT_Factura;
GO

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