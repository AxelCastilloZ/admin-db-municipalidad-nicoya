
-- Creación de Tabla Contribuyente
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
    CONSTRAINT CK_Contribuyente_Tipo CHECK (tipo_contribuyente IN ('Física', 'Jurídica')),
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
