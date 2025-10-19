-- =============================================
-- JOB: Cálculo Automático de Recargos e Intereses
-- Descripción: Job que ejecuta diariamente el cálculo de recargos 
--              e intereses para facturas vencidas
-- Horario: Todos los días a las 2:00 AM
-- =============================================

USE msdb;
GO

PRINT '';
PRINT '========================================';
PRINT '📅 CREANDO JOB DE SQL SERVER AGENT';
PRINT '   Job: Calcular Recargos e Intereses';
PRINT '========================================';
PRINT '';

-- =============================================
-- PASO 1: VERIFICAR SI YA EXISTE EL JOB
-- =============================================

DECLARE @job_name NVARCHAR(128) = N'Job_Calcular_Recargos_Intereses_Municipalidad';
DECLARE @job_id UNIQUEIDENTIFIER;

-- Verificar si el job ya existe
SELECT @job_id = job_id 
FROM msdb.dbo.sysjobs 
WHERE name = @job_name;

IF @job_id IS NOT NULL
BEGIN
    PRINT '⚠️  El job ya existe. Eliminando job anterior...';
    
    -- Eliminar el job existente
    EXEC msdb.dbo.sp_delete_job 
        @job_name = @job_name;
    
    PRINT '✓ Job anterior eliminado';
    PRINT '';
END

-- =============================================
-- PASO 2: CREAR EL JOB
-- =============================================

PRINT '📝 Creando nuevo job...';

BEGIN TRANSACTION;

EXEC msdb.dbo.sp_add_job
    @job_name = @job_name,
    @enabled = 1,
    @description = N'Calcula automáticamente recargos e intereses para facturas vencidas de la Municipalidad de Nicoya. Ejecuta diariamente a las 2:00 AM.',
    @category_name = N'Database Maintenance',
    @owner_login_name = N'sa';

PRINT '✓ Job creado';

-- =============================================
-- PASO 3: AGREGAR STEP AL JOB
-- =============================================

PRINT '📝 Agregando step de ejecución...';

EXEC msdb.dbo.sp_add_jobstep
    @job_name = @job_name,
    @step_name = N'Ejecutar Cálculo de Recargos e Intereses',
    @subsystem = N'TSQL',
    @command = N'
USE MunicipalidadNicoya;
GO

-- =============================================
-- SCRIPT: CÁLCULO DE RECARGOS E INTERESES
-- Ejecutado por: Job Automático
-- Descripción: Calcula y aplica recargos e intereses
--              a facturas vencidas según rubro
-- =============================================

SET NOCOUNT ON;

DECLARE @fecha_actual DATE = CAST(GETDATE() AS DATE);
DECLARE @facturas_procesadas INT = 0;
DECLARE @facturas_actualizadas INT = 0;

PRINT '''';
PRINT ''========================================='';
PRINT ''🔄 INICIO DE CÁLCULO DE RECARGOS E INTERESES'';
PRINT ''   Fecha: '' + CONVERT(VARCHAR(10), @fecha_actual, 120);
PRINT ''   Hora: '' + CONVERT(VARCHAR(8), GETDATE(), 108);
PRINT ''========================================='';
PRINT '''';

-- =============================================
-- 1. IDENTIFICAR FACTURAS VENCIDAS
-- =============================================

PRINT ''📋 1. Identificando facturas vencidas...'';

-- Tabla temporal para almacenar facturas a procesar
CREATE TABLE #FacturasVencidas (
    factura_id INT,
    numero_factura VARCHAR(50),
    fecha_vencimiento DATE,
    dias_mora INT,
    monto_base DECIMAL(12,2),
    recargo_actual DECIMAL(12,2),
    intereses_actual DECIMAL(12,2),
    rubro_id INT,
    aplica_recargo BIT,
    aplica_intereses BIT,
    tasa_recargo DECIMAL(5,2),
    tasa_interes DECIMAL(5,2)
);

-- Insertar facturas vencidas (Pendiente o Vencida)
INSERT INTO #FacturasVencidas
SELECT 
    f.factura_id,
    f.numero_factura,
    f.fecha_vencimiento,
    DATEDIFF(DAY, f.fecha_vencimiento, @fecha_actual) AS dias_mora,
    f.monto_base,
    f.recargo AS recargo_actual,
    f.intereses AS intereses_actual,
    r.rubro_id,
    r.aplica_recargo,
    r.aplica_intereses,
    r.tasa_recargo,
    r.tasa_interes
FROM dbo.Factura f
-- Obtener rubro del primer detalle (asumiendo facturas homogéneas)
INNER JOIN (
    SELECT factura_id, MIN(rubro_id) AS rubro_id
    FROM dbo.Detalle_factura
    GROUP BY factura_id
) df ON f.factura_id = df.factura_id
INNER JOIN dbo.Rubro r ON df.rubro_id = r.rubro_id
WHERE f.estado_factura IN (''Pendiente'', ''Vencida'')
  AND f.fecha_vencimiento < @fecha_actual
  AND (r.aplica_recargo = 1 OR r.aplica_intereses = 1);

