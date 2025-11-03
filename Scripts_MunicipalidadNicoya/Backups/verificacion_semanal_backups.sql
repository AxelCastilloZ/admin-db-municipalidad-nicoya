-- ============================================
-- VERIFICACIÓN RÁPIDA DEL SISTEMA DE BACKUPS
-- Ejecuta esto cuando quieras verificar el estado
-- ============================================

USE msdb;
GO

PRINT '========================================';
PRINT '   ESTADO DEL SISTEMA DE BACKUPS';
PRINT '========================================';
PRINT '';

-- ============================================
-- 1. ¿Está corriendo SQL Server Agent?
-- ============================================
PRINT '1. SQL Server Agent:';
IF (SELECT status FROM sys.dm_server_services WHERE servicename LIKE 'SQL Server Agent%') = 4
    PRINT '    CORRIENDO - Todo bien'
ELSE
    PRINT '    DETENIDO - ¡INICIAR AHORA!'
PRINT '';

-- ============================================
-- 2. Estado de los Jobs configurados
-- ============================================
PRINT '2. Jobs de Backup:';
PRINT '';

SELECT 
    j.name AS 'Nombre del Job',
    CASE j.enabled
        WHEN 1 THEN ' Activo'
        ELSE ' Deshabilitado'
    END AS 'Estado',
    CASE 
        WHEN jh.run_date IS NULL THEN 'Nunca ejecutado'
        ELSE CONVERT(VARCHAR, CONVERT(DATETIME, 
            CAST(jh.run_date AS VARCHAR(8)) + ' ' + 
            STUFF(STUFF(RIGHT('000000' + CAST(jh.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')), 120)
    END AS 'Última Ejecución',
    CASE jh.run_status
        WHEN 1 THEN ' EXITOSO'
        WHEN 0 THEN ' FALLÓ'
        WHEN 3 THEN ' Cancelado'
        ELSE 'Sin historial'
    END AS 'Resultado'
FROM msdb.dbo.sysjobs j
LEFT JOIN (
    SELECT job_id, run_date, run_time, run_status,
           ROW_NUMBER() OVER (PARTITION BY job_id ORDER BY run_date DESC, run_time DESC) as rn
    FROM msdb.dbo.sysjobhistory
    WHERE step_id = 0
) jh ON j.job_id = jh.job_id AND jh.rn = 1
WHERE j.name LIKE '%Nicoya%'
ORDER BY j.name;
GO

PRINT '';

-- ============================================
-- 3. Últimos 10 backups realizados
-- ============================================
PRINT '3. Últimos backups ejecutados:';
PRINT '';

SELECT TOP 10
    CASE bs.type
        WHEN 'D' THEN ' FULL'
        WHEN 'I' THEN ' DIFERENCIAL'
        WHEN 'L' THEN ' LOG'
    END AS 'Tipo',
    CONVERT(VARCHAR, bs.backup_start_date, 120) AS 'Fecha y Hora',
    bs.backup_size / 1024 / 1024 AS 'Tamaño (MB)',
    bs.compressed_backup_size / 1024 / 1024 AS 'Comprimido (MB)',
    DATEDIFF(SECOND, bs.backup_start_date, bs.backup_finish_date) AS 'Duración (seg)',
    RIGHT(bmf.physical_device_name, 50) AS 'Archivo'
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = 'MunicipalidadNicoya'
ORDER BY bs.backup_start_date DESC;
GO

PRINT '';

-- ============================================
-- 4. Espacio en disco disponible
-- ============================================
PRINT '4. Espacio en disco:';
PRINT '';

EXEC xp_fixeddrives;
GO

PRINT '';

-- ============================================
-- 5. Resumen y recomendaciones
-- ============================================
PRINT '========================================';
PRINT '            RESUMEN';
PRINT '========================================';
PRINT '';

DECLARE @CountJobs INT;
DECLARE @CountBackups INT;
DECLARE @AgentStatus INT;

-- Verificar jobs
SELECT @CountJobs = COUNT(*) 
FROM msdb.dbo.sysjobs 
WHERE name LIKE '%Nicoya%' AND enabled = 1;

-- Verificar backups recientes
SELECT @CountBackups = COUNT(*) 
FROM msdb.dbo.backupset 
WHERE database_name = 'MunicipalidadNicoya'
  AND backup_start_date > DATEADD(DAY, -7, GETDATE());

-- Verificar Agent
SELECT @AgentStatus = status 
FROM sys.dm_server_services 
WHERE servicename LIKE 'SQL Server Agent%';

-- Mostrar resultado
IF @AgentStatus = 4 AND @CountJobs >= 2 AND @CountBackups > 0
BEGIN
    
    PRINT 'Sistema de backups operativo:';
    PRINT '  • SQL Agent activo';
    PRINT '  • ' + CAST(@CountJobs AS VARCHAR) + ' jobs configurados';
    PRINT '  • ' + CAST(@CountBackups AS VARCHAR) + ' backups en los últimos 7 días';
END
ELSE
BEGIN
    PRINT ' ATENCIÓN: REVISAR SISTEMA ';
    PRINT '';
    IF @AgentStatus != 4
        PRINT '   SQL Agent detenido - INICIAR';
    IF @CountJobs < 2
        PRINT '   Faltan jobs - Ejecutar script de configuración';
    IF @CountBackups = 0
        PRINT '   Sin backups recientes - Verificar logs';
END

PRINT '';
PRINT '========================================';
GO