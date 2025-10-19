


-- =============================================
-- SCRIPT DE LIMPIEZA: MÓDULO PAGOS Y COBROS
-- Descripción: Elimina TODOS los SPs para poder recrearlos desde cero
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '';
PRINT '========================================';
PRINT '🧹 INICIANDO LIMPIEZA DE STORED PROCEDURES';
PRINT '   Módulo: PAGOS Y COBROS';
PRINT '========================================';
PRINT '';

-- =============================================
-- MÓDULO: RUBRO (5 SPs)
-- =============================================
PRINT '📦 Eliminando SPs del módulo RUBRO...';

DROP PROCEDURE IF EXISTS dbo.sp_insertar_rubro;
PRINT '  ✓ sp_insertar_rubro eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_consultar_rubro_por_id;
PRINT '  ✓ sp_consultar_rubro_por_id eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_listar_rubros;
PRINT '  ✓ sp_listar_rubros eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_actualizar_rubro;
PRINT '  ✓ sp_actualizar_rubro eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_eliminar_rubro;
PRINT '  ✓ sp_eliminar_rubro eliminado';

PRINT '';

-- =============================================
-- MÓDULO: FACTURA (5 SPs)
-- =============================================
PRINT '📦 Eliminando SPs del módulo FACTURA...';

DROP PROCEDURE IF EXISTS dbo.sp_emitir_factura;
PRINT '  ✓ sp_emitir_factura eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_consultar_factura_por_id;
PRINT '  ✓ sp_consultar_factura_por_id eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_listar_facturas;
PRINT '  ✓ sp_listar_facturas eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_actualizar_factura;
PRINT '  ✓ sp_actualizar_factura eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_cancelar_factura;
PRINT '  ✓ sp_cancelar_factura eliminado';

PRINT '';

-- =============================================
-- MÓDULO: DETALLE_FACTURA (4 SPs)
-- =============================================
PRINT '📦 Eliminando SPs del módulo DETALLE_FACTURA...';

DROP PROCEDURE IF EXISTS dbo.sp_insertar_detalle_factura;
PRINT '  ✓ sp_insertar_detalle_factura eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_actualizar_detalle_factura;
PRINT '  ✓ sp_actualizar_detalle_factura eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_eliminar_detalle_factura;
PRINT '  ✓ sp_eliminar_detalle_factura eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_listar_detalles_por_factura;
PRINT '  ✓ sp_listar_detalles_por_factura eliminado';

PRINT '';

-- =============================================
-- MÓDULO: PAGO (4 SPs)
-- =============================================
PRINT '📦 Eliminando SPs del módulo PAGO...';

DROP PROCEDURE IF EXISTS dbo.sp_registrar_pago;
PRINT '  ✓ sp_registrar_pago eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_consultar_pago_por_id;
PRINT '  ✓ sp_consultar_pago_por_id eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_listar_pagos_por_factura;
PRINT '  ✓ sp_listar_pagos_por_factura eliminado';

DROP PROCEDURE IF EXISTS dbo.sp_visualizar_historial_pagos;
PRINT '  ✓ sp_visualizar_historial_pagos eliminado';

PRINT '';
PRINT '========================================';
PRINT '✅ LIMPIEZA COMPLETADA';
PRINT '   Total de SPs eliminados: 18';
PRINT '';
PRINT '   Módulos limpiados:';
PRINT '   - Rubro (5 SPs)';
PRINT '   - Factura (5 SPs)';
PRINT '   - Detalle_Factura (4 SPs)';
PRINT '   - Pago (4 SPs)';
PRINT '';
PRINT '🚀 Ahora ejecuta el script completo de creación';
PRINT '========================================';
GO

-- =============================================
-- MÓDULO: COBROS Y PAGOS
-- Script: Stored Procedures - Tabla Rubro
-- Descripción: CRUD completo para gestión de rubros
-- =============================================

USE MunicipalidadNicoya;
GO

