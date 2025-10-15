-- =============================================
-- MÓDULO: CONTRIBUYENTES E INMUEBLES
-- Script: Creación de Tablas
-- Descripción: Tablas de contribuyentes (físicos/jurídicos) e inmuebles
-- =============================================

USE MunicipalidadNicoya;
GO


-- Eliminar en orden: de tablas dependientes a independientes
DELETE FROM dbo.Tramite;
DELETE FROM dbo.ObservacionInmueble;
DELETE FROM dbo.Colindancias;
DELETE FROM dbo.Catastro;
DELETE FROM dbo.Contribuyente_Inmueble;
DELETE FROM dbo.Contribuyente_juridico;
DELETE FROM dbo.Contribuyente_fisico;
DELETE FROM dbo.Inmueble;
DELETE FROM dbo.TipoUsoInmueble;
DELETE FROM dbo.Contribuyente;
GO

PRINT '✓ Todos los registros eliminados';
GO





-- =============================================
-- ELIMINAR RESTRICCIONES FK ANTES DE DROP
-- =============================================

-- FK externas (desde Tramite)
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Tramite_Inmueble')
    ALTER TABLE dbo.Tramite DROP CONSTRAINT FK_Tramite_Inmueble;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Tramite_Contribuyente')
    ALTER TABLE dbo.Tramite DROP CONSTRAINT FK_Tramite_Contribuyente;

-- FK internas
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ObservacionInmueble_Inmueble')
    ALTER TABLE dbo.ObservacionInmueble DROP CONSTRAINT FK_ObservacionInmueble_Inmueble;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Colindancias_Catastro')
    ALTER TABLE dbo.Colindancias DROP CONSTRAINT FK_Colindancias_Catastro;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Catastro_Inmueble')
    ALTER TABLE dbo.Catastro DROP CONSTRAINT FK_Catastro_Inmueble;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Contribuyente_Inmueble_Contribuyente')
    ALTER TABLE dbo.Contribuyente_Inmueble DROP CONSTRAINT FK_Contribuyente_Inmueble_Contribuyente;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Contribuyente_Inmueble_Inmueble')
    ALTER TABLE dbo.Contribuyente_Inmueble DROP CONSTRAINT FK_Contribuyente_Inmueble_Inmueble;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Inmueble_TipoUsoInmueble')
    ALTER TABLE dbo.Inmueble DROP CONSTRAINT FK_Inmueble_TipoUsoInmueble;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Contribuyente_juridico_Contribuyente')
    ALTER TABLE dbo.Contribuyente_juridico DROP CONSTRAINT FK_Contribuyente_juridico_Contribuyente;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Contribuyente_juridico_Representante')
    ALTER TABLE dbo.Contribuyente_juridico DROP CONSTRAINT FK_Contribuyente_juridico_Representante;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Contribuyente_fisico_Contribuyente')
    ALTER TABLE dbo.Contribuyente_fisico DROP CONSTRAINT FK_Contribuyente_fisico_Contribuyente;

-- Índices
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ObservacionInmueble_Inmueble')
    DROP INDEX IX_ObservacionInmueble_Inmueble ON dbo.ObservacionInmueble;

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Colindancias_Catastro')
    DROP INDEX IX_Colindancias_Catastro ON dbo.Colindancias;

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Catastro_Inmueble')
    DROP INDEX IX_Catastro_Inmueble ON dbo.Catastro;
GO

PRINT '✓ Restricciones e índices eliminados';
GO




-- =============================================
-- ELIMINAR TABLAS ADICIONALES
-- =============================================

IF OBJECT_ID('dbo.ObservacionInmueble', 'U') IS NOT NULL
    DROP TABLE dbo.ObservacionInmueble;
GO

IF OBJECT_ID('dbo.Colindancias', 'U') IS NOT NULL
    DROP TABLE dbo.Colindancias;
GO

