-- =============================================
-- MÓDULO: CONTRIBUYENTES E INMUEBLES
-- Script: Stored Procedures

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
-- =============================================
-- SP: Insertar Contribuyente Jurídico 
-- =============================================
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
    DECLARE @contribuyentes_fisicos_id INT;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        -- Validar que la cédula jurídica no exista
        IF EXISTS (SELECT 1 FROM Contribuyente_juridico WHERE cedula_juridica = @cedula_juridica)
        BEGIN
            THROW 50001, 'La cédula jurídica ya está registrada', 1;
        END
        
        SELECT @contribuyentes_fisicos_id = contribuyentes_fisicos_id
        FROM Contribuyente_fisico
        WHERE contribuyente_id = @representante_legal_id;
        
        -- Validar que el representante legal exista
        IF @contribuyentes_fisicos_id IS NULL
        BEGIN
            THROW 50002, 'El representante legal no existe', 1;
        END
        
        BEGIN TRANSACTION;
        
        -- Insertar en tabla padre Contribuyente
        INSERT INTO Contribuyente (tipo_contribuyente, telefono, email, direccion)
        VALUES ('Jurídica', @telefono, @email, @direccion);
        
        -- Obtener el ID generado
        SET @contribuyente_id = SCOPE_IDENTITY();
        
        -- Insertar usando el contribuyentes_fisicos_id correcto
        INSERT INTO Contribuyente_juridico (
            contribuyente_id, 
            cedula_juridica, 
            nombre_empresa, 
            representante_legal_id
        )
        VALUES (
            @contribuyente_id, 
            @cedula_juridica, 
            @nombre_empresa, 
            @contribuyentes_fisicos_id  
        );
        
        COMMIT TRANSACTION;
        
        -- Retornar el ID generado
        SELECT @contribuyente_id AS contribuyente_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

PRINT ' SP sp_Contribuyente_InsertarJuridico corregido';
GO

-- =============================================
-- SP MODIFICADO: sp_Contribuyente_ConsultarCompleto
-- =============================================
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
        c.tipo_contribuyente AS tipo,
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
        cj.representante_legal_id,
     
        rep.cedula AS representante_legal_cedula,
        rep.nombre AS representante_legal_nombre,
        rep.apellido1 AS representante_legal_apellido1,
        rep.apellido2 AS representante_legal_apellido2
    FROM Contribuyente c
    LEFT JOIN Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
    LEFT JOIN Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id
    LEFT JOIN Contribuyente_fisico rep ON cj.representante_legal_id = rep.contribuyentes_fisicos_id
    WHERE c.contribuyente_id = @contribuyente_id;
END;
GO

-- =============================================
-- SP: sp_Contribuyente_ListarTodos
-- =============================================
IF OBJECT_ID('sp_Contribuyente_ListarTodos', 'P') IS NOT NULL
    DROP PROCEDURE sp_Contribuyente_ListarTodos;
GO

CREATE PROCEDURE sp_Contribuyente_ListarTodos
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        c.contribuyente_id,
        c.tipo_contribuyente AS tipo,
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
        cj.representante_legal_id,
        -- Datos del representante legal
        rep.cedula AS representante_legal_cedula,
        rep.nombre AS representante_legal_nombre,
        rep.apellido1 AS representante_legal_apellido1,
        rep.apellido2 AS representante_legal_apellido2
    FROM Contribuyente c
    LEFT JOIN Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
    LEFT JOIN Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id
    LEFT JOIN Contribuyente_fisico rep ON cj.representante_legal_id = rep.contribuyentes_fisicos_id
    ORDER BY c.contribuyente_id DESC;
END;
GO


-- =============================================
-- SP: Actualizar Contribuyente Físico
-- =============================================
IF OBJECT_ID('sp_Contribuyente_ActualizarFisico', 'P') IS NOT NULL
    DROP PROCEDURE sp_Contribuyente_ActualizarFisico;
GO

