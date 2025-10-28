-- =============================================






-- MÓDULO: COBROS Y PAGOS
-- Script: Creación de Tablas
-- Descripción: Tablas para gestión de facturas, pagos y rubros
-- =============================================

USE MunicipalidadNicoya;
GO

-- =============================================
-- ELIMINAR RESTRICCIONES FK ANTES DE DROP
-- =============================================

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Pago_Factura')
    ALTER TABLE dbo.Pago DROP CONSTRAINT FK_Pago_Factura;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Pago_Usuario')
    ALTER TABLE dbo.Pago DROP CONSTRAINT FK_Pago_Usuario;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DetalleFactura_Factura')
    ALTER TABLE dbo.Detalle_factura DROP CONSTRAINT FK_DetalleFactura_Factura;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_DetalleFactura_Rubro')
    ALTER TABLE dbo.Detalle_factura DROP CONSTRAINT FK_DetalleFactura_Rubro;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Factura_Tramite')
    ALTER TABLE dbo.Factura DROP CONSTRAINT FK_Factura_Tramite;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Factura_Inmueble')
    ALTER TABLE dbo.Factura DROP CONSTRAINT FK_Factura_Inmueble;

-- Índices
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Factura_EstadoFactura')
    DROP INDEX IX_Factura_EstadoFactura ON dbo.Factura;

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Factura_FechaEmision')
    DROP INDEX IX_Factura_FechaEmision ON dbo.Factura;

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Factura_TramiteId')
    DROP INDEX IX_Factura_TramiteId ON dbo.Factura;

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Factura_InmuebleId')
    DROP INDEX IX_Factura_InmuebleId ON dbo.Factura;

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Pago_FacturaId')
    DROP INDEX IX_Pago_FacturaId ON dbo.Pago;

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Pago_FechaPago')
    DROP INDEX IX_Pago_FechaPago ON dbo.Pago;

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DetalleFactura_FacturaId')
    DROP INDEX IX_DetalleFactura_FacturaId ON dbo.Detalle_factura;

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DetalleFactura_RubroId')
    DROP INDEX IX_DetalleFactura_RubroId ON dbo.Detalle_factura;

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Rubro_Vigencia')
    DROP INDEX IX_Rubro_Vigencia ON dbo.Rubro;



PRINT '✓ Restricciones e índices eliminados';
GO

-- =============================================
-- ELIMINAR TABLAS SI EXISTEN
-- =============================================

IF OBJECT_ID('dbo.Pago', 'U') IS NOT NULL
    DROP TABLE dbo.Pago;
GO

IF OBJECT_ID('dbo.Detalle_factura', 'U') IS NOT NULL
    DROP TABLE dbo.Detalle_factura;
GO

IF OBJECT_ID('dbo.Factura', 'U') IS NOT NULL
    DROP TABLE dbo.Factura;
GO

IF OBJECT_ID('dbo.Rubro', 'U') IS NOT NULL
    DROP TABLE dbo.Rubro;
GO


PRINT '✓ Tablas eliminadas';
GO

-- =============================================
-- TABLA CATÁLOGO: Rubro
-- =============================================
CREATE TABLE dbo.Rubro
(
    rubro_id INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(300) NULL,
    periodicidad VARCHAR(20) NULL,
    tarifa_base DECIMAL(12,2) NOT NULL DEFAULT 0, 
    vigencia BIT NOT NULL DEFAULT 1,
    aplica_recargo BIT NOT NULL DEFAULT 0,
    aplica_intereses BIT NOT NULL DEFAULT 0,
    tasa_interes DECIMAL(5,2) NULL DEFAULT 0,
    tasa_recargo DECIMAL(5,2) NULL DEFAULT 0,
    fecha_creacion DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    
    CONSTRAINT PK_Rubro PRIMARY KEY (rubro_id),
    CONSTRAINT UQ_Rubro_Nombre UNIQUE (nombre),
    CONSTRAINT CK_Rubro_Periodicidad 
        CHECK (periodicidad IN ('Mensual', 'Trimestral', 'Anual', 'Único') OR periodicidad IS NULL),
    CONSTRAINT CK_Rubro_TarifaBase 
        CHECK (tarifa_base >= 0), 
    CONSTRAINT CK_Rubro_TasaInteres 
        CHECK (tasa_interes >= 0 AND tasa_interes <= 100),
    CONSTRAINT CK_Rubro_TasaRecargo 
        CHECK (tasa_recargo >= 0 AND tasa_recargo <= 100)
);
GO

CREATE INDEX IX_Rubro_Vigencia ON dbo.Rubro(vigencia);
GO

-- Insertar rubros comunes municipales
INSERT INTO dbo.Rubro (nombre, descripcion, periodicidad, tarifa_base, vigencia, aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo) 
VALUES
('Impuesto Territorial', 'Impuesto sobre bienes inmuebles', 'Trimestral', 15000, 1, 1, 1, 2.5, 1.0),
('Licencia Comercial', 'Licencia para ejercer actividad comercial', 'Anual', 25000, 1, 1, 0, 0, 1.5),
('Patente Municipal', 'Patente para comercio o servicio', 'Anual', 20000, 1, 1, 1, 2.0, 1.0),
('Servicio de Agua', 'Cobro por suministro de agua potable', 'Mensual', 12000, 1, 0, 0, 0, 0),
('Servicio de Basura', 'Recolección y manejo de desechos', 'Mensual', 8500, 1, 0, 0, 0, 0),
('Permiso de Construcción', 'Permiso para construcción o remodelación', 'Único', 50000, 1, 0, 0, 0, 0),
('Permiso de Rótulo', 'Permiso para instalación de rótulos', 'Único', 15000, 1, 0, 0, 0, 0),
('Certificación de Uso de Suelo', 'Certificado de uso de suelo', 'Único', 10000, 1, 0, 0, 0, 0),
('Otros Servicios', 'Servicios varios municipales', NULL, 0, 1, 0, 0, 0, 0);
GO

PRINT '✓ Tabla Rubro creada con datos iniciales (incluye tarifa_base)';
GO

-- =============================================
-- TABLA: Factura
-- =============================================
CREATE TABLE dbo.Factura
(
    factura_id INT IDENTITY(1,1) NOT NULL,
    numero_factura VARCHAR(50) NOT NULL,
    fecha_emision DATETIME NOT NULL DEFAULT GETDATE(),
    fecha_vencimiento DATE NOT NULL,
    periodo DATE NULL,
    monto_base DECIMAL(12,2) NOT NULL DEFAULT 0,
    recargo DECIMAL(12,2) NOT NULL DEFAULT 0,
    intereses DECIMAL(12,2) NOT NULL DEFAULT 0,
    monto_total DECIMAL(12,2) NOT NULL DEFAULT 0,
    estado_factura VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    tramite_id INT NULL,
    inmueble_id INT NULL,
    
    CONSTRAINT PK_Factura PRIMARY KEY (factura_id),
    CONSTRAINT UQ_Factura_NumeroFactura UNIQUE (numero_factura),
    CONSTRAINT FK_Factura_Tramite 
        FOREIGN KEY (tramite_id) REFERENCES dbo.Tramite(tramite_id),
    CONSTRAINT FK_Factura_Inmueble 
        FOREIGN KEY (inmueble_id) REFERENCES dbo.Inmueble(inmueble_id),
    CONSTRAINT CK_Factura_EstadoFactura 
        CHECK (estado_factura IN ('Pendiente', 'Pagada', 'Vencida', 'Cancelada')),
    CONSTRAINT CK_Factura_FechaVencimiento 
        CHECK (fecha_vencimiento >= CAST(fecha_emision AS DATE)),
    CONSTRAINT CK_Factura_MontoBase 
        CHECK (monto_base >= 0),
    CONSTRAINT CK_Factura_Recargo 
        CHECK (recargo >= 0),
    CONSTRAINT CK_Factura_Intereses 
        CHECK (intereses >= 0),
    CONSTRAINT CK_Factura_MontoTotal 
        CHECK (monto_total >= 0),
    CONSTRAINT CK_Factura_ReferenciaRequerida 
        CHECK (tramite_id IS NOT NULL OR inmueble_id IS NOT NULL)
);
GO

CREATE INDEX IX_Factura_EstadoFactura ON dbo.Factura(estado_factura);
CREATE INDEX IX_Factura_FechaEmision ON dbo.Factura(fecha_emision);
CREATE INDEX IX_Factura_TramiteId ON dbo.Factura(tramite_id);
CREATE INDEX IX_Factura_InmuebleId ON dbo.Factura(inmueble_id);
GO

PRINT '✓ Tabla Factura creada';
GO

-- =============================================
-- TABLA: Detalle_factura
-- =============================================
CREATE TABLE dbo.Detalle_factura
(
    detalle_factura_id INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    referencia_servicio VARCHAR(100) NULL,
    cantidad INT NOT NULL DEFAULT 1,
    monto_unitario DECIMAL(12,2) NOT NULL,
    descuento_linea DECIMAL(12,2) NOT NULL DEFAULT 0,
    fecha_servicio DATE NULL,
    factura_id INT NOT NULL,
    rubro_id INT NOT NULL,
    
    CONSTRAINT PK_DetalleFactura PRIMARY KEY (detalle_factura_id),
    CONSTRAINT FK_DetalleFactura_Factura 
        FOREIGN KEY (factura_id) REFERENCES dbo.Factura(factura_id)
        ON DELETE CASCADE,
    CONSTRAINT FK_DetalleFactura_Rubro 
        FOREIGN KEY (rubro_id) REFERENCES dbo.Rubro(rubro_id),
    CONSTRAINT CK_DetalleFactura_Cantidad 
        CHECK (cantidad > 0),
    CONSTRAINT CK_DetalleFactura_MontoUnitario 
        CHECK (monto_unitario >= 0),
    CONSTRAINT CK_DetalleFactura_DescuentoLinea 
        CHECK (descuento_linea >= 0)
);
GO

CREATE INDEX IX_DetalleFactura_FacturaId ON dbo.Detalle_factura(factura_id);
CREATE INDEX IX_DetalleFactura_RubroId ON dbo.Detalle_factura(rubro_id);
GO

PRINT '✓ Tabla Detalle_factura creada';
GO

-- =============================================
-- TABLA: Pago
-- =============================================
CREATE TABLE dbo.Pago
(
    pago_id INT IDENTITY(1,1) NOT NULL,
    monto_pagado DECIMAL(12,2) NOT NULL,
    fecha_pago DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    medio_pago VARCHAR(20) NOT NULL DEFAULT 'Efectivo',
    numero_recibo VARCHAR(50) NOT NULL,
    usuario_id INT NOT NULL,
    factura_id INT NOT NULL,
    
    CONSTRAINT PK_Pago PRIMARY KEY (pago_id),
    CONSTRAINT UQ_Pago_NumeroRecibo UNIQUE (numero_recibo),
    CONSTRAINT FK_Pago_Factura 
        FOREIGN KEY (factura_id) REFERENCES dbo.Factura(factura_id),
    CONSTRAINT FK_Pago_Usuario 
        FOREIGN KEY (usuario_id) REFERENCES dbo.Usuario(usuario_id),
    CONSTRAINT CK_Pago_MontoPagado 
        CHECK (monto_pagado > 0),
    CONSTRAINT CK_Pago_MedioPago 
        CHECK (medio_pago IN ('Efectivo'))
);
GO

CREATE INDEX IX_Pago_FacturaId ON dbo.Pago(factura_id);
CREATE INDEX IX_Pago_FechaPago ON dbo.Pago(fecha_pago);
GO

PRINT '✓ Tabla Pago creada';
GO




