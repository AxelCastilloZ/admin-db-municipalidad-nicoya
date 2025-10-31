-- =============================================
-- AUDITORÍA DE TRÁMITE - VERSIÓN FINAL (SIN ERRORES)
-- Compatible con: Contribuyente (Física/Jurídica), Inmueble
-- SP: sp_Tramite_ConsultarHistorial, sp_Auditoria_Tramite_PorFecha
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '';
PRINT '========================================';
PRINT 'AUDITORÍA DE TRÁMITE - VERSIÓN SIN ERRORES';
PRINT '========================================';
PRINT '';

-- =============================================
-- PASO 1: LIMPIEZA COMPLETA
-- =============================================
PRINT '1. Limpiando componentes...';

IF OBJECT_ID('dbo.fn_ObtenerNombreContribuyente', 'FN') IS NOT NULL
    DROP FUNCTION dbo.fn_ObtenerNombreContribuyente;
GO

DROP TRIGGER IF EXISTS dbo.trg_Tramite_Auditoria_Insert;
GO
DROP TRIGGER IF EXISTS dbo.trg_Tramite_Auditoria_Update;
GO
DROP TRIGGER IF EXISTS dbo.trg_Tramite_Auditoria_Delete;
GO

DROP PROCEDURE IF EXISTS dbo.sp_Tramite_ConsultarHistorial;
GO
DROP PROCEDURE IF EXISTS dbo.sp_Auditoria_Tramite_PorFecha;
GO

IF OBJECT_ID('dbo.Tramite_Auditoria', 'U') IS NOT NULL
    DROP TABLE dbo.Tramite_Auditoria;
GO

PRINT '  ✓ Limpieza completada';
PRINT '';

-- =============================================
-- PASO 2: FUNCIÓN CORREGIDA PARA NOMBRE CONTRIBUYENTE
-- =============================================
PRINT '2. Creando función fn_ObtenerNombreContribuyente...';
go
CREATE FUNCTION dbo.fn_ObtenerNombreContribuyente(@contribuyente_id INT)
RETURNS VARCHAR(200)
AS
BEGIN
    DECLARE @nombre VARCHAR(200);
    
    SELECT @nombre = 
        CASE 
            WHEN cf.nombre IS NOT NULL THEN 
                LTRIM(RTRIM(ISNULL(cf.nombre, '') + ' ' + 
                           ISNULL(cf.apellido1, '') + ' ' + 
                           ISNULL(cf.apellido2, '')))
            WHEN cj.nombre_empresa IS NOT NULL THEN cj.nombre_empresa
            ELSE 'N/A'
        END
    FROM dbo.Contribuyente c
    LEFT JOIN dbo.Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
    LEFT JOIN dbo.Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id
    WHERE c.contribuyente_id = @contribuyente_id;
    
    RETURN ISNULL(@nombre, 'N/A');
END
GO

PRINT '  ✓ fn_ObtenerNombreContribuyente creada';
PRINT '';

-- =============================================
-- PASO 3: TABLA DE AUDITORÍA
-- =============================================
PRINT '3. Creando tabla Tramite_Auditoria...';

CREATE TABLE dbo.Tramite_Auditoria
(
    auditoria_id INT IDENTITY(1,1) PRIMARY KEY,
    tramite_id INT NOT NULL,
    accion VARCHAR(10) NOT NULL,

    -- ANTERIORES
    fecha_ingreso_anterior DATE,
    fecha_resolucion_anterior DATE,
    observaciones_anterior VARCHAR(255),
    estado_actual_anterior VARCHAR(20),
    tipo_tramite_id_anterior INT,
    tipo_tramite_nombre_anterior VARCHAR(100),
    contribuyente_id_anterior INT,
    contribuyente_tipo_anterior VARCHAR(20),
    contribuyente_nombre_anterior VARCHAR(200),
    inmueble_id_anterior INT,
    inmueble_direccion_anterior VARCHAR(255),

    -- NUEVOS
    fecha_ingreso_nuevo DATE,
    fecha_resolucion_nuevo DATE,
    observaciones_nuevo VARCHAR(255),
    estado_actual_nuevo VARCHAR(20),
    tipo_tramite_id_nuevo INT,
    tipo_tramite_nombre_nuevo VARCHAR(100),
    contribuyente_id_nuevo INT,
    contribuyente_tipo_nuevo VARCHAR(20),
    contribuyente_nombre_nuevo VARCHAR(200),
    inmueble_id_nuevo INT,
    inmueble_direccion_nuevo VARCHAR(255),

    -- METADATA
    fecha_cambio DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_cambio VARCHAR(100) NOT NULL DEFAULT SUSER_NAME()
);
GO