-- =============================================
-- SP1: sp_insertar_rubro
-- Descripción: Inserta un nuevo rubro en el sistema
-- =============================================
IF OBJECT_ID('dbo.sp_insertar_rubro', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_insertar_rubro;
GO

CREATE PROCEDURE dbo.sp_insertar_rubro
    @nombre VARCHAR(100),
    @descripcion VARCHAR(300) = NULL,
    @periodicidad VARCHAR(20) = NULL,
    @aplica_recargo BIT = 0,
    @aplica_intereses BIT = 0,
    @tasa_interes DECIMAL(5,2) = 0,
    @tasa_recargo DECIMAL(5,2) = 0,
    @rubro_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validar nombre no vacío
        IF LTRIM(RTRIM(@nombre)) = '' OR @nombre IS NULL
        BEGIN
            THROW 50001, 'El nombre del rubro es obligatorio y no puede estar vacío.', 1;
        END
        
        -- Validar nombre no duplicado
        IF EXISTS (SELECT 1 FROM dbo.Rubro WHERE nombre = @nombre)
        BEGIN
            THROW 50002, 'Ya existe un rubro con ese nombre.', 1;
        END
        
        -- Validar periodicidad si tiene valor
        IF @periodicidad IS NOT NULL AND @periodicidad NOT IN ('Mensual', 'Trimestral', 'Anual', 'Único')
        BEGIN
            THROW 50003, 'La periodicidad debe ser: Mensual, Trimestral, Anual o Único.', 1;
        END
        
        -- Validar tasa de interés
        IF @tasa_interes < 0 OR @tasa_interes > 100
        BEGIN
            THROW 50004, 'La tasa de interés debe estar entre 0 y 100.', 1;
        END
        
        -- Validar tasa de recargo
        IF @tasa_recargo < 0 OR @tasa_recargo > 100
        BEGIN
            THROW 50005, 'La tasa de recargo debe estar entre 0 y 100.', 1;
        END
        
        -- Insertar el rubro
        INSERT INTO dbo.Rubro (
            nombre, 
            descripcion, 
            periodicidad, 
            vigencia,
            aplica_recargo, 
            aplica_intereses, 
            tasa_interes, 
            tasa_recargo
        )
        VALUES (
            @nombre,
            @descripcion,
            @periodicidad,
            1, -- Vigencia activa por defecto
            @aplica_recargo,
            @aplica_intereses,
            @tasa_interes,
            @tasa_recargo
        );
        
        -- Obtener el ID del rubro insertado
        SET @rubro_id = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        
        -- Mensaje de éxito
        PRINT 'Rubro creado exitosamente con ID: ' + CAST(@rubro_id AS VARCHAR(10));
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END
GO

PRINT '✓ SP: sp_insertar_rubro creado';
GO

-- =============================================
-- SP2: sp_consultar_rubro_por_id
-- Descripción: Consulta un rubro específico por su ID
-- =============================================
IF OBJECT_ID('dbo.sp_consultar_rubro_por_id', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_consultar_rubro_por_id;
GO

CREATE PROCEDURE dbo.sp_consultar_rubro_por_id
    @rubro_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que el rubro existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Rubro WHERE rubro_id = @rubro_id)
        BEGIN
            THROW 50006, 'No existe un rubro con el ID especificado.', 1;
        END
        
        -- Retornar el rubro
        SELECT 
            rubro_id,
            nombre,
            descripcion,
            periodicidad,
            vigencia,
            aplica_recargo,
            aplica_intereses,
            tasa_interes,
            tasa_recargo,
            fecha_creacion
        FROM dbo.Rubro
        WHERE rubro_id = @rubro_id;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ SP: sp_consultar_rubro_por_id creado';
GO

-- =============================================
-- SP3: sp_listar_rubros
-- Descripción: Lista rubros con filtros y paginación
-- =============================================
IF OBJECT_ID('dbo.sp_listar_rubros', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_listar_rubros;
GO

CREATE PROCEDURE dbo.sp_listar_rubros
    @vigencia BIT = NULL,
    @periodicidad VARCHAR(20) = NULL,
    @nombre_busqueda VARCHAR(100) = NULL,
    @page_number INT = 1,
    @page_size INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros de paginación
        IF @page_number < 1
            SET @page_number = 1;
            
        IF @page_size < 1
            SET @page_size = 10;
        
        -- Calcular offset
        DECLARE @offset INT = (@page_number - 1) * @page_size;
        
        -- Obtener total de registros (antes de paginar)
        DECLARE @total_registros INT;
        
        SELECT @total_registros = COUNT(*)
        FROM dbo.Rubro
        WHERE 
            (@vigencia IS NULL OR vigencia = @vigencia)
            AND (@periodicidad IS NULL OR periodicidad = @periodicidad)
            AND (@nombre_busqueda IS NULL OR nombre LIKE '%' + @nombre_busqueda + '%');
        
        -- Retornar registros paginados con total
        SELECT 
            rubro_id,
            nombre,
            descripcion,
            periodicidad,
            vigencia,
            aplica_recargo,
            aplica_intereses,
            tasa_interes,
            tasa_recargo,
            fecha_creacion,
            @total_registros AS total_registros,
            @page_number AS pagina_actual,
            @page_size AS registros_por_pagina,
            CEILING(CAST(@total_registros AS FLOAT) / @page_size) AS total_paginas
        FROM dbo.Rubro
        WHERE 
            (@vigencia IS NULL OR vigencia = @vigencia)
            AND (@periodicidad IS NULL OR periodicidad = @periodicidad)
            AND (@nombre_busqueda IS NULL OR nombre LIKE '%' + @nombre_busqueda + '%')
        ORDER BY nombre ASC
        OFFSET @offset ROWS
        FETCH NEXT @page_size ROWS ONLY;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ SP: sp_listar_rubros creado';
GO

-- =============================================
-- SP4: sp_actualizar_rubro
-- Descripción: Actualiza datos de un rubro (incluye reactivación)
-- =============================================
IF OBJECT_ID('dbo.sp_actualizar_rubro', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_actualizar_rubro;
GO

CREATE PROCEDURE dbo.sp_actualizar_rubro
    @rubro_id INT,
    @nombre VARCHAR(100) = NULL,
    @descripcion VARCHAR(300) = NULL,
    @periodicidad VARCHAR(20) = NULL,
    @vigencia BIT = NULL,
    @aplica_recargo BIT = NULL,
    @aplica_intereses BIT = NULL,
    @tasa_interes DECIMAL(5,2) = NULL,
    @tasa_recargo DECIMAL(5,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validar que el rubro existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Rubro WHERE rubro_id = @rubro_id)
        BEGIN
            THROW 50006, 'No existe un rubro con el ID especificado.', 1;
        END
        
        -- Validar nombre no duplicado (si se está actualizando)
        IF @nombre IS NOT NULL AND LTRIM(RTRIM(@nombre)) != ''
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.Rubro WHERE nombre = @nombre AND rubro_id != @rubro_id)
            BEGIN
                THROW 50002, 'Ya existe otro rubro con ese nombre.', 1;
            END
        END
        
        -- Validar periodicidad (si se está actualizando)
        IF @periodicidad IS NOT NULL AND @periodicidad NOT IN ('Mensual', 'Trimestral', 'Anual', 'Único')
        BEGIN
            THROW 50003, 'La periodicidad debe ser: Mensual, Trimestral, Anual o Único.', 1;
        END
        
        -- Validar tasa de interés (si se está actualizando)
        IF @tasa_interes IS NOT NULL AND (@tasa_interes < 0 OR @tasa_interes > 100)
        BEGIN
            THROW 50004, 'La tasa de interés debe estar entre 0 y 100.', 1;
        END
        
        -- Validar tasa de recargo (si se está actualizando)
        IF @tasa_recargo IS NOT NULL AND (@tasa_recargo < 0 OR @tasa_recargo > 100)
        BEGIN
            THROW 50005, 'La tasa de recargo debe estar entre 0 y 100.', 1;
        END
        
        -- Actualizar solo los campos que no sean NULL
        UPDATE dbo.Rubro
        SET
            nombre = ISNULL(@nombre, nombre),
            descripcion = CASE WHEN @descripcion IS NOT NULL THEN @descripcion ELSE descripcion END,
            periodicidad = CASE WHEN @periodicidad IS NOT NULL THEN @periodicidad ELSE periodicidad END,
            vigencia = ISNULL(@vigencia, vigencia),
            aplica_recargo = ISNULL(@aplica_recargo, aplica_recargo),
            aplica_intereses = ISNULL(@aplica_intereses, aplica_intereses),
            tasa_interes = ISNULL(@tasa_interes, tasa_interes),
            tasa_recargo = ISNULL(@tasa_recargo, tasa_recargo)
        WHERE rubro_id = @rubro_id;
        
        COMMIT TRANSACTION;
        
        -- Mensaje de éxito
        IF @vigencia = 1
            PRINT 'Rubro actualizado y reactivado exitosamente.';
        ELSE
            PRINT 'Rubro actualizado exitosamente.';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END
GO

PRINT '✓ SP: sp_actualizar_rubro creado';
GO

-- =============================================
-- SP5: sp_eliminar_rubro (Soft Delete)
-- Descripción: Eliminación lógica cambiando vigencia a 0
-- =============================================
IF OBJECT_ID('dbo.sp_eliminar_rubro', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_eliminar_rubro;
GO

CREATE PROCEDURE dbo.sp_eliminar_rubro
    @rubro_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validar que el rubro existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Rubro WHERE rubro_id = @rubro_id)
        BEGIN
            THROW 50006, 'No existe un rubro con el ID especificado.', 1;
        END
        
        -- Validar que no esté ya eliminado
        IF EXISTS (SELECT 1 FROM dbo.Rubro WHERE rubro_id = @rubro_id AND vigencia = 0)
        BEGIN
            THROW 50007, 'El rubro ya está desactivado.', 1;
        END
        
        -- Soft delete: cambiar vigencia a 0
        UPDATE dbo.Rubro
        SET vigencia = 0
        WHERE rubro_id = @rubro_id;
        
        COMMIT TRANSACTION;
        
        PRINT 'Rubro desactivado exitosamente. Las facturas asociadas mantienen su referencia histórica.';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END
GO

PRINT '✓ SP: sp_eliminar_rubro creado';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ STORED PROCEDURES - TABLA RUBRO';
PRINT '  Todos los SPs creados exitosamente:';
PRINT '  - sp_insertar_rubro';
PRINT '  - sp_consultar_rubro_por_id';
PRINT '  - sp_listar_rubros';
PRINT '  - sp_actualizar_rubro';
PRINT '  - sp_actualizar_rubro';
PRINT '  - sp_eliminar_rubro';
PRINT '========================================';
GO


















-- Script: Stored Procedures - Tabla Factura


-- =============================================
-- SP1: sp_emitir_factura
-- Descripción: Emite una nueva factura con autogeneración de número
-- =============================================
-- =============================================

-- Descripción: Emite una nueva factura con autogeneración de número
-- =============================================

IF OBJECT_ID('dbo.sp_emitir_factura', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_emitir_factura;
GO

CREATE PROCEDURE dbo.sp_emitir_factura
    @fecha_emision DATETIME = NULL,
    @periodo DATE = NULL,
    @tramite_id INT = NULL,
    @inmueble_id INT = NULL,
    @usuario_id INT,
    @factura_id INT OUTPUT,
    @numero_factura VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Si fecha_emision es NULL, usar GETDATE()
        IF @fecha_emision IS NULL
            SET @fecha_emision = GETDATE();
        
        -- 1. Validar referencia obligatoria: al menos tramite_id O inmueble_id
        IF @tramite_id IS NULL AND @inmueble_id IS NULL
        BEGIN
            THROW 50101, 'Debe especificar al menos un tramite_id o un inmueble_id para la factura.', 1;
        END
        
        -- 2. Validar que tramite_id existe (si tiene valor)
        IF @tramite_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Tramite WHERE tramite_id = @tramite_id)
        BEGIN
            THROW 50102, 'El tramite_id especificado no existe.', 1;
        END
        
        -- 3. Validar que inmueble_id existe (si tiene valor)
        IF @inmueble_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM dbo.Inmueble WHERE inmueble_id = @inmueble_id)
        BEGIN
            THROW 50103, 'El inmueble_id especificado no existe.', 1;
        END
        
        -- 4. Validar que usuario_id existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE usuario_id = @usuario_id)
        BEGIN
            THROW 50104, 'El usuario_id especificado no existe.', 1;
        END
        
        -- 5. Calcular fecha_vencimiento (30 días después de fecha_emision)
        DECLARE @fecha_vencimiento DATE;
        SET @fecha_vencimiento = DATEADD(DAY, 30, CAST(@fecha_emision AS DATE));
        
        -- 6. Autogenerar numero_factura con formato F-YYYYMMDD-####
        DECLARE @fecha_str VARCHAR(8) = FORMAT(@fecha_emision, 'yyyyMMdd');
        DECLARE @ultimo_numero INT;
        
        -- Buscar el último número de factura del día
        SELECT @ultimo_numero = ISNULL(MAX(CAST(RIGHT(numero_factura, 4) AS INT)), 0)
        FROM dbo.Factura
        WHERE numero_factura LIKE 'F-' + @fecha_str + '-%';
        
        -- Incrementar el número secuencial
        SET @numero_factura = 'F-' + @fecha_str + '-' + RIGHT('0000' + CAST(@ultimo_numero + 1 AS VARCHAR), 4);
        
        -- 7. Inicializar montos en 0
        -- NOTA: monto_base se calculará automáticamente al agregar detalles (trigger)
        DECLARE @monto_base DECIMAL(12,2) = 0;
        DECLARE @recargo DECIMAL(12,2) = 0;
        DECLARE @intereses DECIMAL(12,2) = 0;
        DECLARE @monto_total DECIMAL(12,2) = 0;
        
        -- 8. Insertar la factura
        INSERT INTO dbo.Factura (
            numero_factura,
            fecha_emision,
            fecha_vencimiento,
            periodo,
            monto_base,
            recargo,
            intereses,
            monto_total,
            estado_factura,
            tramite_id,
            inmueble_id
        )
        VALUES (
            @numero_factura,
            @fecha_emision,
            @fecha_vencimiento,
            @periodo,
            @monto_base,
            @recargo,
            @intereses,
            @monto_total,
            'Pendiente',
            @tramite_id,
            @inmueble_id
        );
        
        -- 9. Obtener el ID de la factura insertada
        SET @factura_id = SCOPE_IDENTITY();
        
        COMMIT TRANSACTION;
        
        -- Mensaje de éxito
        PRINT 'Factura emitida exitosamente: ' + @numero_factura + ' (ID: ' + CAST(@factura_id AS VARCHAR(10)) + ')';
        PRINT 'NOTA: Agregue detalles con sp_insertar_detalle_factura para calcular el monto automáticamente.';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END
GO

PRINT '✓ SP: sp_emitir_factura creado (CORREGIDO)';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ STORED PROCEDURE - sp_emitir_factura';
PRINT '  Factura con autogeneración de número';
PRINT '  Formato: F-YYYYMMDD-####';
PRINT '  NOTA: monto_base inicia en 0';
PRINT '        Se calcula automáticamente al agregar detalles';
PRINT '========================================';
GO







