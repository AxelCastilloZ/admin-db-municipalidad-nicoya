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






-- SP: Insertar Catastro

IF OBJECT_ID('sp_Catastro_Insertar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Catastro_Insertar;
GO

CREATE PROCEDURE sp_Catastro_Insertar
    @numero_plano_catastral VARCHAR(50),
    @area_catastral VARCHAR(100) = NULL,
    @fecha_inscripcion DATE,
    @estado VARCHAR(20) = 'Activo',
    @inmueble_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @catastro_id INT;
    DECLARE @existe_inmueble INT;
    
    BEGIN TRY
        -- Debug: Verificar base de datos actual
        DECLARE @dbName NVARCHAR(128) = DB_NAME();
        PRINT 'Base de datos actual: ' + @dbName;
        
        -- Verificar si el inmueble existe (con contador)
        SELECT @existe_inmueble = COUNT(*) 
        FROM dbo.Inmueble 
        WHERE inmueble_id = @inmueble_id;
        
        PRINT 'Inmuebles encontrados con ID ' + CAST(@inmueble_id AS VARCHAR(10)) + ': ' + CAST(@existe_inmueble AS VARCHAR(10));
        
        IF @existe_inmueble = 0
        BEGIN
            THROW 50001, 'El inmueble no existe', 1;
        END
        
        -- Validar que el número de plano no exista
        IF EXISTS (SELECT 1 FROM dbo.Catastro WHERE numero_plano_catastral = @numero_plano_catastral)
        BEGIN
            THROW 50002, 'El número de plano catastral ya está registrado', 1;
        END
        
        -- Validar estado
        IF @estado NOT IN ('Activo', 'Inactivo', 'En Revisión')
        BEGIN
            THROW 50003, 'Estado inválido', 1;
        END
        
        -- Validar que el inmueble no tenga ya un catastro activo
        IF EXISTS (
            SELECT 1 FROM dbo.Catastro 
            WHERE inmueble_id = @inmueble_id 
            AND estado = 'Activo'
        )
        BEGIN
            THROW 50004, 'El inmueble ya tiene un catastro activo', 1;
        END
        
        BEGIN TRANSACTION;
        
        INSERT INTO dbo.Catastro (
            numero_plano_catastral, 
            area_catastral, 
            fecha_inscripcion, 
            estado, 
            inmueble_id
        )
        VALUES (
            @numero_plano_catastral, 
            @area_catastral, 
            @fecha_inscripcion, 
            @estado, 
            @inmueble_id
        );
        
        SET @catastro_id = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        
        SELECT @catastro_id AS catastro_id, 'SUCCESS' AS status;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- SP: Consultar Catastro por ID
IF OBJECT_ID('sp_Catastro_ConsultarPorID', 'P') IS NOT NULL
    DROP PROCEDURE sp_Catastro_ConsultarPorID;
GO

CREATE PROCEDURE sp_Catastro_ConsultarPorID
    @catastro_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.catastro_id,
        c.numero_plano_catastral,
        c.area_catastral,
        c.fecha_inscripcion,
        c.estado,
        c.inmueble_id,
        i.direccion_exacta AS inmueble_direccion,
        i.area_terreno,
        i.valor_fiscal
    FROM Catastro c
    INNER JOIN Inmueble i ON c.inmueble_id = i.inmueble_id
    WHERE c.catastro_id = @catastro_id;
END;
GO

-- SP: Consultar Catastro por Inmueble
IF OBJECT_ID('sp_Catastro_ConsultarPorInmueble', 'P') IS NOT NULL
    DROP PROCEDURE sp_Catastro_ConsultarPorInmueble;
GO

CREATE PROCEDURE sp_Catastro_ConsultarPorInmueble
    @inmueble_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.catastro_id,
        c.numero_plano_catastral,
        c.area_catastral,
        c.fecha_inscripcion,
        c.estado,
        c.inmueble_id
    FROM Catastro c
    WHERE c.inmueble_id = @inmueble_id
    ORDER BY c.fecha_inscripcion DESC;
END;
GO

-- SP: Listar Todos los Catastros
IF OBJECT_ID('sp_Catastro_ListarTodos', 'P') IS NOT NULL
    DROP PROCEDURE sp_Catastro_ListarTodos;
GO

CREATE PROCEDURE sp_Catastro_ListarTodos
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.catastro_id,
        c.numero_plano_catastral,
        c.area_catastral,
        c.fecha_inscripcion,
        c.estado,
        c.inmueble_id,
        i.direccion_exacta AS inmueble_direccion
    FROM Catastro c
    INNER JOIN Inmueble i ON c.inmueble_id = i.inmueble_id
    ORDER BY c.fecha_inscripcion DESC;
END;
GO

-- SP: Actualizar Catastro
IF OBJECT_ID('sp_Catastro_Actualizar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Catastro_Actualizar;
GO

CREATE PROCEDURE sp_Catastro_Actualizar
    @catastro_id INT,
    @numero_plano_catastral VARCHAR(50),
    @area_catastral VARCHAR(100) = NULL,
    @fecha_inscripcion DATE,
    @estado VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que el catastro existe
        IF NOT EXISTS (SELECT 1 FROM Catastro WHERE catastro_id = @catastro_id)
        BEGIN
            THROW 50001, 'El catastro no existe', 1;
        END
        
        -- Validar número de plano duplicado (excluyendo el actual)
        IF EXISTS (
            SELECT 1 FROM Catastro 
            WHERE numero_plano_catastral = @numero_plano_catastral 
            AND catastro_id <> @catastro_id
        )
        BEGIN
            THROW 50002, 'El número de plano catastral ya está registrado', 1;
        END
        
        -- Validar estado
        IF @estado NOT IN ('Activo', 'Inactivo', 'En Revisión')
        BEGIN
            THROW 50003, 'Estado inválido', 1;
        END
        
        BEGIN TRANSACTION;
        
        UPDATE Catastro
        SET 
            numero_plano_catastral = @numero_plano_catastral,
            area_catastral = @area_catastral,
            fecha_inscripcion = @fecha_inscripcion,
            estado = @estado
        WHERE catastro_id = @catastro_id;
        
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

-- SP: Eliminar Catastro
IF OBJECT_ID('sp_Catastro_Eliminar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Catastro_Eliminar;
GO

CREATE PROCEDURE sp_Catastro_Eliminar
    @catastro_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Catastro WHERE catastro_id = @catastro_id)
        BEGIN
            THROW 50001, 'El catastro no existe', 1;
        END
        
        BEGIN TRANSACTION;
        
        -- Las colindancias se eliminan automáticamente por CASCADE
        DELETE FROM Catastro WHERE catastro_id = @catastro_id;
        
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

-- =============================================
-- SECCIÓN: COLINDANCIAS
-- =============================================

-- SP: Insertar Colindancia
IF OBJECT_ID('sp_Colindancia_Insertar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Colindancia_Insertar;
GO

CREATE PROCEDURE sp_Colindancia_Insertar
    @punto_cardinal VARCHAR(10),
    @colindante VARCHAR(255),
    @catastro_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @colindancia_id INT;
    
    BEGIN TRY
        -- Validar que el catastro existe
        IF NOT EXISTS (SELECT 1 FROM Catastro WHERE catastro_id = @catastro_id)
        BEGIN
            THROW 50001, 'El catastro no existe', 1;
        END
        
        -- Validar punto cardinal
        IF @punto_cardinal NOT IN ('Norte', 'Sur', 'Este', 'Oeste', 'Noreste', 'Noroeste', 'Sureste', 'Suroeste')
        BEGIN
            THROW 50002, 'Punto cardinal inválido', 1;
        END
        
        -- Validar que no exista ya una colindancia con ese punto cardinal para ese catastro
        IF EXISTS (
            SELECT 1 FROM Colindancias 
            WHERE catastro_id = @catastro_id 
            AND punto_cardinal = @punto_cardinal
        )
        BEGIN
            THROW 50003, 'Ya existe una colindancia registrada para ese punto cardinal', 1;
        END
        
        BEGIN TRANSACTION;
        
        INSERT INTO Colindancias (punto_cardinal, colindante, catastro_id)
        VALUES (@punto_cardinal, @colindante, @catastro_id);
        
        SET @colindancia_id = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        
        SELECT @colindancia_id AS colindancias_id, 'SUCCESS' AS status;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP: Listar Colindancias por Catastro
IF OBJECT_ID('sp_Colindancia_ListarPorCatastro', 'P') IS NOT NULL
    DROP PROCEDURE sp_Colindancia_ListarPorCatastro;
GO

CREATE PROCEDURE sp_Colindancia_ListarPorCatastro
    @catastro_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        colindancias_id,
        punto_cardinal,
        colindante,
        catastro_id
    FROM Colindancias
    WHERE catastro_id = @catastro_id
    ORDER BY 
        CASE punto_cardinal
            WHEN 'Norte' THEN 1
            WHEN 'Noreste' THEN 2
            WHEN 'Este' THEN 3
            WHEN 'Sureste' THEN 4
            WHEN 'Sur' THEN 5
            WHEN 'Suroeste' THEN 6
            WHEN 'Oeste' THEN 7
            WHEN 'Noroeste' THEN 8
        END;
END;
GO

-- SP: Actualizar Colindancia
IF OBJECT_ID('sp_Colindancia_Actualizar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Colindancia_Actualizar;
GO

CREATE PROCEDURE sp_Colindancia_Actualizar
    @colindancias_id INT,
    @punto_cardinal VARCHAR(10),
    @colindante VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que la colindancia existe
        IF NOT EXISTS (SELECT 1 FROM Colindancias WHERE colindancias_id = @colindancias_id)
        BEGIN
            THROW 50001, 'La colindancia no existe', 1;
        END
        
        -- Validar punto cardinal
        IF @punto_cardinal NOT IN ('Norte', 'Sur', 'Este', 'Oeste', 'Noreste', 'Noroeste', 'Sureste', 'Suroeste')
        BEGIN
            THROW 50002, 'Punto cardinal inválido', 1;
        END
        
        -- Validar duplicados en el mismo catastro
        DECLARE @catastro_id INT;
        SELECT @catastro_id = catastro_id FROM Colindancias WHERE colindancias_id = @colindancias_id;
        
        IF EXISTS (
            SELECT 1 FROM Colindancias 
            WHERE catastro_id = @catastro_id 
            AND punto_cardinal = @punto_cardinal 
            AND colindancias_id <> @colindancias_id
        )
        BEGIN
            THROW 50003, 'Ya existe una colindancia para ese punto cardinal', 1;
        END
        
        BEGIN TRANSACTION;
        
        UPDATE Colindancias
        SET 
            punto_cardinal = @punto_cardinal,
            colindante = @colindante
        WHERE colindancias_id = @colindancias_id;
        
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

-- SP: Eliminar Colindancia
IF OBJECT_ID('sp_Colindancia_Eliminar', 'P') IS NOT NULL
    DROP PROCEDURE sp_Colindancia_Eliminar;
GO

CREATE PROCEDURE sp_Colindancia_Eliminar
    @colindancias_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Colindancias WHERE colindancias_id = @colindancias_id)
        BEGIN
            THROW 50001, 'La colindancia no existe', 1;
        END
        
        BEGIN TRANSACTION;
        
        DELETE FROM Colindancias WHERE colindancias_id = @colindancias_id;
        
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

-- =============================================
-- SECCIÓN: OBSERVACIONES DE INMUEBLES
-- =============================================

-- SP: Insertar Observación
IF OBJECT_ID('sp_ObservacionInmueble_Insertar', 'P') IS NOT NULL
    DROP PROCEDURE sp_ObservacionInmueble_Insertar;
GO

CREATE PROCEDURE sp_ObservacionInmueble_Insertar
    @descripcion VARCHAR(300),
    @inmueble_id INT,
    @catastro_id INT = NULL,
    @fecha DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @observacion_id INT;
    
    BEGIN TRY
        -- Validar que el inmueble existe
        IF NOT EXISTS (SELECT 1 FROM Inmueble WHERE inmueble_id = @inmueble_id)
        BEGIN
            THROW 50001, 'El inmueble no existe', 1;
        END
        
        -- Si se proporciona catastro_id, validar que existe
        IF @catastro_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Catastro WHERE catastro_id = @catastro_id)
        BEGIN
            THROW 50002, 'El catastro no existe', 1;
        END
        
        -- Si no se proporciona fecha, usar la fecha actual
        IF @fecha IS NULL
            SET @fecha = CAST(GETDATE() AS DATE);
        
        BEGIN TRANSACTION;
        
        INSERT INTO ObservacionInmueble (fecha, descripcion, inmueble_id, catastro_id)
        VALUES (@fecha, @descripcion, @inmueble_id, @catastro_id);
        
        SET @observacion_id = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        
        SELECT @observacion_id AS observacion_inmueble_id, 'SUCCESS' AS status;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP: Listar Observaciones por Inmueble
IF OBJECT_ID('sp_ObservacionInmueble_ListarPorInmueble', 'P') IS NOT NULL
    DROP PROCEDURE sp_ObservacionInmueble_ListarPorInmueble;
GO

CREATE PROCEDURE sp_ObservacionInmueble_ListarPorInmueble
    @inmueble_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        o.observacion_inmueble_id,
        o.fecha,
        o.descripcion,
        o.inmueble_id,
        o.catastro_id,
        c.numero_plano_catastral
    FROM ObservacionInmueble o
    LEFT JOIN Catastro c ON o.catastro_id = c.catastro_id
    WHERE o.inmueble_id = @inmueble_id
    ORDER BY o.fecha DESC;
END;
GO

-- SP: Listar Observaciones por Catastro
IF OBJECT_ID('sp_ObservacionInmueble_ListarPorCatastro', 'P') IS NOT NULL
    DROP PROCEDURE sp_ObservacionInmueble_ListarPorCatastro;
GO

CREATE PROCEDURE sp_ObservacionInmueble_ListarPorCatastro
    @catastro_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        o.observacion_inmueble_id,
        o.fecha,
        o.descripcion,
        o.inmueble_id,
        o.catastro_id,
        i.direccion_exacta AS inmueble_direccion
    FROM ObservacionInmueble o
    INNER JOIN Inmueble i ON o.inmueble_id = i.inmueble_id
    WHERE o.catastro_id = @catastro_id
    ORDER BY o.fecha DESC;
END;
GO

-- SP: Actualizar Observación
IF OBJECT_ID('sp_ObservacionInmueble_Actualizar', 'P') IS NOT NULL
    DROP PROCEDURE sp_ObservacionInmueble_Actualizar;
GO

CREATE PROCEDURE sp_ObservacionInmueble_Actualizar
    @observacion_inmueble_id INT,
    @descripcion VARCHAR(300),
    @fecha DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM ObservacionInmueble WHERE observacion_inmueble_id = @observacion_inmueble_id)
        BEGIN
            THROW 50001, 'La observación no existe', 1;
        END
        
        IF @fecha IS NULL
            SET @fecha = CAST(GETDATE() AS DATE);
        
        BEGIN TRANSACTION;
        
        UPDATE ObservacionInmueble
        SET 
            descripcion = @descripcion,
            fecha = @fecha
        WHERE observacion_inmueble_id = @observacion_inmueble_id;
        
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

-- SP: Eliminar Observación
IF OBJECT_ID('sp_ObservacionInmueble_Eliminar', 'P') IS NOT NULL
    DROP PROCEDURE sp_ObservacionInmueble_Eliminar;
GO

CREATE PROCEDURE sp_ObservacionInmueble_Eliminar
    @observacion_inmueble_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM ObservacionInmueble WHERE observacion_inmueble_id = @observacion_inmueble_id)
        BEGIN
            THROW 50001, 'La observación no existe', 1;
        END
        
        BEGIN TRANSACTION;
        
        DELETE FROM ObservacionInmueble WHERE observacion_inmueble_id = @observacion_inmueble_id;
        
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

