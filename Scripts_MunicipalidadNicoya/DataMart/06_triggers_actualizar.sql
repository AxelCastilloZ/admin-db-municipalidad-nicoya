-- =============================================
-- TRIGGERS PARA ACTUALIZACIÓN AUTOMÁTICA DEL DATAMART
-- VERSIÓN FINAL - Sin errores de subconsultas
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '====================================';
PRINT 'CREANDO TRIGGERS DE ACTUALIZACIÓN';
PRINT '====================================';
PRINT '';

-- =============================================
-- TRIGGER 1: Actualizar DataMart cuando se INSERTA una factura
-- =============================================

IF OBJECT_ID('dbo.trg_Factura_Insert_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Factura_Insert_ActualizarDM;
GO

CREATE TRIGGER trg_Factura_Insert_ActualizarDM
ON dbo.Factura
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FacturaID INT;
    SELECT @FacturaID = factura_id FROM inserted;

    -- Insertar en FACT_Factura las nuevas facturas
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
        i.factura_id,
        dt_emision.tiempo_id,
        dt_venc.tiempo_id,
        
        -- Contribuyente desde el trámite
        (SELECT contribuyente_id 
         FROM dbo.Tramite t 
         WHERE t.tramite_id = i.tramite_id),
        
        i.inmueble_id,
        
        -- Rubro principal (el de mayor monto)
        (SELECT TOP 1 df.rubro_id 
         FROM dbo.Detalle_factura df 
         WHERE df.factura_id = i.factura_id 
         ORDER BY df.monto_unitario * df.cantidad DESC),
        
        i.tramite_id,
        ef.estado_id,
        
        -- MÉTRICAS
        i.monto_base,
        i.recargo,
        i.intereses,
        i.monto_total,
        
        -- Cantidad de líneas
        ISNULL((SELECT COUNT(*) 
                FROM dbo.Detalle_factura df 
                WHERE df.factura_id = i.factura_id), 1),
        
        -- Monto pagado
        ISNULL((SELECT SUM(p.monto_pagado) 
                FROM dbo.Pago p 
                WHERE p.factura_id = i.factura_id), 0),
        
        -- Saldo pendiente
        i.monto_total - ISNULL((SELECT SUM(p.monto_pagado) 
                                FROM dbo.Pago p 
                                WHERE p.factura_id = i.factura_id), 0),
        
        -- Esta vencida
        CASE 
            WHEN i.fecha_vencimiento < CAST(GETDATE() AS DATE) 
                 AND i.estado_factura = 'Pendiente' 
            THEN 1 
            ELSE 0 
        END,
        
        -- Esta pagada
        CASE 
            WHEN i.estado_factura = 'Pagada' THEN 1 
            ELSE 0 
        END,
        
        -- Días de mora
        CASE 
            WHEN i.fecha_vencimiento < CAST(GETDATE() AS DATE) 
                 AND i.estado_factura = 'Pendiente'
            THEN DATEDIFF(DAY, i.fecha_vencimiento, GETDATE())
            ELSE NULL
        END
    FROM inserted i
    LEFT JOIN DM.DIM_Tiempo dt_emision ON CAST(i.fecha_emision AS DATE) = dt_emision.fecha
    LEFT JOIN DM.DIM_Tiempo dt_venc ON i.fecha_vencimiento = dt_venc.fecha
    LEFT JOIN DM.DIM_Estado_Factura ef ON i.estado_factura = ef.estado
    WHERE NOT EXISTS (
        SELECT 1 FROM DM.FACT_Factura 
        WHERE factura_id = i.factura_id
    );
END;
GO

PRINT '✅ Trigger trg_Factura_Insert_ActualizarDM creado';
PRINT '';

-- =============================================
-- TRIGGER 2: Actualizar DataMart cuando se ACTUALIZA una factura
-- =============================================

IF OBJECT_ID('dbo.trg_Factura_Update_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Factura_Update_ActualizarDM;
GO

CREATE TRIGGER trg_Factura_Update_ActualizarDM
ON dbo.Factura
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualizar FACT_Factura con los datos modificados
    UPDATE f
    SET 
        f.tiempo_emision_id = dt_emision.tiempo_id,
        f.tiempo_vencimiento_id = dt_venc.tiempo_id,
        f.estado_factura_id = ef.estado_id,
        f.monto_base = i.monto_base,
        f.recargo = i.recargo,
        f.intereses = i.intereses,
        f.monto_total = i.monto_total,
        f.monto_pagado = ISNULL((SELECT SUM(monto_pagado) 
                                 FROM dbo.Pago 
                                 WHERE factura_id = i.factura_id), 0),
        f.saldo_pendiente = i.monto_total - ISNULL((SELECT SUM(monto_pagado) 
                                                     FROM dbo.Pago 
                                                     WHERE factura_id = i.factura_id), 0),
        f.esta_pagada = CASE WHEN i.estado_factura = 'Pagada' THEN 1 ELSE 0 END,
        f.esta_vencida = CASE 
            WHEN i.fecha_vencimiento < CAST(GETDATE() AS DATE) 
                 AND i.estado_factura = 'Pendiente' 
            THEN 1 
            ELSE 0 
        END,
        f.dias_mora = CASE 
            WHEN i.fecha_vencimiento < CAST(GETDATE() AS DATE) 
                 AND i.estado_factura = 'Pendiente'
            THEN DATEDIFF(DAY, i.fecha_vencimiento, GETDATE())
            ELSE NULL
        END
    FROM DM.FACT_Factura f
    INNER JOIN inserted i ON f.factura_id = i.factura_id
    LEFT JOIN DM.DIM_Tiempo dt_emision ON CAST(i.fecha_emision AS DATE) = dt_emision.fecha
    LEFT JOIN DM.DIM_Tiempo dt_venc ON i.fecha_vencimiento = dt_venc.fecha
    LEFT JOIN DM.DIM_Estado_Factura ef ON i.estado_factura = ef.estado;
END;
GO

PRINT '✅ Trigger trg_Factura_Update_ActualizarDM creado';
PRINT '';

-- =============================================
-- TRIGGER 3: Actualizar DataMart cuando se INSERTA un pago
-- =============================================

IF OBJECT_ID('dbo.trg_Pago_Insert_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Pago_Insert_ActualizarDM;
GO

CREATE TRIGGER trg_Pago_Insert_ActualizarDM
ON dbo.Pago
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualizar los montos pagados y pendientes en FACT_Factura
    UPDATE f
    SET 
        f.monto_pagado = ISNULL((SELECT SUM(monto_pagado) 
                                 FROM dbo.Pago 
                                 WHERE factura_id = i.factura_id), 0),
        f.saldo_pendiente = f.monto_total - ISNULL((SELECT SUM(monto_pagado) 
                                                     FROM dbo.Pago 
                                                     WHERE factura_id = i.factura_id), 0),
        f.esta_pagada = CASE 
            WHEN f.monto_total <= ISNULL((SELECT SUM(monto_pagado) 
                                          FROM dbo.Pago 
                                          WHERE factura_id = i.factura_id), 0) 
            THEN 1 
            ELSE 0 
        END,
        f.esta_vencida = CASE 
            WHEN fa.fecha_vencimiento < CAST(GETDATE() AS DATE)
                AND f.monto_total > ISNULL((SELECT SUM(monto_pagado) 
                                            FROM dbo.Pago 
                                            WHERE factura_id = i.factura_id), 0)
            THEN 1 
            ELSE 0 
        END,
        f.dias_mora = CASE 
            WHEN fa.fecha_vencimiento < CAST(GETDATE() AS DATE)
                AND f.monto_total > ISNULL((SELECT SUM(monto_pagado) 
                                            FROM dbo.Pago 
                                            WHERE factura_id = i.factura_id), 0)
            THEN DATEDIFF(DAY, fa.fecha_vencimiento, GETDATE())
            ELSE NULL
        END
    FROM DM.FACT_Factura f
    INNER JOIN inserted i ON f.factura_id = i.factura_id
    INNER JOIN dbo.Factura fa ON fa.factura_id = i.factura_id;

    -- Si está completamente pagada, actualizar el estado en Factura transaccional
    UPDATE fa
    SET fa.estado_factura = 'Pagada'
    FROM dbo.Factura fa
    INNER JOIN inserted i ON fa.factura_id = i.factura_id
    WHERE fa.monto_total <= (SELECT SUM(monto_pagado) 
                             FROM dbo.Pago 
                             WHERE factura_id = i.factura_id)
      AND fa.estado_factura != 'Pagada';
END;
GO

PRINT '✅ Trigger trg_Pago_Insert_ActualizarDM creado';
PRINT '';

-- =============================================
-- TRIGGER 4: Actualizar dimensión de contribuyentes (FÍSICOS)
-- =============================================

IF OBJECT_ID('dbo.trg_ContribuyenteFisico_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_ContribuyenteFisico_ActualizarDM;
GO

CREATE TRIGGER trg_ContribuyenteFisico_ActualizarDM
ON dbo.Contribuyente_fisico
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualizar o insertar en DIM_Contribuyente
    MERGE INTO DM.DIM_Contribuyente AS target
    USING (
        SELECT 
            cf.contribuyente_id,
            cf.nombre AS nombre,
            cf.cedula,
            'Física' AS tipo_contribuyente,
            c.telefono,
            c.email
        FROM inserted cf
        INNER JOIN dbo.Contribuyente c ON cf.contribuyente_id = c.contribuyente_id
    ) AS source
    ON target.contribuyente_id = source.contribuyente_id
    WHEN MATCHED THEN
        UPDATE SET
            target.nombre = source.nombre,
            target.cedula = source.cedula,
            target.tipo_contribuyente = source.tipo_contribuyente,
            target.telefono = source.telefono,
            target.email = source.email
    WHEN NOT MATCHED THEN
        INSERT (contribuyente_id, nombre, cedula, tipo_contribuyente, distrito, canton, telefono, email)
        VALUES (source.contribuyente_id, source.nombre, source.cedula, 
                source.tipo_contribuyente, NULL, 'Nicoya', source.telefono, source.email);
END;
GO

PRINT '✅ Trigger trg_ContribuyenteFisico_ActualizarDM creado';
PRINT '';

-- =============================================
-- TRIGGER 5: Actualizar dimensión de contribuyentes (JURÍDICOS)
-- =============================================

IF OBJECT_ID('dbo.trg_ContribuyenteJuridico_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_ContribuyenteJuridico_ActualizarDM;
GO

CREATE TRIGGER trg_ContribuyenteJuridico_ActualizarDM
ON dbo.Contribuyente_juridico
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualizar o insertar en DIM_Contribuyente
    MERGE INTO DM.DIM_Contribuyente AS target
    USING (
        SELECT 
            cj.contribuyente_id,
            cj.nombre_empresa AS nombre,
            cj.cedula_juridica AS cedula,
            'Jurídica' AS tipo_contribuyente,
            c.telefono,
            c.email
        FROM inserted cj
        INNER JOIN dbo.Contribuyente c ON cj.contribuyente_id = c.contribuyente_id
    ) AS source
    ON target.contribuyente_id = source.contribuyente_id
    WHEN MATCHED THEN
        UPDATE SET
            target.nombre = source.nombre,
            target.cedula = source.cedula,
            target.tipo_contribuyente = source.tipo_contribuyente,
            target.telefono = source.telefono,
            target.email = source.email
    WHEN NOT MATCHED THEN
        INSERT (contribuyente_id, nombre, cedula, tipo_contribuyente, distrito, canton, telefono, email)
        VALUES (source.contribuyente_id, source.nombre, source.cedula, 
                source.tipo_contribuyente, NULL, 'Nicoya', source.telefono, source.email);
END;
GO

PRINT '✅ Trigger trg_ContribuyenteJuridico_ActualizarDM creado';
PRINT '';

-- =============================================
-- TRIGGER 6: Actualizar dimensión de inmuebles
-- =============================================

IF OBJECT_ID('dbo.trg_Inmueble_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Inmueble_ActualizarDM;
GO

CREATE TRIGGER trg_Inmueble_ActualizarDM
ON dbo.Inmueble
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualizar o insertar en DIM_Inmueble
    MERGE INTO DM.DIM_Inmueble AS target
    USING (
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
        FROM inserted i
        LEFT JOIN dbo.TipoUsoInmueble t ON i.tipo_uso_inmueble_id = t.tipo_uso_inmueble_id
    ) AS source
    ON target.inmueble_id = source.inmueble_id
    WHEN MATCHED THEN
        UPDATE SET
            target.numero_finca = source.numero_finca,
            target.direccion_exacta = source.Direccion_exacta,
            target.distrito = source.distrito,
            target.canton = source.canton,
            target.area_terreno = source.Area_terreno,
            target.area_construccion = source.area_construccion,
            target.uso_inmueble = source.uso_inmueble,
            target.estado_ocupacional = source.Estado_ocupacional,
            target.valor_fiscal = source.valor_fiscal
    WHEN NOT MATCHED THEN
        INSERT (inmueble_id, numero_finca, direccion_exacta, distrito, canton, 
                area_terreno, area_construccion, uso_inmueble, estado_ocupacional, valor_fiscal)
        VALUES (source.inmueble_id, source.numero_finca, source.Direccion_exacta, 
                source.distrito, source.canton, source.Area_terreno, source.area_construccion,
                source.uso_inmueble, source.Estado_ocupacional, source.valor_fiscal);
END;
GO

PRINT '✅ Trigger trg_Inmueble_ActualizarDM creado';
PRINT '';

-- =============================================
-- TRIGGER 7: Actualizar dimensión de trámites
-- =============================================

IF OBJECT_ID('dbo.trg_Tramite_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Tramite_ActualizarDM;
GO

CREATE TRIGGER trg_Tramite_ActualizarDM
ON dbo.Tramite
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualizar o insertar en DIM_Tramite
    MERGE INTO DM.DIM_Tramite AS target
    USING (
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
        FROM inserted t
        INNER JOIN dbo.Tipo_Tramite tt ON t.tipo_tramite_id = tt.tipo_tramite_id
    ) AS source
    ON target.tramite_id = source.tramite_id
    WHEN MATCHED THEN
        UPDATE SET
            target.tipo_tramite = source.tipo_tramite,
            target.estado_tramite = source.estado_tramite,
            target.fecha_ingreso = source.fecha_ingreso,
            target.fecha_resolucion = source.fecha_resolucion,
            target.dias_resolucion = source.dias_resolucion
    WHEN NOT MATCHED THEN
        INSERT (tramite_id, tipo_tramite, estado_tramite, fecha_ingreso, fecha_resolucion, dias_resolucion)
        VALUES (source.tramite_id, source.tipo_tramite, source.estado_tramite, 
                source.fecha_ingreso, source.fecha_resolucion, source.dias_resolucion);
END;
GO

PRINT '✅ Trigger trg_Tramite_ActualizarDM creado';
PRINT '';

-- =============================================
-- VERIFICAR QUE LOS TRIGGERS ESTÁN ACTIVOS
-- =============================================

PRINT '';
PRINT '====================================';
PRINT 'VERIFICACIÓN DE TRIGGERS';
PRINT '====================================';
PRINT '';

SELECT 
    name AS NombreTrigger,
    OBJECT_NAME(parent_id) AS TablaAsociada,
    CASE WHEN is_disabled = 0 THEN 'Activo' ELSE 'Deshabilitado' END AS Estado,
    create_date AS FechaCreacion
FROM sys.triggers
WHERE name LIKE 'trg_%ActualizarDM'
ORDER BY name;

PRINT '';
PRINT '====================================';
PRINT '✅ TODOS LOS TRIGGERS CREADOS';
PRINT '====================================';
PRINT '';
PRINT 'El DataMart se actualizará automáticamente cuando:';
PRINT '  ✅ Se inserte/actualice una factura';
PRINT '  ✅ Se registre un pago';
PRINT '  ✅ Se modifique un contribuyente';
PRINT '  ✅ Se modifique un inmueble';
PRINT '  ✅ Se modifique un trámite';
PRINT '';
PRINT '🧪 PRUEBA:';
PRINT '  1. Inserta una factura desde tu API';
PRINT '  2. Consulta: SELECT TOP 1 * FROM DM.FACT_Factura ORDER BY fact_factura_id DESC';
PRINT '  3. Verifica en Swagger: GET /api/reporte/kpis';
PRINT '';

GO