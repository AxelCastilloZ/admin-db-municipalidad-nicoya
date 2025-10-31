-- =============================================
-- DATAMART: REPORTES ADMINISTRATIVOS
-- Municipalidad de Nicoya - Esquema Estrella
-- Base de datos: MunicipalidadNicoyaDataMart
-- =============================================

USE MunicipalidadNicoyaDataMart;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'DM')
    EXEC('CREATE SCHEMA DM');
GO

DROP TABLE IF EXISTS DM.FACT_Factura;
DROP TABLE IF EXISTS DM.DIM_Tiempo;
DROP TABLE IF EXISTS DM.DIM_Contribuyente;
DROP TABLE IF EXISTS DM.DIM_Inmueble;
DROP TABLE IF EXISTS DM.DIM_Rubro;
DROP TABLE IF EXISTS DM.DIM_Tramite;
DROP TABLE IF EXISTS DM.DIM_Estado_Factura;
GO

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

CREATE TABLE DM.DIM_Estado_Factura (
    estado_id INT IDENTITY(1,1) PRIMARY KEY,
    estado VARCHAR(20) UNIQUE NOT NULL,
    descripcion VARCHAR(100)
);
GO

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
CREATE INDEX IX_Contribuyente_Distrito ON DM.DIM_Contribuyente(distrito);
GO

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

CREATE INDEX IX_Rubro_Nombre ON DM.DIM_Rubro(nombre);
GO

CREATE TABLE DM.DIM_Tramite (
    tramite_id INT PRIMARY KEY,
    tipo_tramite VARCHAR(50) NOT NULL,
    estado_tramite VARCHAR(20) NOT NULL,
    fecha_ingreso DATE,
    fecha_resolucion DATE,
    dias_resolucion INT
);
GO

CREATE INDEX IX_Tramite_Estado ON DM.DIM_Tramite(estado_tramite);
CREATE INDEX IX_Tramite_Tipo ON DM.DIM_Tramite(tipo_tramite);
GO

CREATE TABLE DM.FACT_Factura (
    fact_factura_id INT IDENTITY(1,1) PRIMARY KEY,
    factura_id INT NOT NULL,
    tiempo_emision_id INT NOT NULL,
    tiempo_vencimiento_id INT NOT NULL,
    contribuyente_id INT,
    inmueble_id INT,
    rubro_id INT,
    tramite_id INT,
    estado_factura_id INT NOT NULL,
    monto_base DECIMAL(12,2) NOT NULL,
    recargo DECIMAL(12,2) NOT NULL,
    intereses DECIMAL(12,2) NOT NULL,
    monto_total DECIMAL(12,2) NOT NULL,
    cantidad_lineas INT NOT NULL,
    monto_pagado DECIMAL(12,2) NOT NULL,
    saldo_pendiente DECIMAL(12,2) NOT NULL,
    esta_vencida BIT NOT NULL,
    esta_pagada BIT NOT NULL,
    dias_mora INT,
    fecha_carga DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_FACT_TiempoEmision FOREIGN KEY (tiempo_emision_id) REFERENCES DM.DIM_Tiempo(tiempo_id),
    CONSTRAINT FK_FACT_TiempoVencimiento FOREIGN KEY (tiempo_vencimiento_id) REFERENCES DM.DIM_Tiempo(tiempo_id),
    CONSTRAINT FK_FACT_Contribuyente FOREIGN KEY (contribuyente_id) REFERENCES DM.DIM_Contribuyente(contribuyente_id),
    CONSTRAINT FK_FACT_Inmueble FOREIGN KEY (inmueble_id) REFERENCES DM.DIM_Inmueble(inmueble_id),
    CONSTRAINT FK_FACT_Rubro FOREIGN KEY (rubro_id) REFERENCES DM.DIM_Rubro(rubro_id),
    CONSTRAINT FK_FACT_Tramite FOREIGN KEY (tramite_id) REFERENCES DM.DIM_Tramite(tramite_id),
    CONSTRAINT FK_FACT_EstadoFactura FOREIGN KEY (estado_factura_id) REFERENCES DM.DIM_Estado_Factura(estado_id)
);
GO

CREATE INDEX IX_FACT_TiempoEmision ON DM.FACT_Factura(tiempo_emision_id);
CREATE INDEX IX_FACT_TiempoVencimiento ON DM.FACT_Factura(tiempo_vencimiento_id);
CREATE INDEX IX_FACT_Contribuyente ON DM.FACT_Factura(contribuyente_id);
CREATE INDEX IX_FACT_Inmueble ON DM.FACT_Factura(inmueble_id);
CREATE INDEX IX_FACT_Rubro ON DM.FACT_Factura(rubro_id);
CREATE INDEX IX_FACT_Tramite ON DM.FACT_Factura(tramite_id);
CREATE INDEX IX_FACT_Estado ON DM.FACT_Factura(estado_factura_id);
CREATE INDEX IX_FACT_FacturaID ON DM.FACT_Factura(factura_id);
GO