-- =============================================
-- MÓDULO: TRÁMITES Y PERMISOS
-- Script: Creación de Tablas
-- Descripción: Tablas para gestión de trámites y tipos de trámites
-- =============================================

USE MunicipalidadNicoya;
GO

-- =============================================
-- ELIMINAR TABLAS SI EXISTEN
-- =============================================
IF OBJECT_ID('dbo.Tramite', 'U') IS NOT NULL
    DROP TABLE dbo.Tramite;
GO

IF OBJECT_ID('dbo.Tipo_Tramite', 'U') IS NOT NULL
    DROP TABLE dbo.Tipo_Tramite;
GO

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

PRINT '✓ Tabla Tipo_Tramite creada';
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

-- Default para estado_actual
ALTER TABLE dbo.Tramite
ADD CONSTRAINT DF_Tramite_EstadoActual
    DEFAULT ('En Proceso') FOR estado_actual;
GO

PRINT '✓ Tabla Tramite creada';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ MÓDULO TRÁMITES Y PERMISOS';
PRINT '  Todas las tablas creadas exitosamente';
PRINT '========================================';
GO