


-- ============================================
-- SISTEMA DE BACKUPS AUTOMATIZADO
-- Municipalidad de Nicoya
-- Curso: Administración de Base Datos - UNA
-- ============================================
-- Configuración:
-- - Backup COMPLETO: Cada 2 días a las 11:00 PM
-- - Backup DIFERENCIAL: Diario a las 11:00 PM
-- ============================================

USE msdb;
GO

PRINT '========================================';
PRINT 'INICIANDO CONFIGURACIÓN DE BACKUPS';
PRINT '========================================';
GO

-- ============================================
-- PASO 1: CREAR CARPETA PARA BACKUPS
-- ============================================
PRINT 'Creando estructura de carpetas...';
GO

EXEC xp_cmdshell 'mkdir C:\Backups_Nicoya', NO_OUTPUT;
GO

PRINT '✓ Carpeta C:\Backups_Nicoya creada';
GO

-- ============================================
-- PASO 2: JOB BACKUP COMPLETO (CADA 2 DÍAS)
-- ============================================
PRINT 'Configurando Backup COMPLETO (cada 2 días)...';
GO

-- Eliminar job si ya existe
IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'Backup_Full_Nicoya_Cada2Dias')
BEGIN
    EXEC sp_delete_job @job_name = N'Backup_Full_Nicoya_Cada2Dias';
    PRINT '  - Job anterior eliminado';
END
GO

-- Crear el Job para Backup COMPLETO
EXEC sp_add_job 
    @job_name = N'Backup_Full_Nicoya_Cada2Dias',
    @enabled = 1,
    @description = N'Backup completo cada 2 días - Sistema Municipal Nicoya',
    @category_name = N'Database Maintenance';
GO

-- Agregar paso del backup
EXEC sp_add_jobstep 
    @job_name = N'Backup_Full_Nicoya_Cada2Dias',
    @step_name = N'Ejecutar_Backup_Completo',
    @subsystem = N'TSQL',
    @command = N'
DECLARE @FechaHora VARCHAR(20);
SET @FechaHora = CONVERT(VARCHAR(20), GETDATE(), 112) + ''_'' + 
                 REPLACE(CONVERT(VARCHAR(20), GETDATE(), 108), '':'', '''');

DECLARE @RutaBackup VARCHAR(500);
SET @RutaBackup = ''C:\Backups_Nicoya\MunicipalidadNicoya_FULL_'' + @FechaHora + ''.bak'';

BACKUP DATABASE MunicipalidadNicoya
TO DISK = @RutaBackup
WITH 
    FORMAT,
    NAME = ''Backup Completo - Sistema Municipal'',
    DESCRIPTION = ''Respaldo completo automatizado cada 2 días'',
    COMPRESSION,
    STATS = 10;

PRINT ''✓ Backup COMPLETO ejecutado: '' + @RutaBackup;
',
    @database_name = N'master',
    @on_success_action = 1,
    @on_fail_action = 2,
    @retry_attempts = 2,
    @retry_interval = 5;
GO

-- Programar: Cada 2 días a las 11:00 PM
EXEC sp_add_schedule 
    @schedule_name = N'Schedule_Full_Cada2Dias',
    @freq_type = 4,              -- Diario
    @freq_interval = 2,          -- Cada 2 días
    @active_start_time = 230000; -- 11:00 PM
GO

-- Asociar schedule al job
EXEC sp_attach_schedule 
    @job_name = N'Backup_Full_Nicoya_Cada2Dias',
    @schedule_name = N'Schedule_Full_Cada2Dias';
GO

-- Asignar al servidor local
EXEC sp_add_jobserver 
    @job_name = N'Backup_Full_Nicoya_Cada2Dias';
GO

PRINT '✓ Job Backup COMPLETO configurado exitosamente';
GO

-- ============================================
-- PASO 3: JOB BACKUP DIFERENCIAL (DIARIO)
-- ============================================
PRINT 'Configurando Backup DIFERENCIAL (diario)...';
GO

-- Eliminar job si ya existe
IF EXISTS (SELECT * FROM msdb.dbo.sysjobs WHERE name = N'Backup_Diff_Nicoya_Diario')
BEGIN
    EXEC sp_delete_job @job_name = N'Backup_Diff_Nicoya_Diario';
    PRINT '  - Job anterior eliminado';
END
GO

-- Crear el Job para Backup DIFERENCIAL
EXEC sp_add_job 
    @job_name = N'Backup_Diff_Nicoya_Diario',
    @enabled = 1,
    @description = N'Backup diferencial diario - Sistema Municipal Nicoya',
    @category_name = N'Database Maintenance';
GO

-- Agregar paso del backup diferencial
EXEC sp_add_jobstep 
    @job_name = N'Backup_Diff_Nicoya_Diario',
    @step_name = N'Ejecutar_Backup_Diferencial',
    @subsystem = N'TSQL',
    @command = N'
DECLARE @FechaHora VARCHAR(20);
SET @FechaHora = CONVERT(VARCHAR(20), GETDATE(), 112) + ''_'' + 
                 REPLACE(CONVERT(VARCHAR(20), GETDATE(), 108), '':'', '''');

DECLARE @RutaBackup VARCHAR(500);
SET @RutaBackup = ''C:\Backups_Nicoya\MunicipalidadNicoya_DIFF_'' + @FechaHora + ''.bak'';

BACKUP DATABASE MunicipalidadNicoya
TO DISK = @RutaBackup
WITH 
    DIFFERENTIAL,
    FORMAT,
    NAME = ''Backup Diferencial - Sistema Municipal'',
    DESCRIPTION = ''Respaldo diferencial automatizado diario'',
    COMPRESSION,
    STATS = 10;

PRINT ''✓ Backup DIFERENCIAL ejecutado: '' + @RutaBackup;
',
    @database_name = N'master',
    @on_success_action = 1,
    @on_fail_action = 2,
    @retry_attempts = 2,
    @retry_interval = 5;
GO

-- Programar: Diario a las 11:00 PM
EXEC sp_add_schedule 
    @schedule_name = N'Schedule_Diff_Diario',
    @freq_type = 4,              -- Diario
    @freq_interval = 1,          -- Cada 1 día
    @active_start_time = 230000; -- 11:00 PM
GO

-- Asociar schedule al job
EXEC sp_attach_schedule 
    @job_name = N'Backup_Diff_Nicoya_Diario',
    @schedule_name = N'Schedule_Diff_Diario';
GO

-- Asignar al servidor local
EXEC sp_add_jobserver 
    @job_name = N'Backup_Diff_Nicoya_Diario';
GO

PRINT '✓ Job Backup DIFERENCIAL configurado exitosamente';
GO

-- ============================================
-- PASO 4: VERIFICAR CONFIGURACIÓN
-- ============================================
PRINT '';
PRINT '========================================';
PRINT 'CONFIGURACIÓN COMPLETADA';
PRINT '========================================';
PRINT '';
PRINT 'Jobs creados:';
PRINT '1. Backup_Full_Nicoya_Cada2Dias  → Cada 2 días a las 11:00 PM';
PRINT '2. Backup_Diff_Nicoya_Diario     → Diario a las 11:00 PM';
PRINT '';
PRINT 'Ubicación de backups: C:\Backups_Nicoya\';
PRINT '';
PRINT '¿Qué hacer ahora?';
PRINT '1. Verificar que SQL Server Agent esté corriendo';
PRINT '2. Ejecutar un backup manual de prueba (ver script de prueba)';
PRINT '3. Compartir archivos .bak con el equipo';
PRINT '';
PRINT '========================================';
GO

-- ============================================
-- CONSULTA: Ver estado de los jobs
-- ============================================
SELECT 
    j.name AS 'Nombre del Job',
    j.enabled AS 'Habilitado',
    s.name AS 'Schedule',
    CASE s.freq_type
        WHEN 4 THEN 'Diario'
        WHEN 8 THEN 'Semanal'
    END AS 'Frecuencia',
    s.freq_interval AS 'Intervalo (días)',
    STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') AS 'Hora'
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
INNER JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
WHERE j.name LIKE '%Nicoya%'
ORDER BY j.name;
GO