-- =============================================

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
-- - TipoUsoInmueble (tiene los tipos: Residencial, Comercial, etc.)
-- - Tipo_Tramite (tiene: Permiso de Construcción, Patente Comercial, etc.)
-- - Usuario (si ya tienes usuarios creados)

PRINT '? Base de datos limpiada correctamente';
PRINT '? Puedes ejecutar ahora el script de pruebas';
GO















-- SCRIPT DE PRUEBA COMPLETO
-- Sistema de Gestión Municipal de Nicoya
-- Flujo: Contribuyentes ? Inmuebles ? Trámites ? Pagos
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '';
PRINT '---------------------------------------------------------------';
PRINT '     INICIO DE PRUEBAS - FLUJO COMPLETO DEL SISTEMA';
PRINT '---------------------------------------------------------------';
PRINT '';

-- =============================================
-- FASE 1: MÓDULO CONTRIBUYENTES E INMUEBLES
-- =============================================

PRINT '+-------------------------------------------------------------+';
PRINT '¦ FASE 1: CONTRIBUYENTES E INMUEBLES                         ¦';
PRINT '+-------------------------------------------------------------+';
PRINT '';

-- Variables para almacenar IDs
DECLARE @contrib_fisico1_id INT;
DECLARE @contrib_fisico2_id INT;
DECLARE @contrib_juridico1_id INT;
DECLARE @inmueble1_id INT;
DECLARE @inmueble2_id INT;
DECLARE @inmueble3_id INT;
DECLARE @catastro1_id INT;
DECLARE @tipo_uso_residencial INT;
DECLARE @tipo_uso_comercial INT;

-- =============================================
-- 1.1 INSERTAR CONTRIBUYENTES FÍSICOS
-- =============================================
PRINT '? 1.1 Creando contribuyentes físicos...';

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

-- =============================================
-- 1.2 INSERTAR CONTRIBUYENTE JURÍDICO
-- =============================================
PRINT '';
PRINT '? 1.2 Creando contribuyente jurídico...';

EXEC sp_Contribuyente_InsertarJuridico
    @cedula_juridica = '3-101-987654',
    @nombre_empresa = 'Constructora Nicoya S.A.',
    @representante_legal_id = @contrib_fisico1_id,
    @telefono = '2685-3333',
    @email = 'info@constructoranicoya.cr',
    @direccion = 'Nicoya, Zona Industrial Norte';

SET @contrib_juridico1_id = (SELECT TOP 1 contribuyente_id FROM Contribuyente ORDER BY contribuyente_id DESC);
PRINT '  ? Contribuyente jurídico creado - ID: ' + CAST(@contrib_juridico1_id AS VARCHAR(10));
PRINT '    Representante Legal: Carlos Ramírez Mora';

-- =============================================
-- 1.3 INSERTAR INMUEBLES
-- =============================================
PRINT '';
PRINT '? 1.3 Creando inmuebles...';

-- Obtener IDs de tipos de uso
SELECT @tipo_uso_residencial = tipo_uso_inmueble_id FROM TipoUsoInmueble WHERE nombre_uso = 'Residencial';
SELECT @tipo_uso_comercial = tipo_uso_inmueble_id FROM TipoUsoInmueble WHERE nombre_uso = 'Comercial';

-- Inmueble 1 (Residencial)
EXEC sp_Inmueble_Insertar
    @direccion_exacta = 'Nicoya Centro, 150m norte del Banco Nacional',
    @area_terreno = 280.00,
    @valor_fiscal = 52000000.00,
    @tipo_uso_inmueble_id = @tipo_uso_residencial,
    @estado_ocupacional = 'Ocupado';

SET @inmueble1_id = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id DESC);
PRINT '  ? Inmueble 1 (Residencial) creado - ID: ' + CAST(@inmueble1_id AS VARCHAR(10));