IF OBJECT_ID('dbo.Catastro', 'U') IS NOT NULL
    DROP TABLE dbo.Catastro;
GO



IF OBJECT_ID('dbo.Contribuyente_Inmueble', 'U') IS NOT NULL
    DROP TABLE dbo.Contribuyente_Inmueble;
GO

IF OBJECT_ID('dbo.Inmueble', 'U') IS NOT NULL
    DROP TABLE dbo.Inmueble;
GO

IF OBJECT_ID('dbo.Contribuyente_juridico', 'U') IS NOT NULL
    DROP TABLE dbo.Contribuyente_juridico;
GO

IF OBJECT_ID('dbo.Contribuyente_fisico', 'U') IS NOT NULL
    DROP TABLE dbo.Contribuyente_fisico;
GO

IF OBJECT_ID('dbo.Contribuyente', 'U') IS NOT NULL
    DROP TABLE dbo.Contribuyente;
GO

IF OBJECT_ID('dbo.TipoUsoInmueble', 'U') IS NOT NULL
    DROP TABLE dbo.TipoUsoInmueble;
GO

-- =============================================
-- TABLA: Contribuyente (Padre)
-- =============================================
CREATE TABLE dbo.Contribuyente
(
    contribuyente_id INT IDENTITY(1,1) NOT NULL,
    tipo_contribuyente VARCHAR(20) NOT NULL,
    telefono VARCHAR(20) NULL,
    email VARCHAR(100) NULL,
    direccion VARCHAR(255) NULL,
    
    CONSTRAINT PK_Contribuyente PRIMARY KEY (contribuyente_id),
    CONSTRAINT CK_Contribuyente_Tipo CHECK (tipo_contribuyente IN ('Física', 'Jurídica')),
    CONSTRAINT CK_Contribuyente_Email CHECK (email LIKE '%@%' OR email IS NULL)
);
GO

PRINT '✓ Tabla Contribuyente creada';
GO

-- =============================================
-- TABLA: Contribuyente_fisico (Hija)
-- =============================================
CREATE TABLE dbo.Contribuyente_fisico
(
    contribuyentes_fisicos_id INT IDENTITY(1,1) NOT NULL,
    contribuyente_id INT NOT NULL,
    cedula VARCHAR(20) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido1 VARCHAR(50) NOT NULL,
    apellido2 VARCHAR(50) NOT NULL,
    
    CONSTRAINT PK_Contribuyente_fisico PRIMARY KEY (contribuyentes_fisicos_id),
    CONSTRAINT FK_Contribuyente_fisico_Contribuyente 
        FOREIGN KEY (contribuyente_id) REFERENCES dbo.Contribuyente(contribuyente_id)
        ON DELETE CASCADE,
    CONSTRAINT UQ_Contribuyente_fisico_Cedula UNIQUE (cedula),
    CONSTRAINT UQ_Contribuyente_fisico_Contribuyente UNIQUE (contribuyente_id)
);
GO

PRINT '✓ Tabla Contribuyente_fisico creada';
GO

-- =============================================
-- TABLA: Contribuyente_juridico (Hija)
-- =============================================
CREATE TABLE dbo.Contribuyente_juridico
(
    contribuyentes_fisicos_id INT IDENTITY(1,1) NOT NULL,
    contribuyente_id INT NOT NULL,
    cedula_juridica VARCHAR(50) NOT NULL,
    nombre_empresa VARCHAR(50) NOT NULL,
    representante_legal_id INT NOT NULL,
    
    CONSTRAINT PK_Contribuyente_juridico PRIMARY KEY (contribuyentes_fisicos_id),
    CONSTRAINT FK_Contribuyente_juridico_Contribuyente 
        FOREIGN KEY (contribuyente_id) REFERENCES dbo.Contribuyente(contribuyente_id)
        ON DELETE CASCADE,
    CONSTRAINT FK_Contribuyente_juridico_Representante 
        FOREIGN KEY (representante_legal_id) REFERENCES dbo.Contribuyente_fisico(contribuyentes_fisicos_id),
    CONSTRAINT UQ_Contribuyente_juridico_Cedula UNIQUE (cedula_juridica),
    CONSTRAINT UQ_Contribuyente_juridico_Contribuyente UNIQUE (contribuyente_id)
);
GO