PRINT '  ✓ Tabla creada';
PRINT '';

-- =============================================
-- PASO 4: TRIGGERS
-- =============================================
PRINT '4. Creando triggers...';
go
-- TRIGGER INSERT
CREATE TRIGGER dbo.trg_Tramite_Auditoria_Insert
ON dbo.Tramite
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.Tramite_Auditoria (
        tramite_id, accion,
        fecha_ingreso_nuevo, fecha_resolucion_nuevo, observaciones_nuevo, estado_actual_nuevo,
        tipo_tramite_id_nuevo, tipo_tramite_nombre_nuevo,
        contribuyente_id_nuevo, contribuyente_tipo_nuevo, contribuyente_nombre_nuevo,
        inmueble_id_nuevo, inmueble_direccion_nuevo
    )
    SELECT 
        i.tramite_id, 'INSERT',
        i.fecha_ingreso, i.fecha_resolucion, i.observaciones, i.estado_actual,
        i.tipo_tramite_id, ISNULL(tt.nombre_tipo, 'N/A'),
        i.contribuyente_id, ISNULL(c.tipo_contribuyente, 'N/A'), 
        dbo.fn_ObtenerNombreContribuyente(i.contribuyente_id),
        i.inmueble_id, ISNULL(inm.direccion_exacta, 'Sin inmueble')
    FROM inserted i
    LEFT JOIN dbo.Tipo_Tramite tt ON i.tipo_tramite_id = tt.tipo_tramite_id
    LEFT JOIN dbo.Contribuyente c ON i.contribuyente_id = c.contribuyente_id
    LEFT JOIN dbo.Inmueble inm ON i.inmueble_id = inm.inmueble_id;
END
GO

-- TRIGGER UPDATE
CREATE TRIGGER dbo.trg_Tramite_Auditoria_Update
ON dbo.Tramite
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.Tramite_Auditoria (
        tramite_id, accion,
        -- ANTERIORES
        fecha_ingreso_anterior, fecha_resolucion_anterior, observaciones_anterior, estado_actual_anterior,
        tipo_tramite_id_anterior, tipo_tramite_nombre_anterior,
        contribuyente_id_anterior, contribuyente_tipo_anterior, contribuyente_nombre_anterior,
        inmueble_id_anterior, inmueble_direccion_anterior,
        -- NUEVOS
        fecha_ingreso_nuevo, fecha_resolucion_nuevo, observaciones_nuevo, estado_actual_nuevo,
        tipo_tramite_id_nuevo, tipo_tramite_nombre_nuevo,
        contribuyente_id_nuevo, contribuyente_tipo_nuevo, contribuyente_nombre_nuevo,
        inmueble_id_nuevo, inmueble_direccion_nuevo
    )
    SELECT 
        i.tramite_id, 'UPDATE',
        -- ANTERIORES
        d.fecha_ingreso, d.fecha_resolucion, d.observaciones, d.estado_actual,
        d.tipo_tramite_id, ISNULL(tt_d.nombre_tipo, 'N/A'),
        d.contribuyente_id, ISNULL(c_d.tipo_contribuyente, 'N/A'), dbo.fn_ObtenerNombreContribuyente(d.contribuyente_id),
        d.inmueble_id, ISNULL(inm_d.direccion_exacta, 'Sin inmueble'),
        -- NUEVOS
        i.fecha_ingreso, i.fecha_resolucion, i.observaciones, i.estado_actual,
        i.tipo_tramite_id, ISNULL(tt_i.nombre_tipo, 'N/A'),
        i.contribuyente_id, ISNULL(c_i.tipo_contribuyente, 'N/A'), dbo.fn_ObtenerNombreContribuyente(i.contribuyente_id),
        i.inmueble_id, ISNULL(inm_i.direccion_exacta, 'Sin inmueble')
    FROM inserted i
    INNER JOIN deleted d ON i.tramite_id = d.tramite_id
    LEFT JOIN dbo.Tipo_Tramite tt_d ON d.tipo_tramite_id = tt_d.tipo_tramite_id
    LEFT JOIN dbo.Tipo_Tramite tt_i ON i.tipo_tramite_id = tt_i.tipo_tramite_id
    LEFT JOIN dbo.Contribuyente c_d ON d.contribuyente_id = c_d.contribuyente_id
    LEFT JOIN dbo.Contribuyente c_i ON i.contribuyente_id = c_i.contribuyente_id
    LEFT JOIN dbo.Inmueble inm_d ON d.inmueble_id = inm_d.inmueble_id
    LEFT JOIN dbo.Inmueble inm_i ON i.inmueble_id = inm_i.inmueble_id;