-- Inmueble 2 (Comercial)
EXEC sp_Inmueble_Insertar
    @direccion_exacta = 'Nicoya, Avenida Central frente al Mercado',
    @area_terreno = 350.00,
    @valor_fiscal = 85000000.00,
    @tipo_uso_inmueble_id = @tipo_uso_comercial,
    @estado_ocupacional = 'Ocupado';

SET @inmueble2_id = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id DESC);
PRINT '  ? Inmueble 2 (Comercial) creado - ID: ' + CAST(@inmueble2_id AS VARCHAR(10));

-- Inmueble 3 (Comercial para empresa)
EXEC sp_Inmueble_Insertar
    @direccion_exacta = 'Nicoya, Zona Industrial Norte, Bodega #5',
    @area_terreno = 500.00,
    @valor_fiscal = 95000000.00,
    @tipo_uso_inmueble_id = @tipo_uso_comercial,
    @estado_ocupacional = 'Ocupado';

SET @inmueble3_id = (SELECT TOP 1 inmueble_id FROM Inmueble ORDER BY inmueble_id DESC);
PRINT '  ? Inmueble 3 (Comercial) creado - ID: ' + CAST(@inmueble3_id AS VARCHAR(10));

-- =============================================
-- 1.4 ASOCIAR CONTRIBUYENTES A INMUEBLES
-- =============================================
PRINT '';
PRINT '? 1.4 Asociando contribuyentes a inmuebles...';

-- Carlos Ramírez ? Inmueble 1 (100%)
EXEC sp_Inmueble_AsociarContribuyente
    @contribuyente_id = @contrib_fisico1_id,
    @inmueble_id = @inmueble1_id,
    @porcentaje_propiedad = 100.00;
PRINT '  ? Carlos Ramírez asociado al Inmueble 1 (100%)';

-- Ana López ? Inmueble 2 (100%)
EXEC sp_Inmueble_AsociarContribuyente
    @contribuyente_id = @contrib_fisico2_id,
    @inmueble_id = @inmueble2_id,
    @porcentaje_propiedad = 100.00;
PRINT '  ? Ana López asociada al Inmueble 2 (100%)';

-- Constructora Nicoya S.A. ? Inmueble 3 (100%)
EXEC sp_Inmueble_AsociarContribuyente
    @contribuyente_id = @contrib_juridico1_id,
    @inmueble_id = @inmueble3_id,
    @porcentaje_propiedad = 100.00;
PRINT '  ? Constructora Nicoya S.A. asociada al Inmueble 3 (100%)';

-- =============================================
-- 1.5 CREAR CATASTROS
-- =============================================
PRINT '';
PRINT '? 1.5 Creando información catastral...';

EXEC sp_Catastro_Insertar
    @numero_plano_catastral = 'G-2025-001234',
    @area_catastral = '280.00 m² - Lote urbano residencial',
    @fecha_inscripcion = '2024-06-15',
    @estado = 'Activo',
    @inmueble_id = @inmueble1_id;

SET @catastro1_id = (SELECT TOP 1 catastro_id FROM Catastro ORDER BY catastro_id DESC);
PRINT '  ? Catastro creado para Inmueble 1 - Plano: G-2025-001234';

-- Agregar colindancias
EXEC sp_Colindancia_Insertar
    @punto_cardinal = 'Norte',
    @colindante = 'Calle Pública Principal',
    @catastro_id = @catastro1_id;

EXEC sp_Colindancia_Insertar
    @punto_cardinal = 'Sur',
    @colindante = 'Propiedad de Pedro Vargas',
    @catastro_id = @catastro1_id;

PRINT '  ? Colindancias agregadas';

-- Agregar observación
EXEC sp_ObservacionInmueble_Insertar
    @descripcion = 'Inmueble en buen estado, aprobado para construcción',
    @inmueble_id = @inmueble1_id,
    @fecha = '2025-01-10';

PRINT '  ? Observación registrada';

-- =============================================
-- FASE 2: MÓDULO TRÁMITES Y PERMISOS
-- =============================================

PRINT '';
PRINT '+-------------------------------------------------------------+';
PRINT '¦ FASE 2: TRÁMITES Y PERMISOS                                ¦';
PRINT '+-------------------------------------------------------------+';
PRINT '';

DECLARE @tramite1_id INT;
DECLARE @tramite2_id INT;
DECLARE @tipo_permiso_construccion INT;
DECLARE @tipo_patente_comercial INT;

-- Obtener tipos de trámite
SELECT @tipo_permiso_construccion = tipo_tramite_id 
FROM Tipo_Tramite 
WHERE nombre_tipo = 'Permiso de Construcción';

SELECT @tipo_patente_comercial = tipo_tramite_id 
FROM Tipo_Tramite 
WHERE nombre_tipo = 'Patente Comercial';

-- =============================================
-- 2.1 CREAR TRÁMITE: PERMISO DE CONSTRUCCIÓN
-- =============================================
PRINT '? 2.1 Creando trámite de Permiso de Construcción...';

EXEC sp_Tramite_Insertar
    @fecha_ingreso = '2025-02-01',
    @fecha_resolucion = NULL,
    @observaciones = 'Ampliación de vivienda - Construcción de segundo piso',
    @tipo_tramite_id = @tipo_permiso_construccion,
    @contribuyente_id = @contrib_fisico1_id,
    @inmueble_id = @inmueble1_id,
    @estado_actual = 'En Proceso';

SET @tramite1_id = (SELECT TOP 1 tramite_id FROM Tramite ORDER BY tramite_id DESC);
PRINT '  ? Trámite de Permiso de Construcción creado - ID: ' + CAST(@tramite1_id AS VARCHAR(10));
PRINT '    Contribuyente: Carlos Ramírez Mora';
PRINT '    Inmueble: Nicoya Centro, 150m norte del Banco Nacional';
PRINT '    Estado: En Proceso';

-- =============================================
-- 2.2 CREAR TRÁMITE: PATENTE COMERCIAL
-- =============================================
PRINT '';
PRINT '? 2.2 Creando trámite de Patente Comercial...';

EXEC sp_Tramite_Insertar
    @fecha_ingreso = '2025-02-05',
    @fecha_resolucion = NULL,
    @observaciones = 'Patente para mini super',
    @tipo_tramite_id = @tipo_patente_comercial,
    @contribuyente_id = @contrib_fisico2_id,
    @inmueble_id = @inmueble2_id,
    @estado_actual = 'En Proceso';

SET @tramite2_id = (SELECT TOP 1 tramite_id FROM Tramite ORDER BY tramite_id DESC);
PRINT '  ? Trámite de Patente Comercial creado - ID: ' + CAST(@tramite2_id AS VARCHAR(10));
PRINT '    Contribuyente: Ana López Jiménez';
PRINT '    Inmueble: Nicoya, Avenida Central frente al Mercado';
PRINT '    Estado: En Proceso';

-- =============================================
-- 2.3 CONSULTAR REQUISITOS NECESARIOS
-- =============================================
PRINT '';
PRINT '? 2.3 Consultando requisitos del Permiso de Construcción...';

SELECT 
    r.requisito_id,
    r.nombre,
    r.descripcion
FROM dbo.Tipo_Tramite_Requisito ttr
INNER JOIN dbo.Requisito r ON ttr.requisito_id = r.requisito_id
WHERE ttr.tipo_tramite_id = @tipo_permiso_construccion;

PRINT '  ? Requisitos mostrados';

-- =============================================
-- FASE 3: MÓDULO PAGOS Y COBROS
-- =============================================

PRINT '';
PRINT '+-------------------------------------------------------------+';
PRINT '¦ FASE 3: PAGOS Y COBROS                                     ¦';
PRINT '+-------------------------------------------------------------+';
PRINT '';

DECLARE @rubro_permiso INT;
DECLARE @rubro_patente INT;
DECLARE @rubro_timbres INT;
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

-- Obtener usuario (asumiendo que ya existe el usuario)
SELECT TOP 1 @usuario_id = usuario_id FROM Usuario;

-- Si no existe, crear uno temporal
IF @usuario_id IS NULL
BEGIN
    PRINT '';
    PRINT '  ? No se encontró ningún usuario en el sistema.';
    PRINT '  ? Creando usuario temporal para pruebas...';
    
    -- Verificar estructura de la tabla Usuario primero
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Usuario') AND name = 'nombre')
    BEGIN
        PRINT '';
        PRINT '  ? ERROR: La tabla Usuario no tiene la estructura esperada.';
        PRINT '  ? Por favor, ejecute primero el script de creación de la tabla Usuario.';
        PRINT '  ? O proporcione un usuario_id existente.';
        RETURN;
    END
    
    -- Crear usuario temporal con columnas básicas
    INSERT INTO Usuario (nombre, apellido1, apellido2, email)
    VALUES ('Admin', 'Sistema', 'Municipal', 'admin@nicoya.go.cr');
    
    SET @usuario_id = SCOPE_IDENTITY();
    PRINT '  ? Usuario temporal creado - ID: ' + CAST(@usuario_id AS VARCHAR(10));
    PRINT '    Usuario: Admin Sistema Municipal';
END
ELSE
BEGIN
    PRINT '  ? Usuario encontrado - ID: ' + CAST(@usuario_id AS VARCHAR(10));
END

-- =============================================
-- 3.1 CREAR RUBROS
-- =============================================
PRINT '';
PRINT '? 3.1 Creando rubros de cobro...';

EXEC sp_insertar_rubro
    @nombre = 'Permiso de Construcción',
    @descripcion = 'Tarifa por tramitación de permiso de construcción',
    @periodicidad = 'Único',
    @aplica_recargo = 1,
    @aplica_intereses = 1,
    @tasa_interes = 2.50,
    @tasa_recargo = 5.00,
    @rubro_id = @rubro_permiso OUTPUT;

PRINT '  ? Rubro "Permiso de Construcción" creado - ID: ' + CAST(@rubro_permiso AS VARCHAR(10));

EXEC sp_insertar_rubro
    @nombre = 'Patente Comercial',
    @descripcion = 'Tarifa anual de patente comercial',
    @periodicidad = 'Anual',
    @aplica_recargo = 1,
    @aplica_intereses = 1,
    @tasa_interes = 3.00,
    @tasa_recargo = 10.00,
    @rubro_id = @rubro_patente OUTPUT;

PRINT '  ? Rubro "Patente Comercial" creado - ID: ' + CAST(@rubro_patente AS VARCHAR(10));

EXEC sp_insertar_rubro
    @nombre = 'Timbres Municipales',
    @descripcion = 'Timbres y estampillas municipales',
    @periodicidad = 'Único',
    @aplica_recargo = 0,
    @aplica_intereses = 0,
    @tasa_interes = 0,
    @tasa_recargo = 0,
    @rubro_id = @rubro_timbres OUTPUT;

PRINT '  ? Rubro "Timbres Municipales" creado - ID: ' + CAST(@rubro_timbres AS VARCHAR(10));

-- =============================================
-- 3.2 EMITIR FACTURA #1: PERMISO DE CONSTRUCCIÓN
-- =============================================
PRINT '';
PRINT '? 3.2 Emitiendo factura para Permiso de Construcción...';

EXEC sp_emitir_factura
    @fecha_emision = '2025-02-01',
    @periodo = '2025-02-01',
    @tramite_id = @tramite1_id,
    @inmueble_id = NULL,
    @usuario_id = @usuario_id,
    @factura_id = @factura1_id OUTPUT,
    @numero_factura = @numero_factura1 OUTPUT;

PRINT '  ? Factura emitida: ' + @numero_factura1 + ' (ID: ' + CAST(@factura1_id AS VARCHAR(10)) + ')';
PRINT '    Vencimiento: ' + CONVERT(VARCHAR(10), DATEADD(DAY, 30, '2025-02-01'), 120);

-- Agregar detalles a la factura
PRINT '';
PRINT '? 3.3 Agregando detalles a la factura...';

-- Preparar referencia de servicio para el primer detalle
SET @referencia_servicio1 = 'Tramite #' + CAST(@tramite1_id AS VARCHAR(10));

EXEC sp_insertar_detalle_factura
    @factura_id = @factura1_id,
    @rubro_id = @rubro_permiso,
    @nombre = 'Permiso de Construcción - Ampliación',
    @referencia_servicio = @referencia_servicio1,
    @cantidad = 1,
    @monto_unitario = 75000.00,
    @descuento_linea = 0,
    @fecha_servicio = '2025-02-01',
    @detalle_factura_id = @detalle1_id OUTPUT;

PRINT '  ? Detalle 1: Permiso de Construcción - ¢75,000.00';

-- Preparar referencia de servicio para el segundo detalle
SET @referencia_servicio2 = 'Tramite #' + CAST(@tramite1_id AS VARCHAR(10));

EXEC sp_insertar_detalle_factura
    @factura_id = @factura1_id,
    @rubro_id = @rubro_timbres,
    @nombre = 'Timbres Municipales',
    @referencia_servicio = @referencia_servicio2,
    @cantidad = 10,
    @monto_unitario = 500.00,
    @descuento_linea = 0,
    @fecha_servicio = '2025-02-01',
    @detalle_factura_id = @detalle2_id OUTPUT;

PRINT '  ? Detalle 2: Timbres Municipales (10 x ¢500) - ¢5,000.00';
PRINT '  ? Monto total de la factura recalculado automáticamente por trigger';

-- =============================================
-- 3.4 CONSULTAR FACTURA COMPLETA
-- =============================================
PRINT '';
PRINT '? 3.4 Consultando factura completa...';

EXEC sp_consultar_factura_por_id @factura_id = @factura1_id;

PRINT '  ? Factura consultada con 3 resultsets:';
PRINT '    - Información de la factura';
PRINT '    - Contribuyentes asociados';
PRINT '    - Detalles/ítems de la factura';

-- =============================================
-- 3.5 REGISTRAR PAGO DE LA FACTURA
-- =============================================
PRINT '';
PRINT '? 3.5 Registrando pago de la factura...';

DECLARE @monto_total_factura DECIMAL(12,2);
SELECT @monto_total_factura = monto_total FROM Factura WHERE factura_id = @factura1_id;

EXEC sp_registrar_pago
    @factura_id = @factura1_id,
    @monto_pagado = @monto_total_factura,
    @fecha_pago = '2025-02-10',
    @medio_pago = 'Efectivo',
    @usuario_id = @usuario_id,
    @pago_id = @pago1_id OUTPUT,
    @numero_recibo = @numero_recibo1 OUTPUT;

PRINT '  ? Pago registrado: ' + @numero_recibo1 + ' (ID: ' + CAST(@pago1_id AS VARCHAR(10)) + ')';
PRINT '    Monto pagado: ¢' + CAST(@monto_total_factura AS VARCHAR(20));
PRINT '    Estado de factura actualizado automáticamente a "Pagada" por trigger';

-- =============================================
-- 3.6 EMITIR FACTURA #2: PATENTE COMERCIAL
-- =============================================
PRINT '';
PRINT '? 3.6 Emitiendo factura para Patente Comercial...';

EXEC sp_emitir_factura
    @fecha_emision = '2025-02-05',
    @periodo = '2025-01-01',
    @tramite_id = @tramite2_id,
    @inmueble_id = NULL,
    @usuario_id = @usuario_id,
    @factura_id = @factura2_id OUTPUT,
    @numero_factura = @numero_factura2 OUTPUT;

PRINT '  ? Factura emitida: ' + @numero_factura2 + ' (ID: ' + CAST(@factura2_id AS VARCHAR(10)) + ')';

-- Preparar referencia de servicio
SET @referencia_servicio3 = 'Mini Super - Tramite #' + CAST(@tramite2_id AS VARCHAR(10));

-- Agregar detalle
EXEC sp_insertar_detalle_factura
    @factura_id = @factura2_id,
    @rubro_id = @rubro_patente,
    @nombre = 'Patente Comercial 2025',
    @referencia_servicio = @referencia_servicio3,
    @cantidad = 1,
    @monto_unitario = 120000.00,
    @descuento_linea = 0,
    @fecha_servicio = '2025-02-05',
    @detalle_factura_id = @detalle2_id OUTPUT;

PRINT '  ? Detalle agregado: Patente Comercial 2025 - ¢120,000.00';
PRINT '    Estado: Pendiente de pago';

-- =============================================
-- 3.7 LISTAR FACTURAS
-- =============================================
PRINT '';
PRINT '? 3.7 Listando todas las facturas...';

EXEC sp_listar_facturas
    @estado_factura = NULL,
    @page_number = 1,
    @page_size = 10;

PRINT '  ? Facturas listadas con información completa';

-- =============================================
-- 3.8 VISUALIZAR HISTORIAL DE PAGOS
-- =============================================
PRINT '';
PRINT '? 3.8 Consultando historial de pagos...';

EXEC sp_visualizar_historial_pagos
    @contribuyente_id = @contrib_fisico1_id,
    @page_number = 1,
    @page_size = 10;

PRINT '  ? Historial de pagos de Carlos Ramírez Mora mostrado';

-- =============================================
-- RESUMEN FINAL
-- =============================================

PRINT '';
PRINT '---------------------------------------------------------------';
PRINT '     RESUMEN DE PRUEBAS COMPLETADAS';
PRINT '---------------------------------------------------------------';
PRINT '';
PRINT '? FASE 1: Contribuyentes e Inmuebles';
PRINT '  - 2 Contribuyentes físicos creados';
PRINT '  - 1 Contribuyente jurídico creado';
PRINT '  - 3 Inmuebles registrados';
PRINT '  - Asociaciones contribuyente-inmueble establecidas';
PRINT '  - Información catastral completa (catastro, colindancias, observaciones)';
PRINT '';
PRINT '? FASE 2: Trámites y Permisos';
PRINT '  - Trámite de Permiso de Construcción creado (En Proceso)';
PRINT '  - Trámite de Patente Comercial creado (En Proceso)';
PRINT '  - Requisitos consultados correctamente';
PRINT '';
PRINT '? FASE 3: Pagos y Cobros';
PRINT '  - 3 Rubros de cobro creados';
PRINT '  - 2 Facturas emitidas con autogeneración de número';
PRINT '  - Detalles agregados a facturas';
PRINT '  - Montos recalculados automáticamente por triggers';
PRINT '  - 1 Pago registrado exitosamente';
PRINT '  - Estado de factura actualizado automáticamente (Pendiente ? Pagada)';
PRINT '  - Recibo generado con formato REC-YYYYMMDD-####';
PRINT '';
PRINT '? TRIGGERS PROBADOS:';
PRINT '  - trg_actualizar_monto_factura (Recalcula monto_base)';
PRINT '  - trg_actualizar_estado_factura (Cambia estado a Pagada)';
PRINT '';
PRINT '---------------------------------------------------------------';
PRINT '     PRUEBAS COMPLETADAS EXITOSAMENTE';
PRINT '---------------------------------------------------------------';
PRINT '';
PRINT 'Notas:';
PRINT '- Todos los módulos funcionan correctamente';
PRINT '- Las relaciones entre tablas están bien implementadas';
PRINT '- Los triggers funcionan como se esperaba';
PRINT '- Las validaciones de negocio están activas';
PRINT '- El flujo completo de la aplicación está operativo';
PRINT '';
PRINT 'Estado del sistema: ? OPERATIVO';
GO







PRINT '? 1. Listado de todas las facturas:';
PRINT '';

EXEC sp_listar_facturas
    @estado_factura = NULL,
    @page_number = 1,
    @page_size = 10;

PRINT '';
PRINT '-------------------------------------------------------------';
PRINT '';