




-- =============================================
-- AUDITORIA : FACTURAS Y PAGOS
-- =============================================
USE MunicipalidadNicoya;
GO

PRINT '';
PRINT '========================================';
PRINT ' AUDITORIA';
PRINT '   Tablas: Factura y Pago';
PRINT '========================================';
PRINT '';

-- =============================================
-- PASO 1: Crear tabla de auditoría para FACTURA
-- =============================================
PRINT ' Creando tabla Factura_Auditoria...';

IF OBJECT_ID('dbo.Factura_Auditoria', 'U') IS NOT NULL
    DROP TABLE dbo.Factura_Auditoria;
GO

CREATE TABLE dbo.Factura_Auditoria
(
    auditoria_id INT IDENTITY(1,1) PRIMARY KEY,
    factura_id INT NOT NULL,
    numero_factura VARCHAR(50),
    
    -- Acción realizada
    accion VARCHAR(10) NOT NULL,  -- 'INSERT', 'UPDATE', 'DELETE'
    
    -- Datos ANTES del cambio (solo para UPDATE y DELETE)
    monto_base_anterior DECIMAL(12,2),
    monto_recargo_anterior DECIMAL(12,2),
    monto_interes_anterior DECIMAL(12,2),
    monto_total_anterior DECIMAL(12,2),
    estado_factura_anterior VARCHAR(20),
    fecha_vencimiento_anterior DATE,
    
    -- Datos DESPUÉS del cambio (solo para INSERT y UPDATE)
    monto_base_nuevo DECIMAL(12,2),
    monto_recargo_nuevo DECIMAL(12,2),
    monto_interes_nuevo DECIMAL(12,2),
    monto_total_nuevo DECIMAL(12,2),
    estado_factura_nuevo VARCHAR(20),
    fecha_vencimiento_nuevo DATE,
    
    -- Metadata
    fecha_cambio DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_cambio VARCHAR(100) NOT NULL DEFAULT SUSER_NAME()
);
GO

PRINT '   Tabla Factura_Auditoria creada';
PRINT '';

-- =============================================
-- PASO 2: Crear tabla de auditoría para PAGO
-- =============================================
PRINT ' Creando tabla Pago_Auditoria...';

IF OBJECT_ID('dbo.Pago_Auditoria', 'U') IS NOT NULL
    DROP TABLE dbo.Pago_Auditoria;
GO

CREATE TABLE dbo.Pago_Auditoria
(
    auditoria_id INT IDENTITY(1,1) PRIMARY KEY,
    pago_id INT NOT NULL,
    numero_recibo VARCHAR(50),
    
    -- Acción realizada
    accion VARCHAR(10) NOT NULL,  -- 'INSERT', 'UPDATE', 'DELETE'
    
    -- Datos ANTES del cambio (solo para UPDATE y DELETE)
    factura_id_anterior INT,
    monto_pagado_anterior DECIMAL(12,2),
    fecha_pago_anterior DATETIME,
    medio_pago_anterior VARCHAR(50),
    referencia_pago_anterior VARCHAR(100),
    
    -- Datos DESPUÉS del cambio (solo para INSERT y UPDATE)
    factura_id_nuevo INT,
    monto_pagado_nuevo DECIMAL(12,2),
    fecha_pago_nuevo DATETIME,
    medio_pago_nuevo VARCHAR(50),
    referencia_pago_nuevo VARCHAR(100),
    
    -- Metadata
    fecha_cambio DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_cambio VARCHAR(100) NOT NULL DEFAULT SUSER_NAME()
);
GO

PRINT '   Tabla Pago_Auditoria creada';
PRINT '';

-- =============================================
-- PASO 3: Trigger para INSERT en Factura
-- =============================================
PRINT ' Creando triggers para Factura...';

DROP TRIGGER IF EXISTS dbo.trg_Factura_Auditoria_Insert;
GO

CREATE TRIGGER dbo.trg_Factura_Auditoria_Insert
ON dbo.Factura
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.Factura_Auditoria (
        factura_id,
        numero_factura,
        accion,
        monto_base_nuevo,
        monto_recargo_nuevo,
        monto_interes_nuevo,
        monto_total_nuevo,
        estado_factura_nuevo,
        fecha_vencimiento_nuevo,
        fecha_cambio,
        usuario_cambio
    )
    SELECT 
        i.factura_id,
        i.numero_factura,
        'INSERT',
        i.monto_base,
        i.monto_recargo,
        i.monto_interes,
        i.monto_total,
        i.estado_factura,
        i.fecha_vencimiento,
        GETDATE(),
        SUSER_NAME()
    FROM inserted i;
