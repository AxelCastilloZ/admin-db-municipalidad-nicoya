--Procedimientos almacenados

-----------------------
--CONTRIBUYENTES 
-----------------------
-- SP: Insertar Contribuyente

USE MunicipalidadNicoya;
GO

CREATE PROCEDURE sp_Contribuyente_Insertar
    @cedula VARCHAR(20),
    @nombre VARCHAR(200),
    @tipo VARCHAR(20),
    @telefono VARCHAR(20) = NULL,
    @email VARCHAR(100) = NULL,
    @direccion VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que la c�dula no exista
        IF EXISTS (SELECT 1 FROM Contribuyente WHERE cedula = @cedula)
        BEGIN
            RAISERROR('La c�dula ya est� registrada en el sistema', 16, 1);
            RETURN;
        END
        
        -- Insertar el contribuyente
        INSERT INTO Contribuyente (cedula, nombre, tipo, telefono, email, direccion)
        VALUES (@cedula, @nombre, @tipo, @telefono, @email, @direccion);
        
        -- Retornar el ID generado
        SELECT SCOPE_IDENTITY() AS contribuyente_id;
        
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO


-- SP: Consultar Contribuyente por ID
CREATE PROCEDURE sp_Contribuyente_ConsultarPorID
    @contribuyente_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        contribuyente_id,
        cedula,
        nombre,
        tipo,
        telefono,
        email,
        direccion
    FROM Contribuyente
    WHERE contribuyente_id = @contribuyente_id;
END;
GO

-- SP: Consultar Contribuyente por C�dula
CREATE PROCEDURE sp_Contribuyente_ConsultarPorCedula
    @cedula VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        contribuyente_id,
        cedula,
        nombre,
        tipo,
        telefono,
        email,
        direccion
    FROM Contribuyente
    WHERE cedula = @cedula;
END;
GO

-- SP: Listar Todos los Contribuyentes
CREATE PROCEDURE sp_Contribuyente_Listar
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        contribuyente_id,
        cedula,
        nombre,
        tipo,
        telefono,
        email,
        direccion
    FROM Contribuyente
    ORDER BY nombre;
END;
GO

-- SP: Actualizar Contribuyente
CREATE PROCEDURE sp_Contribuyente_Actualizar
    @contribuyente_id INT,
    @cedula VARCHAR(20),
    @nombre VARCHAR(200),
    @tipo VARCHAR(20),
    @telefono VARCHAR(20) = NULL,
    @email VARCHAR(100) = NULL,
    @direccion VARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que el contribuyente existe
        IF NOT EXISTS (SELECT 1 FROM Contribuyente WHERE contribuyente_id = @contribuyente_id)
        BEGIN
            RAISERROR('El contribuyente no existe', 16, 1);
            RETURN;
        END
        
        -- Validar que la c�dula no est� duplicada (excepto para el mismo contribuyente)
        IF EXISTS (SELECT 1 FROM Contribuyente 
                   WHERE cedula = @cedula 
                   AND contribuyente_id <> @contribuyente_id)
        BEGIN
            RAISERROR('La c�dula ya est� registrada por otro contribuyente', 16, 1);
            RETURN;
        END
        
        -- Actualizar el contribuyente
        UPDATE Contribuyente
        SET 
            cedula = @cedula,
            nombre = @nombre,
            tipo = @tipo,
            telefono = @telefono,
            email = @email,
            direccion = @direccion
        WHERE contribuyente_id = @contribuyente_id;
        
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO


-- SP: Eliminar Contribuyente
CREATE PROCEDURE sp_Contribuyente_Eliminar
    @contribuyente_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que el contribuyente existe
        IF NOT EXISTS (SELECT 1 FROM Contribuyente WHERE contribuyente_id = @contribuyente_id)
        BEGIN
            RAISERROR('El contribuyente no existe', 16, 1);
            RETURN;
        END
        
        -- TODO: Aqu� deber�as validar que no tenga inmuebles o deudas asociadas
        -- Por ahora lo dejamos simple
        
        -- Eliminar el contribuyente
        DELETE FROM Contribuyente
        WHERE contribuyente_id = @contribuyente_id;
        
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO



-- Insertar un contribuyente de prueba
EXEC sp_Contribuyente_Insertar 
    @cedula = '123456789',
    @nombre = 'Juan P�rez G�mez',
    @tipo = 'F�sica',
    @telefono = '8888-8888',
    @email = 'juan@email.com',
    @direccion = 'Nicoya, Guanacaste';

-- Listar todos
EXEC sp_Contribuyente_Listar;

-- Consultar por ID
EXEC sp_Contribuyente_ConsultarPorID @contribuyente_id = 1;


----Fisico
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
        -- Validar que la c�dula no exista
        IF EXISTS (SELECT 1 FROM Contribuyente_fisico WHERE cedula = @cedula)
        BEGIN
            RAISERROR('La c�dula ya est� registrada', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- Insertar en tabla padre Contribuyente
        INSERT INTO Contribuyente (tipo_contribuyente, telefono, email, direccion)
        VALUES ('F�sica', @telefono, @email, @direccion);
        
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


--Juridico
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
        -- Validar que la c�dula jur�dica no exista
        IF EXISTS (SELECT 1 FROM Contribuyente_juridico WHERE cedula_juridica = @cedula_juridica)
        BEGIN
            RAISERROR('La c�dula jur�dica ya est� registrada', 16, 1);
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
        VALUES ('Jur�dica', @telefono, @email, @direccion);
        
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


--Contribuyente Completo
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
        -- Datos de persona f�sica
        cf.contribuyentes_fisicos_id,
        cf.cedula,
        cf.nombre,
        cf.apellido1,
        cf.apellido2,
        -- Datos de persona jur�dica
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

--Listar todos los contribuyentes
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
        -- Datos de persona f�sica
        cf.cedula,
        cf.nombre,
        cf.apellido1,
        cf.apellido2,
        -- Datos de persona jur�dica
        cj.cedula_juridica,
        cj.nombre_empresa,
        cj.representante_legal_id
    FROM Contribuyente c
    LEFT JOIN Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
    LEFT JOIN Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id
    ORDER BY c.contribuyente_id DESC;
END;
GO

-- =============================================
-- SP: Eliminar Contribuyente
-- =============================================
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
        
        -- Las tablas hijas se eliminan autom�ticamente por CASCADE
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

-- Probar inserci�n directa
EXEC sp_Contribuyente_InsertarFisico
    @cedula = '504570381',
    @nombre = 'Greilyn',
    @apellido1 = 'Esquivel',
    @apellido2 = 'Salazar',
    @telefono = '83778589',
    @email = 'greilynesquivel@gmail.com',
    @direccion = 'Hojancha, Pilangostra';
GO

-- Listar todos
EXEC sp_Contribuyente_ListarTodos;
GO

-- Consultar por ID
EXEC sp_Contribuyente_ConsultarCompleto @contribuyente_id = 1;
GO

-----------------------
--Inmueble
-----------------------
USE MunicipalidadNicoya;
GO

-- =============================================
-- SP: Listar Tipos de Uso de Inmueble
-- =============================================
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

-- =============================================
-- SP: Insertar Inmueble
-- =============================================
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
        
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- SP: Asociar Contribuyente a Inmueble
-- =============================================
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
        
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- SP: Listar Todos los Inmuebles
-- =============================================
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

-- =============================================
-- SP: Consultar Inmueble por ID
-- =============================================
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

-- =============================================
-- SP: Inmuebles de un Contribuyente
-- =============================================
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

-- =============================================
-- SP: Actualizar Inmueble
-- =============================================
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
        
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- SP: Eliminar Inmueble
-- =============================================
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
       
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =============================================
-- SP: Desasociar Contribuyente de Inmueble
-- =============================================
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
       
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

PRINT '========================================';
PRINT '✓ Stored Procedures de Inmuebles creados';
PRINT '========================================';
PRINT 'SPs creados:';
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

-- 1. Listar tipos de uso
EXEC sp_TipoUsoInmueble_Listar;
GO

-- 2. Insertar un inmueble
EXEC sp_Inmueble_Insertar
    @direccion_exacta = 'Nicoya Centro, 100m norte del parque',
    @area_terreno = 250.50,
    @valor_fiscal = 75000000.00,
    @tipo_uso_inmueble_id = 1,
    @estado_ocupacional = 'Ocupado';
GO

-- 3. Listar todos los inmuebles
EXEC sp_Inmueble_ListarTodos;
GO

-- 4. Asociar un contribuyente al inmueble (usa IDs reales)
EXEC sp_Inmueble_AsociarContribuyente
    @contribuyente_id = 1,
    @inmueble_id = 1,
    @porcentaje_propiedad = 100.00;
GO

-- 5. Ver inmuebles de un contribuyente
EXEC sp_Inmueble_PorContribuyente @contribuyente_id = 1;
GO

-----------------------
--USUARIO
--ROL
-----------------------
-- SP: Registrar Usuario
CREATE OR ALTER PROCEDURE sp_Usuario_Registrar
    @nombre VARCHAR(50),
    @apellido1 VARCHAR(50),
    @apellido2 VARCHAR(50) = NULL,
    @email VARCHAR(100),
    @password_hash VARCHAR(255),
    @rol_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        IF EXISTS (SELECT 1 FROM Usuario WHERE email = @email)
        BEGIN
            THROW 50001, 'El email ya est� registrado', 1;
        END
        
        IF NOT EXISTS (SELECT 1 FROM Rol WHERE rol_id = @rol_id)
        BEGIN
            THROW 50002, 'El rol no existe', 1;
        END
        
        INSERT INTO Usuario (
            nombre, apellido1, apellido2, email, password_hash, rol_id,
            activo, bloqueado, intentos_fallidos, fecha_creacion
        )
        VALUES (
            @nombre, @apellido1, @apellido2, @email, @password_hash, @rol_id,
            1, 0, 0, GETDATE()
        );
        
        SELECT SCOPE_IDENTITY() AS usuario_id;
        
        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- SP: Obtener Usuario por Email
CREATE OR ALTER PROCEDURE sp_Usuario_ObtenerPorEmail
    @email VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.usuario_id,
        u.nombre,
        u.apellido1,
        u.apellido2,
        u.email,
        u.password_hash,
        u.rol_id,
        r.nombre as rol_nombre,
        u.activo,
        u.bloqueado,
        u.intentos_fallidos,
        u.ultimo_acceso
    FROM Usuario u
    INNER JOIN Rol r ON u.rol_id = r.rol_id
    WHERE u.email = @email;
END
GO

-- SP: Actualizar Login Exitoso
CREATE OR ALTER PROCEDURE sp_Usuario_ActualizarLoginExitoso
    @usuario_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Usuario
    SET 
        ultimo_acceso = GETDATE(),
        intentos_fallidos = 0
    WHERE usuario_id = @usuario_id;
END
GO

-- SP: Registrar Login Fallido
CREATE OR ALTER PROCEDURE sp_Usuario_RegistrarLoginFallido
    @email VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @usuario_id INT;
    DECLARE @intentos INT;
    
    SELECT 
        @usuario_id = usuario_id,
        @intentos = intentos_fallidos
    FROM Usuario
    WHERE email = @email;
    
    IF @usuario_id IS NOT NULL
    BEGIN
        SET @intentos = @intentos + 1;
        
        UPDATE Usuario
        SET 
            intentos_fallidos = @intentos,
            bloqueado = CASE WHEN @intentos >= 5 THEN 1 ELSE 0 END
        WHERE usuario_id = @usuario_id;
    END
END
GO

-- SP: Listar Usuarios
CREATE OR ALTER PROCEDURE sp_Usuario_Listar
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.usuario_id,
        u.nombre,
        u.apellido1,
        u.apellido2,
        u.email,
        u.rol_id,
        r.nombre as rol_nombre,
        u.activo,
        u.bloqueado,
        u.intentos_fallidos,
        u.ultimo_acceso,
        u.fecha_creacion
    FROM Usuario u
    INNER JOIN Rol r ON u.rol_id = r.rol_id
    WHERE u.activo = 1
    ORDER BY u.nombre, u.apellido1;
END
GO

-- SP: Consultar Usuario por ID
CREATE OR ALTER PROCEDURE sp_Usuario_ConsultarPorID
    @usuario_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.usuario_id,
        u.nombre,
        u.apellido1,
        u.apellido2,
        u.email,
        u.rol_id,
        r.nombre as rol_nombre,
        u.activo,
        u.bloqueado,
        u.intentos_fallidos,
        u.ultimo_acceso,
        u.fecha_creacion
    FROM Usuario u
    INNER JOIN Rol r ON u.rol_id = r.rol_id
    WHERE u.usuario_id = @usuario_id;
END
GO

-- SP: Desbloquear Usuario
CREATE OR ALTER PROCEDURE sp_Usuario_Desbloquear
    @usuario_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Usuario
    SET 
        bloqueado = 0,
        intentos_fallidos = 0
    WHERE usuario_id = @usuario_id;
END
GO

-- SP: Cambiar Password
CREATE OR ALTER PROCEDURE sp_Usuario_CambiarPassword
    @usuario_id INT,
    @nuevo_password_hash VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Usuario
    SET password_hash = @nuevo_password_hash
    WHERE usuario_id = @usuario_id;
END
GO

-- SP: Actualizar Usuario
CREATE OR ALTER PROCEDURE sp_Usuario_Actualizar
    @usuario_id INT,
    @nombre VARCHAR(50),
    @apellido1 VARCHAR(50),
    @apellido2 VARCHAR(50) = NULL,
    @email VARCHAR(100),
    @rol_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Usuario WHERE usuario_id = @usuario_id)
        BEGIN
            RAISERROR('El usuario no existe', 16, 1);
            RETURN;
        END
        
        IF EXISTS (SELECT 1 FROM Usuario 
                   WHERE email = @email 
                   AND usuario_id <> @usuario_id)
        BEGIN
            RAISERROR('El email ya est� en uso', 16, 1);
            RETURN;
        END
        
        UPDATE Usuario
        SET 
            nombre = @nombre,
            apellido1 = @apellido1,
            apellido2 = @apellido2,
            email = @email,
            rol_id = @rol_id
        WHERE usuario_id = @usuario_id;
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
GO

