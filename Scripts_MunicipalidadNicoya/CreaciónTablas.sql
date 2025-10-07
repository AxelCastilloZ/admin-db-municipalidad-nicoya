
-- Creación de Tabla Contribuyente
USE MunicipalidadNicoya
GO

CREATE TABLE Contribuyente
(
    contribuyente_id INT IDENTITY(1,1) NOT NULL,
    cedula VARCHAR(20) NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    tipo VARCHAR(20) NOT NULL, -- 'Física' o 'Jurídica'
    telefono VARCHAR(20) NULL,
    email VARCHAR(100) NULL,
    direccion VARCHAR(300) NULL,
    CONSTRAINT PK_Contribuyente PRIMARY KEY (contribuyente_id ),
    
    -- Definir restricciones únicas
    CONSTRAINT UQ_Contribuyente_Cedula UNIQUE (cedula),
    -- Definir restricciones de verificación
    CONSTRAINT CK_Contribuyente_Tipo CHECK (Tipo IN ('Física', 'Jurídica')),
    CONSTRAINT CK_Contribuyente_Email CHECK (Email LIKE '%@%' OR Email IS NULL)
);
GO
select *from Contribuyente
go


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