-- =============================================
-- SP2: sp_consultar_factura_por_id
-- Descripción: Consulta completa de factura con contribuyentes y detalles
-- =============================================
IF OBJECT_ID('dbo.sp_consultar_factura_por_id', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_consultar_factura_por_id;
GO

CREATE PROCEDURE dbo.sp_consultar_factura_por_id
    @factura_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar que la factura existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Factura WHERE factura_id = @factura_id)
        BEGIN
            THROW 50106, 'No existe una factura con el ID especificado.', 1;
        END
        
        -- ===========================================
        -- RESULTSET 1: Información completa de la factura
        -- ===========================================
        SELECT 
            f.factura_id,
            f.numero_factura,
            f.fecha_emision,
            f.fecha_vencimiento,
            f.periodo,
            f.monto_base,
            f.recargo,
            f.intereses,
            f.monto_total,
            f.estado_factura,
            f.tramite_id,
            f.inmueble_id,
            
            -- Información del Trámite (si tiene)
            t.tipo_tramite_id,
            tt.nombre_tipo AS tipo_tramite_nombre,
            t.estado_actual AS tramite_estado,
            t.fecha_ingreso AS tramite_fecha_ingreso,
            
            -- Información del Inmueble (si tiene)
            i.direccion_exacta AS inmueble_direccion,
            i.area_terreno AS inmueble_area,
            i.valor_fiscal AS inmueble_valor_fiscal,
            tui.nombre_uso AS inmueble_tipo_uso,
            
            -- Días de mora (calculado)
            CASE 
                WHEN f.estado_factura IN ('Vencida', 'Pendiente') AND f.fecha_vencimiento < CAST(GETDATE() AS DATE)
                THEN DATEDIFF(DAY, f.fecha_vencimiento, GETDATE())
                ELSE 0
            END AS dias_mora,
            
            -- Indicador de si está vencida
            CASE 
                WHEN f.fecha_vencimiento < CAST(GETDATE() AS DATE) AND f.estado_factura = 'Pendiente'
                THEN 1
                ELSE 0
            END AS esta_vencida
            
        FROM dbo.Factura f
        LEFT JOIN dbo.Tramite t ON f.tramite_id = t.tramite_id
        LEFT JOIN dbo.Tipo_Tramite tt ON t.tipo_tramite_id = tt.tipo_tramite_id
        LEFT JOIN dbo.Inmueble i ON f.inmueble_id = i.inmueble_id
        LEFT JOIN dbo.TipoUsoInmueble tui ON i.tipo_uso_inmueble_id = tui.tipo_uso_inmueble_id
        WHERE f.factura_id = @factura_id;
        
        
        -- ===========================================
        -- RESULTSET 2: Contribuyentes asociados
        -- ===========================================
        -- Obtener factura para saber si es trámite o inmueble
        DECLARE @tramite_id_factura INT;
        DECLARE @inmueble_id_factura INT;
        
        SELECT 
            @tramite_id_factura = tramite_id,
            @inmueble_id_factura = inmueble_id
        FROM dbo.Factura
        WHERE factura_id = @factura_id;
        
        -- Si es factura por trámite
        IF @tramite_id_factura IS NOT NULL
        BEGIN
            SELECT 
                c.contribuyente_id,
                c.tipo_contribuyente,
                c.telefono,
                c.email,
                c.direccion,
                
                -- Nombre completo (físico o jurídico)
                CASE 
                    WHEN c.tipo_contribuyente = 'Física' 
                    THEN cf.nombre + ' ' + cf.apellido1 + ' ' + cf.apellido2
                    ELSE cj.nombre_empresa
                END AS nombre_completo,
                
                -- Cédula
                CASE 
                    WHEN c.tipo_contribuyente = 'Física' 
                    THEN cf.cedula
                    ELSE cj.cedula_juridica
                END AS cedula,
                
                -- Porcentaje propiedad (NULL para trámites)
                CAST(NULL AS DECIMAL(5,2)) AS porcentaje_propiedad,
                
                'Tramite' AS origen
                
            FROM dbo.Tramite t
            INNER JOIN dbo.Contribuyente c ON t.contribuyente_id = c.contribuyente_id
            LEFT JOIN dbo.Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
            LEFT JOIN dbo.Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id
            WHERE t.tramite_id = @tramite_id_factura;
        END
        
        -- Si es factura por inmueble (puede tener múltiples contribuyentes)
        IF @inmueble_id_factura IS NOT NULL
        BEGIN
            SELECT 
                c.contribuyente_id,
                c.tipo_contribuyente,
                c.telefono,
                c.email,
                c.direccion,
                
                -- Nombre completo (físico o jurídico)
                CASE 
                    WHEN c.tipo_contribuyente = 'Física' 
                    THEN cf.nombre + ' ' + cf.apellido1 + ' ' + cf.apellido2
                    ELSE cj.nombre_empresa
                END AS nombre_completo,
                
                -- Cédula
                CASE 
                    WHEN c.tipo_contribuyente = 'Física' 
                    THEN cf.cedula
                    ELSE cj.cedula_juridica
                END AS cedula,
                
                -- Porcentaje propiedad
                ci.porcentaje_propiedad,
                
                'Inmueble' AS origen
                
            FROM dbo.Contribuyente_Inmueble ci
            INNER JOIN dbo.Contribuyente c ON ci.contribuyente_id = c.contribuyente_id
            LEFT JOIN dbo.Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
            LEFT JOIN dbo.Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id
            WHERE ci.inmueble_id = @inmueble_id_factura
            ORDER BY ci.porcentaje_propiedad DESC;
        END
        
        
        -- ===========================================
        -- RESULTSET 3: Detalles/ítems de la factura
        -- ===========================================
        SELECT 
            df.detalle_factura_id,
            df.nombre AS descripcion,
            df.referencia_servicio,
            df.cantidad,
            df.monto_unitario,
            df.descuento_linea,
            df.fecha_servicio,
            
            -- Información del Rubro
            r.rubro_id,
            r.nombre AS rubro_nombre,
            r.periodicidad AS rubro_periodicidad,
            
            -- Subtotal del detalle (cantidad * monto_unitario - descuento)
            (df.cantidad * df.monto_unitario - df.descuento_linea) AS subtotal_detalle
            
        FROM dbo.Detalle_factura df
        INNER JOIN dbo.Rubro r ON df.rubro_id = r.rubro_id
        WHERE df.factura_id = @factura_id
        ORDER BY df.detalle_factura_id;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ SP: sp_consultar_factura_por_id creado';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ STORED PROCEDURE - sp_consultar_factura_por_id';
PRINT '  Retorna 3 resultsets:';
PRINT '  1. Factura completa con información relacionada';
PRINT '  2. Contribuyentes asociados (trámite o inmueble)';
PRINT '  3. Detalles/ítems de la factura';
PRINT '========================================';
GO





-- =============================================
-- SOLUCIÓN DEFINITIVA: sp_listar_facturas
-- =============================================

USE MunicipalidadNicoya;
GO

DROP PROCEDURE IF EXISTS dbo.sp_listar_facturas;
GO

CREATE PROCEDURE dbo.sp_listar_facturas
    @estado_factura VARCHAR(20) = NULL,
    @contribuyente_id INT = NULL,
    @inmueble_id INT = NULL,
    @tramite_id INT = NULL,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL,
    @numero_factura_busqueda VARCHAR(50) = NULL,
    @page_number INT = 1,
    @page_size INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros de paginación
        IF @page_number < 1
            SET @page_number = 1;
            
        IF @page_size < 1
            SET @page_size = 10;
        
        -- Calcular offset
        DECLARE @offset INT = (@page_number - 1) * @page_size;
        
        -- ✅ SOLUCIÓN: Usar COUNT(*) OVER() dentro del CTE
        ;WITH FacturasConInfo AS (
            SELECT 
                f.factura_id,
                f.numero_factura,
                f.fecha_emision,
                f.fecha_vencimiento,
                f.monto_total,
                f.estado_factura,
                f.tramite_id,
                f.inmueble_id,
                
                -- Días de mora calculado
                CASE 
                    WHEN f.estado_factura IN ('Vencida', 'Pendiente') 
                         AND f.fecha_vencimiento < CAST(GETDATE() AS DATE)
                    THEN DATEDIFF(DAY, f.fecha_vencimiento, GETDATE())
                    ELSE 0
                END AS dias_mora,
                
                -- Tipo de origen (Tramite o Inmueble)
                CASE 
                    WHEN f.tramite_id IS NOT NULL THEN 'Tramite'
                    WHEN f.inmueble_id IS NOT NULL THEN 'Inmueble'
                    ELSE 'Sin especificar'
                END AS tipo_origen,
                
                -- Descripción del origen
                CASE 
                    WHEN f.tramite_id IS NOT NULL THEN tt.nombre_tipo
                    WHEN f.inmueble_id IS NOT NULL THEN i.direccion_exacta
                    ELSE NULL
                END AS descripcion_origen,
                
                -- Obtener contribuyente_id según origen
                CASE 
                    WHEN f.tramite_id IS NOT NULL THEN t.contribuyente_id
                    WHEN f.inmueble_id IS NOT NULL THEN ci.contribuyente_id
                    ELSE NULL
                END AS contribuyente_id,
                
                -- ✅ Contar total de registros con ventana
                COUNT(*) OVER() AS total_registros
                
            FROM dbo.Factura f
            LEFT JOIN dbo.Tramite t ON f.tramite_id = t.tramite_id
            LEFT JOIN dbo.Tipo_Tramite tt ON t.tipo_tramite_id = tt.tipo_tramite_id
            LEFT JOIN dbo.Inmueble i ON f.inmueble_id = i.inmueble_id
            LEFT JOIN dbo.Contribuyente_Inmueble ci ON i.inmueble_id = ci.inmueble_id
            
            WHERE 
                -- Filtro por estado
                (@estado_factura IS NULL OR f.estado_factura = @estado_factura)
                -- Filtro por inmueble
                AND (@inmueble_id IS NULL OR f.inmueble_id = @inmueble_id)
                -- Filtro por trámite
                AND (@tramite_id IS NULL OR f.tramite_id = @tramite_id)
                -- Filtro por rango de fechas
                AND (@fecha_desde IS NULL OR CAST(f.fecha_emision AS DATE) >= @fecha_desde)
                AND (@fecha_hasta IS NULL OR CAST(f.fecha_emision AS DATE) <= @fecha_hasta)
                -- Filtro por número de factura (búsqueda parcial)
                AND (@numero_factura_busqueda IS NULL OR f.numero_factura LIKE '%' + @numero_factura_busqueda + '%')
                -- Filtro por contribuyente (busca en trámites o inmuebles)
                AND (
                    @contribuyente_id IS NULL 
                    OR t.contribuyente_id = @contribuyente_id 
                    OR ci.contribuyente_id = @contribuyente_id
                )
        )
        
        -- ✅ Ahora usar el CTE directamente sin SELECT intermedio
        SELECT 
            fci.factura_id,
            fci.numero_factura,
            fci.fecha_emision,
            fci.fecha_vencimiento,
            fci.monto_total,
            fci.estado_factura,
            fci.dias_mora,
            fci.tipo_origen,
            fci.descripcion_origen,
            
            -- Información del contribuyente
            fci.contribuyente_id,
            c.tipo_contribuyente,
            
            -- Nombre completo del contribuyente
            CASE 
                WHEN c.tipo_contribuyente = 'Física' 
                THEN cf.nombre + ' ' + cf.apellido1 + ' ' + ISNULL(cf.apellido2, '')
                ELSE cj.nombre_empresa
            END AS contribuyente_nombre,
            
            -- Cédula del contribuyente
            CASE 
                WHEN c.tipo_contribuyente = 'Física' 
                THEN cf.cedula
                ELSE cj.cedula_juridica
            END AS contribuyente_cedula,
            
            -- Información de paginación (ya viene del CTE)
            fci.total_registros,
            @page_number AS pagina_actual,
            @page_size AS registros_por_pagina,
            CEILING(CAST(fci.total_registros AS FLOAT) / @page_size) AS total_paginas
            
        FROM FacturasConInfo fci
        LEFT JOIN dbo.Contribuyente c ON fci.contribuyente_id = c.contribuyente_id
        LEFT JOIN dbo.Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
        LEFT JOIN dbo.Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id
        
        ORDER BY fci.fecha_emision DESC
        OFFSET @offset ROWS
        FETCH NEXT @page_size ROWS ONLY;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '';