CREATE PROCEDURE sp_Contribuyente_ActualizarFisico
    @contribuyente_id INT,
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
    
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @RowsAffected INT = 0;
    
    BEGIN TRY
        -- Validar que el contribuyente existe y es físico
        IF NOT EXISTS (
            SELECT 1 
            FROM Contribuyente c
            INNER JOIN Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
            WHERE c.contribuyente_id = @contribuyente_id
        )
        BEGIN
            THROW 50001, 'El contribuyente físico no existe', 1;
        END
        
        -- Validar que la cédula no esté duplicada (excluyendo el actual)
        IF EXISTS (
            SELECT 1 
            FROM Contribuyente_fisico 
            WHERE cedula = @cedula 
            AND contribuyente_id <> @contribuyente_id
        )
        BEGIN
            THROW 50002, 'La cédula ya está registrada para otro contribuyente', 1;
        END
        
        -- Validar formato de email si se proporciona
        IF @email IS NOT NULL AND @email NOT LIKE '%@%.%'
        BEGIN
            THROW 50003, 'El formato del email es inválido', 1;
        END
        
        BEGIN TRANSACTION;
        
        -- Actualizar tabla padre Contribuyente
        UPDATE Contribuyente
        SET 
            telefono = @telefono,
            email = @email,
            direccion = @direccion
        WHERE contribuyente_id = @contribuyente_id;
        
        SET @RowsAffected = @@ROWCOUNT;
        
        -- Actualizar tabla hija Contribuyente_fisico
        UPDATE Contribuyente_fisico
        SET 
            cedula = @cedula,
            nombre = @nombre,
            apellido1 = @apellido1,
            apellido2 = @apellido2
        WHERE contribuyente_id = @contribuyente_id;
        
        SET @RowsAffected = @RowsAffected + @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Retornar resultado de éxito
        SELECT 
            @RowsAffected AS RowsAffected, 
            'SUCCESS' AS Status,
            @contribuyente_id AS contribuyente_id;
        
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

PRINT ' SP sp_Contribuyente_ActualizarFisico creado exitosamente';
GO


-- =============================================
-- SP: Actualizar Contribuyente Jurídico 
-- =============================================
IF OBJECT_ID('sp_Contribuyente_ActualizarJuridico', 'P') IS NOT NULL
    DROP PROCEDURE sp_Contribuyente_ActualizarJuridico;
GO

CREATE PROCEDURE sp_Contribuyente_ActualizarJuridico
    @contribuyente_id INT,
    @cedula_juridica VARCHAR(50),
    @nombre_empresa VARCHAR(50),
    @representante_legal_id INT,  
    @telefono VARCHAR(20) = NULL,
    @email VARCHAR(100) = NULL,
    @direccion VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @RowsAffected INT = 0;
    DECLARE @contribuyentes_fisicos_id INT;
    
    BEGIN TRY
        -- Validar que el contribuyente existe y es jurídico
        IF NOT EXISTS (
            SELECT 1 
            FROM Contribuyente c
            INNER JOIN Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id
            WHERE c.contribuyente_id = @contribuyente_id
        )
        BEGIN
            THROW 50001, 'El contribuyente jurídico no existe', 1;
        END
        
        -- Validar que la cédula jurídica no esté duplicada (excluyendo el actual)
        IF EXISTS (
            SELECT 1 
            FROM Contribuyente_juridico 
            WHERE cedula_juridica = @cedula_juridica 
            AND contribuyente_id <> @contribuyente_id
        )
        BEGIN
            THROW 50002, 'La cédula jurídica ya está registrada para otro contribuyente', 1;
        END
        
        SELECT @contribuyentes_fisicos_id = contribuyentes_fisicos_id
        FROM Contribuyente_fisico
        WHERE contribuyente_id = @representante_legal_id;
        
        -- Validar que el representante legal existe
        IF @contribuyentes_fisicos_id IS NULL
        BEGIN
            THROW 50003, 'El representante legal no existe', 1;
        END
        
        -- Validar formato de email si se proporciona
        IF @email IS NOT NULL AND @email NOT LIKE '%@%.%'
        BEGIN
            THROW 50004, 'El formato del email es inválido', 1;
        END
        
        BEGIN TRANSACTION;
        
        -- Actualizar tabla padre Contribuyente
        UPDATE Contribuyente
        SET 
            telefono = @telefono,
            email = @email,
            direccion = @direccion
        WHERE contribuyente_id = @contribuyente_id;
        
        SET @RowsAffected = @@ROWCOUNT;
        
        UPDATE Contribuyente_juridico
        SET 
            cedula_juridica = @cedula_juridica,
            nombre_empresa = @nombre_empresa,
            representante_legal_id = @contribuyentes_fisicos_id  
        WHERE contribuyente_id = @contribuyente_id;
        
        SET @RowsAffected = @RowsAffected + @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Retornar resultado de éxito
        SELECT 
            @RowsAffected AS RowsAffected, 
            'SUCCESS' AS Status,
            @contribuyente_id AS contribuyente_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorMessage = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

