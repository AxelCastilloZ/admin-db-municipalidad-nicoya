


-- ============================================
-- EJECUTAR BACKUPS MANUALES INMEDIATOS
-- Para generar archivos .bak que compartir
-- ============================================


USE master;
GO

PRINT '========================================';
PRINT 'GENERANDO BACKUPS MANUALES';
PRINT '========================================';
GO

-- ============================================
-- 1. BACKUP COMPLETO INMEDIATO
-- ============================================
PRINT '';
PRINT 'Ejecutando Backup COMPLETO...';
GO

DECLARE @FechaHora VARCHAR(20);
SET @FechaHora = CONVERT(VARCHAR(20), GETDATE(), 112) + '_' + 
                 REPLACE(CONVERT(VARCHAR(20), GETDATE(), 108), ':', '');

DECLARE @RutaBackupFull VARCHAR(500);
SET @RutaBackupFull = 'C:\Backups_Nicoya\MunicipalidadNicoya_FULL_' + @FechaHora + '.bak';

BACKUP DATABASE MunicipalidadNicoya
TO DISK = @RutaBackupFull
WITH 
    FORMAT,
    NAME = 'Backup Completo MANUAL - Para compartir',
    DESCRIPTION = 'Respaldo completo generado manualmente para distribución al equipo',
    COMPRESSION,
    STATS = 10;

PRINT ' Backup COMPLETO creado exitosamente';
PRINT '  Ubicación: ' + @RutaBackupFull;
GO

-- ============================================
-- 2. VERIFICAR INTEGRIDAD DEL BACKUP
-- ============================================
PRINT '';
PRINT 'Verificando integridad del backup...';
GO

DECLARE @RutaVerificar VARCHAR(500);
SELECT TOP 1 @RutaVerificar = physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'MunicipalidadNicoya'
  AND bs.type = 'D'  -- Full backup
ORDER BY bs.backup_finish_date DESC;

RESTORE VERIFYONLY 
FROM DISK = @RutaVerificar;

PRINT ' Backup verificado correctamente - Sin errores';
GO

-- ============================================
-- 3. INFORMACIÓN DEL BACKUP CREADO
-- ============================================
PRINT '';
PRINT '========================================';
PRINT 'INFORMACIÓN DEL BACKUP';
PRINT '========================================';
GO

SELECT TOP 1
    bs.database_name AS 'Base de Datos',
    bs.backup_size / 1024 / 1024 AS 'Tamaño (MB)',
    bs.compressed_backup_size / 1024 / 1024 AS 'Tamaño Comprimido (MB)',
    CAST((1 - (CAST(bs.compressed_backup_size AS FLOAT) / bs.backup_size)) * 100 AS DECIMAL(5,2)) AS '% Compresión',
    bs.backup_start_date AS 'Inicio',
    bs.backup_finish_date AS 'Fin',
    DATEDIFF(SECOND, bs.backup_start_date, bs.backup_finish_date) AS 'Duración (seg)',
    bmf.physical_device_name AS 'Ubicación Archivo'
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'MunicipalidadNicoya'
  AND bs.type = 'D'
ORDER BY bs.backup_finish_date DESC;
GO

-- ============================================
-- 4. CREAR BACKUP "PARA COMPARTIR"
-- ============================================
PRINT '';
PRINT 'Creando copia para compartir con el equipo...';
GO

BACKUP DATABASE MunicipalidadNicoya
TO DISK = 'C:\Backups_Nicoya\MunicipalidadNicoya_ParaCompartir.bak'
WITH 
    FORMAT,
    NAME = 'Backup para distribución al equipo',
    DESCRIPTION = 'Backup base para que todo el equipo tenga la misma versión de la BD',
    COMPRESSION,
    STATS = 10;
GO

