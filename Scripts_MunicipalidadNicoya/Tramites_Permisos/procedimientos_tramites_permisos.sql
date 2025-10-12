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
select * from Tipo_Tramite
go

--Insertar Tipos de Trámite
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UQ_Tipo_Tramite_nombre_tipo' AND object_id=OBJECT_ID('dbo.Tipo_Tramite'))
    CREATE UNIQUE INDEX UQ_Tipo_Tramite_nombre_tipo ON dbo.Tipo_Tramite(nombre_tipo);

;WITH Valores(nombre_tipo) AS (
    SELECT 'Permiso de Construcción' UNION ALL
    SELECT 'Uso de Suelo'            UNION ALL
    SELECT 'Patente Comercial'       UNION ALL
    SELECT 'Cambio de Uso de Propiedad'       UNION ALL
    SELECT 'Movimiento de Tierras'
)
INSERT INTO dbo.Tipo_Tramite (nombre_tipo)
SELECT v.nombre_tipo
FROM Valores v
LEFT JOIN dbo.Tipo_Tramite t ON t.nombre_tipo = v.nombre_tipo
WHERE t.tipo_tramite_id IS NULL;

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
IF OBJECT_ID('dbo.sp_Tramite_Listar','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Tramite_Listar;
GO
CREATE PROCEDURE dbo.sp_Tramite_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        -- Trámite
        t.tramite_id,
        t.fecha_ingreso,
        t.fecha_resolucion,
        t.observaciones,
        t.estado_actual,
        t.tipo_tramite_id,
        t.contribuyente_id,
        t.inmueble_id,

        -- Tipo de trámite
        tt.nombre_tipo AS tipo_tramite_nombre,

        -- Contribuyente base
        c.tipo_contribuyente,
        c.telefono        AS contribuyente_telefono,
        c.email           AS contribuyente_email,
        c.direccion       AS contribuyente_direccion,

        -- Nombre e identificación según subtipo
        CASE 
            WHEN c.tipo_contribuyente = 'Física' 
                THEN LTRIM(RTRIM(
                      COALESCE(cf.nombre,'') + ' ' +
                      COALESCE(cf.apellido1,'') + ' ' +
                      COALESCE(cf.apellido2,'')
                ))
            ELSE COALESCE(cj.nombre_empresa,'')
        END AS contribuyente_nombre,
        CASE 
            WHEN c.tipo_contribuyente = 'Física' 
                THEN cf.cedula
            ELSE cj.cedula_juridica
        END AS contribuyente_identificacion,

        -- Inmueble + tipo de uso
        i.direccion_exacta      AS inmueble_direccion_exacta,
        i.area_terreno          AS inmueble_area_terreno,
        i.valor_fiscal          AS inmueble_valor_fiscal,
        i.estado_ocupacional    AS inmueble_estado_ocupacional,
        i.tipo_uso_inmueble_id  AS inmueble_tipo_uso_id,
        tu.nombre_uso           AS inmueble_tipo_uso_nombre
    FROM dbo.Tramite t
    INNER JOIN dbo.Tipo_Tramite        tt ON tt.tipo_tramite_id       = t.tipo_tramite_id
    INNER JOIN dbo.Contribuyente        c ON c.contribuyente_id       = t.contribuyente_id
    LEFT  JOIN dbo.Contribuyente_fisico cf ON cf.contribuyente_id     = c.contribuyente_id
    LEFT  JOIN dbo.Contribuyente_juridico cj ON cj.contribuyente_id   = c.contribuyente_id
    INNER JOIN dbo.Inmueble              i ON i.inmueble_id           = t.inmueble_id
    INNER JOIN dbo.TipoUsoInmueble      tu ON tu.tipo_uso_inmueble_id = i.tipo_uso_inmueble_id
    ORDER BY t.fecha_ingreso DESC;
END
GO

-- SP: Consultar Tramite por ID
IF OBJECT_ID('dbo.sp_Tramite_ConsultarPorID','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Tramite_ConsultarPorID;
GO
CREATE PROCEDURE dbo.sp_Tramite_ConsultarPorID
    @tramite_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        t.tramite_id,
        t.fecha_ingreso,
        t.fecha_resolucion,
        t.observaciones,
        t.estado_actual,
        t.tipo_tramite_id,
        t.contribuyente_id,
        t.inmueble_id,

        tt.nombre_tipo AS tipo_tramite_nombre,

        c.tipo_contribuyente,
        c.telefono        AS contribuyente_telefono,
        c.email           AS contribuyente_email,
        c.direccion       AS contribuyente_direccion,

        CASE 
            WHEN c.tipo_contribuyente = 'Física' 
                THEN LTRIM(RTRIM(
                      COALESCE(cf.nombre,'') + ' ' +
                      COALESCE(cf.apellido1,'') + ' ' +
                      COALESCE(cf.apellido2,'')
                ))
            ELSE COALESCE(cj.nombre_empresa,'')
        END AS contribuyente_nombre,
        CASE 
            WHEN c.tipo_contribuyente = 'Física' 
                THEN cf.cedula
            ELSE cj.cedula_juridica
        END AS contribuyente_identificacion,

        i.direccion_exacta      AS inmueble_direccion_exacta,
        i.area_terreno          AS inmueble_area_terreno,
        i.valor_fiscal          AS inmueble_valor_fiscal,
        i.estado_ocupacional    AS inmueble_estado_ocupacional,
        i.tipo_uso_inmueble_id  AS inmueble_tipo_uso_id,
        tu.nombre_uso           AS inmueble_tipo_uso_nombre
    FROM dbo.Tramite t
    INNER JOIN dbo.Tipo_Tramite        tt ON tt.tipo_tramite_id       = t.tipo_tramite_id
    INNER JOIN dbo.Contribuyente        c ON c.contribuyente_id       = t.contribuyente_id
    LEFT  JOIN dbo.Contribuyente_fisico cf ON cf.contribuyente_id     = c.contribuyente_id
    LEFT  JOIN dbo.Contribuyente_juridico cj ON cj.contribuyente_id   = c.contribuyente_id
    INNER JOIN dbo.Inmueble              i ON i.inmueble_id           = t.inmueble_id
    INNER JOIN dbo.TipoUsoInmueble      tu ON tu.tipo_uso_inmueble_id = i.tipo_uso_inmueble_id
    WHERE t.tramite_id = @tramite_id;
END
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

-- SP: Tramite por contribuyente
IF OBJECT_ID('dbo.sp_Tramite_PorContribuyente', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Tramite_PorContribuyente;
GO
CREATE PROCEDURE dbo.sp_Tramite_PorContribuyente
    @contribuyente_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        t.tramite_id,
        t.fecha_ingreso,
        t.fecha_resolucion,
        t.estado_actual,
        t.observaciones,

        tt.nombre_tipo AS tipo_tramite_nombre,
        i.direccion_exacta AS inmueble_direccion_exacta,
        i.valor_fiscal AS inmueble_valor_fiscal
    FROM dbo.Tramite t
    INNER JOIN dbo.Tipo_Tramite        tt ON tt.tipo_tramite_id       = t.tipo_tramite_id
    INNER JOIN dbo.Inmueble            i  ON i.inmueble_id            = t.inmueble_id
    WHERE t.contribuyente_id = @contribuyente_id
    ORDER BY t.fecha_ingreso DESC;
END;
GO

-- SP: Tramite por inmueble
IF OBJECT_ID('dbo.sp_Tramite_PorInmueble', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Tramite_PorInmueble;
GO
CREATE PROCEDURE dbo.sp_Tramite_PorInmueble
    @inmueble_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        t.tramite_id,
        t.fecha_ingreso,
        t.fecha_resolucion,
        t.estado_actual,
        t.observaciones,

        tt.nombre_tipo AS tipo_tramite_nombre,
        c.tipo_contribuyente,
        CASE 
            WHEN c.tipo_contribuyente = 'Física' 
                THEN LTRIM(RTRIM(COALESCE(cf.nombre,'') + ' ' + COALESCE(cf.apellido1,'') + ' ' + COALESCE(cf.apellido2,'')))
            ELSE cj.nombre_empresa
        END AS contribuyente_nombre
    FROM dbo.Tramite t
    INNER JOIN dbo.Tipo_Tramite        tt ON tt.tipo_tramite_id       = t.tipo_tramite_id
    INNER JOIN dbo.Contribuyente        c  ON c.contribuyente_id      = t.contribuyente_id
    LEFT  JOIN dbo.Contribuyente_fisico cf ON cf.contribuyente_id     = c.contribuyente_id
    LEFT  JOIN dbo.Contribuyente_juridico cj ON cj.contribuyente_id   = c.contribuyente_id
    WHERE t.inmueble_id = @inmueble_id
    ORDER BY t.fecha_ingreso DESC;
END;
GO

-- SP: Tramite por tipo
IF OBJECT_ID('dbo.sp_Tramite_PorTipo', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Tramite_PorTipo;
GO
CREATE PROCEDURE dbo.sp_Tramite_PorTipo
    @tipo_tramite_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        t.tramite_id,
        t.fecha_ingreso,
        t.estado_actual,
        t.observaciones,

        c.tipo_contribuyente,
        CASE 
            WHEN c.tipo_contribuyente = 'Física' 
                THEN LTRIM(RTRIM(COALESCE(cf.nombre,'') + ' ' + COALESCE(cf.apellido1,'') + ' ' + COALESCE(cf.apellido2,'')))
            ELSE cj.nombre_empresa
        END AS contribuyente_nombre,
        i.direccion_exacta AS inmueble_direccion_exacta
    FROM dbo.Tramite t
    INNER JOIN dbo.Contribuyente        c  ON c.contribuyente_id      = t.contribuyente_id
    LEFT  JOIN dbo.Contribuyente_fisico cf ON cf.contribuyente_id     = c.contribuyente_id
    LEFT  JOIN dbo.Contribuyente_juridico cj ON cj.contribuyente_id   = c.contribuyente_id
    INNER JOIN dbo.Inmueble            i   ON i.inmueble_id           = t.inmueble_id
    WHERE t.tipo_tramite_id = @tipo_tramite_id
    ORDER BY t.fecha_ingreso DESC;
END;
GO

-- =============================================
-- SECCIÓN: REQUISITO
-- =============================================

/* =========================================================
   INSERCIÓN DE REQUISITOS PREDEFINIDOS
   ========================================================= */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'UQ_Requisito_nombre'
      AND object_id = OBJECT_ID('dbo.Requisito')
)
    CREATE UNIQUE INDEX UQ_Requisito_nombre ON dbo.Requisito(nombre);
GO

;WITH Req(nombre, descripcion) AS (
    SELECT 'Formulario de solicitud', 'Formulario oficial de solicitud debidamente completado y firmado.' UNION ALL
    SELECT 'Copia de cédula',        'Copia legible de la cédula de identidad del solicitante o representante.' UNION ALL
    SELECT 'Plano catastrado',       'Copia del plano catastrado vigente.' UNION ALL
    SELECT 'Certificación de uso de suelo', 'Certificación municipal del uso de suelo.' UNION ALL
    SELECT 'Comprobante de pago',    'Comprobante de cancelación de derechos municipales.' UNION ALL
    SELECT 'Permiso sanitario',      'Permiso de funcionamiento sanitario vigente.' UNION ALL
    SELECT 'Declaración jurada',     'Declaración jurada de veracidad de la información aportada.' UNION ALL
    SELECT 'Carta de autorización',  'Carta de autorización del propietario (si aplica).'
)
INSERT INTO dbo.Requisito (nombre, descripcion)
SELECT r.nombre, r.descripcion
FROM Req r
LEFT JOIN dbo.Requisito x ON x.nombre = r.nombre
WHERE x.requisito_id IS NULL;
GO


/* =========================================================
   REQUISITO 
   ========================================================= */
use MunicipalidadNicoya
go
-- 1) Listar
IF OBJECT_ID('dbo.sp_Requisito_Listar','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Requisito_Listar;
GO
CREATE PROCEDURE dbo.sp_Requisito_Listar
AS
BEGIN
    SET NOCOUNT ON;
    SELECT requisito_id, nombre, descripcion
    FROM dbo.Requisito
    ORDER BY nombre;
END;
GO

-- 2) Consultar por ID
IF OBJECT_ID('dbo.sp_Requisito_ConsultarPorID','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Requisito_ConsultarPorID;
GO
CREATE PROCEDURE dbo.sp_Requisito_ConsultarPorID
    @requisito_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT requisito_id, nombre, descripcion
    FROM dbo.Requisito
    WHERE requisito_id = @requisito_id;
END;
GO

-- 3) Buscar (nombre/descripcion)
IF OBJECT_ID('dbo.sp_Requisito_Buscar','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Requisito_Buscar;
GO
CREATE PROCEDURE dbo.sp_Requisito_Buscar
    @q VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @q IS NULL OR LTRIM(RTRIM(@q)) = ''
    BEGIN
        SELECT requisito_id, nombre, descripcion
        FROM dbo.Requisito
        ORDER BY nombre;
        RETURN;
    END

    SELECT requisito_id, nombre, descripcion
    FROM dbo.Requisito
    WHERE nombre LIKE '%' + @q + '%'
       OR descripcion LIKE '%' + @q + '%'
    ORDER BY nombre;
END;
GO


/* =========================================================
   TIPO_TRÁMITE_REQUISITO 
   ========================================================= */
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'UQ_TipoTramiteRequisito'
      AND object_id = OBJECT_ID('dbo.Tipo_Tramite_Requisito')
)
    CREATE UNIQUE INDEX UQ_TipoTramiteRequisito
        ON dbo.Tipo_Tramite_Requisito(tipo_tramite_id, requisito_id);
GO

;WITH Mapa(nombre_tipo, nombre_requisito) AS (
    -- Permiso de Construcción
    SELECT 'Permiso de Construcción', 'Formulario de solicitud' UNION ALL
    SELECT 'Permiso de Construcción', 'Copia de cédula'        UNION ALL
    SELECT 'Permiso de Construcción', 'Plano catastrado'       UNION ALL
    SELECT 'Permiso de Construcción', 'Certificación de uso de suelo' UNION ALL
    SELECT 'Permiso de Construcción', 'Comprobante de pago'    UNION ALL

    -- Uso de Suelo
    SELECT 'Uso de Suelo', 'Formulario de solicitud'           UNION ALL
    SELECT 'Uso de Suelo', 'Copia de cédula'                   UNION ALL
    SELECT 'Uso de Suelo', 'Declaración jurada'                UNION ALL

    -- Patente Comercial
    SELECT 'Patente Comercial', 'Formulario de solicitud'      UNION ALL
    SELECT 'Patente Comercial', 'Copia de cédula'              UNION ALL
    SELECT 'Patente Comercial', 'Permiso sanitario'            UNION ALL
    SELECT 'Patente Comercial', 'Comprobante de pago'          UNION ALL

    -- Cambio de Uso de Propiedad
    SELECT 'Cambio de Uso de Propiedad', 'Formulario de solicitud' UNION ALL
    SELECT 'Cambio de Uso de Propiedad', 'Copia de cédula'         UNION ALL
    SELECT 'Cambio de Uso de Propiedad', 'Certificación de uso de suelo' UNION ALL
    SELECT 'Cambio de Uso de Propiedad', 'Comprobante de pago'     UNION ALL

    -- Movimiento de Tierras
    SELECT 'Movimiento de Tierras', 'Formulario de solicitud'  UNION ALL
    SELECT 'Movimiento de Tierras', 'Copia de cédula'          UNION ALL
    SELECT 'Movimiento de Tierras', 'Plano catastrado'         UNION ALL
    SELECT 'Movimiento de Tierras', 'Declaración jurada'
)
INSERT INTO dbo.Tipo_Tramite_Requisito (tipo_tramite_id, requisito_id)
SELECT tt.tipo_tramite_id, rq.requisito_id
FROM Mapa m
JOIN dbo.Tipo_Tramite tt ON tt.nombre_tipo = m.nombre_tipo
JOIN dbo.Requisito rq     ON rq.nombre      = m.nombre_requisito
LEFT JOIN dbo.Tipo_Tramite_Requisito ttr
  ON ttr.tipo_tramite_id = tt.tipo_tramite_id
 AND ttr.requisito_id    = rq.requisito_id
WHERE ttr.tipo_tramite_requisito_id IS NULL;
GO


/* =========================================================
   TIPO_TRÁMITE_REQUISITO 
   ========================================================= */
use MunicipalidadNicoya
go
-- 1) Listar TODAS las relaciones (con nombres útiles)
IF OBJECT_ID('dbo.sp_TipoTramiteRequisito_Listar','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_TipoTramiteRequisito_Listar;
GO
CREATE PROCEDURE dbo.sp_TipoTramiteRequisito_Listar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ttr.tipo_tramite_requisito_id,
        ttr.tipo_tramite_id,
        tt.nombre_tipo,
        ttr.requisito_id,
        r.nombre AS requisito_nombre,
        r.descripcion AS requisito_descripcion
    FROM dbo.Tipo_Tramite_Requisito ttr
    JOIN dbo.Tipo_Tramite tt ON tt.tipo_tramite_id = ttr.tipo_tramite_id
    JOIN dbo.Requisito r     ON r.requisito_id     = ttr.requisito_id
    ORDER BY tt.nombre_tipo, r.nombre;
END;
GO

-- 2) Requisitos por Tipo de Trámite
IF OBJECT_ID('dbo.sp_Requisitos_PorTipoTramite','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Requisitos_PorTipoTramite;
GO
CREATE PROCEDURE dbo.sp_Requisitos_PorTipoTramite
    @tipo_tramite_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT r.requisito_id, r.nombre, r.descripcion
    FROM dbo.Tipo_Tramite_Requisito ttr
    JOIN dbo.Requisito r ON r.requisito_id = ttr.requisito_id
    WHERE ttr.tipo_tramite_id = @tipo_tramite_id
    ORDER BY r.nombre;
END;
GO

-- 3) Tipos de Trámite por Requisito
IF OBJECT_ID('dbo.sp_TiposTramite_PorRequisito','P') IS NOT NULL
    DROP PROCEDURE dbo.sp_TiposTramite_PorRequisito;
GO
CREATE PROCEDURE dbo.sp_TiposTramite_PorRequisito
    @requisito_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT tt.tipo_tramite_id, tt.nombre_tipo
    FROM dbo.Tipo_Tramite_Requisito ttr
    JOIN dbo.Tipo_Tramite tt ON tt.tipo_tramite_id = ttr.tipo_tramite_id
    WHERE ttr.requisito_id = @requisito_id
    ORDER BY tt.nombre_tipo;
END;
GO

PRINT '';
PRINT '========================================';
PRINT '✓ STORED PROCEDURES - TRÁMITES Y PERMISOS';
PRINT '========================================';

PRINT '';
PRINT 'SPs Tipo Trámite:';
PRINT '  - sp_TipoTramite_ConsultarPorID';
PRINT '  - sp_TipoTramite_Listar';
PRINT '  - sp_TipoTramite_BuscarPorNombre';
PRINT '';

PRINT 'SPs Trámites:';
PRINT '  - sp_Tramite_Insertar';
PRINT '  - sp_Tramite_Actualizar';
PRINT '  - sp_Tramite_Listar';
PRINT '  - sp_Tramite_ConsultarPorID';
PRINT '  - sp_Tramite_Eliminar';
PRINT '  - sp_Tramite_ActualizarEstado';
PRINT '  - sp_Tramite_PorContribuyente';
PRINT '  - sp_Tramite_PorInmueble';
PRINT '  - sp_Tramite_PorTipo';
PRINT '';

PRINT 'SPs Requisito:';
PRINT '  - sp_Requisito_Listar';
PRINT '  - sp_Requisito_ConsultarPorID';
PRINT '  - sp_Requisito_Buscar';
PRINT '';

PRINT 'SPs Tipo_Trámite_Requisito:';
PRINT '  - sp_TipoTramiteRequisito_Listar';
PRINT '  - sp_Requisitos_PorTipoTramite';
PRINT '  - sp_TiposTramite_PorRequisito';
PRINT '';

PRINT '========================================';
GO