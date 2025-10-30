-- =============================================
-- SCRIPT: CREACIÓN DE USUARIOS Y ROLES
-- Base de Datos: MunicipalidadNicoya
-- Descripción: Sistema de seguridad con 2 roles
--              - auditor: Acceso total incluyendo auditorías
--              - funcionario_municipal: Acceso operativo SIN auditorías
-- =============================================

USE master;
GO

PRINT '';
PRINT '========================================';
PRINT ' INICIANDO CONFIGURACIÓN DE SEGURIDAD';
PRINT '   Base de Datos: MunicipalidadNicoya';
PRINT '========================================';
PRINT '';

-- =============================================
-- PASO 1: CREAR LOGINS A NIVEL DE SERVIDOR
-- (Si ya existen, los elimina y los vuelve a crear)
-- =============================================

PRINT ' PASO 1: Creando Logins de SQL Server...';
PRINT '';

-- Eliminar logins si ya existen
IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usr_auditor')
BEGIN
    DROP LOGIN usr_auditor;
    PRINT '  Login usr_auditor existente eliminado';
END

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usr_funcionario')
BEGIN
    DROP LOGIN usr_funcionario;
    PRINT '  Login usr_funcionario existente eliminado';
END

-- Crear el login para el AUDITOR
CREATE LOGIN usr_auditor 
    WITH PASSWORD = 'Auditor123',
    DEFAULT_DATABASE = MunicipalidadNicoya,
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = OFF;

PRINT '  Login creado: usr_auditor (Contraseña: Auditor123)';

-- Crear el login para el FUNCIONARIO
CREATE LOGIN usr_funcionario 
    WITH PASSWORD = 'Funcionario123',
    DEFAULT_DATABASE = MunicipalidadNicoya,
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = OFF;

PRINT '  Login creado: usr_funcionario (Contraseña: Funcionario123)';
PRINT '';

-- =============================================
-- PASO 2: CREAR USUARIOS EN LA BASE DE DATOS
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT 'PASO 2: Creando Usuarios en la Base de Datos...';
PRINT '';

-- Eliminar usuarios si ya existen
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_auditor')
BEGIN
    DROP USER usr_auditor;
    PRINT '  Usuario usr_auditor existente eliminado';
END

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_funcionario')
BEGIN
    DROP USER usr_funcionario;
    PRINT '  Usuario usr_funcionario existente eliminado';
END

-- Crear usuario AUDITOR en la BD
CREATE USER usr_auditor FOR LOGIN usr_auditor;
PRINT '  Usuario creado en BD: usr_auditor';

-- Crear usuario FUNCIONARIO en la BD
CREATE USER usr_funcionario FOR LOGIN usr_funcionario;
PRINT '  Usuario creado en BD: usr_funcionario';
PRINT '';

-- =============================================
-- PASO 3: CREAR ROLES DE BASE DE DATOS
-- =============================================

PRINT 'PASO 3: Creando Roles de Base de Datos...';
PRINT '';

-- Eliminar roles si ya existen
IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'auditor' AND type = 'R')
BEGIN
    DROP ROLE auditor;
    PRINT '  Rol auditor existente eliminado';
END

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'funcionario_municipal' AND type = 'R')
BEGIN
    DROP ROLE funcionario_municipal;
    PRINT '  Rol funcionario_municipal existente eliminado';
END

-- Crear rol AUDITOR
CREATE ROLE auditor;
PRINT '  Rol creado: auditor';

-- Crear rol FUNCIONARIO MUNICIPAL
CREATE ROLE funcionario_municipal;
PRINT '  Rol creado: funcionario_municipal';
PRINT '';

-- =============================================
-- PASO 4: ASIGNAR PERMISOS AL ROL AUDITOR
-- (Control total sobre toda la base de datos)
-- =============================================

PRINT 'PASO 4: Asignando permisos al rol AUDITOR...';
PRINT '';

-- El auditor tiene control total (db_owner)
ALTER ROLE db_owner ADD MEMBER auditor;
PRINT '  Rol auditor agregado a db_owner (control total)';

-- Permisos explícitos adicionales para claridad
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO auditor;
PRINT '  Permisos CRUD en schema dbo otorgados';

GRANT EXECUTE ON SCHEMA::dbo TO auditor;
PRINT '  Permiso EXECUTE en todos los SPs otorgado';

GRANT CREATE TABLE TO auditor;
GRANT CREATE VIEW TO auditor;
GRANT CREATE PROCEDURE TO auditor;
PRINT '  Permisos de creación de objetos otorgados';
PRINT '';

-- =============================================
-- PASO 5: ASIGNAR PERMISOS AL ROL FUNCIONARIO_MUNICIPAL
-- (Acceso operativo PERO sin auditorías)
-- =============================================

PRINT ' PASO 5: Asignando permisos al rol FUNCIONARIO_MUNICIPAL...';
PRINT '';

-- Dar permisos básicos de lectura y escritura
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO funcionario_municipal;
PRINT '  Permisos CRUD en schema dbo otorgados';

GRANT EXECUTE ON SCHEMA::dbo TO funcionario_municipal;
PRINT '  Permiso EXECUTE en SPs otorgado (se bloquearán los de auditoría después)';

-- Permisos para crear objetos (tablas, vistas, SPs)
GRANT CREATE TABLE TO funcionario_municipal;
GRANT CREATE VIEW TO funcionario_municipal;
GRANT CREATE PROCEDURE TO funcionario_municipal;
PRINT '  Permisos de creación de objetos otorgados';
PRINT '';

