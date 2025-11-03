-- =============================================
-- TRIGGER: trg_actualizar_monto_factura
-- Tabla: Detalle_factura
-- Evento: AFTER INSERT, UPDATE, DELETE
-- Descripción: Recalcula automáticamente monto_base y monto_total 

USE MunicipalidadNicoya;
GO

-- Eliminar trigger si existe
IF OBJECT_ID('dbo.trg_actualizar_monto_factura', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_actualizar_monto_factura;
GO

CREATE TRIGGER dbo.trg_actualizar_monto_factura
ON dbo.Detalle_factura
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- =============================================
    -- IDENTIFICAR FACTURAS AFECTADAS
    -- =============================================
    
    -- Tabla temporal para almacenar facturas que necesitan recalcular montos
    DECLARE @facturas_afectadas TABLE (factura_id INT);
    
    -- Recoger facturas de los registros insertados/actualizados
    INSERT INTO @facturas_afectadas (factura_id)
    SELECT DISTINCT factura_id FROM INSERTED
    WHERE factura_id IS NOT NULL;
    
    -- Recoger facturas de los registros eliminados
    INSERT INTO @facturas_afectadas (factura_id)
    SELECT DISTINCT factura_id FROM DELETED
    WHERE factura_id IS NOT NULL
    AND factura_id NOT IN (SELECT factura_id FROM @facturas_afectadas);
    
    -- =============================================
    -- RECALCULAR MONTOS DE CADA FACTURA AFECTADA
    -- =============================================
    
    UPDATE f
    SET 
        -- Recalcular monto_base: suma de todos los detalles
        monto_base = ISNULL((
            SELECT SUM((df.cantidad * df.monto_unitario) - df.descuento_linea)
            FROM dbo.Detalle_factura df
            WHERE df.factura_id = f.factura_id
        ), 0),
        
        -- Recalcular monto_total: monto_base + recargo + intereses
        monto_total = ISNULL((
            SELECT SUM((df.cantidad * df.monto_unitario) - df.descuento_linea)
            FROM dbo.Detalle_factura df
            WHERE df.factura_id = f.factura_id
        ), 0) + f.recargo + f.intereses
        
    FROM dbo.Factura f
    WHERE f.factura_id IN (SELECT factura_id FROM @facturas_afectadas);
    
    -- =============================================
    -- NOTA: Este trigger se ejecuta automáticamente
    -- después de INSERT, UPDATE o DELETE en Detalle_factura
    -- =============================================
END
GO

PRINT ' Trigger trg_actualizar_monto_factura creado exitosamente';
GO







-- =============================================
-- TRIGGER: trg_actualizar_estado_factura
-- Tabla: Pago
-- Evento: AFTER INSERT
-- Descripción: Actualiza automáticamente el estado de la factura 
--              a 'Pagada' cuando se registra un pago
-- =============================================

USE MunicipalidadNicoya;
GO

-- Eliminar trigger si existe
IF OBJECT_ID('dbo.trg_actualizar_estado_factura', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_actualizar_estado_factura;
GO

CREATE TRIGGER dbo.trg_actualizar_estado_factura
ON dbo.Pago
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- =============================================
    -- ACTUALIZAR ESTADO DE FACTURAS A 'PAGADA'
    -- =============================================
    
    -- Cambiar estado de todas las facturas asociadas a los pagos insertados
    UPDATE f
    SET estado_factura = 'Pagada'
    FROM dbo.Factura f
    INNER JOIN INSERTED i ON f.factura_id = i.factura_id;
    
    -- =============================================
    -- NOTA: 
    -- - El SP sp_registrar_pago ya validó que monto_pagado = monto_total
    -- - Solo se permite 1 pago por factura (validado en SP)
    -- - Este trigger simplemente actualiza el estado
    -- =============================================
END
GO

PRINT ' Trigger trg_actualizar_estado_factura creado exitosamente';
GO