PRINT 'SP sp_Contribuyente_ActualizarJuridico corregido';
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
        
        -- VALIDACIÓN 1: Verificar si es representante legal de alguna empresa
        IF EXISTS (
            SELECT 1 
            FROM Contribuyente_juridico cj
            INNER JOIN Contribuyente_fisico cf ON cj.representante_legal_id = cf.contribuyentes_fisicos_id
            WHERE cf.contribuyente_id = @contribuyente_id
        )
        BEGIN
            RAISERROR('No se puede eliminar: el contribuyente es representante legal de una o más empresas', 16, 1);
            RETURN;
        END
        
        --  VALIDACIÓN 2: Verificar si tiene inmuebles asociados
        IF EXISTS (
            SELECT 1 FROM Contribuyente_Inmueble 
            WHERE contribuyente_id = @contribuyente_id
        )
        BEGIN
            RAISERROR('No se puede eliminar: el contribuyente tiene inmuebles asociados', 16, 1);
            RETURN;
        END
        
        BEGIN TRANSACTION;
        
        -- Las tablas hijas se eliminan automáticamente por CASCADE
        DELETE FROM Contribuyente WHERE contribuyente_id = @contribuyente_id;
        
        COMMIT TRANSACTION;
        
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

PRINT 'SP sp_Contribuyente_Eliminar actualizado con validaciones de negocio';
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
        t.descripcion AS tipo_uso_descripcion, 
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
    
    DECLARE @RowsAffected INT;
    
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
        
        -- Capturar y retornar las filas afectadas
        SET @RowsAffected = @@ROWCOUNT;
        
        COMMIT TRANSACTION;
        
        -- Retornar el resultado
        SELECT @RowsAffected AS RowsAffected, 'SUCCESS' AS Status;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

PRINT ' SP sp_Catastro_Actualizar corregido con retorno de resultado';
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
     
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
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
        
        DECLARE @dbName NVARCHAR(128) = DB_NAME();
        PRINT 'Base de datos actual: ' + @dbName;
        
        -- Verificar si el inmueble existe
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
        
        -- Validar número de plano duplicado 
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
        IF @punto_cardinal NOT IN ('Norte', 'Sur', 'Este', 'Oeste')
        BEGIN
            THROW 50002, 'Punto cardinal inválido', 1;
        END
        
        -- Obtener el catastro_id y punto_cardinal actual
        DECLARE @catastro_id INT;
        DECLARE @punto_cardinal_actual VARCHAR(10);
        
        SELECT 
            @catastro_id = catastro_id,
            @punto_cardinal_actual = punto_cardinal
        FROM Colindancias 
        WHERE colindancias_id = @colindancias_id;
        
        -- Solo validar duplicados SI se está CAMBIANDO el punto cardinal
        IF @punto_cardinal <> @punto_cardinal_actual
        BEGIN
            IF EXISTS (
                SELECT 1 FROM Colindancias 
                WHERE catastro_id = @catastro_id 
                AND punto_cardinal = @punto_cardinal 
                AND colindancias_id <> @colindancias_id
            )
            BEGIN
                THROW 50003, 'Ya existe una colindancia para ese punto cardinal', 1;
            END
        END
        
        BEGIN TRANSACTION;
        
        UPDATE Colindancias
        SET 
            punto_cardinal = @punto_cardinal,
            colindante = @colindante
        WHERE colindancias_id = @colindancias_id;
        
        COMMIT TRANSACTION;
        
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