-- =============================================
-- SP AVANZADO: Consultar Catastro Completo con Colindancias
-- =============================================
IF OBJECT_ID('sp_Catastro_ConsultarCompleto', 'P') IS NOT NULL
    DROP PROCEDURE sp_Catastro_ConsultarCompleto;
GO

CREATE PROCEDURE sp_Catastro_ConsultarCompleto
    @catastro_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Datos del catastro e inmueble
    SELECT 
        c.catastro_id,
        c.numero_plano_catastral,
        c.area_catastral,
        c.fecha_inscripcion,
        c.estado,
        c.inmueble_id,
        i.direccion_exacta,
        i.area_terreno,
        i.valor_fiscal,
        i.estado_ocupacional,
        t.nombre_uso AS tipo_uso
    FROM Catastro c
    INNER JOIN Inmueble i ON c.inmueble_id = i.inmueble_id
    INNER JOIN TipoUsoInmueble t ON i.tipo_uso_inmueble_id = t.tipo_uso_inmueble_id
    WHERE c.catastro_id = @catastro_id;
    
    -- Colindancias
    SELECT 
        colindancias_id,
        punto_cardinal,
        colindante
    FROM Colindancias
    WHERE catastro_id = @catastro_id
    ORDER BY 
        CASE punto_cardinal
            WHEN 'Norte' THEN 1
            WHEN 'Noreste' THEN 2
            WHEN 'Este' THEN 3
            WHEN 'Sureste' THEN 4
            WHEN 'Sur' THEN 5
            WHEN 'Suroeste' THEN 6
            WHEN 'Oeste' THEN 7
            WHEN 'Noroeste' THEN 8
        END;
    
    -- Observaciones
    SELECT 
        observacion_inmueble_id,
        fecha,
        descripcion
    FROM ObservacionInmueble
    WHERE catastro_id = @catastro_id
    ORDER BY fecha DESC;