PRINT '✅✅✅ sp_listar_facturas - VERSIÓN FINAL CORREGIDA ✅✅✅';
PRINT '  Cambios:';
PRINT '  1. Eliminado SELECT intermedio que rompía el scope del CTE';
PRINT '  2. Usado COUNT(*) OVER() dentro del CTE';
PRINT '  3. total_registros ahora viene directamente del CTE';
GO









-- =============================================
-- SP4: sp_actualizar_factura
-- Descripción: Actualiza datos de una factura con validaciones
-- =============================================
-- =============================================

-- Descripción: Actualiza datos de una factura con validaciones
-- =============================================

IF OBJECT_ID('dbo.sp_actualizar_factura', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_actualizar_factura;
GO

CREATE PROCEDURE dbo.sp_actualizar_factura
    @factura_id INT,
    @fecha_emision DATETIME = NULL,
    @fecha_vencimiento DATE = NULL,
    @periodo DATE = NULL,
    -- ❌ REMOVIDO: @monto_base DECIMAL(12,2) = NULL,
    @recargo DECIMAL(12,2) = NULL,
    @intereses DECIMAL(12,2) = NULL,
    @estado_factura VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1. Validar que la factura existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Factura WHERE factura_id = @factura_id)
        BEGIN
            THROW 50106, 'No existe una factura con el ID especificado.', 1;
        END
        
        -- Obtener estado actual de la factura
        DECLARE @estado_actual VARCHAR(20);
        SELECT @estado_actual = estado_factura
        FROM dbo.Factura
        WHERE factura_id = @factura_id;
        
        -- 2. Validar que solo se pueden actualizar facturas Pendiente o Vencida
        IF @estado_actual NOT IN ('Pendiente', 'Vencida')
        BEGIN
            THROW 50107, 'Solo se pueden actualizar facturas en estado Pendiente o Vencida.', 1;
        END
        
        -- 3. Validar cambios de estado permitidos
        IF @estado_factura IS NOT NULL
        BEGIN
            -- Solo permitir: Pendiente → Vencida o Cancelada
            IF @estado_actual = 'Pendiente' AND @estado_factura NOT IN ('Pendiente', 'Vencida', 'Cancelada')
            BEGIN
                THROW 50108, 'Solo se puede cambiar el estado de Pendiente a Vencida o Cancelada.', 1;
            END
            
            -- Vencida solo puede cambiar a Cancelada o mantenerse Vencida
            IF @estado_actual = 'Vencida' AND @estado_factura NOT IN ('Vencida', 'Cancelada')
            BEGIN
                THROW 50109, 'Una factura Vencida solo puede cambiar a Cancelada.', 1;
            END
            
            -- Validar que el nuevo estado sea válido
            IF @estado_factura NOT IN ('Pendiente', 'Pagada', 'Vencida', 'Cancelada')
            BEGIN
                THROW 50110, 'El estado de factura debe ser: Pendiente, Pagada, Vencida o Cancelada.', 1;
            END
        END
        
        -- 4. Validar que no tenga pagos registrados si se actualizan recargo/intereses
        IF (@recargo IS NOT NULL OR @intereses IS NOT NULL)
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.Pago WHERE factura_id = @factura_id)
            BEGIN
                THROW 50111, 'No se pueden actualizar los montos de una factura que ya tiene pagos registrados.', 1;
            END
        END
        
        -- 5. Validar montos no negativos
        IF @recargo IS NOT NULL AND @recargo < 0
        BEGIN
            THROW 50113, 'El recargo no puede ser negativo.', 1;
        END
        
        IF @intereses IS NOT NULL AND @intereses < 0
        BEGIN
            THROW 50114, 'Los intereses no pueden ser negativos.', 1;
        END
        
        -- 6. Validar fecha_vencimiento >= fecha_emision
        IF @fecha_emision IS NOT NULL AND @fecha_vencimiento IS NOT NULL
        BEGIN
            IF @fecha_vencimiento < CAST(@fecha_emision AS DATE)
            BEGIN
                THROW 50115, 'La fecha_vencimiento no puede ser anterior a la fecha_emision.', 1;
            END
        END
        
        -- Si solo se actualiza fecha_emision, validar con fecha_vencimiento actual
        IF @fecha_emision IS NOT NULL AND @fecha_vencimiento IS NULL
        BEGIN
            DECLARE @fecha_vencimiento_actual DATE;
            SELECT @fecha_vencimiento_actual = fecha_vencimiento
            FROM dbo.Factura
            WHERE factura_id = @factura_id;
            
            IF @fecha_vencimiento_actual < CAST(@fecha_emision AS DATE)
            BEGIN
                THROW 50116, 'La nueva fecha_emision no puede ser posterior a la fecha_vencimiento actual.', 1;
            END
        END
        
        -- 7. Obtener valores actuales para recalcular monto_total
        DECLARE @monto_base_actual DECIMAL(12,2);
        DECLARE @recargo_actual DECIMAL(12,2);
        DECLARE @intereses_actual DECIMAL(12,2);
        
        SELECT 
            @monto_base_actual = monto_base,
            @recargo_actual = recargo,
            @intereses_actual = intereses
        FROM dbo.Factura
        WHERE factura_id = @factura_id;
        
        -- Usar valores actuales si no se especificaron nuevos
        -- NOTA: monto_base NO se actualiza aquí, solo desde trigger de detalles
        SET @recargo = ISNULL(@recargo, @recargo_actual);
        SET @intereses = ISNULL(@intereses, @intereses_actual);
        
        -- Calcular nuevo monto_total (usa monto_base ACTUAL + nuevos recargo/intereses)
        DECLARE @monto_total_nuevo DECIMAL(12,2) = @monto_base_actual + @recargo + @intereses;
        
        -- 8. Actualizar solo los campos que no sean NULL (actualización selectiva)
        UPDATE dbo.Factura
        SET
            fecha_emision = ISNULL(@fecha_emision, fecha_emision),
            fecha_vencimiento = ISNULL(@fecha_vencimiento, fecha_vencimiento),
            periodo = CASE WHEN @periodo IS NOT NULL THEN @periodo ELSE periodo END,
            -- monto_base NO se actualiza aquí (solo desde trigger)
            recargo = @recargo,
            intereses = @intereses,
            monto_total = @monto_total_nuevo,
            estado_factura = ISNULL(@estado_factura, estado_factura)
        WHERE factura_id = @factura_id;
        
        COMMIT TRANSACTION;
        
        PRINT 'Factura actualizada exitosamente.';
        PRINT 'NOTA: El monto_base se calcula automáticamente desde los detalles de la factura.';
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END
GO

PRINT '✓ SP: sp_actualizar_factura creado (CORREGIDO)';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ STORED PROCEDURE - sp_actualizar_factura';
PRINT '  Restricciones implementadas:';
PRINT '  - Solo estados Pendiente/Vencida';
PRINT '  - Cambios de estado controlados';
PRINT '  - NO permite cambiar tramite_id/inmueble_id';
PRINT '  - NO permite cambiar monto_base (se calcula desde detalles)';
PRINT '  - Valida que NO tenga pagos antes de actualizar recargo/intereses';
PRINT '  - Recalcula monto_total automáticamente';
PRINT '  - Actualización selectiva de campos';
PRINT '========================================';
GO









