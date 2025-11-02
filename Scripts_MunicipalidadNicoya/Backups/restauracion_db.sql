


-- ============================================
-- SCRIPT DE RESTAURACIÓN PARA EL EQUIPO
-- Municipalidad de Nicoya
-- ============================================
-- Instrucciones:
-- 1. Descarga el archivo .bak que te compartieron
-- 2. Guárdalo en: C:\Backups_Nicoya\
-- 3. Ejecuta este script en tu SQL Server local
-- ============================================

USE master;
GO

PRINT '========================================';
PRINT 'RESTAURACIÓN DE BASE DE DATOS';
PRINT 'Sistema Municipal Nicoya';
PRINT '========================================';
GO

-- ============================================
-- CONFIGURACIÓN: Ruta del archivo .bak
-- ============================================
DECLARE @RutaBackup VARCHAR(500);
SET @RutaBackup = 'C:\Backups_Nicoya\MunicipalidadNicoya_ParaCompartir.bak';

PRINT 'Archivo a restaurar: ' + @RutaBackup;
PRINT '';
GO

-- ============================================
-- PASO 1: Verificar que el archivo existe
-- ============================================
PRINT 'Verificando archivo...';
GO

DECLARE @RutaBackup VARCHAR(500) = 'C:\Backups_Nicoya\MunicipalidadNicoya_ParaCompartir.bak';

RESTORE VERIFYONLY 
FROM DISK = @RutaBackup;

PRINT '✓ Archivo verificado correctamente';
PRINT '';
GO

-- ============================================
-- PASO 2: Ver información del backup
-- ============================================
PRINT 'Información del backup:';
GO

DECLARE @RutaBackup VARCHAR(500) = 'C:\Backups_Nicoya\MunicipalidadNicoya_ParaCompartir.bak';

RESTORE HEADERONLY 
FROM DISK = @RutaBackup;
GO

-- ============================================
-- PASO 3: Desconectar usuarios (si la BD ya existe)
-- ============================================
PRINT 'Preparando base de datos...';
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'MunicipalidadNicoya')
BEGIN
    PRINT '  - Base de datos existente detectada';
    PRINT '  - Desconectando usuarios activos...';
    
    ALTER DATABASE MunicipalidadNicoya 
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    PRINT '  ✓ Usuarios desconectados';
END
ELSE
BEGIN
    PRINT '  - Primera instalación (BD no existe)';
END
GO

-- ============================================
-- PASO 4: RESTAURAR LA BASE DE DATOS
-- ============================================
PRINT '';
PRINT 'Iniciando restauración...';
PRINT '(Esto puede tardar unos minutos)';
GO

DECLARE @RutaBackup VARCHAR(500) = 'C:\Backups_Nicoya\MunicipalidadNicoya_ParaCompartir.bak';

RESTORE DATABASE MunicipalidadNicoya
FROM DISK = @RutaBackup
WITH 
    REPLACE,          -- Reemplaza la BD si ya existe
    RECOVERY,         -- Deja la BD lista para usar
    STATS = 10;       -- Muestra progreso cada 10%
GO

-- ============================================
-- PASO 5: Activar acceso multiusuario
-- ============================================
PRINT '';
PRINT 'Configurando acceso...';
GO

ALTER DATABASE MunicipalidadNicoya 
SET MULTI_USER;
GO

PRINT '✓ Base de datos accesible';
GO

-- ============================================
-- PASO 6: VERIFICACIÓN FINAL
-- ============================================
PRINT '';
PRINT '========================================';
PRINT 'VERIFICACIÓN FINAL';
PRINT '========================================';
GO

USE MunicipalidadNicoya;
GO

-- Ver tablas disponibles
PRINT '';
PRINT 'Tablas en la base de datos:';
SELECT 
    TABLE_SCHEMA AS 'Esquema',
    TABLE_NAME AS 'Tabla',
    TABLE_TYPE AS 'Tipo'
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
GO

-- Contar registros en algunas tablas (ajusta según tus tablas)
PRINT '';
PRINT 'Conteo de registros (muestra):';

-- NOTA: Ajusta estos nombres según las tablas reales de tu proyecto
IF OBJECT_ID('dbo.Contribuyentes', 'U') IS NOT NULL
    SELECT 'Contribuyentes' AS Tabla, COUNT(*) AS Registros FROM dbo.Contribuyentes
ELSE
    PRINT '  (Tabla Contribuyentes no encontrada - ajustar script)';

IF OBJECT_ID('dbo.Inmuebles', 'U') IS NOT NULL
    SELECT 'Inmuebles' AS Tabla, COUNT(*) AS Registros FROM dbo.Inmuebles
ELSE
    PRINT '  (Tabla Inmuebles no encontrada - ajustar script)';

IF OBJECT_ID('dbo.Tramites', 'U') IS NOT NULL
    SELECT 'Tramites' AS Tabla, COUNT(*) AS Registros FROM dbo.Tramites
ELSE
    PRINT '  (Tabla Tramites no encontrada - ajustar script)';

IF OBJECT_ID('dbo.Pagos', 'U') IS NOT NULL
    SELECT 'Pagos' AS Tabla, COUNT(*) AS Registros FROM dbo.Pagos
ELSE
    PRINT '  (Tabla Pagos no encontrada - ajustar script)';

GO

PRINT '';
PRINT '========================================';
PRINT '✓✓✓ RESTAURACIÓN COMPLETADA ✓✓✓';
PRINT '========================================';
PRINT '';
PRINT 'La base de datos MunicipalidadNicoya está lista para usar';
PRINT '';
PRINT 'Siguiente paso:';
PRINT '- Verifica que puedes ver las tablas en Object Explorer';
PRINT '- Ejecuta consultas de prueba';
PRINT '';
GO

-- ============================================
-- CONSULTA DE PRUEBA SIMPLE
-- ============================================
PRINT 'Consulta de prueba:';
SELECT 
    name AS 'Base de Datos',
    create_date AS 'Fecha Creación',
    compatibility_level AS 'Nivel Compatibilidad',
    state_desc AS 'Estado'
FROM sys.databases
WHERE name = 'MunicipalidadNicoya';
GO