-- SP: Eliminar Usuario (l�gico)
CREATE OR ALTER PROCEDURE sp_Usuario_Eliminar
    @usuario_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Usuario
    SET activo = 0
    WHERE usuario_id = @usuario_id;
END
GO

-- SP: Listar Roles
CREATE OR ALTER PROCEDURE sp_Rol_Listar
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        rol_id,
        nombre
    FROM Rol
    ORDER BY nombre;
END
GO

-- VERIFICACI�N
-- Ver roles creados
SELECT * FROM Rol;

-- Ver SPs creados
SELECT name FROM sys.procedures WHERE name LIKE 'sp_Usuario%' OR name LIKE 'sp_Rol%' ORDER BY name;
GO

EXEC sp_Usuario_Registrar
    @nombre = 'Administrador',
    @apellido1 = 'Sistema',
    @apellido2 = 'Municipal',
    @email = 'admin@gmail.com',
    @password_hash = '12345678',
    @rol_id = 1; -- Administrador

    select * from Usuario

-----------------------
--Tipo_Tramite 
-----------------------
/* =========================================================
   SP: Insertar Tipo_Tramite
========================================================= */
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

/* =========================================================
   SP: Consultar Tipo_Tramite por ID
========================================================= */
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

/* =========================================================
   SP: Listar Tipos_Tramite 
========================================================= */
Use MunicipalidadNicoya
go
CREATE PROCEDURE sp_TipoTramite_Listar
AS
BEGIN
  SET NOCOUNT ON;

  SELECT tipo_tramite_id, nombre_tipo
  FROM dbo.Tipo_Tramite
  ORDER BY nombre_tipo;