-- =============================================
-- SP5: sp_cancelar_factura
-- Descripción: Cancela una factura con validaciones y registro en auditoría
-- =============================================
IF OBJECT_ID('dbo.sp_cancelar_factura', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_cancelar_factura;
GO

CREATE PROCEDURE dbo.sp_cancelar_factura
    @factura_id INT,
    @motivo_cancelacion VARCHAR(255),
    @usuario_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- 1. Validar que la factura existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Factura WHERE factura_id = @factura_id)
        BEGIN
            THROW 50106, 'No existe una factura con el ID especificado.', 1;
        END
        
        -- Obtener estado actual de la factura
        DECLARE @estado_actual VARCHAR(20);
        SELECT @estado_actual = estado_factura
        FROM dbo.Factura
        WHERE factura_id = @factura_id;
        
        -- 2. Validar que la factura NO esté ya cancelada
        IF @estado_actual = 'Cancelada'
        BEGIN
            THROW 50117, 'La factura ya está cancelada.', 1;
        END
        
        -- 3. Validar que la factura NO esté pagada
        IF @estado_actual = 'Pagada'
        BEGIN
            THROW 50118, 'No se puede cancelar una factura que ya está pagada.', 1;
        END
        
        -- 4. Validar que solo se pueden cancelar facturas Pendiente o Vencida
        IF @estado_actual NOT IN ('Pendiente', 'Vencida')
        BEGIN
            THROW 50119, 'Solo se pueden cancelar facturas en estado Pendiente o Vencida.', 1;
        END
        
        -- 5. Validar que NO tenga pagos registrados
        IF EXISTS (SELECT 1 FROM dbo.Pago WHERE factura_id = @factura_id)
        BEGIN
            THROW 50120, 'No se puede cancelar una factura que tiene pagos registrados.', 1;
        END
        
        -- 6. Validar motivo de cancelación no vacío
        IF LTRIM(RTRIM(@motivo_cancelacion)) = '' OR @motivo_cancelacion IS NULL
        BEGIN
            THROW 50121, 'Debe especificar un motivo de cancelación.', 1;
        END
        
        -- 7. Validar que el usuario existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE usuario_id = @usuario_id)
        BEGIN
            THROW 50122, 'El usuario_id especificado no existe.', 1;
        END
        
        -- 8. Obtener información de la factura para auditoría
        DECLARE @numero_factura VARCHAR(50);
        DECLARE @monto_total DECIMAL(12,2);
        
        SELECT 
            @numero_factura = numero_factura,
            @monto_total = monto_total
        FROM dbo.Factura
        WHERE factura_id = @factura_id;
        
        -- 9. Cambiar estado a Cancelada
        UPDATE dbo.Factura
        SET estado_factura = 'Cancelada'
        WHERE factura_id = @factura_id;
        
        -- 10. Registrar en auditoría
        DECLARE @valores_nuevos NVARCHAR(MAX) = JSON_OBJECT(
            'estado_anterior': @estado_actual,
            'estado_nuevo': 'Cancelada',
            'motivo_cancelacion': @motivo_cancelacion,
            'numero_factura': @numero_factura,
            'monto_total': @monto_total,
            'fecha_cancelacion': FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss')
        );
        
        INSERT INTO dbo.Auditoria (
            tabla_afectada,
            operacion,
            registro_id,
            usuario_id,
            fecha_hora,
            valores_anteriores,
            valores_nuevos
        )
        VALUES (
            'Factura',
            'UPDATE',
            @factura_id,
            @usuario_id,
            GETDATE(),
            JSON_OBJECT('estado_factura': @estado_actual),
            @valores_nuevos
        );
        
        COMMIT TRANSACTION;
        
        PRINT 'Factura ' + @numero_factura + ' cancelada exitosamente.';
        PRINT 'Motivo: ' + @motivo_cancelacion;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        THROW;
    END CATCH
END
GO

PRINT '✓ SP: sp_cancelar_factura creado';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ STORED PROCEDURE - sp_cancelar_factura';
PRINT '  Validaciones implementadas:';
PRINT '  - NO cancela si ya está cancelada';
PRINT '  - NO cancela si está pagada';
PRINT '  - NO cancela si tiene pagos registrados';
PRINT '  - Solo cancela estados Pendiente/Vencida';
PRINT '  - Requiere motivo obligatorio';
PRINT '  - Registra en auditoría con motivo';
PRINT '  - Mantiene detalles de factura (historial)';
PRINT '========================================';
GO

PRINT '';
PRINT '========================================';
PRINT '✓✓✓ MÓDULO FACTURA COMPLETADO ✓✓✓';
PRINT '  Todos los SPs creados:';
PRINT '  1. sp_emitir_factura';
PRINT '  2. sp_consultar_factura_por_id';
PRINT '  3. sp_listar_facturas';
PRINT '  4. sp_actualizar_factura';
PRINT '  5. sp_cancelar_factura';
PRINT '========================================';
GO












-- =============================================
-- SP: sp_insertar_detalle_factura
-- Descripción: Agrega un detalle (línea) a una factura existente
-- =============================================

USE MunicipalidadNicoya;
GO

IF OBJECT_ID('dbo.sp_insertar_detalle_factura', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_insertar_detalle_factura;
GO

CREATE PROCEDURE dbo.sp_insertar_detalle_factura
    @factura_id INT,
    @rubro_id INT,
    @nombre VARCHAR(100) = NULL,
    @referencia_servicio VARCHAR(100) = NULL,
    @cantidad INT = 1,
    @monto_unitario DECIMAL(12,2),
    @descuento_linea DECIMAL(12,2) = 0,
    @fecha_servicio DATE = NULL,
    @detalle_factura_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- =============================================
        -- VALIDACIONES
        -- =============================================
        
        -- 1. Validar que la factura existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Factura WHERE factura_id = @factura_id)
        BEGIN
            THROW 50151, 'La factura especificada no existe', 1;
        END
        
        -- 2. Validar que la factura esté en estado editable (Pendiente o Vencida)
        DECLARE @estado_factura VARCHAR(20);
        SELECT @estado_factura = estado_factura 
        FROM dbo.Factura 
        WHERE factura_id = @factura_id;
        
        IF @estado_factura NOT IN ('Pendiente', 'Vencida')
        BEGIN
            THROW 50152, 'Solo se pueden agregar detalles a facturas en estado Pendiente o Vencida', 1;
        END
        
        -- 3. Validar que la factura NO tenga pagos registrados
        IF EXISTS (SELECT 1 FROM dbo.Pago WHERE factura_id = @factura_id)
        BEGIN
            THROW 50153, 'No se pueden agregar detalles a una factura que ya tiene pagos registrados', 1;
        END
        
        -- 4. Validar que el rubro existe y está activo (vigencia = 1)
        IF NOT EXISTS (SELECT 1 FROM dbo.Rubro WHERE rubro_id = @rubro_id AND vigencia = 1)
        BEGIN
            THROW 50154, 'El rubro especificado no existe o no está activo', 1;
        END
        
        -- 5. Autocompletar nombre desde Rubro si viene NULL o vacío
        IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        BEGIN
            SELECT @nombre = nombre 
            FROM dbo.Rubro 
            WHERE rubro_id = @rubro_id AND vigencia = 1;
        END
        
        -- 6. Validar cantidad > 0 (ya está en CHECK de tabla, pero validamos antes)
        IF @cantidad <= 0
        BEGIN
            THROW 50155, 'La cantidad debe ser mayor a cero', 1;
        END
        
        -- 7. Validar monto_unitario >= 0
        IF @monto_unitario < 0
        BEGIN
            THROW 50156, 'El monto unitario no puede ser negativo', 1;
        END
        
        -- 8. Validar descuento_linea >= 0
        IF @descuento_linea < 0
        BEGIN
            THROW 50157, 'El descuento no puede ser negativo', 1;
        END
        
        -- 9. Validar que descuento_linea no supere el subtotal de la línea
        DECLARE @subtotal_linea DECIMAL(12,2);
        SET @subtotal_linea = @cantidad * @monto_unitario;
        
        IF @descuento_linea > @subtotal_linea
        BEGIN
            THROW 50158, 'El descuento no puede ser mayor al subtotal de la línea', 1;
        END
        
        -- =============================================
        -- INSERCIÓN DEL DETALLE
        -- =============================================
        
        INSERT INTO dbo.Detalle_factura (
            nombre,
            referencia_servicio,
            cantidad,
            monto_unitario,
            descuento_linea,
            fecha_servicio,
            factura_id,
            rubro_id
        )
        VALUES (
            @nombre,
            @referencia_servicio,
            @cantidad,
            @monto_unitario,
            @descuento_linea,
            @fecha_servicio,
            @factura_id,
            @rubro_id
        );
        
        -- Obtener el ID del detalle insertado
        SET @detalle_factura_id = SCOPE_IDENTITY();
        
        -- =============================================
        -- NOTA: El trigger trg_actualizar_monto_factura
        -- se encargará de recalcular automáticamente
        -- el monto_base de la factura
        -- =============================================
        
        COMMIT TRANSACTION;
        
        -- Retornar el detalle insertado
        SELECT 
            detalle_factura_id,
            nombre,
            referencia_servicio,
            cantidad,
            monto_unitario,
            descuento_linea,
            (cantidad * monto_unitario - descuento_linea) AS subtotal_linea,
            fecha_servicio,
            factura_id,
            rubro_id
        FROM dbo.Detalle_factura
        WHERE detalle_factura_id = @detalle_factura_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        THROW;
    END CATCH
END
GO

PRINT '✓ SP sp_insertar_detalle_factura creado exitosamente';
GO









-- =============================================
-- SP: sp_actualizar_detalle_factura
-- Descripción: Actualiza un detalle existente de una factura
-- Nota: factura_id y rubro_id son inmutables
-- =============================================

USE MunicipalidadNicoya;
GO

