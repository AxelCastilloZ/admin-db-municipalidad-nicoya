-- =============================================
-- PROCEDIMIENTOS ALMACENADOS -  DATAMART
-- Automatización del proceso ETL para actualizaciones incrementales
-- Base de datos: MunicipalidadNicoyaDataMart
-- Origen: MunicipalidadNicoya
-- =============================================

USE MunicipalidadNicoyaDataMart;
GO

CREATE OR ALTER PROCEDURE DM.sp_Actualizar_DIM_Contribuyente
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @registros_nuevos INT = 0;
    DECLARE @registros_actualizados INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO DM.DIM_Contribuyente (
            contribuyente_id,
            nombre,
            tipo_contribuyente,
            cedula,
            distrito,
            canton,
            telefono,
            email
        )
        SELECT 
            c.contribuyente_id,
            COALESCE(cf.nombre, cj.nombre_empresa, 'Sin nombre') AS nombre,
            CASE 
                WHEN cf.contribuyente_id IS NOT NULL THEN 'Física'
                WHEN cj.contribuyente_id IS NOT NULL THEN 'Jurídica'
                ELSE 'Física'
            END AS tipo_contribuyente,
            COALESCE(cf.cedula, cj.cedula_juridica, 'N/A') AS cedula,
            CASE
                WHEN c.direccion LIKE '%Belén%' OR c.direccion LIKE '%Belen%' OR c.direccion LIKE '%Nosarita%' THEN 'Belén de Nosarita'
                WHEN c.direccion LIKE '%Nosara%' THEN 'Nosara'
                WHEN c.direccion LIKE '%Sámara%' OR c.direccion LIKE '%Samara%' THEN 'Sámara'
                WHEN c.direccion LIKE '%Quebrada Honda%' OR c.direccion LIKE '%Qda Honda%' THEN 'Quebrada Honda'
                WHEN c.direccion LIKE '%San Antonio%' OR c.direccion LIKE '%Sn Antonio%' THEN 'San Antonio'
                WHEN c.direccion LIKE '%Mansión%' OR c.direccion LIKE '%Mansion%' THEN 'Mansión'
                WHEN c.direccion LIKE '%Nicoya%' OR c.direccion LIKE '%Centro%' OR c.direccion LIKE '%centro%' THEN 'Nicoya'
                ELSE 'Nicoya'
            END AS distrito,
            'Nicoya' AS canton,
            c.telefono,
            c.email
        FROM MunicipalidadNicoya.dbo.Contribuyente c
        LEFT JOIN MunicipalidadNicoya.dbo.Contribuyente_Fisico cf ON c.contribuyente_id = cf.contribuyente_id
        LEFT JOIN MunicipalidadNicoya.dbo.Contribuyente_Juridico cj ON c.contribuyente_id = cj.contribuyente_id
        WHERE NOT EXISTS (
            SELECT 1 FROM DM.DIM_Contribuyente dc 
            WHERE dc.contribuyente_id = c.contribuyente_id
        );
        
        SET @registros_nuevos = @@ROWCOUNT;
        
        UPDATE dc
        SET 
            dc.nombre = COALESCE(cf.nombre, cj.nombre_empresa, 'Sin nombre'),
            dc.telefono = c.telefono,
            dc.email = c.email
        FROM DM.DIM_Contribuyente dc
        INNER JOIN MunicipalidadNicoya.dbo.Contribuyente c ON dc.contribuyente_id = c.contribuyente_id
        LEFT JOIN MunicipalidadNicoya.dbo.Contribuyente_Fisico cf ON c.contribuyente_id = cf.contribuyente_id
        LEFT JOIN MunicipalidadNicoya.dbo.Contribuyente_Juridico cj ON c.contribuyente_id = cj.contribuyente_id;
        
        SET @registros_actualizados = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE DM.sp_Actualizar_DIM_Inmueble
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @registros_nuevos INT = 0;
    DECLARE @registros_actualizados INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO DM.DIM_Inmueble (
            inmueble_id,
            numero_finca,
            direccion_exacta,
            distrito,
            canton,
            area_terreno,
            area_construccion,
            uso_inmueble,
            estado_ocupacional,
            valor_fiscal
        )
        SELECT 
            i.inmueble_id,
            'FINCA-' + CAST(i.inmueble_id AS VARCHAR(10)) AS numero_finca,
            i.Direccion_exacta,
            'Nicoya' AS distrito,
            'Nicoya' AS canton,
            i.Area_terreno,
            NULL AS area_construccion,
            t.nombre_uso AS uso_inmueble,
            i.Estado_ocupacional,
            i.valor_fiscal
        FROM MunicipalidadNicoya.dbo.Inmueble i
        LEFT JOIN MunicipalidadNicoya.dbo.TipoUsoInmueble t ON i.tipo_uso_inmueble_id = t.tipo_uso_inmueble_id
        WHERE NOT EXISTS (
            SELECT 1 FROM DM.DIM_Inmueble di 
            WHERE di.inmueble_id = i.inmueble_id
        );
        
        SET @registros_nuevos = @@ROWCOUNT;
        
        UPDATE di
        SET 
            di.direccion_exacta = i.Direccion_exacta,
            di.area_terreno = i.Area_terreno,
            di.uso_inmueble = t.nombre_uso,
            di.estado_ocupacional = i.Estado_ocupacional,
            di.valor_fiscal = i.valor_fiscal
        FROM DM.DIM_Inmueble di
        INNER JOIN MunicipalidadNicoya.dbo.Inmueble i ON di.inmueble_id = i.inmueble_id
        LEFT JOIN MunicipalidadNicoya.dbo.TipoUsoInmueble t ON i.tipo_uso_inmueble_id = t.tipo_uso_inmueble_id;
        
        SET @registros_actualizados = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE DM.sp_Actualizar_DIM_Tramite
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @registros_nuevos INT = 0;
    DECLARE @registros_actualizados INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO DM.DIM_Tramite (
            tramite_id,
            tipo_tramite,
            estado_tramite,
            fecha_ingreso,
            fecha_resolucion,
            dias_resolucion
        )
        SELECT 
            t.tramite_id,
            tt.nombre_tipo AS tipo_tramite,
            t.estado_actual AS estado_tramite,
            t.fecha_ingreso,
            t.fecha_resolucion,
            CASE 
                WHEN t.fecha_resolucion IS NOT NULL 
                THEN DATEDIFF(DAY, t.fecha_ingreso, t.fecha_resolucion)
                ELSE NULL
            END AS dias_resolucion
        FROM MunicipalidadNicoya.dbo.Tramite t
        INNER JOIN MunicipalidadNicoya.dbo.Tipo_Tramite tt ON t.tipo_tramite_id = tt.tipo_tramite_id
        WHERE NOT EXISTS (
            SELECT 1 FROM DM.DIM_Tramite dt 
            WHERE dt.tramite_id = t.tramite_id
        );
        
        SET @registros_nuevos = @@ROWCOUNT;
        
        UPDATE dt
        SET 
            dt.estado_tramite = t.estado_actual,
            dt.fecha_resolucion = t.fecha_resolucion,
            dt.dias_resolucion = CASE 
                WHEN t.fecha_resolucion IS NOT NULL 
                THEN DATEDIFF(DAY, t.fecha_ingreso, t.fecha_resolucion)
                ELSE NULL
            END
        FROM DM.DIM_Tramite dt
        INNER JOIN MunicipalidadNicoya.dbo.Tramite t ON dt.tramite_id = t.tramite_id;
        
        SET @registros_actualizados = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE DM.sp_Actualizar_FACT_Factura
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @registros_nuevos INT = 0;
    DECLARE @registros_actualizados INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
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
            dt_emision.tiempo_id AS tiempo_emision_id,
            dt_venc.tiempo_id AS tiempo_vencimiento_id,
            COALESCE(
                (SELECT t.contribuyente_id 
                 FROM MunicipalidadNicoya.dbo.Tramite t 
                 WHERE t.tramite_id = f.tramite_id),
                (SELECT TOP 1 ci.contribuyente_id
                 FROM MunicipalidadNicoya.dbo.Contribuyente_Inmueble ci
                 WHERE ci.inmueble_id = f.inmueble_id
                 ORDER BY ci.porcentaje_propiedad DESC)
            ) AS contribuyente_id,
            f.inmueble_id,
            (SELECT TOP 1 df.rubro_id 
             FROM MunicipalidadNicoya.dbo.Detalle_factura df 
             WHERE df.factura_id = f.factura_id 
               AND df.rubro_id IS NOT NULL
             ORDER BY (df.monto_unitario * df.cantidad - ISNULL(df.descuento_linea, 0)) DESC) AS rubro_id,
            f.tramite_id,
            ef.estado_id AS estado_factura_id,
            f.monto_base,
            f.recargo,
            f.intereses,
            f.monto_total,
            (SELECT COUNT(*) 
             FROM MunicipalidadNicoya.dbo.Detalle_factura df 
             WHERE df.factura_id = f.factura_id) AS cantidad_lineas,
            COALESCE(
                (SELECT SUM(p.monto_pagado) 
                 FROM MunicipalidadNicoya.dbo.Pago p 
                 WHERE p.factura_id = f.factura_id),
                0
            ) AS monto_pagado,
            f.monto_total - COALESCE(
                (SELECT SUM(p.monto_pagado) 
                 FROM MunicipalidadNicoya.dbo.Pago p 
                 WHERE p.factura_id = f.factura_id),
                0
            ) AS saldo_pendiente,
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
        INNER JOIN DM.DIM_Tiempo dt_emision 
            ON CAST(f.fecha_emision AS DATE) = dt_emision.fecha
        INNER JOIN DM.DIM_Tiempo dt_venc 
            ON f.fecha_vencimiento = dt_venc.fecha
        INNER JOIN DM.DIM_Estado_Factura ef 
            ON f.estado_factura = ef.estado
        WHERE NOT EXISTS (
            SELECT 1 FROM DM.FACT_Factura ff 
            WHERE ff.factura_id = f.factura_id
        )
        AND EXISTS (
            SELECT 1 
            FROM MunicipalidadNicoya.dbo.Detalle_factura df 
            WHERE df.factura_id = f.factura_id 
              AND df.rubro_id IS NOT NULL
        );
        
        SET @registros_nuevos = @@ROWCOUNT;
        
        UPDATE ff
        SET 
            ff.estado_factura_id = ef.estado_id,
            ff.monto_pagado = COALESCE(
                (SELECT SUM(p.monto_pagado) 
                 FROM MunicipalidadNicoya.dbo.Pago p 
                 WHERE p.factura_id = f.factura_id),
                0
            ),
            ff.saldo_pendiente = f.monto_total - COALESCE(
                (SELECT SUM(p.monto_pagado) 
                 FROM MunicipalidadNicoya.dbo.Pago p 
                 WHERE p.factura_id = f.factura_id),
                0
            ),
            ff.esta_vencida = CASE 
                WHEN f.fecha_vencimiento < CAST(GETDATE() AS DATE) 
                     AND f.estado_factura IN ('Pendiente', 'Vencida')
                THEN 1 
                ELSE 0 
            END,
            ff.esta_pagada = CASE 
                WHEN f.estado_factura = 'Pagada' THEN 1 
                ELSE 0 
            END,
            ff.dias_mora = CASE 
                WHEN f.fecha_vencimiento < CAST(GETDATE() AS DATE) 
                     AND f.estado_factura IN ('Pendiente', 'Vencida')
                THEN DATEDIFF(DAY, f.fecha_vencimiento, GETDATE())
                ELSE NULL
            END
        FROM DM.FACT_Factura ff
        INNER JOIN MunicipalidadNicoya.dbo.Factura f ON ff.factura_id = f.factura_id
        INNER JOIN DM.DIM_Estado_Factura ef ON f.estado_factura = ef.estado;
        
        SET @registros_actualizados = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE DM.sp_Actualizar_Datamart_Completo
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @fecha_inicio DATETIME = GETDATE();
    DECLARE @fecha_fin DATETIME;
    
    BEGIN TRY
        EXEC DM.sp_Actualizar_DIM_Contribuyente;
        EXEC DM.sp_Actualizar_DIM_Inmueble;
        EXEC DM.sp_Actualizar_DIM_Tramite;
        EXEC DM.sp_Actualizar_FACT_Factura;
        
        SET @fecha_fin = GETDATE();
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO
