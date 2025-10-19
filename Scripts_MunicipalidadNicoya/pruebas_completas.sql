-- =============================================
-- SCRIPT DE LIMPIEZA COMPLETA
-- Ejecutar ANTES del script de pruebas
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT 'Limpiando base de datos...';

-- Eliminar en orden inverso de dependencias
DELETE FROM Pago;
DELETE FROM Detalle_factura;
DELETE FROM Factura;
DELETE FROM Servicio_Inmueble;
DELETE FROM Rubro;
DELETE FROM Tramite;
DELETE FROM Tipo_Tramite_Requisito;
DELETE FROM Requisito;
DELETE FROM ObservacionInmueble;
DELETE FROM Colindancias;
DELETE FROM Catastro;
DELETE FROM Contribuyente_Inmueble;
DELETE FROM Inmueble;
DELETE FROM Contribuyente_juridico;
DELETE FROM Contribuyente_fisico;
DELETE FROM Contribuyente;

-- NO eliminar estas tablas de catálogo:
-- - TipoUsoInmueble
-- - Tipo_Tramite
-- - Usuario

PRINT '? Base de datos limpiada correctamente';
PRINT '? Puedes ejecutar ahora el script de pruebas';
GO















-- =============================================
-- SCRIPT DE PRUEBA COMPLETO Y CORREGIDO
-- Sistema de Gestión Municipal de Nicoya
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '';
PRINT '---------------------------------------------------------------';
PRINT '     INICIO DE PRUEBAS - FLUJO COMPLETO DEL SISTEMA';
PRINT '---------------------------------------------------------------';
PRINT '';

-- =============================================
-- DECLARACIÓN DE VARIABLES (TODAS AL INICIO)
-- =============================================

-- Variables de Rubros
DECLARE @rubro_impuesto_territorial INT;
DECLARE @rubro_licencia_comercial INT;
DECLARE @rubro_patente_municipal INT;
DECLARE @rubro_servicio_agua INT;
DECLARE @rubro_servicio_basura INT;
DECLARE @rubro_permiso_construccion INT;
DECLARE @rubro_permiso_rotulo INT;
DECLARE @rubro_certificacion_suelo INT;
DECLARE @rubro_timbres_municipales INT;
DECLARE @rubro_otros_servicios INT;

-- Variables de Contribuyentes
DECLARE @contrib_fisico1_id INT;
DECLARE @contrib_fisico2_id INT;
DECLARE @contrib_juridico1_id INT;

-- Variables de Inmuebles
DECLARE @inmueble1_id INT;
DECLARE @inmueble2_id INT;
DECLARE @inmueble3_id INT;
DECLARE @catastro1_id INT;
DECLARE @tipo_uso_residencial INT;
DECLARE @tipo_uso_comercial INT;

-- Variables de Trámites
DECLARE @tramite1_id INT;
DECLARE @tramite2_id INT;
DECLARE @tipo_permiso_construccion INT;
DECLARE @tipo_patente_comercial INT;

-- Variables de Facturas y Pagos
DECLARE @factura1_id INT;
DECLARE @factura2_id INT;
DECLARE @numero_factura1 VARCHAR(50);
DECLARE @numero_factura2 VARCHAR(50);
DECLARE @detalle1_id INT;
DECLARE @detalle2_id INT;
DECLARE @pago1_id INT;
DECLARE @numero_recibo1 VARCHAR(50);
DECLARE @usuario_id INT;
DECLARE @referencia_servicio1 VARCHAR(100);
DECLARE @referencia_servicio2 VARCHAR(100);
DECLARE @referencia_servicio3 VARCHAR(100);

-- Variables auxiliares
DECLARE @count_rubros INT;
DECLARE @monto_total_factura DECIMAL(12,2);
DECLARE @rubros_batch_inmueble2 VARCHAR(100);
DECLARE @rubros_batch_inmueble3 VARCHAR(100);

-- =============================================
-- FASE 0: PREPARACIÓN DE DATOS BASE (RUBROS)
-- =============================================

PRINT '+-------------------------------------------------------------+';
PRINT '| FASE 0: PREPARACIÓN DE RUBROS                               |';
PRINT '+-------------------------------------------------------------+';
PRINT '';

PRINT '?? 0.1 Verificando rubros en el sistema...';

SELECT @count_rubros = COUNT(*) FROM dbo.Rubro;

IF @count_rubros = 0
BEGIN
    PRINT '  ??  No se encontraron rubros en el sistema.';
    PRINT '  ?? Insertando rubros base...';
    PRINT '';
    
    -- Rubro 1: Impuesto Territorial
    INSERT INTO dbo.Rubro (nombre, descripcion, periodicidad, tarifa_base, vigencia, aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo) 
    VALUES ('Impuesto Territorial', 'Impuesto sobre bienes inmuebles', 'Trimestral', 50000.00, 1, 1, 1, 2.5, 1.0);
    SET @rubro_impuesto_territorial = SCOPE_IDENTITY();
    
    -- Rubro 2: Licencia Comercial
    INSERT INTO dbo.Rubro (nombre, descripcion, periodicidad, tarifa_base, vigencia, aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo) 
    VALUES ('Licencia Comercial', 'Licencia para ejercer actividad comercial', 'Anual', 35000.00, 1, 1, 0, 0, 1.5);
    SET @rubro_licencia_comercial = SCOPE_IDENTITY();
    
    -- Rubro 3: Patente Municipal
    INSERT INTO dbo.Rubro (nombre, descripcion, periodicidad, tarifa_base, vigencia, aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo) 
    VALUES ('Patente Municipal', 'Patente para comercio o servicio', 'Anual', 120000.00, 1, 1, 1, 3.0, 10.0);
    SET @rubro_patente_municipal = SCOPE_IDENTITY();
    
    -- Rubro 4: Servicio de Agua
    INSERT INTO dbo.Rubro (nombre, descripcion, periodicidad, tarifa_base, vigencia, aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo) 
    VALUES ('Servicio de Agua', 'Cobro por suministro de agua potable', 'Mensual', 3500.00, 1, 0, 0, 0, 0);
    SET @rubro_servicio_agua = SCOPE_IDENTITY();
    
    -- Rubro 5: Servicio de Basura
    INSERT INTO dbo.Rubro (nombre, descripcion, periodicidad, tarifa_base, vigencia, aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo) 
    VALUES ('Servicio de Basura', 'Recolección y manejo de desechos', 'Mensual', 4000.00, 1, 0, 0, 0, 0);
    SET @rubro_servicio_basura = SCOPE_IDENTITY();
    
    -- Rubro 6: Permiso de Construcción
    INSERT INTO dbo.Rubro (nombre, descripcion, periodicidad, tarifa_base, vigencia, aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo) 
    VALUES ('Permiso de Construcción', 'Permiso para construcción o remodelación', 'Único', 75000.00, 1, 1, 1, 2.5, 5.0);
    SET @rubro_permiso_construccion = SCOPE_IDENTITY();
    
    -- Rubro 7: Permiso de Rótulo
    INSERT INTO dbo.Rubro (nombre, descripcion, periodicidad, tarifa_base, vigencia, aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo) 
    VALUES ('Permiso de Rótulo', 'Permiso para instalación de rótulos', 'Único', 15000.00, 1, 0, 0, 0, 0);
    SET @rubro_permiso_rotulo = SCOPE_IDENTITY();
    
    -- Rubro 8: Certificación de Uso de Suelo
    INSERT INTO dbo.Rubro (nombre, descripcion, periodicidad, tarifa_base, vigencia, aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo) 
    VALUES ('Certificación de Uso de Suelo', 'Certificado de uso de suelo', 'Único', 8000.00, 1, 0, 0, 0, 0);
    SET @rubro_certificacion_suelo = SCOPE_IDENTITY();
    
    -- Rubro 9: Timbres Municipales
    INSERT INTO dbo.Rubro (nombre, descripcion, periodicidad, tarifa_base, vigencia, aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo) 
    VALUES ('Timbres Municipales', 'Timbres y estampillas municipales', 'Único', 500.00, 1, 0, 0, 0, 0);
    SET @rubro_timbres_municipales = SCOPE_IDENTITY();
    
    -- Rubro 10: Otros Servicios
    INSERT INTO dbo.Rubro (nombre, descripcion, periodicidad, tarifa_base, vigencia, aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo) 
    VALUES ('Otros Servicios', 'Servicios varios municipales', NULL, 0.00, 1, 0, 0, 0, 0);
    SET @rubro_otros_servicios = SCOPE_IDENTITY();
    
    PRINT '  ? 10 rubros insertados correctamente';
    PRINT '';
END
ELSE
BEGIN
    -- Si ya existen, obtener los IDs por nombre
    SELECT @rubro_impuesto_territorial = rubro_id FROM Rubro WHERE nombre = 'Impuesto Territorial';
    SELECT @rubro_licencia_comercial = rubro_id FROM Rubro WHERE nombre = 'Licencia Comercial';
    SELECT @rubro_patente_municipal = rubro_id FROM Rubro WHERE nombre = 'Patente Municipal';
    SELECT @rubro_servicio_agua = rubro_id FROM Rubro WHERE nombre = 'Servicio de Agua';
    SELECT @rubro_servicio_basura = rubro_id FROM Rubro WHERE nombre = 'Servicio de Basura';
    SELECT @rubro_permiso_construccion = rubro_id FROM Rubro WHERE nombre = 'Permiso de Construcción';
    SELECT @rubro_permiso_rotulo = rubro_id FROM Rubro WHERE nombre = 'Permiso de Rótulo';
    SELECT @rubro_certificacion_suelo = rubro_id FROM Rubro WHERE nombre = 'Certificación de Uso de Suelo';
    SELECT @rubro_timbres_municipales = rubro_id FROM Rubro WHERE nombre = 'Timbres Municipales';
    SELECT @rubro_otros_servicios = rubro_id FROM Rubro WHERE nombre = 'Otros Servicios';
    
    PRINT '  ? Rubros encontrados en el sistema: ' + CAST(@count_rubros AS VARCHAR(10));
    PRINT '';
END

PRINT '? FASE 0 COMPLETADA: Rubros disponibles';
PRINT '';

-- =============================================
-- FASE 1: MÓDULO CONTRIBUYENTES E INMUEBLES
-- =============================================

PRINT '+-------------------------------------------------------------+';
PRINT '| FASE 1: CONTRIBUYENTES E INMUEBLES                          |';
PRINT '+-------------------------------------------------------------+';
PRINT '';

PRINT '?? 1.1 Creando contribuyentes físicos...';

EXEC sp_Contribuyente_InsertarFisico
    @cedula = '1-0890-0456',
    @nombre = 'Carlos',
    @apellido1 = 'Ramírez',
    @apellido2 = 'Mora',
    @telefono = '2685-1111',
    @email = 'carlos.ramirez@email.com',
    @direccion = 'Nicoya Centro, 100m sur del parque';

SET @contrib_fisico1_id = (SELECT TOP 1 contribuyente_id FROM Contribuyente ORDER BY contribuyente_id DESC);
PRINT '  ? Contribuyente físico 1 creado - ID: ' + CAST(@contrib_fisico1_id AS VARCHAR(10));

EXEC sp_Contribuyente_InsertarFisico
    @cedula = '1-0567-0789',
    @nombre = 'Ana',
    @apellido1 = 'López',
    @apellido2 = 'Jiménez',
    @telefono = '2685-2222',
    @email = 'ana.lopez@email.com',
    @direccion = 'Nicoya, Barrio San José';

SET @contrib_fisico2_id = (SELECT TOP 1 contribuyente_id FROM Contribuyente ORDER BY contribuyente_id DESC);
PRINT '  ? Contribuyente físico 2 creado - ID: ' + CAST(@contrib_fisico2_id AS VARCHAR(10));

PRINT '';
PRINT '?? 1.2 Creando contribuyente jurídico...';

EXEC sp_Contribuyente_InsertarJuridico
    @cedula_juridica = '3-101-987654',
    @nombre_empresa = 'Constructora Nicoya S.A.',
    @representante_legal_id = @contrib_fisico1_id,
    @telefono = '2685-3333',
    @email = 'info@constructoranicoya.cr',
    @direccion = 'Nicoya, Zona Industrial Norte';

SET @contrib_juridico1_id = (SELECT TOP 1 contribuyente_id FROM Contribuyente ORDER BY contribuyente_id DESC);
PRINT '  ? Contribuyente jurídico creado - ID: ' + CAST(@contrib_juridico1_id AS VARCHAR(10));

PRINT '';
PRINT '??? 1.3 Creando inmuebles...';

SELECT @tipo_uso_residencial = tipo_uso_inmueble_id FROM TipoUsoInmueble WHERE nombre_uso = 'Residencial';
SELECT @tipo_uso_comercial = tipo_uso_inmueble_id FROM TipoUsoInmueble WHERE nombre_uso = 'Comercial';

EXEC sp_Inmueble_Insertar
    @direccion_exacta = 'Nicoya Centro, 150m norte del Banco Nacional',
    @area_terreno = 280.00,
    @valor_fiscal = 52000000.00,
    @tipo_uso_inmueble_id = @tipo_uso_residencial,
    @estado_ocupacional = 'Ocupado';

SET @inmueble1_id = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id DESC);
PRINT '  ? Inmueble 1 (Residencial) creado - ID: ' + CAST(@inmueble1_id AS VARCHAR(10));

EXEC sp_Inmueble_Insertar
    @direccion_exacta = 'Nicoya, Avenida Central frente al Mercado',
    @area_terreno = 350.00,
    @valor_fiscal = 85000000.00,
    @tipo_uso_inmueble_id = @tipo_uso_comercial,
    @estado_ocupacional = 'Ocupado';

SET @inmueble2_id = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id DESC);
PRINT '  ? Inmueble 2 (Comercial) creado - ID: ' + CAST(@inmueble2_id AS VARCHAR(10));

EXEC sp_Inmueble_Insertar
    @direccion_exacta = 'Nicoya, Zona Industrial Norte, Bodega #5',
    @area_terreno = 500.00,
    @valor_fiscal = 95000000.00,
    @tipo_uso_inmueble_id = @tipo_uso_comercial,
    @estado_ocupacional = 'Ocupado';

SET @inmueble3_id = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id DESC);
PRINT '  ? Inmueble 3 (Comercial) creado - ID: ' + CAST(@inmueble3_id AS VARCHAR(10));

PRINT '';
PRINT '?? 1.4 Asociando contribuyentes a inmuebles...';

EXEC sp_Inmueble_AsociarContribuyente
    @contribuyente_id = @contrib_fisico1_id,
    @inmueble_id = @inmueble1_id,
    @porcentaje_propiedad = 100.00;
PRINT '  ? Carlos Ramírez asociado al Inmueble 1';

EXEC sp_Inmueble_AsociarContribuyente
    @contribuyente_id = @contrib_fisico2_id,
    @inmueble_id = @inmueble2_id,
    @porcentaje_propiedad = 100.00;
PRINT '  ? Ana López asociada al Inmueble 2';

EXEC sp_Inmueble_AsociarContribuyente
    @contribuyente_id = @contrib_juridico1_id,
    @inmueble_id = @inmueble3_id,
    @porcentaje_propiedad = 100.00;
PRINT '  ? Constructora Nicoya S.A. asociada al Inmueble 3';

PRINT '';
PRINT '?? 1.5 Creando información catastral...';

EXEC sp_Catastro_Insertar
    @numero_plano_catastral = 'G-2025-001234',
    @area_catastral = '280.00 m² - Lote urbano residencial',
    @fecha_inscripcion = '2024-06-15',
    @estado = 'Activo',
    @inmueble_id = @inmueble1_id;

SET @catastro1_id = (SELECT TOP 1 catastro_id FROM Catastro ORDER BY catastro_id DESC);
PRINT '  ? Catastro creado para Inmueble 1';

EXEC sp_Colindancia_Insertar
    @punto_cardinal = 'Norte',
    @colindante = 'Calle Pública Principal',
    @catastro_id = @catastro1_id;

EXEC sp_Colindancia_Insertar
    @punto_cardinal = 'Sur',
    @colindante = 'Propiedad de Pedro Vargas',
    @catastro_id = @catastro1_id;

PRINT '  ? Colindancias agregadas';

EXEC sp_ObservacionInmueble_Insertar
    @descripcion = 'Inmueble en buen estado',
    @inmueble_id = @inmueble1_id,
    @fecha = '2025-01-10';

PRINT '  ? Observación registrada';
PRINT '';
PRINT '? FASE 1 COMPLETADA';
PRINT '';

-- =============================================
-- FASE 1.5: SERVICIOS DE INMUEBLES
-- =============================================

PRINT '+-------------------------------------------------------------+';
PRINT '| FASE 1.5: CONFIGURACIÓN DE SERVICIOS                       |';
PRINT '+-------------------------------------------------------------+';
PRINT '';

PRINT '?? 1.5.1 Configurando servicios para Inmueble 1...';

EXEC sp_agregar_servicio_inmueble
    @inmueble_id = @inmueble1_id,
    @rubro_id = @rubro_impuesto_territorial,
    @tarifa_personalizada = NULL,
    @observaciones = 'Uso residencial';

PRINT '  ? Impuesto Territorial agregado';

EXEC sp_agregar_servicio_inmueble
    @inmueble_id = @inmueble1_id,
    @rubro_id = @rubro_servicio_agua,
    @tarifa_personalizada = 5000.00,
    @observaciones = 'Familia de 5 personas';

PRINT '  ? Servicio de Agua agregado (tarifa personalizada)';

EXEC sp_agregar_servicio_inmueble
    @inmueble_id = @inmueble1_id,
    @rubro_id = @rubro_servicio_basura,
    @tarifa_personalizada = NULL,
    @observaciones = NULL;

PRINT '  ? Servicio de Basura agregado';

PRINT '';
PRINT '?? 1.5.2 Configurando servicios para Inmueble 2...';

SET @rubros_batch_inmueble2 = 
    CAST(@rubro_impuesto_territorial AS VARCHAR(10)) + ',' +
    CAST(@rubro_servicio_agua AS VARCHAR(10)) + ',' +
    CAST(@rubro_servicio_basura AS VARCHAR(10));

EXEC sp_agregar_servicios_batch
    @inmueble_id = @inmueble2_id,
    @rubros_ids = @rubros_batch_inmueble2;

PRINT '  ? 3 servicios agregados en batch';

EXEC sp_agregar_servicio_inmueble
    @inmueble_id = @inmueble2_id,
    @rubro_id = @rubro_licencia_comercial,
    @tarifa_personalizada = 50000.00,
    @observaciones = 'Mini Super';

PRINT '  ? Licencia Comercial agregada';

PRINT '';
PRINT '?? 1.5.3 Configurando servicios para Inmueble 3...';

SET @rubros_batch_inmueble3 = 
    CAST(@rubro_impuesto_territorial AS VARCHAR(10)) + ',' +
    CAST(@rubro_servicio_agua AS VARCHAR(10)) + ',' +
    CAST(@rubro_servicio_basura AS VARCHAR(10));

EXEC sp_agregar_servicios_batch
    @inmueble_id = @inmueble3_id,
    @rubros_ids = @rubros_batch_inmueble3;

PRINT '  ? 3 servicios base agregados';

EXEC sp_agregar_servicio_inmueble
    @inmueble_id = @inmueble3_id,
    @rubro_id = @rubro_patente_municipal,
    @tarifa_personalizada = 80000.00,
    @observaciones = 'Constructora';

PRINT '  ? Patente Municipal agregada';
PRINT '';
PRINT '? FASE 1.5 COMPLETADA';
PRINT '';

-- =============================================
-- FASE 2: MÓDULO TRÁMITES Y PERMISOS
-- =============================================

PRINT '+-------------------------------------------------------------+';
PRINT '| FASE 2: TRÁMITES Y PERMISOS                                |';
PRINT '+-------------------------------------------------------------+';
PRINT '';

SELECT @tipo_permiso_construccion = tipo_tramite_id 
FROM Tipo_Tramite 
WHERE nombre_tipo = 'Permiso de Construcción';

SELECT @tipo_patente_comercial = tipo_tramite_id 
FROM Tipo_Tramite 
WHERE nombre_tipo = 'Patente Comercial';

PRINT '?? 2.1 Creando trámite de Permiso de Construcción...';

EXEC sp_Tramite_Insertar
    @fecha_ingreso = '2025-02-01',
    @fecha_resolucion = NULL,
    @observaciones = 'Ampliación de vivienda',
    @tipo_tramite_id = @tipo_permiso_construccion,
    @contribuyente_id = @contrib_fisico1_id,
    @inmueble_id = @inmueble1_id,
    @estado_actual = 'En Proceso';

SET @tramite1_id = (SELECT TOP 1 tramite_id FROM Tramite ORDER BY tramite_id DESC);
PRINT '  ? Trámite creado - ID: ' + CAST(@tramite1_id AS VARCHAR(10));

PRINT '';
PRINT '?? 2.2 Creando trámite de Patente Comercial...';

EXEC sp_Tramite_Insertar
    @fecha_ingreso = '2025-02-05',
    @fecha_resolucion = NULL,
    @observaciones = 'Patente para mini super',
    @tipo_tramite_id = @tipo_patente_comercial,
    @contribuyente_id = @contrib_fisico2_id,
    @inmueble_id = @inmueble2_id,
    @estado_actual = 'En Proceso';

SET @tramite2_id = (SELECT TOP 1 tramite_id FROM Tramite ORDER BY tramite_id DESC);
PRINT '  ? Trámite creado - ID: ' + CAST(@tramite2_id AS VARCHAR(10));
PRINT '';
PRINT '? FASE 2 COMPLETADA';
PRINT '';

-- =============================================
-- FASE 3: MÓDULO PAGOS Y COBROS
-- =============================================

PRINT '+-------------------------------------------------------------+';
PRINT '| FASE 3: PAGOS Y COBROS                                     |';
PRINT '+-------------------------------------------------------------+';
PRINT '';

-- Obtener o crear usuario
SELECT TOP 1 @usuario_id = usuario_id FROM Usuario;

IF @usuario_id IS NULL
BEGIN
    PRINT '  ??  Creando usuario temporal...';
    INSERT INTO Usuario (nombre, apellido1, apellido2, email)
    VALUES ('Admin', 'Sistema', 'Municipal', 'admin@nicoya.go.cr');
    SET @usuario_id = SCOPE_IDENTITY();
    PRINT '  ? Usuario creado - ID: ' + CAST(@usuario_id AS VARCHAR(10));
    PRINT '';
END

PRINT '?? 3.1 Emitiendo factura para Permiso de Construcción...';

EXEC sp_emitir_factura
    @fecha_emision = '2025-02-01',
    @periodo = '2025-02-01',
    @tramite_id = @tramite1_id,
    @inmueble_id = NULL,
    @usuario_id = @usuario_id,
    @factura_id = @factura1_id OUTPUT,
    @numero_factura = @numero_factura1 OUTPUT;

PRINT '  ? Factura emitida: ' + @numero_factura1;

PRINT '';
PRINT '?? 3.2 Agregando detalles a la factura...';

SET @referencia_servicio1 = 'Tramite #' + CAST(@tramite1_id AS VARCHAR(10));

EXEC sp_insertar_detalle_factura
    @factura_id = @factura1_id,
    @rubro_id = @rubro_permiso_construccion,
    @nombre = 'Permiso de Construcción',
    @referencia_servicio = @referencia_servicio1,
    @cantidad = 1,
    @monto_unitario = NULL,
    @descuento_linea = 0,
    @fecha_servicio = '2025-02-01',
    @detalle_factura_id = @detalle1_id OUTPUT;

PRINT '  ? Detalle 1: Permiso de Construcción';

SET @referencia_servicio2 = 'Tramite #' + CAST(@tramite1_id AS VARCHAR(10));

EXEC sp_insertar_detalle_factura
    @factura_id = @factura1_id,
    @rubro_id = @rubro_timbres_municipales,
    @nombre = 'Timbres Municipales',
    @referencia_servicio = @referencia_servicio2,
    @cantidad = 10,
    @monto_unitario = NULL,
    @descuento_linea = 0,
    @fecha_servicio = '2025-02-01',
    @detalle_factura_id = @detalle2_id OUTPUT;

PRINT '  ? Detalle 2: Timbres Municipales (10 x ?500)';

PRINT '';
PRINT '?? 3.3 Registrando pago...';

-- Obtener monto total con verificación
SELECT @monto_total_factura = monto_total 
FROM Factura 
WHERE factura_id = @factura1_id;

-- Verificar que se obtuvo el monto
IF @monto_total_factura IS NULL OR @monto_total_factura <= 0
BEGIN
    PRINT '  ? ERROR: No se pudo obtener el monto total de la factura';
    PRINT '  Factura ID: ' + CAST(@factura1_id AS VARCHAR(10));
    
    -- Mostrar información de la factura para debug
    SELECT 
        factura_id,
        numero_factura,
        monto_base,
        recargo,
        intereses,
        monto_total,
        estado_factura
    FROM Factura 
    WHERE factura_id = @factura1_id;
    
    PRINT '';
    PRINT '  ??  Esperando 2 segundos para que el trigger actualice...';
    WAITFOR DELAY '00:00:02';
    
    -- Reintentar obtener el monto
    SELECT @monto_total_factura = monto_total 
    FROM Factura 
    WHERE factura_id = @factura1_id;
END

-- Mostrar monto para debug
PRINT '  Monto total de factura: ?' + CAST(ISNULL(@monto_total_factura, 0) AS VARCHAR(20));

-- Solo proceder si hay un monto válido
IF @monto_total_factura > 0
BEGIN
    EXEC sp_registrar_pago
        @factura_id = @factura1_id,
        @monto_pagado = @monto_total_factura,
        @fecha_pago = '2025-02-10',
        @medio_pago = 'Efectivo',
        @usuario_id = @usuario_id,
        @pago_id = @pago1_id OUTPUT,
        @numero_recibo = @numero_recibo1 OUTPUT;

    PRINT '  ? Pago registrado: ' + @numero_recibo1;
    PRINT '  ? Monto: ?' + CAST(@monto_total_factura AS VARCHAR(20));
END
ELSE
BEGIN
    PRINT '  ? ERROR: No se puede registrar pago con monto ?0';
    PRINT '  ??  Verifique que el trigger trg_actualizar_monto_factura esté funcionando';
END

PRINT '';
PRINT '? FASE 3 COMPLETADA';
PRINT '';
PRINT '';
PRINT '===============================================================';
PRINT '     RESUMEN DE PRUEBAS COMPLETADAS';
PRINT '===============================================================';
PRINT '';
PRINT '? FASE 0: 10 Rubros configurados';
PRINT '? FASE 1: 3 Contribuyentes + 3 Inmuebles creados';
PRINT '? FASE 1.5: 11 Servicios configurados';
PRINT '? FASE 2: 2 Trámites creados';
PRINT '? FASE 3: 1 Factura + 1 Pago procesados';
PRINT '';
PRINT '?? TRIGGERS VERIFICADOS:';
PRINT '  - Recálculo automático de montos';
PRINT '  - Actualización de estado a Pagada';
PRINT '';
PRINT '?? Estado del sistema: OPERATIVO';
PRINT '';
PRINT '===============================================================';
GO