PRINT ' SP sp_Colindancia_Actualizar corregido';
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
        
          -- Validar que la descripción no esté vacía
        IF LEN(TRIM(@descripcion)) = 0
        BEGIN
            THROW 50002, 'La descripción no puede estar vacía', 1;
        END

        -- Si no se proporciona fecha, usar la fecha actual
        IF @fecha IS NULL
            SET @fecha = CAST(GETDATE() AS DATE);
        
        BEGIN TRANSACTION;
        
        INSERT INTO ObservacionInmueble (fecha, descripcion, inmueble_id)
        VALUES (@fecha, @descripcion, @inmueble_id);
        
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
        i.direccion_exacta AS inmueble_direccion,
        -- Información del catastro asociado al inmueble
        c.catastro_id,
        c.numero_plano_catastral,
        c.estado AS catastro_estado
    FROM ObservacionInmueble o
    INNER JOIN Inmueble i ON o.inmueble_id = i.inmueble_id
    LEFT JOIN Catastro c ON i.inmueble_id = c.inmueble_id AND c.estado = 'Activo'
    WHERE o.inmueble_id = @inmueble_id
    ORDER BY o.fecha DESC;
END;
GO

-- SP: Listar Observaciones por Catastro
IF OBJECT_ID('sp_ObservacionInmueble_ListarPorCatastro', 'P') IS NOT NULL
    DROP PROCEDURE sp_ObservacionInmueble_ListarPorCatastro;
GO

PRINT 'SP obsoleto sp_ObservacionInmueble_ListarPorCatastro eliminado';
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
    
    DECLARE @inmueble_id INT;
    
    -- Obtener el inmueble_id del catastro
    SELECT @inmueble_id = inmueble_id 
    FROM Catastro 
    WHERE catastro_id = @catastro_id;
    
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
            WHEN 'Este' THEN 2
            WHEN 'Sur' THEN 3
            WHEN 'Oeste' THEN 4
        END;
    
    -- Observaciones del inmueble asociado
    SELECT 
        observacion_inmueble_id,
        fecha,
        descripcion,
        inmueble_id
    FROM ObservacionInmueble
    WHERE inmueble_id = @inmueble_id
    ORDER BY fecha DESC;
END;
GO








-- =============================================
-- SP NUEVO: Listar Observaciones con Catastro
-- =============================================
IF OBJECT_ID('sp_ObservacionInmueble_ListarConCatastro', 'P') IS NOT NULL
    DROP PROCEDURE sp_ObservacionInmueble_ListarConCatastro;
GO