END;
GO

/* =========================================================
    SP: Buscar Tipos_Tramite por nombre (LIKE '%@nombre%') 
========================================================= */

CREATE PROCEDURE sp_TipoTramite_BuscarPorNombre
  @nombre VARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;

  IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
  BEGIN
    -- si viene vacío, devuelve todo (por comodidad)
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


/* =========================================================
   SP: Actualizar Tipo_Tramite
========================================================= */
CREATE PROCEDURE sp_TipoTramite_Actualizar
  @tipo_tramite_id INT,
  @nombre_tipo VARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    -- Existe el ID
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

    -- Duplicados (excluyendo el mismo ID)
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

    SELECT 1 AS resultado; -- éxito
  END TRY
  BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@ErrorMessage, 16, 1);
  END CATCH
END;
GO

/* =========================================================
   SP: Eliminar Tipo_Tramite
   - Evita eliminar si está referenciado por Tramite
========================================================= */
use MunicipalidadNicoya
go
CREATE PROCEDURE sp_TipoTramite_Eliminar
  @tipo_tramite_id INT
AS
BEGIN
  -- Importante: NOCOUNT OFF para que ExecuteNonQuery() retorne filas afectadas
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

--Ejemplos de uso 
use MunicipalidadNicoya
go
-- Insertar
EXEC sp_TipoTramite_Insertar @nombre_tipo = 'Uso de Suelo';
select * from Tipo_Tramite
go

