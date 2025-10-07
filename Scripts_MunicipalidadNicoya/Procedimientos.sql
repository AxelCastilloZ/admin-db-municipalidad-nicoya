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
        -- Validar que la cédula no exista
        IF EXISTS (SELECT 1 FROM Contribuyente WHERE cedula = @cedula)
        BEGIN
            RAISERROR('La cédula ya está registrada en el sistema', 16, 1);
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

-- SP: Consultar Contribuyente por Cédula
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
        
        -- Validar que la cédula no esté duplicada (excepto para el mismo contribuyente)
        IF EXISTS (SELECT 1 FROM Contribuyente 
                   WHERE cedula = @cedula 
                   AND contribuyente_id <> @contribuyente_id)
        BEGIN
            RAISERROR('La cédula ya está registrada por otro contribuyente', 16, 1);
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
        
        -- TODO: Aquí deberías validar que no tenga inmuebles o deudas asociadas
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
    @nombre = 'Juan Pérez Gómez',
    @tipo = 'Física',
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

-- Probar inserción directa
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
            THROW 50001, 'El email ya está registrado', 1;
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
            RAISERROR('El email ya está en uso', 16, 1);
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

-- SP: Eliminar Usuario (lógico)
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

-- VERIFICACIÓN
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