CREATE PROCEDURE sp_ObservacionInmueble_ListarConCatastro
    @inmueble_id INT = NULL,
    @catastro_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Si se proporciona catastro_id, obtener el inmueble_id
    IF @catastro_id IS NOT NULL
    BEGIN
        SELECT @inmueble_id = inmueble_id 
        FROM Catastro 
        WHERE catastro_id = @catastro_id;
        
        IF @inmueble_id IS NULL
        BEGIN
            THROW 50001, 'El catastro no existe', 1;
        END
    END
    
    -- Validar que se proporcionó al menos un parámetro
    IF @inmueble_id IS NULL
    BEGIN
        THROW 50002, 'Debe proporcionar inmueble_id o catastro_id', 1;
    END
    
    SELECT 
        o.observacion_inmueble_id,
        o.fecha,
        o.descripcion,
        o.inmueble_id,
        i.direccion_exacta,
        i.area_terreno,
        i.valor_fiscal,
        c.catastro_id,
        c.numero_plano_catastral,
        c.area_catastral,
        c.estado AS catastro_estado
    FROM ObservacionInmueble o
    INNER JOIN Inmueble i ON o.inmueble_id = i.inmueble_id
    LEFT JOIN Catastro c ON i.inmueble_id = c.inmueble_id
    WHERE o.inmueble_id = @inmueble_id
    ORDER BY o.fecha DESC;
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
    
    DECLARE @RowsAffected INT;

    BEGIN TRY
        -- Validar que el inmueble existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Inmueble WHERE inmueble_id = @inmueble_id)
        BEGIN
            THROW 50001, 'El inmueble no existe', 1;
        END

        -- Validar que el tipo de uso exista
        IF NOT EXISTS (SELECT 1 FROM dbo.TipoUsoInmueble WHERE tipo_uso_inmueble_id = @tipo_uso_inmueble_id)
        BEGIN
            THROW 50002, 'El tipo de uso del inmueble no existe', 1;
        END

        -- Validar área terreno > 0
        IF @area_terreno <= 0
        BEGIN
            THROW 50003, 'El área del terreno debe ser mayor a 0', 1;
        END

        -- Validar valor fiscal >= 0
        IF @valor_fiscal < 0
        BEGIN
            THROW 50004, 'El valor fiscal no puede ser negativo', 1;
        END

        -- Validar dirección no vacía
        IF NULLIF(LTRIM(RTRIM(@direccion_exacta)), '') IS NULL
        BEGIN
            THROW 50005, 'La dirección exacta es obligatoria', 1;
        END

        BEGIN TRANSACTION;

        UPDATE dbo.Inmueble
        SET 
            direccion_exacta = @direccion_exacta,
            area_terreno = @area_terreno,
            valor_fiscal = @valor_fiscal,
            tipo_uso_inmueble_id = @tipo_uso_inmueble_id,
            estado_ocupacional = @estado_ocupacional
        WHERE inmueble_id = @inmueble_id;

        SET @RowsAffected = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Retornar resultado
        SELECT @RowsAffected AS RowsAffected, 'SUCCESS' AS Status;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Relanzar el error para que lo capture el C#
        THROW;
    END CATCH
END;
GO

PRINT 'SP sp_Inmueble_Actualizar creado correctamente con validaciones y transacción';
GO





-- =============================================
-- SCRIPT CORREGIDO: DATOS DE PRUEBA Y TESTS
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '';
PRINT '========================================';
PRINT 'PREPARANDO DATOS DE PRUEBA';
PRINT '========================================';
GO

-- =============================================
-- LIMPIAR DATOS PREVIOS (OPCIONAL)
-- =============================================
PRINT '1. Limpiando datos previos...';
GO

DELETE FROM ObservacionInmueble;
DELETE FROM Colindancias;
DELETE FROM Catastro;
DELETE FROM Contribuyente_Inmueble;
DELETE FROM Inmueble;
DELETE FROM Contribuyente_juridico;
DELETE FROM Contribuyente_fisico;
DELETE FROM Contribuyente;
GO

PRINT ' Datos previos eliminados';
GO

-- =============================================
-- INSERTAR CONTRIBUYENTES DE PRUEBA
-- =============================================
PRINT '';
PRINT '2. Insertando contribuyentes de prueba...';
GO

DECLARE @contribuyente1_id INT;
DECLARE @contribuyente2_id INT;

-- Contribuyente Físico 1
EXEC sp_Contribuyente_InsertarFisico
    @cedula = '1-0234-0567',
    @nombre = 'Juan',
    @apellido1 = 'Pérez',
    @apellido2 = 'González',
    @telefono = '2685-1234',
    @email = 'juan.perez@email.com',
    @direccion = 'Nicoya Centro, 200m norte del parque';