PRINT '✓ Tabla Contribuyente_juridico creada';
GO

-- =============================================
-- TABLA CATÁLOGO: TipoUsoInmueble
-- =============================================
CREATE TABLE dbo.TipoUsoInmueble
(
    tipo_uso_inmueble_id INT IDENTITY(1,1) NOT NULL,
    nombre_uso VARCHAR(50) NOT NULL,
    descripcion VARCHAR(300) NULL,
    
    CONSTRAINT PK_TipoUsoInmueble PRIMARY KEY (tipo_uso_inmueble_id),
    CONSTRAINT UQ_TipoUsoInmueble_Nombre UNIQUE (nombre_uso)
);
GO

-- Insertar tipos de uso comunes
INSERT INTO TipoUsoInmueble (nombre_uso, descripcion) VALUES
('Residencial', 'Vivienda familiar o multifamiliar'),
('Comercial', 'Establecimientos comerciales, tiendas, oficinas'),
('Industrial', 'Fábricas, bodegas, instalaciones industriales'),
('Agrícola', 'Terrenos para cultivo o ganadería'),
('Mixto', 'Uso residencial y comercial combinado'),
('Baldío', 'Terreno sin construcción ni uso específico'),
('Institucional', 'Escuelas, hospitales, iglesias, edificios públicos'),
('Recreativo', 'Parques, centros deportivos, áreas verdes');
GO

PRINT '✓ Tabla TipoUsoInmueble creada con datos iniciales';
GO

-- =============================================
-- TABLA: Inmueble
-- =============================================
CREATE TABLE dbo.Inmueble
(
    inmueble_id INT IDENTITY(1,1) NOT NULL,
    direccion_exacta VARCHAR(255) NOT NULL,
    area_terreno DECIMAL(10,2) NOT NULL,
    valor_fiscal DECIMAL(18,2) NOT NULL,
    estado_ocupacional VARCHAR(50) NULL,
    tipo_uso_inmueble_id INT NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT PK_Inmueble PRIMARY KEY (inmueble_id),
    CONSTRAINT FK_Inmueble_TipoUsoInmueble 
        FOREIGN KEY (tipo_uso_inmueble_id) 
        REFERENCES dbo.TipoUsoInmueble(tipo_uso_inmueble_id),
    CONSTRAINT CK_Inmueble_AreaTerreno CHECK (area_terreno > 0),
    CONSTRAINT CK_Inmueble_ValorFiscal CHECK (valor_fiscal >= 0)
);
GO

PRINT '✓ Tabla Inmueble creada';
GO

-- =============================================
-- TABLA RELACIÓN N:M: Contribuyente_Inmueble
-- =============================================
CREATE TABLE dbo.Contribuyente_Inmueble
(
    contribuyente_inmueble_id INT IDENTITY(1,1) NOT NULL,
    contribuyente_id INT NOT NULL,
    inmueble_id INT NOT NULL,
    porcentaje_propiedad DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    fecha_registro DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT PK_Contribuyente_Inmueble PRIMARY KEY (contribuyente_inmueble_id),
    CONSTRAINT FK_Contribuyente_Inmueble_Contribuyente 
        FOREIGN KEY (contribuyente_id) 
        REFERENCES dbo.Contribuyente(contribuyente_id)
        ON DELETE CASCADE,
    CONSTRAINT FK_Contribuyente_Inmueble_Inmueble 
        FOREIGN KEY (inmueble_id) 
        REFERENCES dbo.Inmueble(inmueble_id)
        ON DELETE CASCADE,
    CONSTRAINT CK_Contribuyente_Inmueble_Porcentaje 
        CHECK (porcentaje_propiedad > 0 AND porcentaje_propiedad <= 100),
    CONSTRAINT UQ_Contribuyente_Inmueble 
        UNIQUE (contribuyente_id, inmueble_id)
);
GO

