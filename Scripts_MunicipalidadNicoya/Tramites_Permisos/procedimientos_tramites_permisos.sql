-- =============================================
-- MÓDULO: TRÁMITES Y PERMISOS
-- Script: Stored Procedures
-- Descripción: Procedimientos almacenados para gestión de trámites
-- =============================================

USE MunicipalidadNicoya;
GO

-- =============================================
-- SECCIÓN: TIPO TRÁMITE
-- =============================================

-- SP: Insertar Tipo_Tramite
IF OBJECT_ID('sp_TipoTramite_Insertar', 'P') IS NOT NULL
    DROP PROCEDURE sp_TipoTramite_Insertar;
GO

CREATE PROCEDURE sp_TipoTramite_Insertar
    @nombre_tipo VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar obligatorio
        IF @nombre_tipo IS NULL OR LTRIM(RTRIM(@nombre_tipo)) = ''
        BEGIN
            RAISERROR('El nombre del tipo de trámite es obligatorio', 16, 1);
            RETURN;
        END
        
        -- Validar duplicado
        IF EXISTS (SELECT 1 FROM Tipo_Tramite WHERE nombre_tipo = @nombre_tipo)
        BEGIN
            RAISERROR('El nombre de tipo de trámite ya está registrado', 16, 1);
            RETURN;
        END
        
        INSERT INTO Tipo_Tramite (nombre_tipo)
        VALUES (@nombre_tipo);
        
        SELECT SCOPE_IDENTITY() AS tipo_tramite_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- SP: Consultar Tipo_Tramite por ID
IF OBJECT_ID('sp_TipoTramite_ConsultarPorID', 'P') IS NOT NULL
    DROP PROCEDURE sp_TipoTramite_ConsultarPorID;
GO

CREATE PROCEDURE sp_TipoTramite_ConsultarPorID
    @tipo_tramite_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT
        tipo_tramite_id,
        nombre_tipo
    FROM Tipo_Tramite
    WHERE tipo_tramite_id = @tipo_tramite_id;
END;
GO

-- SP: Listar Tipos_Tramite
IF OBJECT_ID('sp_TipoTramite_Listar', 'P') IS NOT NULL
    DROP PROCEDURE sp_TipoTramite_Listar;
GO

CREATE PROCEDURE sp_TipoTramite_Listar
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT tipo_tramite_id, nombre_tipo
    FROM dbo.Tipo_Tramite
    ORDER BY nombre_tipo;
END;
GO

-- SP: Buscar Tipos_Tramite por nombre
IF OBJECT_ID('sp_TipoTramite_BuscarPorNombre', 'P') IS NOT NULL
    DROP PROCEDURE sp_TipoTramite_BuscarPorNombre;
GO

CREATE PROCEDURE sp_TipoTramite_BuscarPorNombre
    @nombre VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
    BEGIN
        -- Si viene vacío, devuelve todo
        SELECT tipo_tramite_id, nombre_tipo
        FROM dbo.Tipo_Tramite
        ORDER BY nombre_tipo;
        RETURN;
    END
    
    SELECT tipo_tramite_id, nombre_tipo
    FROM dbo.Tipo_Tramite
    WHERE nombre_tipo LIKE '%' + @nombre + '%'
    ORDER BY nombre_tipo;
END;
GO

-- SP: Actualizar Tipo_Tramite
IF OBJECT_ID('sp_TipoTramite_Actualizar', 'P') IS NOT NULL
    DROP PROCEDURE sp_TipoTramite_Actualizar;
GO

CREATE PROCEDURE sp_TipoTramite_Actualizar
    @tipo_tramite_id INT,
    @nombre_tipo VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que existe
        IF NOT EXISTS (SELECT 1 FROM Tipo_Tramite WHERE tipo_tramite_id = @tipo_tramite_id)
        BEGIN
            RAISERROR('El tipo de trámite no existe', 16, 1);
            RETURN;
        END
        
        -- Validar nombre
        IF @nombre_tipo IS NULL OR LTRIM(RTRIM(@nombre_tipo)) = ''
        BEGIN
            RAISERROR('El nombre del tipo de trámite es obligatorio', 16, 1);
            RETURN;
        END
        
        -- Validar duplicados (excluyendo el mismo ID)
        IF EXISTS (
            SELECT 1
            FROM Tipo_Tramite
            WHERE nombre_tipo = @nombre_tipo
            AND tipo_tramite_id <> @tipo_tramite_id
        )
        BEGIN
            RAISERROR('El nombre ya está registrado por otro tipo de trámite', 16, 1);
            RETURN;
        END
        
        UPDATE Tipo_Tramite
        SET nombre_tipo = @nombre_tipo
        WHERE tipo_tramite_id = @tipo_tramite_id;
        
        SELECT 1 AS resultado;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- SP: Eliminar Tipo_Tramite
IF OBJECT_ID('sp_TipoTramite_Eliminar', 'P') IS NOT NULL
    DROP PROCEDURE sp_TipoTramite_Eliminar;
GO

CREATE PROCEDURE sp_TipoTramite_Eliminar
    @tipo_tramite_id INT
