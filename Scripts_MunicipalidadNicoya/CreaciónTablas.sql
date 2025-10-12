
-- Creaci�n de Tabla Contribuyente
USE MunicipalidadNicoya
GO
IF OBJECT_ID('dbo.Contribuyente_Inmueble', 'U') IS NOT NULL
    DROP TABLE dbo.Contribuyente_Inmueble;
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

-- Tabla Padre: Contribuyente
CREATE TABLE dbo.Contribuyente
(
    contribuyente_id INT IDENTITY(1,1) NOT NULL,
    tipo_contribuyente VARCHAR(20) NOT NULL,
    telefono VARCHAR(20) NULL,
    email VARCHAR(100) NULL,
    direccion VARCHAR(255) NULL,
    
    CONSTRAINT PK_Contribuyente PRIMARY KEY (contribuyente_id),
    CONSTRAINT CK_Contribuyente_Tipo CHECK (tipo_contribuyente IN ('F�sica', 'Jur�dica')),
    CONSTRAINT CK_Contribuyente_Email CHECK (email LIKE '%@%' OR email IS NULL)
);
GO

-- Tabla Hija: Contribuyente_fisico
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

-- Tabla Hija: Contribuyente_juridico
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






-- =============================================
-- Tabla Catálogo: TipoUsoInmueble
-- =============================================
IF OBJECT_ID('dbo.TipoUsoInmueble', 'U') IS NOT NULL
    DROP TABLE dbo.TipoUsoInmueble;
GO

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
-- Eliminar tablas dependientes primero
-- =============================================
IF OBJECT_ID('dbo.Contribuyente_Inmueble', 'U') IS NOT NULL
    DROP TABLE dbo.Contribuyente_Inmueble;
GO

IF OBJECT_ID('dbo.Inmueble', 'U') IS NOT NULL
    DROP TABLE dbo.Inmueble;
GO

-- =============================================
-- Tabla: Inmueble
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

PRINT '✓ Tabla Inmueble creada correctamente';
GO

-- =============================================
-- Tabla Relación N:M: Contribuyente_Inmueble
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

PRINT '✓ Tabla Contribuyente_Inmueble creada correctamente';
GO


-- =============================================
-- Eliminar tablas si existen 
-- =============================================
IF OBJECT_ID('dbo.Contribuyente_Inmueble', 'U') IS NOT NULL
    DROP TABLE dbo.Contribuyente_Inmueble;
GO

IF OBJECT_ID('dbo.Inmueble', 'U') IS NOT NULL
    DROP TABLE dbo.Inmueble;
GO

-- =============================================
-- Crear tabla Inmueble
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
-- Crear tabla Contribuyente_Inmueble
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



-- ============================================
-- TABLA: Rol
-- ============================================
CREATE TABLE Rol (
    rol_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);
GO

-- ============================================
-- INSERTAR ROLES DEL SISTEMA
-- ============================================
INSERT INTO Rol (nombre) VALUES
('Administrador'),
('Gerente'),
('Cajero');
GO

-- ============================================
-- TABLA: Usuario
-- ============================================
CREATE TABLE Usuario (
    usuario_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido1 VARCHAR(50) NOT NULL,
    apellido2 VARCHAR(50) NULL,
    rol_id INT NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    activo BIT NOT NULL DEFAULT 1,
    bloqueado BIT NOT NULL DEFAULT 0,
    intentos_fallidos INT NOT NULL DEFAULT 0,
    ultimo_acceso DATETIME NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT FK_Usuario_Rol FOREIGN KEY (rol_id) REFERENCES Rol(rol_id),
    CONSTRAINT CK_Usuario_Email CHECK (email LIKE '%@%.%')
);
GO

-- ============================================
-- TABLA: Tipo Tramite
-- ============================================

CREATE TABLE Tipo_Tramite
(
    tipo_tramite_id INT IDENTITY(1,1) NOT NULL,
    nombre_tipo     VARCHAR(50) NOT NULL,

    -- PRIMARY KEY 
    CONSTRAINT PK_TipoTramite PRIMARY KEY (tipo_tramite_id),
)
GO

-- ============================================
-- TABLA: Tramite
-- ============================================

CREATE TABLE Tramite
(
  tramite_id         INT IDENTITY(1,1) NOT NULL,
  fecha_ingreso      DATE NOT NULL,
  fecha_resolucion   DATE NULL,
  observaciones      VARCHAR(255) NULL,
  estado_actual      VARCHAR(20) NOT NULL,
  tipo_tramite_id    INT NOT NULL,
  contribuyente_id   INT NOT NULL,
  inmueble_id        INT NOT NULL,

  CONSTRAINT PK_Tramite PRIMARY KEY (tramite_id),

  -- Checks (uno de lista y otro de coherencia de fechas)
  CONSTRAINT CK_Tramite_EstadoActual
    CHECK (estado_actual IN ('En Proceso', 'Aprobado', 'Rechazado', 'Finalizado')),
  CONSTRAINT CK_Tramite_Fechas
    CHECK (fecha_resolucion IS NULL OR fecha_resolucion >= fecha_ingreso),

  -- FKs
  CONSTRAINT FK_Tramite_TipoTramite
    FOREIGN KEY (tipo_tramite_id) REFERENCES Tipo_Tramite(tipo_tramite_id),
  CONSTRAINT FK_Tramite_Contribuyente
    FOREIGN KEY (contribuyente_id) REFERENCES Contribuyente(contribuyente_id),
  CONSTRAINT FK_Tramite_Inmueble
    FOREIGN KEY (inmueble_id) REFERENCES Inmueble(inmueble_id)
);
GO

--DEFAULTS Tabla Tramite
ALTER TABLE Tramite
ADD CONSTRAINT DF_Tramite_EstadoActual
    DEFAULT ('En Proceso') FOR estado_actual;
GO