PRINT '✓ Tabla Contribuyente_Inmueble creada';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ MÓDULO CONTRIBUYENTES E INMUEBLES';
PRINT '  Todas las tablas creadas exitosamente';
PRINT '========================================';
GO

use MunicipalidadNicoya
go
-- =============================================
-- TABLA: Catastro
-- =============================================
CREATE TABLE dbo.Catastro
(
    catastro_id INT IDENTITY(1,1) NOT NULL,
    numero_plano_catastral VARCHAR(50) NOT NULL,
    area_catastral VARCHAR(100) NULL,
    fecha_inscripcion DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Activo',
    inmueble_id INT NOT NULL,
    
    CONSTRAINT PK_Catastro PRIMARY KEY (catastro_id),
    CONSTRAINT FK_Catastro_Inmueble 
        FOREIGN KEY (inmueble_id) REFERENCES dbo.Inmueble(inmueble_id)
        ON DELETE CASCADE,
    CONSTRAINT UQ_Catastro_NumeroPlano UNIQUE (numero_plano_catastral),
    CONSTRAINT CK_Catastro_Estado CHECK (estado IN ('Activo', 'Inactivo', 'En Revisión'))
);
GO

CREATE INDEX IX_Catastro_Inmueble ON dbo.Catastro(inmueble_id);
GO

PRINT '✓ Tabla Catastro creada';
GO

-- =============================================
-- TABLA: Colindancias
-- =============================================
CREATE TABLE dbo.Colindancias
(
    colindancias_id INT IDENTITY(1,1) NOT NULL,
    punto_cardinal VARCHAR(10) NOT NULL,
    colindante VARCHAR(255) NOT NULL,
    catastro_id INT NOT NULL,
    
    CONSTRAINT PK_Colindancias PRIMARY KEY (colindancias_id),
    CONSTRAINT FK_Colindancias_Catastro 
        FOREIGN KEY (catastro_id) REFERENCES dbo.Catastro(catastro_id)
        ON DELETE CASCADE,
    CONSTRAINT CK_Colindancias_PuntoCardinal 
        CHECK (punto_cardinal IN ('Norte', 'Sur', 'Este', 'Oeste'))
);
GO

CREATE INDEX IX_Colindancias_Catastro ON dbo.Colindancias(catastro_id);
GO

PRINT '✓ Tabla Colindancias creada';
GO

-- =============================================
-- TABLA: ObservacionInmueble
-- =============================================
CREATE TABLE dbo.ObservacionInmueble
(
    observacion_inmueble_id INT IDENTITY(1,1) NOT NULL,
    fecha DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    descripcion VARCHAR(300) NOT NULL,
    inmueble_id INT NOT NULL,
    
    
    CONSTRAINT PK_ObservacionInmueble PRIMARY KEY (observacion_inmueble_id),
    CONSTRAINT FK_ObservacionInmueble_Inmueble 
        FOREIGN KEY (inmueble_id) REFERENCES dbo.Inmueble(inmueble_id)
        ON DELETE CASCADE,
    CONSTRAINT CK_ObservacionInmueble_Descripcion 
        CHECK (LEN(TRIM(descripcion)) > 0)
   
);
GO

CREATE INDEX IX_ObservacionInmueble_Inmueble ON dbo.ObservacionInmueble(inmueble_id);
GO

PRINT '✓ Tabla ObservacionInmueble creada';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ TABLAS CREADAS';
PRINT '  - Catastro';
PRINT '  - Colindancias';
PRINT '  - ObservacionInmueble';
PRINT '========================================';
GO


