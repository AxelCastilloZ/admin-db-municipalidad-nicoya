

-- ============================================
-- VER SI EL BACKUP DE HOY SE EJECUTÓ
-- Ejecuta esto a las 11:30 PM para verificar
-- ============================================

USE msdb;
GO

PRINT '========================================';
PRINT 'ÚLTIMOS BACKUPS REALIZADOS';
PRINT '========================================';
PRINT '';

SELECT TOP 10
    CASE bs.type
        WHEN 'D' THEN ' FULL'
        WHEN 'I' THEN ' DIFERENCIAL'
    END AS 'Tipo',
    CONVERT(VARCHAR, bs.backup_start_date, 120) AS 'Fecha y Hora',
    bs.backup_size / 1024 / 1024 AS 'Tamaño (MB)',
    bs.compressed_backup_size / 1024 / 1024 AS 'Comprimido (MB)',
    DATEDIFF(SECOND, bs.backup_start_date, bs.backup_finish_date) AS 'Segundos',
    CASE 
        WHEN bs.backup_start_date > DATEADD(HOUR, -1, GETDATE()) THEN ' Recién hecho'
        WHEN bs.backup_start_date > DATEADD(DAY, -1, GETDATE()) THEN ' Hoy'
        ELSE ' Antiguo'
    END AS 'Estado'
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'MunicipalidadNicoya'
ORDER BY bs.backup_start_date DESC;
GO

PRINT '';
PRINT '========================================';