SET @contribuyente1_id = (SELECT TOP 1 contribuyente_id FROM Contribuyente ORDER BY contribuyente_id DESC);

-- Contribuyente Físico 2 (para representante legal)
EXEC sp_Contribuyente_InsertarFisico
    @cedula = '1-0345-0678',
    @nombre = 'María',
    @apellido1 = 'González',
    @apellido2 = 'Rodríguez',
    @telefono = '2685-5678',
    @email = 'maria.gonzalez@email.com',
    @direccion = 'Nicoya, Barrio San Martín';

SET @contribuyente2_id = (SELECT TOP 1 contribuyente_id FROM Contribuyente ORDER BY contribuyente_id DESC);

-- Contribuyente Jurídico


EXEC sp_Contribuyente_InsertarJuridico
    @cedula_juridica = '3-101-234567',
    @nombre_empresa = 'Nicoya Desarrollos S.A.',
    @representante_legal_id = @contribuyente2_id,
    @telefono = '2685-9999',
    @email = 'info@nicoyadesarrollos.cr',
    @direccion = 'Nicoya, Zona Industrial';

PRINT ' Contribuyentes insertados';
PRINT '  - Contribuyente 1 ID: ' + CAST(@contribuyente1_id AS VARCHAR(10));
PRINT '  - Contribuyente 2 ID: ' + CAST(@contribuyente2_id AS VARCHAR(10));
GO

-- =============================================
-- INSERTAR INMUEBLES DE PRUEBA
-- =============================================
PRINT '';
PRINT '3. Insertando inmuebles de prueba...';
GO

DECLARE @inmueble1_id INT;
DECLARE @inmueble2_id INT;
DECLARE @inmueble3_id INT;

-- Inmueble 1 (Residencial)
EXEC sp_Inmueble_Insertar
    @direccion_exacta = 'Nicoya Centro, 300m este del Parque Central',
    @area_terreno = 250.50,
    @valor_fiscal = 45000000.00,
    @tipo_uso_inmueble_id = 1,
    @estado_ocupacional = 'Ocupado';

SET @inmueble1_id = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id DESC);

-- Inmueble 2 (Comercial)
EXEC sp_Inmueble_Insertar
    @direccion_exacta = 'Nicoya, Calle Principal frente al mercado',
    @area_terreno = 180.00,
    @valor_fiscal = 65000000.00,
    @tipo_uso_inmueble_id = 2,
    @estado_ocupacional = 'Ocupado';

SET @inmueble2_id = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id DESC);

-- Inmueble 3 (Agrícola)
EXEC sp_Inmueble_Insertar
    @direccion_exacta = 'Nicoya, San Antonio, sector rural',
    @area_terreno = 5000.00,
    @valor_fiscal = 120000000.00,
    @tipo_uso_inmueble_id = 4,
    @estado_ocupacional = 'Desocupado';

SET @inmueble3_id = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id DESC);

PRINT ' Inmuebles insertados';
PRINT '  - Inmueble 1 ID: ' + CAST(@inmueble1_id AS VARCHAR(10));
PRINT '  - Inmueble 2 ID: ' + CAST(@inmueble2_id AS VARCHAR(10));
PRINT '  - Inmueble 3 ID: ' + CAST(@inmueble3_id AS VARCHAR(10));
GO

-- =============================================
-- ASOCIAR CONTRIBUYENTES A INMUEBLES
-- =============================================
PRINT '';
PRINT '4. Asociando contribuyentes a inmuebles...';
GO

