-- =============================================
-- MÓDULO: CONTRIBUYENTES E INMUEBLES
-- Script: Stored Procedures
-- Descripción: Procedimientos almacenados para gestión de contribuyentes e inmuebles
-- =============================================

USE MunicipalidadNicoya;
GO

-- =============================================
-- SECCIÓN: CONTRIBUYENTES FÍSICOS
-- =============================================

-- SP: Insertar Contribuyente Físico
IF OBJECT_ID('sp_Contribuyente_InsertarFisico', 'P') IS NOT NULL
    DROP PROCEDURE sp_Contribuyente_InsertarFisico;
GO

CREATE PROCEDURE sp_Contribuyente_InsertarFisico
    @cedula VARCHAR(20),
    @nombre VARCHAR(50),
    @apellido1 VARCHAR(50),
    @apellido2 VARCHAR(50),
    @telefono VARCHAR(20) = NULL,
    @email VARCHAR(100) = NULL,
    @direccion VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @contribuyente_id INT;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        -- Validar que la cédula no exista
        IF EXISTS (SELECT 1 FROM Contribuyente_fisico WHERE cedula = @cedula)
        BEGIN
            RAISERROR('La cédula ya está registrada', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- Insertar en tabla padre Contribuyente
        INSERT INTO Contribuyente (tipo_contribuyente, telefono, email, direccion)
        VALUES ('Física', @telefono, @email, @direccion);
        
        -- Obtener el ID generado
        SET @contribuyente_id = SCOPE_IDENTITY();
        
        -- Insertar en tabla hija Contribuyente_fisico
        INSERT INTO Contribuyente_fisico (contribuyente_id, cedula, nombre, apellido1, apellido2)
        VALUES (@contribuyente_id, @cedula, @nombre, @apellido1, @apellido2);
        
        COMMIT TRANSACTION;
        
        -- Retornar el ID generado
        SELECT @contribuyente_id AS contribuyente_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
END;
GO

-- SP: Insertar Contribuyente Jurídico
IF OBJECT_ID('sp_Contribuyente_InsertarJuridico', 'P') IS NOT NULL
    DROP PROCEDURE sp_Contribuyente_InsertarJuridico;
GO

CREATE PROCEDURE sp_Contribuyente_InsertarJuridico
    @cedula_juridica VARCHAR(50),
    @nombre_empresa VARCHAR(50),
    @representante_legal_id INT,
    @telefono VARCHAR(20) = NULL,
    @email VARCHAR(100) = NULL,
    @direccion VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @contribuyente_id INT;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        -- Validar que la cédula jurídica no exista
        IF EXISTS (SELECT 1 FROM Contribuyente_juridico WHERE cedula_juridica = @cedula_juridica)
        BEGIN
            RAISERROR('La cédula jurídica ya está registrada', 16, 1);
            RETURN;
        END
        
        -- Validar que el representante legal exista
        IF NOT EXISTS (SELECT 1 FROM Contribuyente_fisico WHERE contribuyentes_fisicos_id = @representante_legal_id)
        BEGIN
            RAISERROR('El representante legal no existe', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- Insertar en tabla padre Contribuyente
        INSERT INTO Contribuyente (tipo_contribuyente, telefono, email, direccion)
        VALUES ('Jurídica', @telefono, @email, @direccion);
        
        -- Obtener el ID generado
        SET @contribuyente_id = SCOPE_IDENTITY();
        
        -- Insertar en tabla hija Contribuyente_juridico
        INSERT INTO Contribuyente_juridico (contribuyente_id, cedula_juridica, nombre_empresa, representante_legal_id)
        VALUES (@contribuyente_id, @cedula_juridica, @nombre_empresa, @representante_legal_id);
        
        COMMIT TRANSACTION;
        
        -- Retornar el ID generado
        SELECT @contribuyente_id AS contribuyente_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
END;
GO

-- SP: Consultar Contribuyente Completo
IF OBJECT_ID('sp_Contribuyente_ConsultarCompleto', 'P') IS NOT NULL
    DROP PROCEDURE sp_Contribuyente_ConsultarCompleto;
GO

CREATE PROCEDURE sp_Contribuyente_ConsultarCompleto
    @contribuyente_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.contribuyente_id,
        c.tipo_contribuyente,
        c.telefono,
        c.email,
        c.direccion,
        -- Datos de persona física
        cf.contribuyentes_fisicos_id,
        cf.cedula,
        cf.nombre,
        cf.apellido1,
        cf.apellido2,
        -- Datos de persona jurídica
        cj.contribuyentes_fisicos_id AS contribuyente_juridico_id,
        cj.cedula_juridica,
        cj.nombre_empresa,
        cj.representante_legal_id
    FROM Contribuyente c
    LEFT JOIN Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
    LEFT JOIN Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id
    WHERE c.contribuyente_id = @contribuyente_id;
END;
GO

-- SP: Listar Todos los Contribuyentes
IF OBJECT_ID('sp_Contribuyente_ListarTodos', 'P') IS NOT NULL
    DROP PROCEDURE sp_Contribuyente_ListarTodos;
GO

CREATE PROCEDURE sp_Contribuyente_ListarTodos
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.contribuyente_id,
        c.tipo_contribuyente,
        c.telefono,
        c.email,
        c.direccion,
        -- Datos de persona física
        cf.cedula,
        cf.nombre,
        cf.apellido1,
        cf.apellido2,
        -- Datos de persona jurídica
        cj.cedula_juridica,
        cj.nombre_empresa,
        cj.representante_legal_id
    FROM Contribuyente c
    LEFT JOIN Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
    LEFT JOIN Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id
    ORDER BY c.contribuyente_id DESC;
END;
GO

-- SP: Eliminar Contribuyente
IF OBJECT_ID('sp_Contribuyente_Eliminar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Contribuyente_Eliminar;
GO

CREATE PROCEDURE sp_Contribuyente_Eliminar
    @contribuyente_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        -- Validar que el contribuyente existe
        IF NOT EXISTS (SELECT 1 FROM Contribuyente WHERE contribuyente_id = @contribuyente_id)
        BEGIN
            RAISERROR('El contribuyente no existe', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- Las tablas hijas se eliminan automáticamente por CASCADE
        DELETE FROM Contribuyente WHERE contribuyente_id = @contribuyente_id;
        
        COMMIT TRANSACTION;
        
        SELECT 1 AS resultado;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH
END;
GO

-- =============================================
-- SECCIÓN: INMUEBLES
-- =============================================

-- SP: Listar Tipos de Uso de Inmueble
IF OBJECT_ID('sp_TipoUsoInmueble_Listar', 'P') IS NOT NULL
    DROP PROCEDURE sp_TipoUsoInmueble_Listar;
GO

CREATE PROCEDURE sp_TipoUsoInmueble_Listar
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        tipo_uso_inmueble_id,
        nombre_uso,
        descripcion
    FROM TipoUsoInmueble
    ORDER BY nombre_uso;
END;
GO

-- SP: Insertar Inmueble
IF OBJECT_ID('sp_Inmueble_Insertar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Inmueble_Insertar;
GO

CREATE PROCEDURE sp_Inmueble_Insertar
    @direccion_exacta VARCHAR(255),
    @area_terreno DECIMAL(10,2),
    @valor_fiscal DECIMAL(18,2),
    @tipo_uso_inmueble_id INT,
    @estado_ocupacional VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @inmueble_id INT;
    
    BEGIN TRY
        IF @area_terreno <= 0
        BEGIN
            THROW 50001, 'El área del terreno debe ser mayor a 0', 1;
        END
        
        IF @valor_fiscal < 0
        BEGIN
            THROW 50002, 'El valor fiscal no puede ser negativo', 1;
        END
        
        IF NOT EXISTS (SELECT 1 FROM TipoUsoInmueble WHERE tipo_uso_inmueble_id = @tipo_uso_inmueble_id)
        BEGIN
            THROW 50003, 'El tipo de uso de inmueble no existe', 1;
        END
        
        BEGIN TRANSACTION;
        
        INSERT INTO Inmueble (direccion_exacta, area_terreno, valor_fiscal, tipo_uso_inmueble_id, estado_ocupacional)
        VALUES (@direccion_exacta, @area_terreno, @valor_fiscal, @tipo_uso_inmueble_id, @estado_ocupacional);
        
        SET @inmueble_id = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        
        SELECT @inmueble_id AS inmueble_id, 'SUCCESS' AS status;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP: Asociar Contribuyente a Inmueble
IF OBJECT_ID('sp_Inmueble_AsociarContribuyente', 'P') IS NOT NULL
    DROP PROCEDURE sp_Inmueble_AsociarContribuyente;
GO

CREATE PROCEDURE sp_Inmueble_AsociarContribuyente
    @contribuyente_id INT,
    @inmueble_id INT,
    @porcentaje_propiedad DECIMAL(5,2) = 100.00
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Contribuyente WHERE contribuyente_id = @contribuyente_id)
        BEGIN
            THROW 50001, 'El contribuyente no existe', 1;
        END
        
        IF NOT EXISTS (SELECT 1 FROM Inmueble WHERE inmueble_id = @inmueble_id)
        BEGIN
            THROW 50002, 'El inmueble no existe', 1;
        END
        
        IF EXISTS (SELECT 1 FROM Contribuyente_Inmueble 
                   WHERE contribuyente_id = @contribuyente_id 
                   AND inmueble_id = @inmueble_id)
        BEGIN
            THROW 50003, 'Esta asociación ya existe', 1;
        END
        
        IF @porcentaje_propiedad <= 0 OR @porcentaje_propiedad > 100
        BEGIN
            THROW 50004, 'El porcentaje de propiedad debe estar entre 0 y 100', 1;
        END
        
        BEGIN TRANSACTION;
        
        INSERT INTO Contribuyente_Inmueble (contribuyente_id, inmueble_id, porcentaje_propiedad)
        VALUES (@contribuyente_id, @inmueble_id, @porcentaje_propiedad);
        
        COMMIT TRANSACTION;
        
        SELECT 1 AS resultado, 'SUCCESS' AS status;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP: Listar Todos los Inmuebles
IF OBJECT_ID('sp_Inmueble_ListarTodos', 'P') IS NOT NULL
    DROP PROCEDURE sp_Inmueble_ListarTodos;
GO

CREATE PROCEDURE sp_Inmueble_ListarTodos
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        i.inmueble_id,
        i.direccion_exacta,
        i.area_terreno,
        i.valor_fiscal,
        i.estado_ocupacional,
        i.tipo_uso_inmueble_id,
        t.nombre_uso AS tipo_uso_nombre,
        t.descripcion AS tipo_uso_descripcion,
        i.fecha_registro
    FROM Inmueble i
    INNER JOIN TipoUsoInmueble t ON i.tipo_uso_inmueble_id = t.tipo_uso_inmueble_id
    ORDER BY i.inmueble_id DESC;
END;
GO

-- SP: Consultar Inmueble por ID
IF OBJECT_ID('sp_Inmueble_ConsultarPorID', 'P') IS NOT NULL
    DROP PROCEDURE sp_Inmueble_ConsultarPorID;
GO

CREATE PROCEDURE sp_Inmueble_ConsultarPorID
    @inmueble_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Datos del inmueble
    SELECT 
        i.inmueble_id,
        i.direccion_exacta,
        i.area_terreno,
        i.valor_fiscal,
        i.estado_ocupacional,
        i.tipo_uso_inmueble_id,
        t.nombre_uso AS tipo_uso_nombre,
        t.descripcion AS tipo_uso_descripcion,
        i.fecha_registro
    FROM Inmueble i
    INNER JOIN TipoUsoInmueble t ON i.tipo_uso_inmueble_id = t.tipo_uso_inmueble_id
    WHERE i.inmueble_id = @inmueble_id;
    
    -- Propietarios del inmueble
    SELECT 
        ci.contribuyente_inmueble_id,
        ci.contribuyente_id,
        ci.porcentaje_propiedad,
        ci.fecha_registro AS fecha_asociacion,
        c.tipo_contribuyente,
        cf.nombre,
        cf.apellido1,
        cf.apellido2,
        cf.cedula,
        CONCAT(cf.nombre, ' ', cf.apellido1, ' ', cf.apellido2) AS nombre_completo,
        cj.nombre_empresa,
        cj.cedula_juridica
    FROM Contribuyente_Inmueble ci
    INNER JOIN Contribuyente c ON ci.contribuyente_id = c.contribuyente_id
    LEFT JOIN Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
    LEFT JOIN Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id
    WHERE ci.inmueble_id = @inmueble_id;
END;
GO

-- SP: Inmuebles de un Contribuyente
IF OBJECT_ID('sp_Inmueble_PorContribuyente', 'P') IS NOT NULL
    DROP PROCEDURE sp_Inmueble_PorContribuyente;
GO

CREATE PROCEDURE sp_Inmueble_PorContribuyente
    @contribuyente_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        i.inmueble_id,
        i.direccion_exacta,
        i.area_terreno,
        i.valor_fiscal,
        i.estado_ocupacional,
        i.tipo_uso_inmueble_id,
        t.nombre_uso AS tipo_uso_nombre,
        i.fecha_registro,
        ci.porcentaje_propiedad,
        ci.fecha_registro AS fecha_asociacion
    FROM Inmueble i
    INNER JOIN TipoUsoInmueble t ON i.tipo_uso_inmueble_id = t.tipo_uso_inmueble_id
    INNER JOIN Contribuyente_Inmueble ci ON i.inmueble_id = ci.inmueble_id
    WHERE ci.contribuyente_id = @contribuyente_id
    ORDER BY i.inmueble_id DESC;
END;
GO

-- SP: Actualizar Inmueble
IF OBJECT_ID('sp_Inmueble_Actualizar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Inmueble_Actualizar;
GO

CREATE PROCEDURE sp_Inmueble_Actualizar
    @inmueble_id INT,
    @direccion_exacta VARCHAR(255),
    @area_terreno DECIMAL(10,2),
    @valor_fiscal DECIMAL(18,2),
    @tipo_uso_inmueble_id INT,
    @estado_ocupacional VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Inmueble WHERE inmueble_id = @inmueble_id)
        BEGIN
            THROW 50001, 'El inmueble no existe', 1;
        END
        
        IF @area_terreno <= 0
        BEGIN
            THROW 50002, 'El área del terreno debe ser mayor a 0', 1;
        END
        
        IF @valor_fiscal < 0
        BEGIN
            THROW 50003, 'El valor fiscal no puede ser negativo', 1;
        END
        
        IF NOT EXISTS (SELECT 1 FROM TipoUsoInmueble WHERE tipo_uso_inmueble_id = @tipo_uso_inmueble_id)
        BEGIN
            THROW 50004, 'El tipo de uso de inmueble no existe', 1;
        END
        
        BEGIN TRANSACTION;
        
        UPDATE Inmueble
        SET 
            direccion_exacta = @direccion_exacta,
            area_terreno = @area_terreno,
            valor_fiscal = @valor_fiscal,
            tipo_uso_inmueble_id = @tipo_uso_inmueble_id,
            estado_ocupacional = @estado_ocupacional
        WHERE inmueble_id = @inmueble_id;
        
        COMMIT TRANSACTION;
        
        SELECT 1 AS resultado, 'SUCCESS' AS status;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP: Eliminar Inmueble
IF OBJECT_ID('sp_Inmueble_Eliminar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Inmueble_Eliminar;
GO

CREATE PROCEDURE sp_Inmueble_Eliminar
    @inmueble_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Inmueble WHERE inmueble_id = @inmueble_id)
        BEGIN
            THROW 50001, 'El inmueble no existe', 1;
        END
        
        BEGIN TRANSACTION;
        
        DELETE FROM Inmueble WHERE inmueble_id = @inmueble_id;
        
        COMMIT TRANSACTION;
        
        SELECT 1 AS resultado, 'SUCCESS' AS status;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP: Desasociar Contribuyente de Inmueble
IF OBJECT_ID('sp_Inmueble_DesasociarContribuyente', 'P') IS NOT NULL
    DROP PROCEDURE sp_Inmueble_DesasociarContribuyente;
GO

CREATE PROCEDURE sp_Inmueble_DesasociarContribuyente
    @contribuyente_id INT,
    @inmueble_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Contribuyente_Inmueble 
                       WHERE contribuyente_id = @contribuyente_id 
                       AND inmueble_id = @inmueble_id)
        BEGIN
            THROW 50001, 'La asociación no existe', 1;
        END
        
        BEGIN TRANSACTION;
        
        DELETE FROM Contribuyente_Inmueble 
        WHERE contribuyente_id = @contribuyente_id 
        AND inmueble_id = @inmueble_id;
        
        COMMIT TRANSACTION;
        
        SELECT 1 AS resultado, 'SUCCESS' AS status;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

PRINT '';
PRINT '========================================';
PRINT '✓ STORED PROCEDURES - CONTRIBUYENTES E INMUEBLES';
PRINT '========================================';
PRINT 'SPs Contribuyentes:';
PRINT '  - sp_Contribuyente_InsertarFisico';
PRINT '  - sp_Contribuyente_InsertarJuridico';
PRINT '  - sp_Contribuyente_ConsultarCompleto';
PRINT '  - sp_Contribuyente_ListarTodos';
PRINT '  - sp_Contribuyente_Eliminar';
PRINT '';
PRINT 'SPs Inmuebles:';
PRINT '  - sp_TipoUsoInmueble_Listar';
PRINT '  - sp_Inmueble_Insertar';
PRINT '  - sp_Inmueble_AsociarContribuyente';
PRINT '  - sp_Inmueble_ListarTodos';
PRINT '  - sp_Inmueble_ConsultarPorID';
PRINT '  - sp_Inmueble_PorContribuyente';
PRINT '  - sp_Inmueble_Actualizar';
PRINT '  - sp_Inmueble_Eliminar';
PRINT '  - sp_Inmueble_DesasociarContribuyente';
PRINT '========================================';
GO