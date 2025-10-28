-- =============================================
-- DATAMART: REPORTES ADMINISTRATIVOS
-- Municipalidad de Nicoya - Esquema Estrella
-- Versión CORREGIDA - rubro_id permite NULL
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '========================================';
PRINT 'CREANDO DATAMART - ESQUEMA ESTRELLA';
PRINT '========================================';
PRINT '';
GO

-- =============================================
-- CREAR SCHEMA PARA EL DATAMART
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'DM')
    EXEC('CREATE SCHEMA DM');
GO

PRINT '✓ Schema DM creado';
GO

-- =============================================
-- LIMPIAR TABLAS EXISTENTES
-- =============================================

DROP TABLE IF EXISTS DM.FACT_Factura;
DROP TABLE IF EXISTS DM.DIM_Tiempo;
DROP TABLE IF EXISTS DM.DIM_Contribuyente;
DROP TABLE IF EXISTS DM.DIM_Inmueble;
DROP TABLE IF EXISTS DM.DIM_Rubro;
DROP TABLE IF EXISTS DM.DIM_Tramite;
DROP TABLE IF EXISTS DM.DIM_Estado_Factura;
GO

PRINT '✓ Tablas anteriores eliminadas (si existían)';
GO

-- =============================================
-- DIMENSIÓN: DIM_Tiempo
-- =============================================

CREATE TABLE DM.DIM_Tiempo (
    tiempo_id INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE UNIQUE NOT NULL,
    anio SMALLINT NOT NULL,
    trimestre TINYINT NOT NULL,
    mes TINYINT NOT NULL,
    mes_nombre VARCHAR(20) NOT NULL,
    dia TINYINT NOT NULL,
    dia_semana TINYINT NOT NULL,
    dia_semana_nombre VARCHAR(20) NOT NULL,
    semana_anio TINYINT NOT NULL,
    es_fin_semana BIT NOT NULL
);
GO

CREATE INDEX IX_Tiempo_Anio ON DM.DIM_Tiempo(anio);
CREATE INDEX IX_Tiempo_Mes ON DM.DIM_Tiempo(anio, mes);
GO

PRINT '✓ DIM_Tiempo creada';
GO

-- =============================================
-- DIMENSIÓN: DIM_Estado_Factura
-- =============================================

CREATE TABLE DM.DIM_Estado_Factura (
    estado_id INT IDENTITY(1,1) PRIMARY KEY,
    estado VARCHAR(20) UNIQUE NOT NULL,
    descripcion VARCHAR(100)
);
GO

PRINT '✓ DIM_Estado_Factura creada';
GO

-- =============================================
-- DIMENSIÓN: DIM_Contribuyente
-- =============================================

CREATE TABLE DM.DIM_Contribuyente (
    contribuyente_id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo_contribuyente VARCHAR(20) NOT NULL,
    cedula VARCHAR(20) NOT NULL,
    distrito VARCHAR(50),
    canton VARCHAR(50),
    telefono VARCHAR(20),
    email VARCHAR(100)
);
GO

CREATE INDEX IX_Contribuyente_Tipo ON DM.DIM_Contribuyente(tipo_contribuyente);
GO

PRINT '✓ DIM_Contribuyente creada';
GO

-- =============================================
-- DIMENSIÓN: DIM_Inmueble
-- =============================================

CREATE TABLE DM.DIM_Inmueble (
    inmueble_id INT PRIMARY KEY,
    numero_finca VARCHAR(50) NOT NULL,
    direccion_exacta VARCHAR(200),
    distrito VARCHAR(50),
    canton VARCHAR(50),
    area_terreno DECIMAL(12,2),
    area_construccion DECIMAL(12,2),
    uso_inmueble VARCHAR(50),
    estado_ocupacional VARCHAR(50),
    valor_fiscal DECIMAL(15,2)
);
GO

CREATE INDEX IX_Inmueble_Distrito ON DM.DIM_Inmueble(distrito);
GO

PRINT '✓ DIM_Inmueble creada';
GO

-- =============================================
-- DIMENSIÓN: DIM_Rubro
-- =============================================