-- Declarar variables con TOP 1 para evitar errores de ORDER BY
DECLARE @contrib1 INT = (SELECT TOP 1 contribuyente_id FROM Contribuyente WHERE tipo_contribuyente = 'Física' ORDER BY contribuyente_id);
DECLARE @contrib2 INT = (SELECT TOP 1 contribuyente_id FROM Contribuyente WHERE tipo_contribuyente = 'Física' AND contribuyente_id > @contrib1 ORDER BY contribuyente_id);
DECLARE @contrib3 INT = (SELECT TOP 1 contribuyente_id FROM Contribuyente WHERE tipo_contribuyente = 'Jurídica' ORDER BY contribuyente_id DESC);

DECLARE @inm1 INT = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id);
DECLARE @inm2 INT = (SELECT TOP 1 inmueble_id FROM Inmueble WHERE inmueble_id > @inm1 ORDER BY inmueble_id);
DECLARE @inm3 INT = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id DESC);

-- Asociación 1
EXEC sp_Inmueble_AsociarContribuyente
    @contribuyente_id = @contrib1,
    @inmueble_id = @inm1,
    @porcentaje_propiedad = 100.00;

-- Asociación 2
EXEC sp_Inmueble_AsociarContribuyente
    @contribuyente_id = @contrib2,
    @inmueble_id = @inm2,
    @porcentaje_propiedad = 100.00;

-- Asociación 3
EXEC sp_Inmueble_AsociarContribuyente
    @contribuyente_id = @contrib3,
    @inmueble_id = @inm3,
    @porcentaje_propiedad = 100.00;

PRINT 'Asociaciones creadas';
GO

-- =============================================
-- INSERTAR CATASTROS
-- =============================================
PRINT '';
PRINT '5. Insertando catastros...';
GO

DECLARE @inm1 INT = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id);
DECLARE @inm2 INT = (SELECT TOP 1 inmueble_id FROM Inmueble WHERE inmueble_id > @inm1 ORDER BY inmueble_id);
DECLARE @catastro1_id INT;
DECLARE @catastro2_id INT;

-- Catastro Inmueble 1
EXEC sp_Catastro_Insertar
    @numero_plano_catastral = 'G-1234567-2024',
    @area_catastral = '250.50 m² - Zona Urbana Nicoya Centro',
    @fecha_inscripcion = '2024-01-15',
    @estado = 'Activo',
    @inmueble_id = @inm1;

SET @catastro1_id = (SELECT TOP 1 catastro_id FROM Catastro ORDER BY catastro_id DESC);

-- Catastro Inmueble 2
EXEC sp_Catastro_Insertar
    @numero_plano_catastral = 'G-2345678-2024',
    @area_catastral = '180.00 m² - Zona Comercial Centro',
    @fecha_inscripcion = '2024-02-20',
    @estado = 'Activo',
    @inmueble_id = @inm2;

SET @catastro2_id = (SELECT TOP 1 catastro_id FROM Catastro ORDER BY catastro_id DESC);

PRINT ' Catastros insertados';
PRINT '  - Catastro 1 ID: ' + CAST(@catastro1_id AS VARCHAR(10));
PRINT '  - Catastro 2 ID: ' + CAST(@catastro2_id AS VARCHAR(10));
GO

-- =============================================
-- INSERTAR COLINDANCIAS
-- =============================================
PRINT '';
PRINT '6. Insertando colindancias...';
GO

DECLARE @cat1 INT = (SELECT TOP 1 catastro_id FROM Catastro ORDER BY catastro_id);

EXEC sp_Colindancia_Insertar
    @punto_cardinal = 'Norte',
    @colindante = 'Propiedad de Juan Ramírez',
    @catastro_id = @cat1;

EXEC sp_Colindancia_Insertar
    @punto_cardinal = 'Sur',
    @colindante = 'Calle Pública Principal',
    @catastro_id = @cat1;

EXEC sp_Colindancia_Insertar
    @punto_cardinal = 'Este',
    @colindante = 'Propiedad de Ana Mora',
    @catastro_id = @cat1;