END;
GO

PRINT '';
PRINT '========================================';
PRINT '✓ STORED PROCEDURES - CATASTRO Y OBSERVACIONES';
PRINT '========================================';
PRINT 'SPs Catastro:';
PRINT '  - sp_Catastro_Insertar';
PRINT '  - sp_Catastro_ConsultarPorID';
PRINT '  - sp_Catastro_ConsultarPorInmueble';
PRINT '  - sp_Catastro_ListarTodos';
PRINT '  - sp_Catastro_Actualizar';
PRINT '  - sp_Catastro_Eliminar';
PRINT '  - sp_Catastro_ConsultarCompleto';
PRINT '';
PRINT 'SPs Colindancias:';
PRINT '  - sp_Colindancia_Insertar';
PRINT '  - sp_Colindancia_ListarPorCatastro';
PRINT '  - sp_Colindancia_Actualizar';
PRINT '  - sp_Colindancia_Eliminar';
PRINT '';
PRINT 'SPs Observaciones:';
PRINT '  - sp_ObservacionInmueble_Insertar';
PRINT '  - sp_ObservacionInmueble_ListarPorInmueble';
PRINT '  - sp_ObservacionInmueble_ListarPorCatastro';
PRINT '  - sp_ObservacionInmueble_Actualizar';
PRINT '  - sp_ObservacionInmueble_Eliminar';
PRINT '========================================';
GO