SET @facturas_procesadas = @@ROWCOUNT;

PRINT ''  ✓ Facturas vencidas encontradas: '' + CAST(@facturas_procesadas AS VARCHAR(10));

-- =============================================
-- 2. CALCULAR Y APLICAR RECARGOS E INTERESES
-- =============================================

IF @facturas_procesadas > 0
BEGIN
    PRINT '''';
    PRINT ''💰 2. Calculando recargos e intereses...'';
    PRINT '''';
    
    -- Variables para el cursor
    DECLARE @factura_id INT;
    DECLARE @numero_factura VARCHAR(50);
    DECLARE @dias_mora INT;
    DECLARE @monto_base DECIMAL(12,2);
    DECLARE @recargo_actual DECIMAL(12,2);
    DECLARE @intereses_actual DECIMAL(12,2);
    DECLARE @aplica_recargo BIT;
    DECLARE @aplica_intereses BIT;
    DECLARE @tasa_recargo DECIMAL(5,2);
    DECLARE @tasa_interes DECIMAL(5,2);
    
    -- Nuevos valores calculados
    DECLARE @nuevo_recargo DECIMAL(12,2);
    DECLARE @nuevos_intereses DECIMAL(12,2);
    DECLARE @nuevo_monto_total DECIMAL(12,2);
    
    -- Cursor para procesar cada factura
    DECLARE cursor_facturas CURSOR FOR
    SELECT 
        factura_id,
        numero_factura,
        dias_mora,
        monto_base,
        recargo_actual,
        intereses_actual,
        aplica_recargo,
        aplica_intereses,
        tasa_recargo,
        tasa_interes
    FROM #FacturasVencidas;
    
    OPEN cursor_facturas;
    
    FETCH NEXT FROM cursor_facturas INTO 
        @factura_id, @numero_factura, @dias_mora, @monto_base,
        @recargo_actual, @intereses_actual, @aplica_recargo,
        @aplica_intereses, @tasa_recargo, @tasa_interes;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Inicializar valores
        SET @nuevo_recargo = @recargo_actual;
        SET @nuevos_intereses = @intereses_actual;
        
        -- Calcular recargo (una sola vez, no acumulativo)
        IF @aplica_recargo = 1 AND @recargo_actual = 0
        BEGIN
            SET @nuevo_recargo = @monto_base * (@tasa_recargo / 100);
        END
        
        -- Calcular intereses (acumulativo mensual)
        IF @aplica_intereses = 1
        BEGIN
            -- Interés mensual: (monto_base * tasa_interes / 100) * (dias_mora / 30)
            SET @nuevos_intereses = (@monto_base * (@tasa_interes / 100)) * (@dias_mora / 30.0);
        END
        
        -- Calcular nuevo monto total
        SET @nuevo_monto_total = @monto_base + @nuevo_recargo + @nuevos_intereses;
        
        -- Actualizar la factura
        UPDATE dbo.Factura
        SET 
            recargo = @nuevo_recargo,
            intereses = @nuevos_intereses,
            monto_total = @nuevo_monto_total,
            estado_factura = ''Vencida''
        WHERE factura_id = @factura_id;
        
        SET @facturas_actualizadas = @facturas_actualizadas + 1;
        
        -- Log del procesamiento
        PRINT ''  ✓ '' + @numero_factura + '' - Mora: '' + CAST(@dias_mora AS VARCHAR(10)) + '' días'';
        PRINT ''    Recargo: ₡'' + CAST(@nuevo_recargo AS VARCHAR(20));
        PRINT ''    Intereses: ₡'' + CAST(@nuevos_intereses AS VARCHAR(20));
        PRINT ''    Total: ₡'' + CAST(@nuevo_monto_total AS VARCHAR(20));
        PRINT '''';
        
        FETCH NEXT FROM cursor_facturas INTO 
            @factura_id, @numero_factura, @dias_mora, @monto_base,
            @recargo_actual, @intereses_actual, @aplica_recargo,
            @aplica_intereses, @tasa_recargo, @tasa_interes;
    END
    
    CLOSE cursor_facturas;
    DEALLOCATE cursor_facturas;
    
    PRINT ''✓ Facturas actualizadas: '' + CAST(@facturas_actualizadas AS VARCHAR(10));
END
ELSE
BEGIN
    PRINT ''  ℹ️  No hay facturas vencidas pendientes de procesar'';
END

-- Limpiar tabla temporal
DROP TABLE #FacturasVencidas;

-- =============================================
-- 3. RESUMEN DE EJECUCIÓN
-- =============================================

PRINT '''';
PRINT ''========================================='';
PRINT ''✅ CÁLCULO COMPLETADO'';
PRINT ''   Facturas procesadas: '' + CAST(@facturas_procesadas AS VARCHAR(10));
PRINT ''   Facturas actualizadas: '' + CAST(@facturas_actualizadas AS VARCHAR(10));
PRINT ''   Finalizado: '' + CONVERT(VARCHAR(8), GETDATE(), 108);
PRINT ''========================================='';
PRINT '''';
',
    @database_name = N'MunicipalidadNicoya',
    @on_success_action = 1, -- Quit with success
    @on_fail_action = 2, -- Quit with failure
    @retry_attempts = 2,
    @retry_interval = 5; -- 5 minutos entre reintentos

PRINT '✓ Step agregado';

-- =============================================
-- PASO 4: CREAR SCHEDULE (DIARIO A LAS 2:00 AM)
-- =============================================

PRINT '📅 Configurando schedule diario...';

EXEC msdb.dbo.sp_add_jobschedule
    @job_name = @job_name,
    @name = N'Schedule_Diario_2AM',
    @enabled = 1,
    @freq_type = 4, -- Daily
    @freq_interval = 1, -- Every 1 day
    @freq_subday_type = 1, -- At the specified time
    @freq_subday_interval = 0,
    @freq_relative_interval = 0,
    @freq_recurrence_factor = 1,
    @active_start_date = 20250101, -- Formato YYYYMMDD
    @active_end_date = 99991231,
    @active_start_time = 020000, -- 02:00:00 AM (formato HHMMSS)
    @active_end_time = 235959;

PRINT '✓ Schedule configurado: Diario a las 2:00 AM';

-- =============================================
-- PASO 5: ASIGNAR EL JOB A UN SERVER
-- =============================================

PRINT '🖥️  Asignando job al servidor local...';

EXEC msdb.dbo.sp_add_jobserver
    @job_name = @job_name,
    @server_name = N'(local)';

PRINT '✓ Job asignado al servidor';

COMMIT TRANSACTION;

-- =============================================
-- PASO 6: VERIFICAR CREACIÓN DEL JOB
-- =============================================

PRINT '';
PRINT '🔍 Verificando creación del job...';
PRINT '';

SELECT 
    j.job_id,
    j.name AS job_name,
    j.enabled AS job_enabled,
    j.description,
    s.name AS schedule_name,
    s.enabled AS schedule_enabled,
    CASE s.freq_type
        WHEN 4 THEN 'Diario'
        WHEN 8 THEN 'Semanal'
        WHEN 16 THEN 'Mensual'
        ELSE 'Otro'
    END AS frecuencia,
    RIGHT('0' + CAST(s.active_start_time / 10000 AS VARCHAR(2)), 2) + ':' +
    RIGHT('0' + CAST((s.active_start_time / 100) % 100 AS VARCHAR(2)), 2) + ':' +
    RIGHT('0' + CAST(s.active_start_time % 100 AS VARCHAR(2)), 2) AS hora_ejecucion,
    j.date_created,
    j.date_modified
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
LEFT JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
WHERE j.name = @job_name;

PRINT '';
PRINT '========================================';
PRINT '✅ JOB CREADO EXITOSAMENTE';
PRINT '   Nombre: ' + @job_name;
PRINT '   Horario: Diario a las 2:00 AM';
PRINT '   Estado: Habilitado';
PRINT '========================================';
PRINT '';

-- =============================================
-- OPCIONAL: EJECUTAR JOB MANUALMENTE AHORA
-- =============================================

PRINT '';
PRINT '¿Desea ejecutar el job manualmente ahora? (Para pruebas)';
PRINT '';
PRINT 'Ejecute este comando para probar el job:';
PRINT '';
PRINT 'EXEC msdb.dbo.sp_start_job @job_name = N''' + @job_name + ''';';
PRINT '';
PRINT 'Para ver el historial de ejecución:';
PRINT '';
PRINT 'SELECT TOP 10';
PRINT '    j.name AS job_name,';
PRINT '    h.run_date,';
PRINT '    h.run_time,';
PRINT '    h.run_duration,';
PRINT '    CASE h.run_status';
PRINT '        WHEN 0 THEN ''Failed''';
PRINT '        WHEN 1 THEN ''Succeeded''';
PRINT '        WHEN 2 THEN ''Retry''';
PRINT '        WHEN 3 THEN ''Canceled''';
PRINT '    END AS run_status,';
PRINT '    h.message';
PRINT 'FROM msdb.dbo.sysjobs j';
PRINT 'INNER JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id';
PRINT 'WHERE j.name = N''' + @job_name + '''';
PRINT 'ORDER BY h.run_date DESC, h.run_time DESC;';
PRINT '';

GO






-- Ejecutar manualmente el job
EXEC msdb.dbo.sp_start_job 
    @job_name = N'Job_Calcular_Recargos_Intereses_Municipalidad';

