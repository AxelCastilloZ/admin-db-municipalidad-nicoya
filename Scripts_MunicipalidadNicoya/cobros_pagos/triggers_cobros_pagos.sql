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




-- Eliminar trigger si existe
IF OBJECT_ID('dbo.trg_verificar_vencimiento_post_emision', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_verificar_vencimiento_post_emision;
GO

CREATE TRIGGER dbo.trg_verificar_vencimiento_post_emision
ON dbo.Factura
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- La fecha actual (sólo fecha)
    DECLARE @fecha_actual DATE = CAST(GETDATE() AS DATE);
    
    -- =============================================
    -- ACTUALIZAR FACTURAS RECIÉN INSERTADAS SI ESTÁN VENCIDAS
    -- =============================================
    
    UPDATE f
    SET 
        estado_factura = 'Vencida'
    -- Se unen las facturas recién insertadas (INSERTED) con la tabla Factura (f)
    FROM dbo.Factura f
    INNER JOIN INSERTED i ON f.factura_id = i.factura_id
    WHERE 
        -- Condición 1: El estado actual debe ser 'Pendiente' (estado por defecto de la inserción)
        f.estado_factura = 'Pendiente' 
        -- Condición 2: La fecha de vencimiento es anterior a la fecha de hoy
        AND f.fecha_vencimiento < @fecha_actual;
        
    -- NOTA: No es necesario usar la tabla DELETED ya que este es un trigger AFTER INSERT.
    -- Los triggers de auditoría existentes (si los hubiera) registrarán este cambio de estado.
END
GO

PRINT ' Trigger trg_verificar_vencimiento_post_emision creado exitosamente';