IF OBJECT_ID('dbo.sp_actualizar_detalle_factura', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_actualizar_detalle_factura;
GO

CREATE PROCEDURE dbo.sp_actualizar_detalle_factura
    @detalle_factura_id INT,
    @nombre VARCHAR(100) = NULL,
    @referencia_servicio VARCHAR(100) = NULL,
    @cantidad INT = NULL,
    @monto_unitario DECIMAL(12,2) = NULL,
    @descuento_linea DECIMAL(12,2) = NULL,
    @fecha_servicio DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- =============================================
        -- VALIDACIONES
        -- =============================================
        
        -- 1. Validar que el detalle existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Detalle_factura WHERE detalle_factura_id = @detalle_factura_id)
        BEGIN
            THROW 50159, 'El detalle de factura especificado no existe', 1;
        END
        
        -- 2. Obtener datos actuales del detalle y su factura asociada
        DECLARE @factura_id INT;
        DECLARE @estado_factura VARCHAR(20);
        DECLARE @cantidad_actual INT;
        DECLARE @monto_unitario_actual DECIMAL(12,2);
        DECLARE @descuento_actual DECIMAL(12,2);
        
        SELECT 
            @factura_id = df.factura_id,
            @cantidad_actual = df.cantidad,
            @monto_unitario_actual = df.monto_unitario,
            @descuento_actual = df.descuento_linea
        FROM dbo.Detalle_factura df
        WHERE df.detalle_factura_id = @detalle_factura_id;
        
        -- 3. Validar que la factura esté en estado editable (Pendiente o Vencida)
        SELECT @estado_factura = estado_factura
        FROM dbo.Factura
        WHERE factura_id = @factura_id;
        
        IF @estado_factura NOT IN ('Pendiente', 'Vencida')
        BEGIN
            THROW 50160, 'Solo se pueden actualizar detalles de facturas en estado Pendiente o Vencida', 1;
        END
        
        -- 4. Validar que la factura NO tenga pagos registrados
        IF EXISTS (SELECT 1 FROM dbo.Pago WHERE factura_id = @factura_id)
        BEGIN
            THROW 50161, 'No se pueden actualizar detalles de una factura que ya tiene pagos registrados', 1;
        END
        
        -- 5. Validar cantidad > 0 (si se está actualizando)
        IF @cantidad IS NOT NULL AND @cantidad <= 0
        BEGIN
            THROW 50162, 'La cantidad debe ser mayor a cero', 1;
        END
        
        -- 6. Validar monto_unitario >= 0 (si se está actualizando)
        IF @monto_unitario IS NOT NULL AND @monto_unitario < 0
        BEGIN
            THROW 50163, 'El monto unitario no puede ser negativo', 1;
        END
        
        -- 7. Validar descuento_linea >= 0 (si se está actualizando)
        IF @descuento_linea IS NOT NULL AND @descuento_linea < 0
        BEGIN
            THROW 50164, 'El descuento no puede ser negativo', 1;
        END
        
        -- 8. Validar que el descuento no supere el subtotal (combinando valores actuales y nuevos)
        DECLARE @cantidad_final INT;
        DECLARE @monto_unitario_final DECIMAL(12,2);
        DECLARE @descuento_final DECIMAL(12,2);
        DECLARE @subtotal_final DECIMAL(12,2);
        
        -- Combinar valores actuales con nuevos (si vienen)
        SET @cantidad_final = COALESCE(@cantidad, @cantidad_actual);
        SET @monto_unitario_final = COALESCE(@monto_unitario, @monto_unitario_actual);
        SET @descuento_final = COALESCE(@descuento_linea, @descuento_actual);
        
        -- Calcular subtotal con los valores finales
        SET @subtotal_final = @cantidad_final * @monto_unitario_final;
        
        -- Validar que el descuento no supere el subtotal
        IF @descuento_final > @subtotal_final
        BEGIN
            DECLARE @mensaje_error VARCHAR(200);
            SET @mensaje_error = 'El descuento (' + CAST(@descuento_final AS VARCHAR) + 
                                ') no puede ser mayor al subtotal (' + CAST(@subtotal_final AS VARCHAR) + ')';
            THROW 50165, @mensaje_error, 1;
        END
        
        -- =============================================
        -- ACTUALIZACIÓN DEL DETALLE
        -- =============================================
        
        UPDATE dbo.Detalle_factura
        SET
            nombre = COALESCE(@nombre, nombre),
            referencia_servicio = COALESCE(@referencia_servicio, referencia_servicio),
            cantidad = COALESCE(@cantidad, cantidad),
            monto_unitario = COALESCE(@monto_unitario, monto_unitario),
            descuento_linea = COALESCE(@descuento_linea, descuento_linea),
            fecha_servicio = COALESCE(@fecha_servicio, fecha_servicio)
        WHERE detalle_factura_id = @detalle_factura_id;
        
        -- =============================================
        -- NOTA: El trigger trg_actualizar_monto_factura
        -- recalculará automáticamente el monto_base
        -- de la factura asociada
        -- =============================================
        
        COMMIT TRANSACTION;
        
        -- Retornar el detalle actualizado
        SELECT 
            detalle_factura_id,
            nombre,
            referencia_servicio,
            cantidad,
            monto_unitario,
            descuento_linea,
            (cantidad * monto_unitario - descuento_linea) AS subtotal_linea,
            fecha_servicio,
            factura_id,
            rubro_id
        FROM dbo.Detalle_factura
        WHERE detalle_factura_id = @detalle_factura_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        THROW;
    END CATCH
END
GO

PRINT '✓ SP sp_actualizar_detalle_factura creado exitosamente';
GO










-- =============================================
-- SP: sp_eliminar_detalle_factura
-- Descripción: Elimina un detalle de una factura (eliminación física)
-- Nota: NO permite eliminar el último detalle (factura debe tener al menos 1)
-- =============================================

USE MunicipalidadNicoya;
GO

IF OBJECT_ID('dbo.sp_eliminar_detalle_factura', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_eliminar_detalle_factura;
GO

CREATE PROCEDURE dbo.sp_eliminar_detalle_factura
    @detalle_factura_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- =============================================
        -- VALIDACIONES
        -- =============================================
        
        -- 1. Validar que el detalle existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Detalle_factura WHERE detalle_factura_id = @detalle_factura_id)
        BEGIN
            THROW 50166, 'El detalle de factura especificado no existe', 1;
        END
        
        -- 2. Obtener la factura asociada
        DECLARE @factura_id INT;
        DECLARE @estado_factura VARCHAR(20);
        
        SELECT @factura_id = factura_id
        FROM dbo.Detalle_factura
        WHERE detalle_factura_id = @detalle_factura_id;
        
        -- 3. Validar que la factura esté en estado editable (Pendiente o Vencida)
        SELECT @estado_factura = estado_factura
        FROM dbo.Factura
        WHERE factura_id = @factura_id;
        
        IF @estado_factura NOT IN ('Pendiente', 'Vencida')
        BEGIN
            THROW 50167, 'Solo se pueden eliminar detalles de facturas en estado Pendiente o Vencida', 1;
        END
        
        -- 4. Validar que la factura NO tenga pagos registrados
        IF EXISTS (SELECT 1 FROM dbo.Pago WHERE factura_id = @factura_id)
        BEGIN
            THROW 50168, 'No se pueden eliminar detalles de una factura que ya tiene pagos registrados', 1;
        END
        
        -- 5. Validar que NO sea el último detalle de la factura
        DECLARE @cantidad_detalles INT;
        
        SELECT @cantidad_detalles = COUNT(*)
        FROM dbo.Detalle_factura
        WHERE factura_id = @factura_id;
        
        IF @cantidad_detalles = 1
        BEGIN
            THROW 50169, 'No puede eliminar el único detalle de la factura. Use sp_cancelar_factura si desea anular la factura completa', 1;
        END
        
        -- =============================================
        -- ELIMINACIÓN FÍSICA DEL DETALLE
        -- =============================================
        
        DELETE FROM dbo.Detalle_factura
        WHERE detalle_factura_id = @detalle_factura_id;
        
        -- =============================================
        -- NOTA: El trigger trg_actualizar_monto_factura
        -- recalculará automáticamente el monto_base
        -- de la factura asociada (AFTER DELETE)
        -- =============================================
        
        -- =============================================
        -- NOTA: El trigger trg_audit_detalle_factura
        -- registrará la eliminación en la tabla Auditoria
        -- =============================================
        
        COMMIT TRANSACTION;
        
        -- Retornar datos de la factura actualizada
        SELECT 
            f.factura_id,
            f.numero_factura,
            f.fecha_emision,
            f.fecha_vencimiento,
            f.monto_base,  -- Ya recalculado por el trigger
            f.recargo,
            f.intereses,
            f.monto_total,
            f.estado_factura,
            (SELECT COUNT(*) FROM dbo.Detalle_factura WHERE factura_id = f.factura_id) AS detalles_restantes
        FROM dbo.Factura f
        WHERE f.factura_id = @factura_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        THROW;
    END CATCH
END
GO

PRINT '✓ SP sp_eliminar_detalle_factura creado exitosamente';
GO












-- =============================================
-- SP: sp_listar_detalles_por_factura
-- Descripción: Lista todos los detalles (líneas) de una factura específica
-- =============================================

USE MunicipalidadNicoya;
GO