-- Listar todos
EXEC sp_TipoTramite_Listar;

-- Buscar por nombre
EXEC sp_TipoTramite_BuscarPorNombre @nombre = 'Permiso';

-- Consultar por ID
EXEC sp_TipoTramite_ConsultarPorID @tipo_tramite_id = 1;

-- Actualizar
EXEC sp_TipoTramite_Actualizar
  @tipo_tramite_id = 1,
  @nombre_tipo = 'Patente Municipal';

-- Eliminar
EXEC sp_TipoTramite_Eliminar @tipo_tramite_id = 1;


-----------------------
--TRAMITES
-----------------------
-- SP: Insertar Tramite
-- SP: Insertar Tramite
Use MunicipalidadNicoya
go
CREATE PROCEDURE dbo.sp_tramite_insertar
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

    IF @estado_actual NOT IN ('En Proceso','Aprobado','Rechazado','Finalizado')
    BEGIN 
        RAISERROR('Estado inválido.',16,1);
        RETURN;
    END

    IF @fecha_resolucion IS NOT NULL AND @fecha_resolucion < @fecha_ingreso
    BEGIN 
        RAISERROR('fecha_resolucion debe ser >= fecha_ingreso.',16,1);
        RETURN;
    END

    IF NOT EXISTS(SELECT 1 FROM dbo.Tipo_Tramite WHERE tipo_tramite_id=@tipo_tramite_id)
    BEGIN RAISERROR('tipo_tramite_id no existe.',16,1); RETURN; END

    IF NOT EXISTS(SELECT 1 FROM dbo.Contribuyente WHERE contribuyente_id=@contribuyente_id)
    BEGIN RAISERROR('contribuyente_id no existe.',16,1); RETURN; END

    IF NOT EXISTS(SELECT 1 FROM dbo.Inmueble WHERE inmueble_id=@inmueble_id)
    BEGIN RAISERROR('inmueble_id no existe.',16,1); RETURN; END

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
END
GO
-- SP: Actualizar Tramite
CREATE PROCEDURE dbo.sp_tramite_actualizar
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

    IF NOT EXISTS(SELECT 1 FROM dbo.Tramite WHERE tramite_id=@tramite_id)
    BEGIN RAISERROR('El trámite no existe.',16,1); RETURN; END

    IF @fecha_resolucion < @fecha_ingreso
    BEGIN RAISERROR('fecha_resolucion debe ser >= fecha_ingreso.',16,1); RETURN; END

    IF NOT EXISTS(SELECT 1 FROM dbo.Tipo_Tramite WHERE tipo_tramite_id=@tipo_tramite_id)
    BEGIN RAISERROR('tipo_tramite_id no existe.',16,1); RETURN; END

    IF NOT EXISTS(SELECT 1 FROM dbo.Contribuyente WHERE contribuyente_id=@contribuyente_id)
    BEGIN RAISERROR('contribuyente_id no existe.',16,1); RETURN; END

    IF NOT EXISTS(SELECT 1 FROM dbo.Inmueble WHERE inmueble_id=@inmueble_id)
    BEGIN RAISERROR('inmueble_id no existe.',16,1); RETURN; END

    UPDATE dbo.Tramite
    SET fecha_ingreso=@fecha_ingreso,
        fecha_resolucion=@fecha_resolucion,
        observaciones=@observaciones,
        tipo_tramite_id=@tipo_tramite_id,
        contribuyente_id=@contribuyente_id,
        inmueble_id=@inmueble_id
    WHERE tramite_id=@tramite_id;

    SELECT 1 AS resultado;
