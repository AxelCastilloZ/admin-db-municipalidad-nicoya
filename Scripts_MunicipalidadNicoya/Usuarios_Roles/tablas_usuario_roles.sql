


-- =============================================
-- TABLA: Rol
-- =============================================
CREATE TABLE dbo.Rol
(
    rol_id INT IDENTITY(1,1) NOT NULL,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    
    CONSTRAINT PK_Rol PRIMARY KEY (rol_id)
);
GO

-- Insertar roles del sistema
INSERT INTO Rol (nombre) VALUES
('Administrador'),
('Gerente'),
('Cajero');
GO

PRINT '✓ Tabla Rol creada con datos iniciales';
GO

-- =============================================
-- TABLA: Usuario
-- =============================================
CREATE TABLE dbo.Usuario
(
    usuario_id INT IDENTITY(1,1) NOT NULL,
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
    
    CONSTRAINT PK_Usuario PRIMARY KEY (usuario_id),
    CONSTRAINT FK_Usuario_Rol FOREIGN KEY (rol_id) REFERENCES Rol(rol_id),
    CONSTRAINT CK_Usuario_Email CHECK (email LIKE '%@%.%')
);
GO

PRINT '✓ Tabla Usuario creada';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ MÓDULO USUARIOS Y ROLES';
PRINT '  Todas las tablas creadas exitosamente';
PRINT '========================================';
GO