-- =============================================
-- PASO 5.1: ASIGNAR PERMISOS EN ESQUEMA DM (DATA MART)
-- =============================================

PRINT ' PASO 5.1: Asignando permisos en esquema DM (Data Mart)...';
PRINT '';

-- Verificar si existe el esquema DM
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'DM')
BEGIN
    -- Permisos completos para AUDITOR en esquema DM
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::DM TO auditor;
    PRINT '  Permisos CRUD en schema DM otorgados a auditor';
    
    -- Permisos de lectura para FUNCIONARIO en esquema DM
    GRANT SELECT ON SCHEMA::DM TO funcionario_municipal;
    PRINT '  Permiso SELECT en schema DM otorgado a funcionario_municipal';
END
ELSE
BEGIN
    PRINT '  ADVERTENCIA: Esquema DM no existe aún. Ejecutar permisos cuando se cree.';
END

PRINT '';

-- =============================================
-- PASO 6: BLOQUEAR ACCESO A TABLAS DE AUDITORÍA
-- (DENY explícito para funcionario_municipal)
-- =============================================

PRINT ' PASO 6: Bloqueando acceso a tablas de AUDITORÍA...';
PRINT '';

-- Bloquear acceso a Factura_Auditoria
IF OBJECT_ID('dbo.Factura_Auditoria', 'U') IS NOT NULL
BEGIN
    DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Factura_Auditoria TO funcionario_municipal;
    PRINT '  Acceso BLOQUEADO a Factura_Auditoria';
END
ELSE
BEGIN
    PRINT '  Tabla Factura_Auditoria no existe aún (crear DENY cuando exista)';
END

-- Bloquear acceso a Pago_Auditoria
IF OBJECT_ID('dbo.Pago_Auditoria', 'U') IS NOT NULL
BEGIN
    DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Pago_Auditoria TO funcionario_municipal;
    PRINT '  Acceso BLOQUEADO a Pago_Auditoria';
END
ELSE
BEGIN
    PRINT '  Tabla Pago_Auditoria no existe aún (crear DENY cuando exista)';
END

PRINT '';

-- =============================================
-- PASO 7: BLOQUEAR STORED PROCEDURES DE AUDITORÍA
-- (DENY explícito para funcionario_municipal)
-- =============================================

PRINT ' PASO 7: Bloqueando SPs de consulta de AUDITORÍA...';
PRINT '';

-- Bloquear SP de historial de facturas
IF OBJECT_ID('dbo.sp_Factura_ConsultarHistorial', 'P') IS NOT NULL
BEGIN
    DENY EXECUTE ON dbo.sp_Factura_ConsultarHistorial TO funcionario_municipal;
    PRINT '  Ejecución BLOQUEADA: sp_Factura_ConsultarHistorial';
END
ELSE
BEGIN
    PRINT '  SP sp_Factura_ConsultarHistorial no existe aún';
END

-- Bloquear SP de historial de pagos
IF OBJECT_ID('dbo.sp_Pago_ConsultarHistorial', 'P') IS NOT NULL
BEGIN
    DENY EXECUTE ON dbo.sp_Pago_ConsultarHistorial TO funcionario_municipal;
    PRINT '  Ejecución BLOQUEADA: sp_Pago_ConsultarHistorial';
END
ELSE
BEGIN
    PRINT '  SP sp_Pago_ConsultarHistorial no existe aún';
END

-- Bloquear SP de consulta por fecha
IF OBJECT_ID('dbo.sp_Auditoria_ConsultarPorFecha', 'P') IS NOT NULL
BEGIN
    DENY EXECUTE ON dbo.sp_Auditoria_ConsultarPorFecha TO funcionario_municipal;
    PRINT '  Ejecución BLOQUEADA: sp_Auditoria_ConsultarPorFecha';
END
ELSE
BEGIN
    PRINT '  SP sp_Auditoria_ConsultarPorFecha no existe aún';
END

PRINT '';

-- =============================================
-- PASO 8: ASIGNAR USUARIOS A SUS ROLES
-- =============================================

PRINT ' PASO 8: Asignando usuarios a sus roles...';
PRINT '';

-- Asignar usr_auditor al rol auditor
ALTER ROLE auditor ADD MEMBER usr_auditor;
PRINT '  usr_auditor asignado al rol: auditor';

-- Asignar usr_funcionario al rol funcionario_municipal
ALTER ROLE funcionario_municipal ADD MEMBER usr_funcionario;
PRINT '  usr_funcionario asignado al rol: funcionario_municipal';

PRINT '';
PRINT '========================================';
PRINT ' CONFIGURACIÓN COMPLETADA EXITOSAMENTE';
PRINT '========================================';
PRINT '';
PRINT ' RESUMEN DE USUARIOS CREADOS:';
PRINT '   - usr_auditor (Contraseña: Auditor123)';
PRINT '     Rol: auditor - Acceso total + auditorías';
PRINT '';
PRINT '   - usr_funcionario (Contraseña: Funcionario123)';
PRINT '     Rol: funcionario_municipal - Acceso operativo sin auditorías';
PRINT '';
PRINT ' ESQUEMAS CON PERMISOS:';
PRINT '   - dbo (ambos roles)';
PRINT '   - DM (ambos roles - Data Mart)';
PRINT '';
GO