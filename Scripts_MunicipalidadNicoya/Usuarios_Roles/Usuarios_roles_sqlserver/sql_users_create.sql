-- =============================================
-- SCRIPT UNIFICADO: CONFIGURACIÓN COMPLETA DE SEGURIDAD
-- Base de Datos: MunicipalidadNicoya + DataMart
-- Descripción: Configuración desde cero con limpieza previa
-- Usuarios: usr_auditor y usr_funcionario
-- =============================================

USE master;
GO

PRINT '';
PRINT '========================================';
PRINT ' INICIANDO LIMPIEZA Y CONFIGURACIÓN';
PRINT '   Sistema de Seguridad Completo';
PRINT '========================================';
PRINT '';

-- =============================================
-- FASE 1: LIMPIEZA COMPLETA
-- =============================================

PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '   FASE 1: LIMPIEZA DE CONFIGURACIÓN PREVIA';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '';

-- Limpiar usuarios en DataMart
USE MunicipalidadNicoyaDataMart;
GO

PRINT 'Limpiando usuarios en DataMart...';

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_auditor')
BEGIN
    DROP USER usr_auditor;
    PRINT '  ✓ Usuario usr_auditor eliminado de DataMart';
END

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_funcionario')
BEGIN
    DROP USER usr_funcionario;
    PRINT '  ✓ Usuario usr_funcionario eliminado de DataMart';
END

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'auditor' AND type = 'R')
BEGIN
    DROP ROLE auditor;
    PRINT '  ✓ Rol auditor eliminado de DataMart';
END

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'funcionario_municipal' AND type = 'R')
BEGIN
    DROP ROLE funcionario_municipal;
    PRINT '  ✓ Rol funcionario_municipal eliminado de DataMart';
END

PRINT '';

-- Limpiar usuarios en MunicipalidadNicoya
USE MunicipalidadNicoya;
GO

PRINT 'Limpiando usuarios en MunicipalidadNicoya...';

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_auditor')
BEGIN
    DROP USER usr_auditor;
    PRINT '  ✓ Usuario usr_auditor eliminado';
END

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_funcionario')
BEGIN
    DROP USER usr_funcionario;
    PRINT '  ✓ Usuario usr_funcionario eliminado';
END

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'auditor' AND type = 'R')
BEGIN
    DROP ROLE auditor;
    PRINT '  ✓ Rol auditor eliminado';
END

IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'funcionario_municipal' AND type = 'R')
BEGIN
    DROP ROLE funcionario_municipal;
    PRINT '  ✓ Rol funcionario_municipal eliminado';
END

PRINT '';

-- Limpiar logins a nivel de servidor
USE master;
GO

PRINT 'Limpiando logins del servidor...';

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usr_auditor')
BEGIN
    DROP LOGIN usr_auditor;
    PRINT '  ✓ Login usr_auditor eliminado';
END

IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usr_funcionario')
BEGIN
    DROP LOGIN usr_funcionario;
    PRINT '  ✓ Login usr_funcionario eliminado';
END

PRINT '';
PRINT ' LIMPIEZA COMPLETADA';
PRINT '';

-- =============================================
-- FASE 2: CONFIGURACIÓN DE CROSS-DATABASE
-- =============================================

PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '   FASE 2: CONFIGURACIÓN CROSS-DATABASE';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '';

-- Configurar ownership de bases de datos
ALTER AUTHORIZATION ON DATABASE::MunicipalidadNicoya TO sa;
PRINT '  ✓ Owner de MunicipalidadNicoya sa';

ALTER AUTHORIZATION ON DATABASE::MunicipalidadNicoyaDataMart TO sa;
PRINT '  ✓ Owner de MunicipalidadNicoyaDataMart sa';

-- Habilitar cross-database ownership chaining
ALTER DATABASE MunicipalidadNicoya SET DB_CHAINING ON;
PRINT '  ✓ DB_CHAINING habilitado en MunicipalidadNicoya';

ALTER DATABASE MunicipalidadNicoyaDataMart SET DB_CHAINING ON;
PRINT '  ✓ DB_CHAINING habilitado en DataMart';

-- Configurar Trustworthy
ALTER DATABASE MunicipalidadNicoya SET TRUSTWORTHY ON;
PRINT '  ✓ TRUSTWORTHY habilitado en MunicipalidadNicoya';

ALTER DATABASE MunicipalidadNicoyaDataMart SET TRUSTWORTHY ON;
PRINT '  ✓ TRUSTWORTHY habilitado en DataMart';

PRINT '';
PRINT ' CONFIGURACIÓN CROSS-DATABASE COMPLETADA';
PRINT '';

-- =============================================
-- FASE 3: CREAR LOGINS A NIVEL DE SERVIDOR
-- =============================================

PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '   FASE 3: CREACIÓN DE LOGINS';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '';

CREATE LOGIN usr_auditor 
    WITH PASSWORD = 'Auditor123',
    DEFAULT_DATABASE = MunicipalidadNicoya,
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = OFF;
PRINT '  ✓ Login creado: usr_auditor (Password: Auditor123)';