EXEC sp_Colindancia_Insertar
    @punto_cardinal = 'Oeste',
    @colindante = 'Parque Central de Nicoya',
    @catastro_id = @cat1;

PRINT '✓ Colindancias insertadas';
GO

-- =============================================
-- INSERTAR OBSERVACIONES
-- =============================================
PRINT '';
PRINT '7. Insertando observaciones...';
GO

DECLARE @inm1 INT = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id);
DECLARE @inm2 INT = (SELECT TOP 1 inmueble_id FROM Inmueble WHERE inmueble_id > @inm1 ORDER BY inmueble_id);

-- Observaciones Inmueble 1
EXEC sp_ObservacionInmueble_Insertar
    @descripcion = 'Inmueble en excelente estado de conservación',
    @inmueble_id = @inm1;

EXEC sp_ObservacionInmueble_Insertar
    @descripcion = 'Requiere actualización de avalúo fiscal',
    @inmueble_id = @inm1;

EXEC sp_ObservacionInmueble_Insertar
    @descripcion = 'Pendiente revisión de linderos con vecino norte',
    @inmueble_id = @inm1,
    @fecha = '2024-09-15';

-- Observaciones Inmueble 2
EXEC sp_ObservacionInmueble_Insertar
    @descripcion = 'Local comercial bien ubicado, alta afluencia',
    @inmueble_id = @inm2;

PRINT ' Observaciones insertadas';
GO

-- =============================================
-- PRUEBAS DE CONSULTA
-- =============================================
PRINT '';
PRINT '========================================';
PRINT 'EJECUTANDO PRUEBAS DE CONSULTA';
PRINT '========================================';
GO

-- Test 1
PRINT '';
PRINT 'Test 1: Listar todos los contribuyentes';
EXEC sp_Contribuyente_ListarTodos;
GO

-- Test 2
PRINT '';
PRINT 'Test 2: Listar todos los inmuebles';
EXEC sp_Inmueble_ListarTodos;
GO

-- Test 3
PRINT '';
PRINT 'Test 3: Consultar inmueble por ID (con propietarios)';
DECLARE @inm INT = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id);
EXEC sp_Inmueble_ConsultarPorID @inmueble_id = @inm;
GO

-- Test 4
PRINT '';
PRINT 'Test 4: Listar todos los catastros';
EXEC sp_Catastro_ListarTodos;
GO

-- Test 5
PRINT '';
PRINT 'Test 5: Consultar catastro completo (con colindancias y observaciones)';
DECLARE @cat INT = (SELECT TOP 1 catastro_id FROM Catastro ORDER BY catastro_id);
EXEC sp_Catastro_ConsultarCompleto @catastro_id = @cat;
GO

-- Test 6
PRINT '';
PRINT 'Test 6: Listar observaciones por inmueble';
DECLARE @inm INT = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id);
EXEC sp_ObservacionInmueble_ListarPorInmueble @inmueble_id = @inm;
GO

-- Test 7
PRINT '';
PRINT 'Test 7: Listar observaciones con información de catastro';
DECLARE @inm INT = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id);
EXEC sp_ObservacionInmueble_ListarConCatastro @inmueble_id = @inm;
GO

-- Test 8
PRINT '';
PRINT 'Test 8: Listar observaciones proporcionando catastro_id';
DECLARE @cat INT = (SELECT TOP 1 catastro_id FROM Catastro ORDER BY catastro_id);
EXEC sp_ObservacionInmueble_ListarConCatastro @catastro_id = @cat;
GO

PRINT '';
PRINT '========================================';
PRINT 'TODAS LAS PRUEBAS COMPLETADAS';
PRINT '=======================================';
PRINT 'Resumen:';
PRINT '  - Contribuyentes creados y listados';
PRINT '  - Inmuebles creados y asociados';
PRINT '  - Catastros registrados';
PRINT '  - Colindancias definidas';
PRINT '  - Observaciones registradas';
PRINT '  - Consultas verificadas';
PRINT '========================================';
GO