END
GO

-- TRIGGER DELETE
CREATE TRIGGER dbo.trg_Tramite_Auditoria_Delete
ON dbo.Tramite
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.Tramite_Auditoria (
        tramite_id, accion,
        fecha_ingreso_anterior, fecha_resolucion_anterior, observaciones_anterior, estado_actual_anterior,
        tipo_tramite_id_anterior, tipo_tramite_nombre_anterior,
        contribuyente_id_anterior, contribuyente_tipo_anterior, contribuyente_nombre_anterior,
        inmueble_id_anterior, inmueble_direccion_anterior
    )
    SELECT 
        d.tramite_id, 'DELETE',
        d.fecha_ingreso, d.fecha_resolucion, d.observaciones, d.estado_actual,
        d.tipo_tramite_id, ISNULL(tt.nombre_tipo, 'N/A'),
        d.contribuyente_id, ISNULL(c.tipo_contribuyente, 'N/A'), dbo.fn_ObtenerNombreContribuyente(d.contribuyente_id),
        d.inmueble_id, ISNULL(inm.direccion_exacta, 'Sin inmueble')
    FROM deleted d
    LEFT JOIN dbo.Tipo_Tramite tt ON d.tipo_tramite_id = tt.tipo_tramite_id
    LEFT JOIN dbo.Contribuyente c ON d.contribuyente_id = c.contribuyente_id
    LEFT JOIN dbo.Inmueble inm ON d.inmueble_id = inm.inmueble_id;
END
GO

PRINT '  ✓ Triggers creados';
PRINT '';

-- =============================================
-- PASO 5: STORED PROCEDURES (SELECT *)
-- =============================================
PRINT '5. Creando Stored Procedures...';
go
CREATE PROCEDURE dbo.sp_Tramite_ConsultarHistorial
    @tramite_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.Tramite_Auditoria
    WHERE tramite_id = @tramite_id
    ORDER BY fecha_cambio DESC;
END
GO

CREATE  PROCEDURE dbo.sp_Auditoria_Tramite_PorFecha
    @fecha_inicio DATETIME,
    @fecha_fin DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    -- Incluye todo el día final
    SELECT *
    FROM dbo.Tramite_Auditoria
    WHERE fecha_cambio >= @fecha_inicio
      AND fecha_cambio < DATEADD(DAY, 1, @fecha_fin)
    ORDER BY fecha_cambio DESC;
END
GO


PRINT '  ✓ SP creados: sp_Tramite_ConsultarHistorial, sp_Auditoria_Tramite_PorFecha';
PRINT '';

-- =============================================
-- VERIFICACIÓN FINAL
-- =============================================
PRINT '========================================';
PRINT '✅ AUDITORÍA COMPLETA - SIN ERRORES';
PRINT '========================================';
PRINT '';
PRINT 'Ejemplos de uso:';
PRINT '';
PRINT 'EXEC sp_Tramite_ConsultarHistorial @tramite_id = 1;';
PRINT '';
PRINT 'DECLARE @hoy DATETIME = CAST(GETDATE() AS DATE);';
PRINT 'EXEC sp_Auditoria_Tramite_PorFecha @fecha_inicio = @hoy, @fecha_fin = DATEADD(DAY,1,@hoy);';
PRINT '';
PRINT '========================================';
GO   

-- DECLARE @hoy DATETIME = CAST(GETDATE() AS DATE);
-- EXEC sp_Auditoria_Tramite_PorFecha @fecha_inicio = @hoy, @fecha_fin = DATEADD(DAY,1,@hoy);
-- select * from Usuario

-- EXEC sp_Auditoria_Tramite_PorFecha @fecha_inicio ='2025-10-26', @fecha_fin ='2025-10-28';


-- EXEC sp_Auditoria_Tramite_PorFecha '2025-10-28', '2025-10-29';
-- DECLARE @hoy DATETIME = CAST(GETDATE() AS DATE);
-- DECLARE @mañana DATETIME = DATEADD(DAY, 1, @hoy);

-- EXEC sp_Auditoria_Tramite_PorFecha @hoy, @mañana;