AS
BEGIN
    SET NOCOUNT OFF;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Tipo_Tramite WHERE tipo_tramite_id = @tipo_tramite_id)
        BEGIN
            RAISERROR('El tipo de trámite no existe', 16, 1);
            RETURN;
        END
        
        IF OBJECT_ID('dbo.Tramite','U') IS NOT NULL
           AND EXISTS (SELECT 1 FROM dbo.Tramite WHERE tipo_tramite_id = @tipo_tramite_id)
        BEGIN
            RAISERROR('No se puede eliminar: existen trámites asociados a este tipo', 16, 1);
            RETURN;
        END
        
        DELETE FROM dbo.Tipo_Tramite
        WHERE tipo_tramite_id = @tipo_tramite_id;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =============================================
-- SECCIÓN: TRÁMITES
-- =============================================

-- SP: Insertar Tramite
IF OBJECT_ID('sp_Tramite_Insertar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Tramite_Insertar;
GO

CREATE PROCEDURE sp_Tramite_Insertar
    @fecha_ingreso DATE,
    @fecha_resolucion DATE = NULL,
    @observaciones VARCHAR(255) = NULL,
    @tipo_tramite_id INT,
    @contribuyente_id INT,
    @inmueble_id INT,
    @estado_actual VARCHAR(20) = 'En Proceso'
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar estado
        IF @estado_actual NOT IN ('En Proceso','Aprobado','Rechazado','Finalizado')
        BEGIN 
            RAISERROR('Estado inválido.',16,1);
            RETURN;
        END
        
        -- Validar fechas
        IF @fecha_resolucion IS NOT NULL AND @fecha_resolucion < @fecha_ingreso
        BEGIN 
            RAISERROR('fecha_resolucion debe ser >= fecha_ingreso.',16,1);
            RETURN;
        END
        
        -- Validar tipo de trámite
        IF NOT EXISTS(SELECT 1 FROM dbo.Tipo_Tramite WHERE tipo_tramite_id=@tipo_tramite_id)
        BEGIN 
            RAISERROR('tipo_tramite_id no existe.',16,1); 
            RETURN; 
        END
        
        -- Validar contribuyente
        IF NOT EXISTS(SELECT 1 FROM dbo.Contribuyente WHERE contribuyente_id=@contribuyente_id)
        BEGIN 
            RAISERROR('contribuyente_id no existe.',16,1); 
            RETURN; 
        END
        
        -- Validar inmueble
        IF NOT EXISTS(SELECT 1 FROM dbo.Inmueble WHERE inmueble_id=@inmueble_id)
        BEGIN 
            RAISERROR('inmueble_id no existe.',16,1); 
            RETURN; 
        END
        
        -- Insertar
        INSERT INTO dbo.Tramite (
            fecha_ingreso, 
            fecha_resolucion, 
            observaciones, 
            estado_actual,
            tipo_tramite_id, 
            contribuyente_id, 
            inmueble_id
        )
        VALUES (
            @fecha_ingreso, 
            @fecha_resolucion, 
            @observaciones, 
            @estado_actual,
            @tipo_tramite_id, 
            @contribuyente_id, 
            @inmueble_id
        );
        
        SELECT SCOPE_IDENTITY() AS tramite_id;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- SP: Actualizar Tramite
IF OBJECT_ID('sp_Tramite_Actualizar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Tramite_Actualizar;
GO

CREATE PROCEDURE sp_Tramite_Actualizar
    @tramite_id INT,
    @fecha_ingreso DATE,
    @fecha_resolucion DATE,
    @observaciones VARCHAR(255),
    @tipo_tramite_id INT,
    @contribuyente_id INT,
    @inmueble_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS(SELECT 1 FROM dbo.Tramite WHERE tramite_id=@tramite_id)
        BEGIN 
            RAISERROR('El trámite no existe.',16,1); 
            RETURN; 
        END
        
        IF @fecha_resolucion < @fecha_ingreso
        BEGIN 
            RAISERROR('fecha_resolucion debe ser >= fecha_ingreso.',16,1); 
            RETURN; 
        END
        
        IF NOT EXISTS(SELECT 1 FROM dbo.Tipo_Tramite WHERE tipo_tramite_id=@tipo_tramite_id)
        BEGIN 
            RAISERROR('tipo_tramite_id no existe.',16,1); 
            RETURN; 
        END
        
        IF NOT EXISTS(SELECT 1 FROM dbo.Contribuyente WHERE contribuyente_id=@contribuyente_id)
        BEGIN 
            RAISERROR('contribuyente_id no existe.',16,1); 
            RETURN; 
        END
        
        IF NOT EXISTS(SELECT 1 FROM dbo.Inmueble WHERE inmueble_id=@inmueble_id)
        BEGIN 
            RAISERROR('inmueble_id no existe.',16,1); 
            RETURN; 
        END
        
        UPDATE dbo.Tramite
        SET fecha_ingreso=@fecha_ingreso,
            fecha_resolucion=@fecha_resolucion,
            observaciones=@observaciones,
            tipo_tramite_id=@tipo_tramite_id,
            contribuyente_id=@contribuyente_id,
            inmueble_id=@inmueble_id
        WHERE tramite_id=@tramite_id;
        
        SELECT 1 AS resultado;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- SP: Listar Tramites
IF OBJECT_ID('sp_Tramite_Listar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Tramite_Listar;
GO

CREATE PROCEDURE sp_Tramite_Listar
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        tramite_id,
        fecha_ingreso,
        fecha_resolucion,
        observaciones,
        estado_actual,
        tipo_tramite_id,
        contribuyente_id,
        inmueble_id
    FROM dbo.Tramite
    ORDER BY fecha_ingreso DESC;
END;
GO

-- SP: Consultar Tramite por ID
IF OBJECT_ID('sp_Tramite_ConsultarPorID', 'P') IS NOT NULL
    DROP PROCEDURE sp_Tramite_ConsultarPorID;
GO

CREATE PROCEDURE sp_Tramite_ConsultarPorID
    @tramite_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP 1
        tramite_id,
        fecha_ingreso,
        fecha_resolucion,
        observaciones,
        estado_actual,
        tipo_tramite_id,
        contribuyente_id,
        inmueble_id
    FROM dbo.Tramite
    WHERE tramite_id = @tramite_id;
END;
GO

-- SP: Eliminar Tramite
IF OBJECT_ID('sp_Tramite_Eliminar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Tramite_Eliminar;
GO

CREATE PROCEDURE sp_Tramite_Eliminar
    @tramite_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS(SELECT 1 FROM dbo.Tramite WHERE tramite_id=@tramite_id)
        BEGIN 
            RAISERROR('El trámite no existe.',16,1); 
            RETURN; 
        END
        
        IF EXISTS(SELECT 1 FROM dbo.Tramite WHERE tramite_id=@tramite_id AND estado_actual <> 'En Proceso')
        BEGIN 
            RAISERROR('Solo se puede eliminar un trámite con estado "En Proceso".',16,1); 
            RETURN; 
        END
        
        DELETE FROM dbo.Tramite WHERE tramite_id=@tramite_id;
        SELECT 1 AS resultado;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- SP: Actualizar Estado del Tramite
IF OBJECT_ID('sp_Tramite_ActualizarEstado', 'P') IS NOT NULL
    DROP PROCEDURE sp_Tramite_ActualizarEstado;
GO

CREATE PROCEDURE sp_Tramite_ActualizarEstado
    @tramite_id INT,
    @nuevo_estado VARCHAR(20),
    @observaciones VARCHAR(255) = NULL,
    @fecha_resolucion DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF @nuevo_estado NOT IN ('En Proceso','Aprobado','Rechazado','Finalizado')
        BEGIN 
            RAISERROR('Estado inválido.',16,1); 
            RETURN; 
        END
        
        IF NOT EXISTS(SELECT 1 FROM dbo.Tramite WHERE tramite_id=@tramite_id)
        BEGIN 
            RAISERROR('El trámite no existe.',16,1); 
            RETURN; 
        END
        
        DECLARE @fecha_ingreso DATE;
        SELECT @fecha_ingreso = fecha_ingreso FROM dbo.Tramite WHERE tramite_id=@tramite_id;
        
        -- Si se finaliza/aprueba/rechaza y no pasan fecha, usamos hoy
        IF @nuevo_estado IN ('Aprobado','Rechazado','Finalizado')
        BEGIN
            SET @fecha_resolucion = COALESCE(@fecha_resolucion, CAST(GETDATE() AS DATE));
            IF @fecha_resolucion < @fecha_ingreso
                SET @fecha_resolucion = @fecha_ingreso;
        END
        ELSE
        BEGIN
            -- En Proceso: mantenemos la fecha_resolucion actual
            SELECT @fecha_resolucion = fecha_resolucion FROM dbo.Tramite WHERE tramite_id=@tramite_id;
        END
        
        UPDATE dbo.Tramite
        SET estado_actual = @nuevo_estado,
            observaciones = COALESCE(@observaciones, observaciones),
            fecha_resolucion = @fecha_resolucion
        WHERE tramite_id=@tramite_id;
        
        SELECT 1 AS resultado;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

PRINT '';
PRINT '========================================';
PRINT '✓ STORED PROCEDURES - TRÁMITES Y PERMISOS';
PRINT '========================================';
PRINT 'SPs Tipo Trámite:';
PRINT '  - sp_TipoTramite_Insertar';
PRINT '  - sp_TipoTramite_ConsultarPorID';
PRINT '  - sp_TipoTramite_Listar';
PRINT '  - sp_TipoTramite_BuscarPorNombre';
PRINT '  - sp_TipoTramite_Actualizar';
PRINT '  - sp_TipoTramite_Eliminar';
PRINT '';
PRINT 'SPs Trámites:';
PRINT '  - sp_Tramite_Insertar';
PRINT '  - sp_Tramite_Actualizar';
PRINT '  - sp_Tramite_Listar';
PRINT '  - sp_Tramite_ConsultarPorID';
PRINT '  - sp_Tramite_Eliminar';
PRINT '  - sp_Tramite_ActualizarEstado';
PRINT '========================================';
GO