CREATE LOGIN usr_funcionario 
    WITH PASSWORD = 'Funcionario123',
    DEFAULT_DATABASE = MunicipalidadNicoya,
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = OFF;
PRINT '  ✓ Login creado: usr_funcionario (Password: Funcionario123)';

PRINT '';
PRINT ' LOGINS CREADOS';
PRINT '';

-- =============================================
-- FASE 4: CONFIGURAR MunicipalidadNicoya
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '   FASE 4: CONFIGURANDO MunicipalidadNicoya';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '';

-- Crear usuarios
CREATE USER usr_auditor FOR LOGIN usr_auditor;
PRINT '  ✓ Usuario creado: usr_auditor';

CREATE USER usr_funcionario FOR LOGIN usr_funcionario;
PRINT '  ✓ Usuario creado: usr_funcionario';

-- Crear roles
CREATE ROLE auditor;
PRINT '  ✓ Rol creado: auditor';

CREATE ROLE funcionario_municipal;
PRINT '  ✓ Rol creado: funcionario_municipal';

-- Permisos para AUDITOR
ALTER ROLE db_owner ADD MEMBER auditor;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO auditor;
GRANT EXECUTE ON SCHEMA::dbo TO auditor;
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE TO auditor;
PRINT '  ✓ Permisos otorgados a auditor (control total)';

-- Permisos para FUNCIONARIO MUNICIPAL
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO funcionario_municipal;
GRANT EXECUTE ON SCHEMA::dbo TO funcionario_municipal;
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE TO funcionario_municipal;
PRINT '  ✓ Permisos otorgados a funcionario_municipal';

-- Bloquear tablas de auditoría para funcionario
IF OBJECT_ID('dbo.Factura_Auditoria', 'U') IS NOT NULL
BEGIN
    DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Factura_Auditoria TO funcionario_municipal;
    PRINT '  ✓ Acceso bloqueado a Factura_Auditoria';
END

IF OBJECT_ID('dbo.Pago_Auditoria', 'U') IS NOT NULL
BEGIN
    DENY SELECT, INSERT, UPDATE, DELETE ON dbo.Pago_Auditoria TO funcionario_municipal;
    PRINT '  ✓ Acceso bloqueado a Pago_Auditoria';
END

-- Asignar usuarios a roles
ALTER ROLE auditor ADD MEMBER usr_auditor;
PRINT '  ✓ usr_auditor → rol auditor';

ALTER ROLE funcionario_municipal ADD MEMBER usr_funcionario;
PRINT '  ✓ usr_funcionario → rol funcionario_municipal';

PRINT '';
PRINT ' MunicipalidadNicoya CONFIGURADA';
PRINT '';

-- =============================================
-- FASE 5: CONFIGURAR DataMart
-- =============================================

USE MunicipalidadNicoyaDataMart;
GO

PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '   FASE 5: CONFIGURANDO DataMart';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '';

-- Crear usuarios
CREATE USER usr_auditor FOR LOGIN usr_auditor;
PRINT '  ✓ Usuario creado: usr_auditor';

CREATE USER usr_funcionario FOR LOGIN usr_funcionario;
PRINT '  ✓ Usuario creado: usr_funcionario';

-- Crear roles
CREATE ROLE auditor;
PRINT '  ✓ Rol creado: auditor';

CREATE ROLE funcionario_municipal;
PRINT '  ✓ Rol creado: funcionario_municipal';

-- Permisos para AUDITOR
ALTER ROLE db_owner ADD MEMBER auditor;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO auditor;
GRANT EXECUTE ON SCHEMA::dbo TO auditor;
PRINT '  ✓ Permisos otorgados a auditor (control total)';

-- Permisos en esquema DM si existe
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'DM')
BEGIN
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::DM TO auditor;
    GRANT EXECUTE ON SCHEMA::DM TO auditor;
    PRINT '  ✓ Permisos en schema DM otorgados a auditor';
END

-- Permisos para FUNCIONARIO MUNICIPAL
ALTER ROLE db_datareader ADD MEMBER funcionario_municipal;
ALTER ROLE db_datawriter ADD MEMBER funcionario_municipal;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO funcionario_municipal;
GRANT EXECUTE ON SCHEMA::dbo TO funcionario_municipal;
PRINT '  ✓ Permisos otorgados a funcionario_municipal';

-- Permisos en esquema DM si existe
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'DM')
BEGIN
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::DM TO funcionario_municipal;
    GRANT EXECUTE ON SCHEMA::DM TO funcionario_municipal;
    PRINT '  ✓ Permisos en schema DM otorgados a funcionario_municipal';
END

-- Asignar usuarios a roles
ALTER ROLE auditor ADD MEMBER usr_auditor;
PRINT '   usr_auditor → rol auditor';

ALTER ROLE funcionario_municipal ADD MEMBER usr_funcionario;
PRINT '   usr_funcionario  rol funcionario_municipal';

PRINT '';
PRINT ' DataMart CONFIGURADO';
PRINT '';

-- =============================================
-- VERIFICACIÓN FINAL
-- =============================================

PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '    CONFIGURACIÓN COMPLETADA';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

GO