END
GO

PRINT '  trg_Factura_Auditoria_Insert creado';

-- =============================================
-- PASO 4: Trigger para UPDATE en Factura
-- =============================================
DROP TRIGGER IF EXISTS dbo.trg_Factura_Auditoria_Update;
GO

CREATE TRIGGER dbo.trg_Factura_Auditoria_Update
ON dbo.Factura
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.Factura_Auditoria (
        factura_id,
        numero_factura,
        accion,
        -- Datos anteriores (deleted)
        monto_base_anterior,
        monto_recargo_anterior,
        monto_interes_anterior,
        monto_total_anterior,
        estado_factura_anterior,
        fecha_vencimiento_anterior,
        -- Datos nuevos (inserted)
        monto_base_nuevo,
        monto_recargo_nuevo,
        monto_interes_nuevo,
        monto_total_nuevo,
        estado_factura_nuevo,
        fecha_vencimiento_nuevo,
        fecha_cambio,
        usuario_cambio
    )
    SELECT 
        i.factura_id,
        i.numero_factura,
        'UPDATE',
        -- Anteriores
        d.monto_base,
        d.monto_recargo,
        d.monto_interes,
        d.monto_total,
        d.estado_factura,
        d.fecha_vencimiento,
        -- Nuevos
        i.monto_base,
        i.monto_recargo,
        i.monto_interes,
        i.monto_total,
        i.estado_factura,
        i.fecha_vencimiento,
        GETDATE(),
        SUSER_NAME()
    FROM inserted i
    INNER JOIN deleted d ON i.factura_id = d.factura_id;
END
GO

PRINT '  trg_Factura_Auditoria_Update creado';

-- =============================================
-- PASO 5: Trigger para DELETE en Factura
-- =============================================
DROP TRIGGER IF EXISTS dbo.trg_Factura_Auditoria_Delete;
GO

CREATE TRIGGER dbo.trg_Factura_Auditoria_Delete
ON dbo.Factura
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.Factura_Auditoria (
        factura_id,
        numero_factura,
        accion,
        monto_base_anterior,
        monto_recargo_anterior,
        monto_interes_anterior,
        monto_total_anterior,
        estado_factura_anterior,
        fecha_vencimiento_anterior,
        fecha_cambio,
        usuario_cambio
    )
    SELECT 
        d.factura_id,
        d.numero_factura,
        'DELETE',
        d.monto_base,
        d.monto_recargo,
        d.monto_interes,
        d.monto_total,
        d.estado_factura,
        d.fecha_vencimiento,
        GETDATE(),
        SUSER_NAME()
    FROM deleted d;
END
GO

PRINT '  ✓ trg_Factura_Auditoria_Delete creado';
PRINT '';

-- =============================================
-- PASO 6: Trigger para INSERT en Pago
-- =============================================
PRINT ' Creando triggers para Pago...';

DROP TRIGGER IF EXISTS dbo.trg_Pago_Auditoria_Insert;
GO

CREATE TRIGGER dbo.trg_Pago_Auditoria_Insert
ON dbo.Pago
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.Pago_Auditoria (
        pago_id,
        numero_recibo,
        accion,
        factura_id_nuevo,
        monto_pagado_nuevo,
        fecha_pago_nuevo,
        medio_pago_nuevo,
        referencia_pago_nuevo,
        fecha_cambio,
        usuario_cambio
    )
    SELECT 
        i.pago_id,
        i.numero_recibo,
        'INSERT',
        i.factura_id,
        i.monto_pagado,
        i.fecha_pago,
        i.medio_pago,
        i.referencia_pago,
        GETDATE(),
        SUSER_NAME()
    FROM inserted i;
END
GO

PRINT '   trg_Pago_Auditoria_Insert creado';

-- =============================================
-- PASO 7: Trigger para UPDATE en Pago
-- =============================================
DROP TRIGGER IF EXISTS dbo.trg_Pago_Auditoria_Update;
GO