END
GO

-- SP: Listar Tramite
CREATE PROCEDURE dbo.sp_Tramite_Listar
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
END
GO

-- SP: Eliminar Tramite solo si está "En Proceso"
CREATE PROCEDURE dbo.sp_tramite_eliminar
    @tramite_id INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS(SELECT 1 FROM dbo.Tramite WHERE tramite_id=@tramite_id)
    BEGIN RAISERROR('El trámite no existe.',16,1); RETURN; END

    IF EXISTS(SELECT 1 FROM dbo.Tramite WHERE tramite_id=@tramite_id AND estado_actual <> 'En Proceso')
    BEGIN RAISERROR('Solo se puede eliminar un trámite con estado "En Proceso".',16,1); RETURN; END

    DELETE FROM dbo.Tramite WHERE tramite_id=@tramite_id;
    SELECT 1 AS resultado;
END
GO

--SP: Cambiar estado
CREATE PROCEDURE dbo.sp_tramite_actualizar_estado
    @tramite_id INT,
    @nuevo_estado VARCHAR(20),
    @observaciones VARCHAR(255) = NULL,
    @fecha_resolucion DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @nuevo_estado NOT IN ('En Proceso','Aprobado','Rechazado','Finalizado')
    BEGIN RAISERROR('Estado inválido.',16,1); RETURN; END

    IF NOT EXISTS(SELECT 1 FROM dbo.Tramite WHERE tramite_id=@tramite_id)
    BEGIN RAISERROR('El trámite no existe.',16,1); RETURN; END

    DECLARE @fecha_ingreso DATE;
    SELECT @fecha_ingreso = fecha_ingreso FROM dbo.Tramite WHERE tramite_id=@tramite_id;

    -- si se finaliza/aprueba/rechaza y no pasan fecha, usamos hoy pero aseguramos coherencia
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
END
GO

--SP: Consultar por ID
CREATE PROCEDURE dbo.sp_tramite_consultar_por_id
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
END
GO

--Insertar  Tramites de Prueba
USE MunicipalidadNicoya;
GO

EXEC dbo.sp_tramite_insertar 
    @fecha_ingreso = '2025-09-01',
    @fecha_resolucion = '2025-09-10',
    @observaciones = 'Solicitud de permiso de construcción para vivienda unifamiliar.',
    @tipo_tramite_id = 1,          -- Permiso de Construcción
    @contribuyente_id = 1,         -- Juan Pérez Gómez
    @inmueble_id = 1,
    @estado_actual = 'En Proceso';
GO

EXEC dbo.sp_tramite_insertar 
    @fecha_ingreso = '2025-08-05',
    @fecha_resolucion = '2025-08-20',
    @observaciones = 'Trámite de alineamiento de lote.',
    @tipo_tramite_id = 5,          -- Alineamiento de Propiedad
    @contribuyente_id = 1,
    @inmueble_id = 1,
    @estado_actual = 'Aprobado';
GO

EXEC dbo.sp_Tramite_Listar;
GO

--Bucar por Tramite por ID
USE MunicipalidadNicoya;
GO

EXEC dbo.sp_tramite_consultar_por_id @tramite_id = 1;
GO



-- Verificar datos existentes
SELECT 'Contribuyentes' AS Tabla, COUNT(*) AS Total FROM Contribuyente
UNION ALL
SELECT 'Inmuebles', COUNT(*) FROM Inmueble
UNION ALL
SELECT 'Tipos de Trámite', COUNT(*) FROM Tipo_Tramite;
GO

-- Ver los IDs disponibles
SELECT TOP 5 contribuyente_id, tipo_contribuyente FROM Contribuyente;
SELECT TOP 5 inmueble_id, direccion_exacta FROM Inmueble;
SELECT TOP 5 tipo_tramite_id, nombre_tipo FROM Tipo_Tramite;
GO

SELECT name, create_date, modify_date
FROM sys.procedures
WHERE name = 'sp_tramite_insertar';
GO