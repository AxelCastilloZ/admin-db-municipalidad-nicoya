-- =============================================
-- PROCEDIMIENTOS ALMACENADOS - ACTUALIZACIÓN DATAMART
-- Automatización del proceso ETL para actualizaciones incrementales
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '';
PRINT '========================================';
PRINT '⚙️ CREANDO PROCEDIMIENTOS ETL';
PRINT '========================================';
PRINT '';
GO

-- =============================================
-- SP 1: Actualizar Dimensión Contribuyente
-- =============================================

CREATE OR ALTER PROCEDURE DM.sp_Actualizar_DIM_Contribuyente
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @registros_nuevos INT = 0;
    DECLARE @registros_actualizados INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insertar nuevos contribuyentes
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
            NULL AS distrito,
            'Nicoya' AS canton,
            c.telefono,
            c.email
        FROM dbo.Contribuyente c
        LEFT JOIN dbo.Contribuyente_Fisico cf ON c.contribuyente_id = cf.contribuyente_id
        LEFT JOIN dbo.Contribuyente_Juridico cj ON c.contribuyente_id = cj.contribuyente_id
        WHERE NOT EXISTS (
            SELECT 1 FROM DM.DIM_Contribuyente dc 
            WHERE dc.contribuyente_id = c.contribuyente_id
        );
        
        SET @registros_nuevos = @@ROWCOUNT;
        
        -- Actualizar contribuyentes existentes
        UPDATE dc
        SET 
            dc.nombre = COALESCE(cf.nombre, cj.nombre_empresa, 'Sin nombre'),
            dc.telefono = c.telefono,
            dc.email = c.email
        FROM DM.DIM_Contribuyente dc
        INNER JOIN dbo.Contribuyente c ON dc.contribuyente_id = c.contribuyente_id
        LEFT JOIN dbo.Contribuyente_Fisico cf ON c.contribuyente_id = cf.contribuyente_id
        LEFT JOIN dbo.Contribuyente_Juridico cj ON c.contribuyente_id = cj.contribuyente_id;
        
        SET @registros_actualizados = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        PRINT '✓ DIM_Contribuyente actualizada:';
        PRINT '  - Nuevos: ' + CAST(@registros_nuevos AS VARCHAR);
        PRINT '  - Actualizados: ' + CAST(@registros_actualizados AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT '❌ Error al actualizar DIM_Contribuyente:';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

-- =============================================
-- SP 2: Actualizar Dimensión Inmueble
-- =============================================

CREATE OR ALTER PROCEDURE DM.sp_Actualizar_DIM_Inmueble
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @registros_nuevos INT = 0;
    DECLARE @registros_actualizados INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insertar nuevos inmuebles
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
        FROM dbo.Inmueble i
        LEFT JOIN dbo.TipoUsoInmueble t ON i.tipo_uso_inmueble_id = t.tipo_uso_inmueble_id
        WHERE NOT EXISTS (
            SELECT 1 FROM DM.DIM_Inmueble di 
            WHERE di.inmueble_id = i.inmueble_id
        );
        
        SET @registros_nuevos = @@ROWCOUNT;
        
        -- Actualizar inmuebles existentes
        UPDATE di
        SET 
            di.direccion_exacta = i.Direccion_exacta,
            di.area_terreno = i.Area_terreno,
            di.uso_inmueble = t.nombre_uso,
            di.estado_ocupacional = i.Estado_ocupacional,
            di.valor_fiscal = i.valor_fiscal
        FROM DM.DIM_Inmueble di
        INNER JOIN dbo.Inmueble i ON di.inmueble_id = i.inmueble_id
        LEFT JOIN dbo.TipoUsoInmueble t ON i.tipo_uso_inmueble_id = t.tipo_uso_inmueble_id;
        
        SET @registros_actualizados = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        PRINT '✓ DIM_Inmueble actualizada:';
        PRINT '  - Nuevos: ' + CAST(@registros_nuevos AS VARCHAR);
        PRINT '  - Actualizados: ' + CAST(@registros_actualizados AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT '❌ Error al actualizar DIM_Inmueble:';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

-- =============================================
-- SP 3: Actualizar Dimensión Trámite
-- =============================================

CREATE OR ALTER PROCEDURE DM.sp_Actualizar_DIM_Tramite
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @registros_nuevos INT = 0;
    DECLARE @registros_actualizados INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insertar nuevos trámites
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
        FROM dbo.Tramite t
        INNER JOIN dbo.Tipo_Tramite tt ON t.tipo_tramite_id = tt.tipo_tramite_id
        WHERE NOT EXISTS (
            SELECT 1 FROM DM.DIM_Tramite dt 
            WHERE dt.tramite_id = t.tramite_id
        );
        
        SET @registros_nuevos = @@ROWCOUNT;
        
        -- Actualizar trámites existentes (estado puede cambiar)
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
        INNER JOIN dbo.Tramite t ON dt.tramite_id = t.tramite_id;
        
        SET @registros_actualizados = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        PRINT '✓ DIM_Tramite actualizada:';
        PRINT '  - Nuevos: ' + CAST(@registros_nuevos AS VARCHAR);
        PRINT '  - Actualizados: ' + CAST(@registros_actualizados AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT '❌ Error al actualizar DIM_Tramite:';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

-- =============================================
-- SP 4: Actualizar Tabla de Hechos (Incremental)
-- =============================================

CREATE OR ALTER PROCEDURE DM.sp_Actualizar_FACT_Factura
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @registros_nuevos INT = 0;
    DECLARE @registros_actualizados INT = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Insertar nuevas facturas
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
            (SELECT t.contribuyente_id 
             FROM dbo.Tramite t 
             WHERE t.tramite_id = f.tramite_id) AS contribuyente_id,
            f.inmueble_id,
            (SELECT TOP 1 df.rubro_id 
             FROM dbo.Detalle_factura df 
             WHERE df.factura_id = f.factura_id 
             ORDER BY df.monto_unitario * df.cantidad DESC) AS rubro_id,
            f.tramite_id,
            ef.estado_id AS estado_factura_id,
            f.monto_base,
            f.recargo,
            f.intereses,
            f.monto_total,
            (SELECT COUNT(*) 
             FROM dbo.Detalle_factura df 
             WHERE df.factura_id = f.factura_id) AS cantidad_lineas,
            COALESCE(
                (SELECT SUM(p.monto_pagado) 
                 FROM dbo.Pago p 
                 WHERE p.factura_id = f.factura_id),
                0
            ) AS monto_pagado,
            f.monto_total - COALESCE(
                (SELECT SUM(p.monto_pagado) 
                 FROM dbo.Pago p 
                 WHERE p.factura_id = f.factura_id),
                0
            ) AS saldo_pendiente,
            CASE 
                WHEN f.fecha_vencimiento < CAST(GETDATE() AS DATE) 
                     AND f.estado_factura = 'Pendiente' 
                THEN 1 
                ELSE 0 
            END AS esta_vencida,
            CASE 
                WHEN f.estado_factura = 'Pagada' THEN 1 
                ELSE 0 
            END AS esta_pagada,
            CASE 
                WHEN f.fecha_vencimiento < CAST(GETDATE() AS DATE) 
                     AND f.estado_factura = 'Pendiente'
                THEN DATEDIFF(DAY, f.fecha_vencimiento, GETDATE())
                ELSE NULL
            END AS dias_mora
        FROM dbo.Factura f
        INNER JOIN DM.DIM_Tiempo dt_emision 
            ON CAST(f.fecha_emision AS DATE) = dt_emision.fecha
        INNER JOIN DM.DIM_Tiempo dt_venc 
            ON f.fecha_vencimiento = dt_venc.fecha
        INNER JOIN DM.DIM_Estado_Factura ef 
            ON f.estado_factura = ef.estado
        WHERE NOT EXISTS (
            SELECT 1 FROM DM.FACT_Factura ff 
            WHERE ff.factura_id = f.factura_id
        );
        
        SET @registros_nuevos = @@ROWCOUNT;
        
        -- Actualizar facturas existentes (estados y pagos pueden cambiar)
        UPDATE ff
        SET 
            ff.estado_factura_id = ef.estado_id,
            ff.monto_pagado = COALESCE(
                (SELECT SUM(p.monto_pagado) 
                 FROM dbo.Pago p 
                 WHERE p.factura_id = f.factura_id),
                0
            ),
            ff.saldo_pendiente = f.monto_total - COALESCE(
                (SELECT SUM(p.monto_pagado) 
                 FROM dbo.Pago p 
                 WHERE p.factura_id = f.factura_id),
                0
            ),
            ff.esta_vencida = CASE 
                WHEN f.fecha_vencimiento < CAST(GETDATE() AS DATE) 
                     AND f.estado_factura = 'Pendiente' 
                THEN 1 
                ELSE 0 
            END,
            ff.esta_pagada = CASE 
                WHEN f.estado_factura = 'Pagada' THEN 1 
                ELSE 0 
            END,
            ff.dias_mora = CASE 
                WHEN f.fecha_vencimiento < CAST(GETDATE() AS DATE) 
                     AND f.estado_factura = 'Pendiente'
                THEN DATEDIFF(DAY, f.fecha_vencimiento, GETDATE())
                ELSE NULL
            END
        FROM DM.FACT_Factura ff
        INNER JOIN dbo.Factura f ON ff.factura_id = f.factura_id
        INNER JOIN DM.DIM_Estado_Factura ef ON f.estado_factura = ef.estado;
        
        SET @registros_actualizados = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        PRINT '✓ FACT_Factura actualizada:';
        PRINT '  - Nuevas: ' + CAST(@registros_nuevos AS VARCHAR);
        PRINT '  - Actualizadas: ' + CAST(@registros_actualizados AS VARCHAR);
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        PRINT '❌ Error al actualizar FACT_Factura:';
        PRINT ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

-- =============================================
-- SP 5: Actualizar TODO el Datamart (Master)
-- =============================================

CREATE OR ALTER PROCEDURE DM.sp_Actualizar_Datamart_Completo
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @fecha_inicio DATETIME = GETDATE();
    DECLARE @fecha_fin DATETIME;
    
    PRINT '';
    PRINT '========================================';
    PRINT '🔄 ACTUALIZANDO DATAMART COMPLETO';
    PRINT '========================================';
    PRINT '';
    PRINT 'Fecha Inicio: ' + CONVERT(VARCHAR, @fecha_inicio, 120);
    PRINT '';
    
    BEGIN TRY
        -- 1. Actualizar dimensiones
        PRINT '📋 Paso 1: Actualizando Dimensiones...';
        EXEC DM.sp_Actualizar_DIM_Contribuyente;
        EXEC DM.sp_Actualizar_DIM_Inmueble;
        EXEC DM.sp_Actualizar_DIM_Tramite;
        PRINT '';
        
        -- 2. Actualizar tabla de hechos
        PRINT '📊 Paso 2: Actualizando Tabla de Hechos...';
        EXEC DM.sp_Actualizar_FACT_Factura;
        PRINT '';
        
        SET @fecha_fin = GETDATE();
        
        PRINT '========================================';
        PRINT '✅ DATAMART ACTUALIZADO EXITOSAMENTE';
        PRINT '========================================';
        PRINT '';
        PRINT 'Fecha Fin: ' + CONVERT(VARCHAR, @fecha_fin, 120);
        PRINT 'Tiempo Total: ' + CAST(DATEDIFF(SECOND, @fecha_inicio, @fecha_fin) AS VARCHAR) + ' segundos';
        PRINT '';
        
    END TRY
    BEGIN CATCH
        PRINT '';
        PRINT '========================================';
        PRINT '❌ ERROR AL ACTUALIZAR DATAMART';
        PRINT '========================================';
        PRINT ERROR_MESSAGE();
        PRINT '';
        THROW;
    END CATCH
END;
GO

PRINT '';
PRINT '========================================';
PRINT '✅ PROCEDIMIENTOS ETL CREADOS';
PRINT '========================================';
PRINT '';
PRINT 'Procedimientos disponibles:';
PRINT '  • DM.sp_Actualizar_DIM_Contribuyente';
PRINT '  • DM.sp_Actualizar_DIM_Inmueble';
PRINT '  • DM.sp_Actualizar_DIM_Tramite';
PRINT '  • DM.sp_Actualizar_FACT_Factura';
PRINT '  • DM.sp_Actualizar_Datamart_Completo';
PRINT '';
PRINT 'Para actualizar el Datamart ejecuta:';
PRINT '  EXEC DM.sp_Actualizar_Datamart_Completo';
PRINT '========================================';
GO