-- =============================================
-- EJEMPLOS DE PRUEBA - CATASTRO Y COLINDANCIAS
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '========================================';
PRINT 'PRUEBAS: Catastro, Colindancias y Observaciones';
PRINT '========================================';
GO

-- =============================================
-- 1. INSERTAR CATASTRO
-- =============================================
PRINT '1. Insertando catastro...';
GO

DECLARE @catastro_id INT;

EXEC sp_Catastro_Insertar
    @numero_plano_catastral = 'G-1234567-2024',
    @area_catastral = 'Zona Norte Nicoya',
    @fecha_inscripcion = '2024-01-15',
    @estado = 'Activo',
    @inmueble_id = 1;

SET @catastro_id = (SELECT TOP 1 catastro_id FROM Catastro ORDER BY catastro_id DESC);
PRINT 'Catastro insertado con ID: ' + CAST(@catastro_id AS VARCHAR(10));
GO

-- =============================================
-- 2. INSERTAR COLINDANCIAS
-- =============================================
PRINT '';
PRINT '2. Insertando colindancias...';
GO

DECLARE @catastro_id INT = (SELECT TOP 1 catastro_id FROM Catastro ORDER BY catastro_id DESC);

EXEC sp_Colindancia_Insertar
    @punto_cardinal = 'Norte',
    @colindante = 'Propiedad de Juan Pérez',
    @catastro_id = @catastro_id;