CREATE TRIGGER dbo.trg_Pago_Auditoria_Update
ON dbo.Pago
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.Pago_Auditoria (
        pago_id,
        numero_recibo,
        accion,
        -- Datos anteriores
        factura_id_anterior,
        monto_pagado_anterior,
        fecha_pago_anterior,
        medio_pago_anterior,
        referencia_pago_anterior,
        -- Datos nuevos
        factura_id_nuevo,
        monto_pagado_nuevo,
        fecha_pago_nuevo,
        medio_pago_nuevo,
        referencia_pago_nuevo,
        fecha_cambio,
        usuario_cambio
    )
    SELECT 
        i.pago_id,
        i.numero_recibo,
        'UPDATE',
        -- Anteriores
        d.factura_id,
        d.monto_pagado,
        d.fecha_pago,
        d.medio_pago,
        d.referencia_pago,
        -- Nuevos
        i.factura_id,
        i.monto_pagado,
        i.fecha_pago,
        i.medio_pago,
        i.referencia_pago,
        GETDATE(),
        SUSER_NAME()
    FROM inserted i
    INNER JOIN deleted d ON i.pago_id = d.pago_id;
END
GO

PRINT '  trg_Pago_Auditoria_Update creado';

-- =============================================
-- PASO 8: Trigger para DELETE en Pago
-- =============================================
DROP TRIGGER IF EXISTS dbo.trg_Pago_Auditoria_Delete;
GO

CREATE TRIGGER dbo.trg_Pago_Auditoria_Delete
ON dbo.Pago
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.Pago_Auditoria (
        pago_id,
        numero_recibo,
        accion,
        factura_id_anterior,
        monto_pagado_anterior,
        fecha_pago_anterior,
        medio_pago_anterior,
        referencia_pago_anterior,
        fecha_cambio,
        usuario_cambio
    )
    SELECT 
        d.pago_id,
        d.numero_recibo,
        'DELETE',
        d.factura_id,
        d.monto_pagado,
        d.fecha_pago,
        d.medio_pago,
        d.referencia_pago,
        GETDATE(),
        SUSER_NAME()
    FROM deleted d;
END
GO

PRINT '  trg_Pago_Auditoria_Delete creado';
PRINT '';

-- =============================================
-- PASO 9: Crear SPs para consultar auditoría
-- =============================================
PRINT ' Creando Stored Procedures de consulta...';

-- SP: Ver historial de una factura
CREATE OR ALTER PROCEDURE sp_Factura_ConsultarHistorial
    @factura_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        auditoria_id,
        factura_id,
        numero_factura,
        accion,
        monto_total_anterior,
        monto_total_nuevo,
        estado_factura_anterior,
        estado_factura_nuevo,
        fecha_cambio,
        usuario_cambio
    FROM Factura_Auditoria
    WHERE factura_id = @factura_id
    ORDER BY fecha_cambio DESC;
END
GO

PRINT '   sp_Factura_ConsultarHistorial creado';

-- SP: Ver historial de un pago
CREATE OR ALTER PROCEDURE sp_Pago_ConsultarHistorial
    @pago_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        auditoria_id,
        pago_id,
        numero_recibo,
        accion,
        monto_pagado_anterior,
        monto_pagado_nuevo,
        medio_pago_anterior,
        medio_pago_nuevo,
        fecha_cambio,
        usuario_cambio
    FROM Pago_Auditoria
    WHERE pago_id = @pago_id
    ORDER BY fecha_cambio DESC;
END
GO

PRINT '  sp_Pago_ConsultarHistorial creado';

-- SP: Ver auditoría por fecha
CREATE OR ALTER PROCEDURE sp_Auditoria_ConsultarPorFecha
    @fecha_inicio DATETIME,
    @fecha_fin DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 'FACTURA' AS tipo, * 
    FROM Factura_Auditoria
    WHERE fecha_cambio BETWEEN @fecha_inicio AND @fecha_fin
    
    UNION ALL
    
    SELECT 'PAGO' AS tipo, * 
    FROM Pago_Auditoria
    WHERE fecha_cambio BETWEEN @fecha_inicio AND @fecha_fin
    
    ORDER BY fecha_cambio DESC;
END
GO

PRINT '  sp_Auditoria_ConsultarPorFecha creado';
PRINT '';

-- =============================================
-- VERIFICACIÓN
-- =============================================
PRINT '========================================';
PRINT ' AUDITORÍA IMPLEMENTADA EXITOSAMENTE';
PRINT '========================================';
GO