IF OBJECT_ID('dbo.sp_listar_detalles_por_factura', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_listar_detalles_por_factura;
GO

CREATE PROCEDURE dbo.sp_listar_detalles_por_factura
    @factura_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- =============================================
        -- VALIDACIONES
        -- =============================================
        
        -- Validar que la factura existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Factura WHERE factura_id = @factura_id)
        BEGIN
            THROW 50170, 'La factura especificada no existe', 1;
        END
        
        -- =============================================
        -- CONSULTA DE DETALLES
        -- =============================================
        
        SELECT 
            df.detalle_factura_id,
            df.nombre,
            df.referencia_servicio,
            df.cantidad,
            df.monto_unitario,
            df.descuento_linea,
            (df.cantidad * df.monto_unitario - df.descuento_linea) AS subtotal_linea,
            df.fecha_servicio,
            df.factura_id,
            r.rubro_id,
            r.nombre AS rubro_nombre,
            r.descripcion AS rubro_descripcion,
            r.periodicidad AS rubro_periodicidad,
            r.vigencia AS rubro_vigente
        FROM dbo.Detalle_factura df
        INNER JOIN dbo.Rubro r ON df.rubro_id = r.rubro_id
        WHERE df.factura_id = @factura_id
        ORDER BY df.detalle_factura_id ASC;
        
        -- Si no hay detalles, retorna conjunto vacío (0 filas)
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ SP sp_listar_detalles_por_factura creado exitosamente';
GO













-- =============================================
-- SP: sp_registrar_pago
-- Descripción: Registra un pago total para una factura
-- Nota: Solo permite pagos totales (monto_pagado = monto_total)
-- =============================================

USE MunicipalidadNicoya;
GO

IF OBJECT_ID('dbo.sp_registrar_pago', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_registrar_pago;
GO

CREATE PROCEDURE dbo.sp_registrar_pago
    @factura_id INT,
    @monto_pagado DECIMAL(12,2),
    @fecha_pago DATE = NULL,
    @medio_pago VARCHAR(20) = 'Efectivo',
    @usuario_id INT,
    @pago_id INT OUTPUT,
    @numero_recibo VARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- =============================================
        -- VALIDACIONES
        -- =============================================
        
        -- 1. Validar que la factura existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Factura WHERE factura_id = @factura_id)
        BEGIN
            THROW 50201, 'La factura especificada no existe', 1;
        END
        
        -- 2. Obtener datos de la factura
        DECLARE @estado_factura VARCHAR(20);
        DECLARE @monto_total_factura DECIMAL(12,2);
        
        SELECT 
            @estado_factura = estado_factura,
            @monto_total_factura = monto_total
        FROM dbo.Factura
        WHERE factura_id = @factura_id;
        
        -- 3. Validar que la factura esté en estado que permite pago (Pendiente o Vencida)
        IF @estado_factura NOT IN ('Pendiente', 'Vencida')
        BEGIN
            THROW 50202, 'Solo se pueden registrar pagos para facturas en estado Pendiente o Vencida', 1;
        END
        
        -- 4. Validar que la factura NO tenga pagos previos (solo 1 pago por factura)
        IF EXISTS (SELECT 1 FROM dbo.Pago WHERE factura_id = @factura_id)
        BEGIN
            THROW 50203, 'La factura ya tiene un pago registrado', 1;
        END
        
        -- 5. Validar que el usuario existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Usuario WHERE usuario_id = @usuario_id)
        BEGIN
            THROW 50204, 'El usuario especificado no existe', 1;
        END
        
        -- 6. Validar monto_pagado > 0
        IF @monto_pagado <= 0
        BEGIN
            THROW 50205, 'El monto pagado debe ser mayor a cero', 1;
        END
        
        -- 7. Validar que monto_pagado = monto_total (IGUALDAD EXACTA, solo pagos totales)
        IF @monto_pagado <> @monto_total_factura
        BEGIN
            DECLARE @mensaje_monto VARCHAR(300);
            SET @mensaje_monto = 'El monto pagado (' + CAST(@monto_pagado AS VARCHAR) + 
                               ') debe ser igual al monto total de la factura (' + 
                               CAST(@monto_total_factura AS VARCHAR) + '). Solo se permiten pagos totales';
            THROW 50206, @mensaje_monto, 1;
        END
        
        -- 8. Validar medio de pago (por ahora solo Efectivo)
        IF @medio_pago <> 'Efectivo'
        BEGIN
            THROW 50207, 'Actualmente solo se permiten pagos en efectivo', 1;
        END
        
        -- 9. Validar y configurar fecha de pago
        IF @fecha_pago IS NULL
        BEGIN
            SET @fecha_pago = CAST(GETDATE() AS DATE);
        END
        
        -- 10. No permitir fechas futuras
        IF @fecha_pago > CAST(GETDATE() AS DATE)
        BEGIN
            THROW 50208, 'No se pueden registrar pagos con fecha futura', 1;
        END
        
        -- Nota: Fechas pasadas SÍ están permitidas (para registros retroactivos)
        
        -- =============================================
        -- AUTOGENERAR NÚMERO DE RECIBO
        -- Formato: REC-YYYYMMDD-####
        -- =============================================
        
        DECLARE @fecha_actual DATE = CAST(GETDATE() AS DATE);
        DECLARE @prefijo VARCHAR(20) = 'REC-' + FORMAT(@fecha_actual, 'yyyyMMdd') + '-';
        DECLARE @ultimo_secuencial INT;
        
        -- Buscar el último número secuencial del día actual
        SELECT @ultimo_secuencial = ISNULL(MAX(CAST(RIGHT(numero_recibo, 4) AS INT)), 0)
        FROM dbo.Pago
        WHERE numero_recibo LIKE @prefijo + '%';
        
        -- Generar nuevo número de recibo
        SET @numero_recibo = @prefijo + RIGHT('0000' + CAST(@ultimo_secuencial + 1 AS VARCHAR), 4);
        
        -- =============================================
        -- INSERTAR EL PAGO
        -- =============================================
        
        INSERT INTO dbo.Pago (
            monto_pagado,
            fecha_pago,
            medio_pago,
            numero_recibo,
            usuario_id,
            factura_id
        )
        VALUES (
            @monto_pagado,
            @fecha_pago,
            @medio_pago,
            @numero_recibo,
            @usuario_id,
            @factura_id
        );
        
        -- Obtener el ID del pago insertado
        SET @pago_id = SCOPE_IDENTITY();
        
        -- =============================================
        -- NOTA: El trigger trg_actualizar_estado_factura
        -- cambiará automáticamente el estado de la factura
        -- a 'Pagada' (AFTER INSERT en Pago)
        -- =============================================
        
        COMMIT TRANSACTION;
        
        -- Retornar información del pago registrado con datos de la factura
        SELECT 
            p.pago_id,
            p.numero_recibo,
            p.monto_pagado,
            p.fecha_pago,
            p.medio_pago,
            p.usuario_id,
            u.nombre AS usuario_nombre,
            p.factura_id,
            f.numero_factura,
            f.estado_factura, -- Ya debe estar en 'Pagada' por el trigger
            f.monto_total AS factura_monto_total
        FROM dbo.Pago p
        INNER JOIN dbo.Usuario u ON p.usuario_id = u.usuario_id
        INNER JOIN dbo.Factura f ON p.factura_id = f.factura_id
        WHERE p.pago_id = @pago_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        THROW;
    END CATCH
END
GO

PRINT '✓ SP sp_registrar_pago creado exitosamente';
GO









-- =============================================
-- SP: sp_consultar_pago_por_id
-- Descripción: Consulta información completa de un pago específico
-- Retorna: 2 RESULTSETS (pago+factura, contribuyentes)
-- =============================================

USE MunicipalidadNicoya;
GO

IF OBJECT_ID('dbo.sp_consultar_pago_por_id', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_consultar_pago_por_id;
GO

CREATE PROCEDURE dbo.sp_consultar_pago_por_id
    @pago_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- =============================================
        -- VALIDACIÓN
        -- =============================================
        
        -- Validar que el pago existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Pago WHERE pago_id = @pago_id)
        BEGIN
            THROW 50209, 'El pago especificado no existe', 1;
        END
        
        -- =============================================
        -- RESULTSET 1: INFORMACIÓN DEL PAGO Y FACTURA
        -- =============================================
        
        SELECT 
            -- Datos del Pago
            p.pago_id,
            p.numero_recibo,
            p.monto_pagado,
            p.fecha_pago,
            p.medio_pago,
            
            -- Datos del Usuario que registró el pago
            p.usuario_id,
            u.nombre AS usuario_nombre,
            u.email AS usuario_email,
            
            -- Datos de la Factura
            f.factura_id,
            f.numero_factura,
            f.fecha_emision,
            f.fecha_vencimiento,
            f.periodo,
            f.monto_base,
            f.recargo,
            f.intereses,
            f.monto_total,
            f.estado_factura,
            
            -- Referencias de origen (solo IDs)
            f.tramite_id,
            f.inmueble_id,
            
            -- Tipo de origen
            CASE 
                WHEN f.tramite_id IS NOT NULL THEN 'Tramite'
                WHEN f.inmueble_id IS NOT NULL THEN 'Inmueble'
            END AS tipo_origen
            
        FROM dbo.Pago p
        INNER JOIN dbo.Usuario u ON p.usuario_id = u.usuario_id
        INNER JOIN dbo.Factura f ON p.factura_id = f.factura_id
        WHERE p.pago_id = @pago_id;
        
        -- =============================================
        -- RESULTSET 2: CONTRIBUYENTES ASOCIADOS
        -- =============================================
        
        -- Obtener factura_id del pago
        DECLARE @factura_id INT;
        SELECT @factura_id = factura_id FROM dbo.Pago WHERE pago_id = @pago_id;
        
        -- Obtener contribuyentes (de trámite o inmueble)
        SELECT 
            c.contribuyente_id,
            c.tipo_contribuyente,
            c.telefono,
            c.email,
            c.direccion,
            
            -- Nombre completo según tipo
            CASE 
                WHEN c.tipo_contribuyente = 'Física' THEN 
                    CONCAT(cf.nombre, ' ', cf.apellido1, ' ', ISNULL(cf.apellido2, ''))
                WHEN c.tipo_contribuyente = 'Jurídica' THEN 
                    cj.nombre_empresa
            END AS nombre_completo,
            
            -- Cédula según tipo
            CASE 
                WHEN c.tipo_contribuyente = 'Física' THEN cf.cedula
                WHEN c.tipo_contribuyente = 'Jurídica' THEN cj.cedula_juridica
            END AS cedula,
            
            -- Porcentaje de propiedad (solo para inmuebles, NULL para trámites)
            ci.porcentaje_propiedad,
            
            -- Origen del contribuyente
            CASE 
                WHEN f.tramite_id IS NOT NULL THEN 'Tramite'
                WHEN f.inmueble_id IS NOT NULL THEN 'Inmueble'
            END AS origen
            
        FROM dbo.Factura f
        LEFT JOIN dbo.Tramite t ON f.tramite_id = t.tramite_id
        LEFT JOIN dbo.Inmueble i ON f.inmueble_id = i.inmueble_id
        LEFT JOIN dbo.Contribuyente_Inmueble ci ON i.inmueble_id = ci.inmueble_id
        LEFT JOIN dbo.Contribuyente c ON (
            t.contribuyente_id = c.contribuyente_id OR 
            ci.contribuyente_id = c.contribuyente_id
        )
        LEFT JOIN dbo.Contribuyente_Fisico cf ON c.contribuyente_id = cf.contribuyente_id
        LEFT JOIN dbo.Contribuyente_Juridico cj ON c.contribuyente_id = cj.contribuyente_id
        WHERE f.factura_id = @factura_id
        ORDER BY ci.porcentaje_propiedad DESC;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ SP sp_consultar_pago_por_id creado exitosamente';