EXEC sp_Colindancia_Insertar
    @punto_cardinal = 'Sur',
    @colindante = 'Calle Pública',
    @catastro_id = @catastro_id;

EXEC sp_Colindancia_Insertar
    @punto_cardinal = 'Este',
    @colindante = 'Propiedad de María González',
    @catastro_id = @catastro_id;

EXEC sp_Colindancia_Insertar
    @punto_cardinal = 'Oeste',
    @colindante = 'Río Tempisque',
    @catastro_id = @catastro_id;

PRINT 'Colindancias insertadas correctamente';
GO

-- =============================================
-- 3. INSERTAR OBSERVACIONES
-- =============================================
PRINT '';
PRINT '3. Insertando observaciones...';
GO

DECLARE @inmueble_id INT = 1;
DECLARE @catastro_id INT = (SELECT TOP 1 catastro_id FROM Catastro ORDER BY catastro_id DESC);

EXEC sp_ObservacionInmueble_Insertar
    @descripcion = 'Inmueble en excelente estado de conservación',
    @inmueble_id = @inmueble_id,
    @catastro_id = @catastro_id;

EXEC sp_ObservacionInmueble_Insertar
    @descripcion = 'Requiere actualización de avalúo fiscal',
    @inmueble_id = @inmueble_id,
    @catastro_id = @catastro_id;

PRINT 'Observaciones insertadas correctamente';
GO
