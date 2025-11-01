-- =============================================
-- MÓDULO: TRÁMITES Y PERMISOS
-- Script: Creación de Tablas
-- Descripción: Tablas para gestión de trámites y tipos de trámites
-- =============================================

USE MunicipalidadNicoya;
GO


PRINT '========================================';
PRINT 'MÓDULO: TRÁMITES Y PERMISOS';
PRINT '========================================';
GO

-- =============================================
-- PASO 1: ELIMINAR FK EXTERNAS QUE REFERENCIAN ESTAS TABLAS
-- =============================================

-- FK desde módulo Pagos
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Factura_Tramite')
    ALTER TABLE dbo.Factura DROP CONSTRAINT FK_Factura_Tramite;

-- FK internas del módulo
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Tramite_TipoTramite')
    ALTER TABLE dbo.Tramite DROP CONSTRAINT FK_Tramite_TipoTramite;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Tramite_Contribuyente')
    ALTER TABLE dbo.Tramite DROP CONSTRAINT FK_Tramite_Contribuyente;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Tramite_Inmueble')
    ALTER TABLE dbo.Tramite DROP CONSTRAINT FK_Tramite_Inmueble;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TipoTramiteRequisito_TipoTramite')
    ALTER TABLE dbo.Tipo_Tramite_Requisito DROP CONSTRAINT FK_TipoTramiteRequisito_TipoTramite;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_TipoTramiteRequisito_Requisito')
    ALTER TABLE dbo.Tipo_Tramite_Requisito DROP CONSTRAINT FK_TipoTramiteRequisito_Requisito;
GO

PRINT ' Foreign keys eliminadas';
GO

-- =============================================
-- PASO 2: ELIMINAR TABLAS SI EXISTEN
-- =============================================

DROP TABLE IF EXISTS dbo.Tipo_Tramite_Requisito;
DROP TABLE IF EXISTS dbo.Requisito;
DROP TABLE IF EXISTS dbo.Tramite;
DROP TABLE IF EXISTS dbo.Tipo_Tramite;
GO

PRINT 'Tablas eliminadas';
GO
-- 3. Ahora sí crear las tablas desde cero

-- =============================================
-- TABLA: Tipo_Tramite
-- =============================================
CREATE TABLE dbo.Tipo_Tramite
(
    tipo_tramite_id INT IDENTITY(1,1) NOT NULL,
    nombre_tipo VARCHAR(50) NOT NULL,
    
    CONSTRAINT PK_TipoTramite PRIMARY KEY (tipo_tramite_id)
);
GO

PRINT ' Tabla Tipo_Tramite creada';
GO

-- =============================================
-- TABLA: Tramite
-- =============================================
CREATE TABLE dbo.Tramite
(
    tramite_id INT IDENTITY(1,1) NOT NULL,
    fecha_ingreso DATE NOT NULL,
    fecha_resolucion DATE NULL,
    observaciones VARCHAR(255) NULL,
    estado_actual VARCHAR(20) NOT NULL,
    tipo_tramite_id INT NOT NULL,
    contribuyente_id INT NOT NULL,
    inmueble_id INT NOT NULL,
    
    CONSTRAINT PK_Tramite PRIMARY KEY (tramite_id),
    
    -- Checks
    CONSTRAINT CK_Tramite_EstadoActual
        CHECK (estado_actual IN ('En Proceso', 'Aprobado', 'Rechazado', 'Finalizado')),
    CONSTRAINT CK_Tramite_Fechas
        CHECK (fecha_resolucion IS NULL OR fecha_resolucion >= fecha_ingreso),
    
    -- Foreign Keys
    CONSTRAINT FK_Tramite_TipoTramite
        FOREIGN KEY (tipo_tramite_id) REFERENCES dbo.Tipo_Tramite(tipo_tramite_id),
    CONSTRAINT FK_Tramite_Contribuyente
        FOREIGN KEY (contribuyente_id) REFERENCES dbo.Contribuyente(contribuyente_id),
    CONSTRAINT FK_Tramite_Inmueble
        FOREIGN KEY (inmueble_id) REFERENCES dbo.Inmueble(inmueble_id)
);
GO

ALTER TABLE dbo.Tramite
ALTER COLUMN inmueble_id INT NULL;

-- Default para estado_actual
ALTER TABLE dbo.Tramite
ADD CONSTRAINT DF_Tramite_EstadoActual
    DEFAULT ('En Proceso') FOR estado_actual;
GO

PRINT ' Tabla Tramite creada';
GO

-- =============================================
-- TABLA: Requisito
-- =============================================
use MunicipalidadNicoya
go
CREATE TABLE Requisito
(
	requisito_id int identity(1,1) NOT NULL,
	nombre varchar(50) NOT NULL,
	descripcion varchar(255) NOT NULL,

	CONSTRAINT PK_Requisito PRIMARY KEY (requisito_id)
)
GO

PRINT 'Tabla Requisito creada';
GO

-- =============================================
-- TABLA: Tipo_Tramite_Requisito
-- =============================================
CREATE TABLE Tipo_Tramite_Requisito
(
	tipo_tramite_requisito_id int identity(1,1) NOT NULL,
	tipo_tramite_id int NOT NULL,
	requisito_id int NOT NULL,

	--PK
	CONSTRAINT PK_Tramite_Requisito PRIMARY KEY (tipo_tramite_requisito_id),

	--FKs
	CONSTRAINT FK_TipoTramiteRequisito_TipoTramite
		FOREIGN KEY (tipo_tramite_id) REFERENCES Tipo_Tramite(tipo_tramite_id),
	CONSTRAINT FK_TipoTramiteRequisito_Requisito
		FOREIGN KEY (requisito_id) REFERENCES Requisito(requisito_id)
)
GO

PRINT ' Tabla Tipo_Tramite_Requisito creada';
GO
PRINT '';
PRINT '========================================';
PRINT ' MÓDULO TRÁMITES Y PERMISOS';
PRINT '  Todas las tablas creadas exitosamente';
PRINT '========================================';
GO