CREATE TABLE DM.DIM_Rubro (
    rubro_id INT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(300),
    periodicidad VARCHAR(20),
    tarifa_base DECIMAL(12,2),
    aplica_recargo BIT NOT NULL,
    aplica_intereses BIT NOT NULL,
    tasa_interes DECIMAL(5,2),
    tasa_recargo DECIMAL(5,2)
);
GO

PRINT '✓ DIM_Rubro creada';
GO

-- =============================================
-- DIMENSIÓN: DIM_Tramite
-- =============================================

CREATE TABLE DM.DIM_Tramite (
    tramite_id INT PRIMARY KEY,
    tipo_tramite VARCHAR(50) NOT NULL,
    estado_tramite VARCHAR(20) NOT NULL,
    fecha_ingreso DATE,
    fecha_resolucion DATE,
    dias_resolucion INT
);
GO

PRINT '✓ DIM_Tramite creada';
GO

-- =============================================
-- TABLA DE HECHOS: FACT_Factura
-- ✅ CORRECCIÓN: rubro_id ahora permite NULL
-- =============================================

CREATE TABLE DM.FACT_Factura (
    fact_factura_id INT IDENTITY(1,1) PRIMARY KEY,
    factura_id INT NOT NULL,
    tiempo_emision_id INT NOT NULL,
    tiempo_vencimiento_id INT NOT NULL,
    contribuyente_id INT,
    inmueble_id INT,
    rubro_id INT NULL,  -- ✅ MODIFICADO: Ahora permite NULL
    tramite_id INT,
    estado_factura_id INT NOT NULL,
    
    -- Métricas
    monto_base DECIMAL(12,2) NOT NULL,
    recargo DECIMAL(12,2) NOT NULL,
    intereses DECIMAL(12,2) NOT NULL,
    monto_total DECIMAL(12,2) NOT NULL,
    cantidad_lineas INT NOT NULL,
    monto_pagado DECIMAL(12,2) NOT NULL,
    saldo_pendiente DECIMAL(12,2) NOT NULL,
    
    -- Flags
    esta_vencida BIT NOT NULL,
    esta_pagada BIT NOT NULL,
    dias_mora INT,
    
    fecha_carga DATETIME DEFAULT GETDATE(),
    
    -- Foreign Keys
    FOREIGN KEY (tiempo_emision_id) REFERENCES DM.DIM_Tiempo(tiempo_id),
    FOREIGN KEY (tiempo_vencimiento_id) REFERENCES DM.DIM_Tiempo(tiempo_id),
    FOREIGN KEY (contribuyente_id) REFERENCES DM.DIM_Contribuyente(contribuyente_id),
    FOREIGN KEY (inmueble_id) REFERENCES DM.DIM_Inmueble(inmueble_id),
    FOREIGN KEY (rubro_id) REFERENCES DM.DIM_Rubro(rubro_id),
    FOREIGN KEY (tramite_id) REFERENCES DM.DIM_Tramite(tramite_id),
    FOREIGN KEY (estado_factura_id) REFERENCES DM.DIM_Estado_Factura(estado_id)
);
GO

-- Índices para optimizar consultas
CREATE INDEX IX_FACT_TiempoEmision ON DM.FACT_Factura(tiempo_emision_id);
CREATE INDEX IX_FACT_Contribuyente ON DM.FACT_Factura(contribuyente_id);
CREATE INDEX IX_FACT_Rubro ON DM.FACT_Factura(rubro_id);
CREATE INDEX IX_FACT_Estado ON DM.FACT_Factura(estado_factura_id);
GO

PRINT '✓ FACT_Factura creada (rubro_id permite NULL)';
GO

PRINT '';
PRINT '========================================';
PRINT 'DATAMART CREADO EXITOSAMENTE';
PRINT '========================================';
PRINT '';
PRINT 'Tablas creadas:';
PRINT '  • 6 Dimensiones';
PRINT '  • 1 Tabla de Hechos';
PRINT '';
PRINT '✅ CORRECCIÓN APLICADA:';
PRINT '   rubro_id ahora permite NULL en FACT_Factura';
PRINT '   Esto soluciona el error al emitir facturas';
PRINT '';
GO