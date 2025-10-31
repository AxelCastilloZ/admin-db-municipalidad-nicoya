-- =============================================
-- TRIGGERS PARA ACTUALIZACIÓN AUTOMÁTICA DEL DATAMART
-- Base de datos origen: MunicipalidadNicoya
-- Base de datos destino: MunicipalidadNicoyaDataMart
-- =============================================

USE MunicipalidadNicoya;
GO

IF OBJECT_ID('dbo.trg_Factura_Insert_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Factura_Insert_ActualizarDM;
GO

CREATE TRIGGER trg_Factura_Insert_ActualizarDM
ON dbo.Factura
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO MunicipalidadNicoyaDataMart.DM.FACT_Factura (
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
        (SELECT contribuyente_id 
         FROM dbo.Tramite t 
         WHERE t.tramite_id = i.tramite_id),
        i.inmueble_id,
        (SELECT TOP 1 df.rubro_id 
         FROM dbo.Detalle_factura df 
         WHERE df.factura_id = i.factura_id 
         ORDER BY df.monto_unitario * df.cantidad DESC),
        i.tramite_id,
        ef.estado_id,
        i.monto_base,
        i.recargo,
        i.intereses,
        i.monto_total,
        ISNULL((SELECT COUNT(*) 
                FROM dbo.Detalle_factura df 
                WHERE df.factura_id = i.factura_id), 1),
        ISNULL((SELECT SUM(p.monto_pagado) 
                FROM dbo.Pago p 
                WHERE p.factura_id = i.factura_id), 0),
        i.monto_total - ISNULL((SELECT SUM(p.monto_pagado) 
                                FROM dbo.Pago p 
                                WHERE p.factura_id = i.factura_id), 0),
        CASE 
            WHEN i.fecha_vencimiento < CAST(GETDATE() AS DATE) 
                 AND i.estado_factura = 'Pendiente' 
            THEN 1 
            ELSE 0 
        END,
        CASE 
            WHEN i.estado_factura = 'Pagada' THEN 1 
            ELSE 0 
        END,
        CASE 
            WHEN i.fecha_vencimiento < CAST(GETDATE() AS DATE) 
                 AND i.estado_factura = 'Pendiente'
            THEN DATEDIFF(DAY, i.fecha_vencimiento, GETDATE())
            ELSE NULL
        END
    FROM inserted i
    LEFT JOIN MunicipalidadNicoyaDataMart.DM.DIM_Tiempo dt_emision ON CAST(i.fecha_emision AS DATE) = dt_emision.fecha
    LEFT JOIN MunicipalidadNicoyaDataMart.DM.DIM_Tiempo dt_venc ON i.fecha_vencimiento = dt_venc.fecha
    LEFT JOIN MunicipalidadNicoyaDataMart.DM.DIM_Estado_Factura ef ON i.estado_factura = ef.estado
    WHERE NOT EXISTS (
        SELECT 1 FROM MunicipalidadNicoyaDataMart.DM.FACT_Factura 
        WHERE factura_id = i.factura_id
    );
END;
GO

IF OBJECT_ID('dbo.trg_Factura_Update_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Factura_Update_ActualizarDM;
GO

CREATE TRIGGER trg_Factura_Update_ActualizarDM
ON dbo.Factura
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

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
    FROM MunicipalidadNicoyaDataMart.DM.FACT_Factura f
    INNER JOIN inserted i ON f.factura_id = i.factura_id
    LEFT JOIN MunicipalidadNicoyaDataMart.DM.DIM_Tiempo dt_emision ON CAST(i.fecha_emision AS DATE) = dt_emision.fecha
    LEFT JOIN MunicipalidadNicoyaDataMart.DM.DIM_Tiempo dt_venc ON i.fecha_vencimiento = dt_venc.fecha
    LEFT JOIN MunicipalidadNicoyaDataMart.DM.DIM_Estado_Factura ef ON i.estado_factura = ef.estado;
END;
GO

IF OBJECT_ID('dbo.trg_Pago_Insert_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Pago_Insert_ActualizarDM;
GO

CREATE TRIGGER trg_Pago_Insert_ActualizarDM
ON dbo.Pago
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

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
    FROM MunicipalidadNicoyaDataMart.DM.FACT_Factura f
    INNER JOIN inserted i ON f.factura_id = i.factura_id
    INNER JOIN dbo.Factura fa ON fa.factura_id = i.factura_id;

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

IF OBJECT_ID('dbo.trg_ContribuyenteFisico_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_ContribuyenteFisico_ActualizarDM;
GO

CREATE TRIGGER trg_ContribuyenteFisico_ActualizarDM
ON dbo.Contribuyente_fisico
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO MunicipalidadNicoyaDataMart.DM.DIM_Contribuyente AS target
    USING (
        SELECT 
            cf.contribuyente_id,
            cf.nombre AS nombre,
            cf.cedula,
            'Física' AS tipo_contribuyente,
            c.telefono,
            c.email,
            CASE
                WHEN c.direccion LIKE '%Belén%' OR c.direccion LIKE '%Belen%' OR c.direccion LIKE '%Nosarita%' THEN 'Belén de Nosarita'
                WHEN c.direccion LIKE '%Nosara%' THEN 'Nosara'
                WHEN c.direccion LIKE '%Sámara%' OR c.direccion LIKE '%Samara%' THEN 'Sámara'
                WHEN c.direccion LIKE '%Quebrada Honda%' OR c.direccion LIKE '%Qda Honda%' THEN 'Quebrada Honda'
                WHEN c.direccion LIKE '%San Antonio%' OR c.direccion LIKE '%Sn Antonio%' THEN 'San Antonio'
                WHEN c.direccion LIKE '%Mansión%' OR c.direccion LIKE '%Mansion%' THEN 'Mansión'
                WHEN c.direccion LIKE '%Nicoya%' OR c.direccion LIKE '%Centro%' OR c.direccion LIKE '%centro%' THEN 'Nicoya'
                ELSE 'Nicoya'
            END AS distrito
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
            target.email = source.email,
            target.distrito = source.distrito
    WHEN NOT MATCHED THEN
        INSERT (contribuyente_id, nombre, cedula, tipo_contribuyente, distrito, canton, telefono, email)
        VALUES (source.contribuyente_id, source.nombre, source.cedula, 
                source.tipo_contribuyente, source.distrito, 'Nicoya', source.telefono, source.email);
END;
GO

IF OBJECT_ID('dbo.trg_ContribuyenteJuridico_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_ContribuyenteJuridico_ActualizarDM;
GO

CREATE TRIGGER trg_ContribuyenteJuridico_ActualizarDM
ON dbo.Contribuyente_juridico
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO MunicipalidadNicoyaDataMart.DM.DIM_Contribuyente AS target
    USING (
        SELECT 
            cj.contribuyente_id,
            cj.nombre_empresa AS nombre,
            cj.cedula_juridica AS cedula,
            'Jurídica' AS tipo_contribuyente,
            c.telefono,
            c.email,
            CASE
                WHEN c.direccion LIKE '%Belén%' OR c.direccion LIKE '%Belen%' OR c.direccion LIKE '%Nosarita%' THEN 'Belén de Nosarita'
                WHEN c.direccion LIKE '%Nosara%' THEN 'Nosara'
                WHEN c.direccion LIKE '%Sámara%' OR c.direccion LIKE '%Samara%' THEN 'Sámara'
                WHEN c.direccion LIKE '%Quebrada Honda%' OR c.direccion LIKE '%Qda Honda%' THEN 'Quebrada Honda'
                WHEN c.direccion LIKE '%San Antonio%' OR c.direccion LIKE '%Sn Antonio%' THEN 'San Antonio'
                WHEN c.direccion LIKE '%Mansión%' OR c.direccion LIKE '%Mansion%' THEN 'Mansión'
                WHEN c.direccion LIKE '%Nicoya%' OR c.direccion LIKE '%Centro%' OR c.direccion LIKE '%centro%' THEN 'Nicoya'
                ELSE 'Nicoya'
            END AS distrito
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
            target.email = source.email,
            target.distrito = source.distrito
    WHEN NOT MATCHED THEN
        INSERT (contribuyente_id, nombre, cedula, tipo_contribuyente, distrito, canton, telefono, email)
        VALUES (source.contribuyente_id, source.nombre, source.cedula, 
                source.tipo_contribuyente, source.distrito, 'Nicoya', source.telefono, source.email);
END;
GO

IF OBJECT_ID('dbo.trg_Inmueble_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Inmueble_ActualizarDM;
GO

CREATE TRIGGER trg_Inmueble_ActualizarDM
ON dbo.Inmueble
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO MunicipalidadNicoyaDataMart.DM.DIM_Inmueble AS target
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

IF OBJECT_ID('dbo.trg_Tramite_ActualizarDM', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_Tramite_ActualizarDM;
GO

CREATE TRIGGER trg_Tramite_ActualizarDM
ON dbo.Tramite
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    MERGE INTO MunicipalidadNicoyaDataMart.DM.DIM_Tramite AS target
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

SELECT 
    name AS NombreTrigger,
    OBJECT_NAME(parent_id) AS TablaAsociada,
    CASE WHEN is_disabled = 0 THEN 'Activo' ELSE 'Deshabilitado' END AS Estado,
    create_date AS FechaCreacion
FROM sys.triggers
WHERE name LIKE 'trg_%ActualizarDM'
ORDER BY name;
GO