GO









-- =============================================
-- SP: sp_listar_pagos_por_factura
-- Descripción: Lista todos los pagos de una factura específica
-- Nota: Actualmente solo habrá 1 pago por factura (pagos totales)
-- =============================================

USE MunicipalidadNicoya;
GO

IF OBJECT_ID('dbo.sp_listar_pagos_por_factura', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_listar_pagos_por_factura;
GO

CREATE PROCEDURE dbo.sp_listar_pagos_por_factura
    @factura_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- =============================================
        -- VALIDACIÓN
        -- =============================================
        
        -- Validar que la factura existe
        IF NOT EXISTS (SELECT 1 FROM dbo.Factura WHERE factura_id = @factura_id)
        BEGIN
            THROW 50210, 'La factura especificada no existe', 1;
        END
        
        -- =============================================
        -- CONSULTA DE PAGOS
        -- =============================================
        
        SELECT 
            p.pago_id,
            p.numero_recibo,
            p.monto_pagado,
            p.fecha_pago,
            p.medio_pago,
            p.usuario_id,
            u.nombre AS usuario_nombre,
            u.email AS usuario_email,
            p.factura_id,
            f.numero_factura,
            f.monto_total AS factura_monto_total,
            f.estado_factura
        FROM dbo.Pago p
        INNER JOIN dbo.Usuario u ON p.usuario_id = u.usuario_id
        INNER JOIN dbo.Factura f ON p.factura_id = f.factura_id
        WHERE p.factura_id = @factura_id
        ORDER BY p.fecha_pago DESC, p.pago_id DESC;
        
        -- Si no hay pagos, retorna conjunto vacío (0 filas)
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ SP sp_listar_pagos_por_factura creado exitosamente';
GO










-- =============================================
-- SP: sp_visualizar_historial_pagos
-- Descripción: Lista historial de pagos con filtros avanzados y paginación
-- =============================================

USE MunicipalidadNicoya;
GO

IF OBJECT_ID('dbo.sp_visualizar_historial_pagos', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_visualizar_historial_pagos;
GO

CREATE PROCEDURE dbo.sp_visualizar_historial_pagos
    @contribuyente_id INT = NULL,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL,
    @medio_pago VARCHAR(20) = NULL,
    @usuario_id INT = NULL,
    @numero_recibo_busqueda VARCHAR(50) = NULL,
    @page_number INT = 1,
    @page_size INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- =============================================
        -- VALIDACIONES
        -- =============================================
        
        -- 1. Validar que contribuyente existe (si se especifica)
        IF @contribuyente_id IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM dbo.Contribuyente WHERE contribuyente_id = @contribuyente_id
        )
        BEGIN
            THROW 50211, 'El contribuyente especificado no existe', 1;
        END
        
        -- 2. Validar que usuario existe (si se especifica)
        IF @usuario_id IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM dbo.Usuario WHERE usuario_id = @usuario_id
        )
        BEGIN
            THROW 50212, 'El usuario especificado no existe', 1;
        END
        
        -- 3. Validar page_number >= 1
        IF @page_number < 1
        BEGIN
            THROW 50213, 'El número de página debe ser mayor o igual a 1', 1;
        END
        
        -- 4. Validar page_size entre 1 y 100
        IF @page_size < 1 OR @page_size > 100
        BEGIN
            THROW 50214, 'El tamaño de página debe estar entre 1 y 100', 1;
        END
        
        -- 5. Validar rango de fechas (si se especifican ambas)
        IF @fecha_desde IS NOT NULL AND @fecha_hasta IS NOT NULL AND @fecha_desde > @fecha_hasta
        BEGIN
            THROW 50215, 'La fecha desde no puede ser mayor a la fecha hasta', 1;
        END
        
        -- =============================================
        -- CONSULTA CON FILTROS Y PAGINACIÓN
        -- =============================================
        
        -- Usar CTE para optimizar la consulta con paginación
        ;WITH PagosCTE AS (
            SELECT 
                p.pago_id,
                p.numero_recibo,
                p.monto_pagado,
                p.fecha_pago,
                p.medio_pago,
                p.usuario_id,
                u.nombre AS usuario_nombre,
                f.factura_id,
                f.numero_factura,
                f.monto_total AS factura_monto_total,
                f.tramite_id,
                f.inmueble_id,
                
                -- Obtener el contribuyente principal (mayor porcentaje si es inmueble)
                COALESCE(
                    t.contribuyente_id, 
                    (SELECT TOP 1 ci2.contribuyente_id 
                     FROM dbo.Contribuyente_Inmueble ci2 
                     WHERE ci2.inmueble_id = f.inmueble_id 
                     ORDER BY ci2.porcentaje_propiedad DESC)
                ) AS contribuyente_id,
                
                -- Tipo de origen
                CASE 
                    WHEN f.tramite_id IS NOT NULL THEN 'Tramite'
                    WHEN f.inmueble_id IS NOT NULL THEN 'Inmueble'
                END AS tipo_origen,
                
                -- Para contar total de registros
                COUNT(*) OVER() AS total_registros
                
            FROM dbo.Pago p
            INNER JOIN dbo.Usuario u ON p.usuario_id = u.usuario_id
            INNER JOIN dbo.Factura f ON p.factura_id = f.factura_id
            LEFT JOIN dbo.Tramite t ON f.tramite_id = t.tramite_id
            LEFT JOIN dbo.Inmueble i ON f.inmueble_id = i.inmueble_id
            LEFT JOIN dbo.Contribuyente_Inmueble ci ON i.inmueble_id = ci.inmueble_id
            
            WHERE 1=1
                -- Filtro por contribuyente (buscar en trámite o inmueble)
                AND (
                    @contribuyente_id IS NULL 
                    OR t.contribuyente_id = @contribuyente_id 
                    OR ci.contribuyente_id = @contribuyente_id
                )
                -- Filtro por rango de fechas
                AND (@fecha_desde IS NULL OR p.fecha_pago >= @fecha_desde)
                AND (@fecha_hasta IS NULL OR p.fecha_pago <= @fecha_hasta)
                -- Filtro por medio de pago
                AND (@medio_pago IS NULL OR p.medio_pago = @medio_pago)
                -- Filtro por usuario que registró
                AND (@usuario_id IS NULL OR p.usuario_id = @usuario_id)
                -- Búsqueda parcial por número de recibo
                AND (@numero_recibo_busqueda IS NULL OR p.numero_recibo LIKE '%' + @numero_recibo_busqueda + '%')
        )
        
        -- Consulta final con información del contribuyente y paginación
        SELECT DISTINCT
            pc.pago_id,
            pc.numero_recibo,
            pc.monto_pagado,
            pc.fecha_pago,
            pc.medio_pago,
            pc.usuario_id,
            pc.usuario_nombre,
            pc.factura_id,
            pc.numero_factura,
            pc.factura_monto_total,
            pc.tipo_origen,
            
            -- Información del contribuyente principal
            pc.contribuyente_id,
            c.tipo_contribuyente,
            CASE 
                WHEN c.tipo_contribuyente = 'Física' THEN 
                    CONCAT(cf.nombre, ' ', cf.apellido1, ' ', ISNULL(cf.apellido2, ''))
                WHEN c.tipo_contribuyente = 'Jurídica' THEN 
                    cj.nombre_empresa
            END AS contribuyente_nombre,
            CASE 
                WHEN c.tipo_contribuyente = 'Física' THEN cf.cedula
                WHEN c.tipo_contribuyente = 'Jurídica' THEN cj.cedula_juridica
            END AS contribuyente_cedula,
            
            -- Metadatos de paginación
            pc.total_registros,
            @page_number AS pagina_actual,
            @page_size AS registros_por_pagina,
            CEILING(CAST(pc.total_registros AS FLOAT) / @page_size) AS total_paginas
            
        FROM PagosCTE pc
        LEFT JOIN dbo.Contribuyente c ON pc.contribuyente_id = c.contribuyente_id
        LEFT JOIN dbo.Contribuyente_Fisico cf ON c.contribuyente_id = cf.contribuyente_id
        LEFT JOIN dbo.Contribuyente_Juridico cj ON c.contribuyente_id = cj.contribuyente_id
        
        ORDER BY pc.fecha_pago DESC, pc.pago_id DESC
        OFFSET (@page_number - 1) * @page_size ROWS
        FETCH NEXT @page_size ROWS ONLY;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

PRINT '✓ SP sp_visualizar_historial_pagos creado exitosamente';
GO





















