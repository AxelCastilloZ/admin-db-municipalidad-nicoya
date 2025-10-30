-- =============================================
-- ETL PARTE 1: POBLACIÓN DE DIMENSIONES
-- Datamart: Reportes Administrativos
-- =============================================

USE MunicipalidadNicoya;
GO

-- Dimensión: DIM_Tiempo
DECLARE @FechaInicio DATE = '2020-01-01';
DECLARE @FechaFin DATE = '2030-12-31';
DECLARE @FechaActual DATE = @FechaInicio;

WHILE @FechaActual <= @FechaFin
BEGIN
    INSERT INTO DM.DIM_Tiempo (
        fecha, anio, trimestre, mes, mes_nombre, dia, dia_semana, 
        dia_semana_nombre, semana_anio, es_fin_semana
    )
    VALUES (
        @FechaActual,
        YEAR(@FechaActual),
        DATEPART(QUARTER, @FechaActual),
        MONTH(@FechaActual),
        CASE MONTH(@FechaActual)
            WHEN 1 THEN 'Enero' WHEN 2 THEN 'Febrero' WHEN 3 THEN 'Marzo'
            WHEN 4 THEN 'Abril' WHEN 5 THEN 'Mayo' WHEN 6 THEN 'Junio'
            WHEN 7 THEN 'Julio' WHEN 8 THEN 'Agosto' WHEN 9 THEN 'Septiembre'
            WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
        END,
        DAY(@FechaActual),
        DATEPART(WEEKDAY, @FechaActual),
        CASE DATEPART(WEEKDAY, @FechaActual)
            WHEN 1 THEN 'Domingo' WHEN 2 THEN 'Lunes' WHEN 3 THEN 'Martes'
            WHEN 4 THEN 'Miércoles' WHEN 5 THEN 'Jueves' WHEN 6 THEN 'Viernes'
            WHEN 7 THEN 'Sábado'
        END,
        DATEPART(WEEK, @FechaActual),
        CASE WHEN DATEPART(WEEKDAY, @FechaActual) IN (1, 7) THEN 1 ELSE 0 END
    );
    SET @FechaActual = DATEADD(DAY, 1, @FechaActual);
END;
GO

-- Dimensión: DIM_Estado_Factura
INSERT INTO DM.DIM_Estado_Factura (estado, descripcion)
VALUES 
    ('Pendiente', 'Factura emitida, pendiente de pago'),
    ('Pagada', 'Factura pagada completamente'),
    ('Vencida', 'Factura con fecha de vencimiento superada'),
    ('Cancelada', 'Factura anulada o cancelada');
GO

-- Dimensión: DIM_Contribuyente (con extracción de distrito desde dirección)
INSERT INTO DM.DIM_Contribuyente (
    contribuyente_id, nombre, tipo_contribuyente, cedula, 
    distrito, canton, telefono, email
)
SELECT 
    c.contribuyente_id,
    COALESCE(cf.nombre, cj.nombre_empresa, 'Sin nombre'),
    CASE 
        WHEN cf.contribuyente_id IS NOT NULL THEN 'Física'
        WHEN cj.contribuyente_id IS NOT NULL THEN 'Jurídica'
        ELSE 'Física'
    END,
    COALESCE(cf.cedula, cj.cedula_juridica, 'N/A'),
    CASE
        WHEN c.direccion LIKE '%Belén%' OR c.direccion LIKE '%Belen%' OR c.direccion LIKE '%Nosarita%' THEN 'Belén de Nosarita'
        WHEN c.direccion LIKE '%Nosara%' THEN 'Nosara'
        WHEN c.direccion LIKE '%Sámara%' OR c.direccion LIKE '%Samara%' THEN 'Sámara'
        WHEN c.direccion LIKE '%Quebrada Honda%' OR c.direccion LIKE '%Qda Honda%' THEN 'Quebrada Honda'
        WHEN c.direccion LIKE '%San Antonio%' OR c.direccion LIKE '%Sn Antonio%' THEN 'San Antonio'
        WHEN c.direccion LIKE '%Mansión%' OR c.direccion LIKE '%Mansion%' THEN 'Mansión'
        WHEN c.direccion LIKE '%Nicoya%' OR c.direccion LIKE '%Centro%' OR c.direccion LIKE '%centro%' THEN 'Nicoya'
        ELSE 'Nicoya'
    END AS distrito,
    'Nicoya' AS canton,
    c.telefono,
    c.email
FROM dbo.Contribuyente c
LEFT JOIN dbo.Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
LEFT JOIN dbo.Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id;
GO

-- Dimensión: DIM_Inmueble
INSERT INTO DM.DIM_Inmueble (
    inmueble_id,
    numero_finca,
    direccion_exacta,
    distrito,
    canton,
    area_terreno,
    area_construccion,
    uso_inmueble,
    estado_ocupacional,
    valor_fiscal
)
SELECT 
    i.inmueble_id,
    'FINCA-' + CAST(i.inmueble_id AS VARCHAR(10)) AS numero_finca,
    i.Direccion_exacta,
    'Nicoya' AS distrito,
    'Nicoya' AS canton,
    i.Area_terreno,
    NULL AS area_construccion,
    t.nombre_uso AS uso_inmueble,
    i.Estado_ocupacional,
    i.valor_fiscal
FROM dbo.Inmueble i
LEFT JOIN dbo.TipoUsoInmueble t ON i.tipo_uso_inmueble_id = t.tipo_uso_inmueble_id;
GO

-- Dimensión: DIM_Rubro
INSERT INTO DM.DIM_Rubro (
    rubro_id, nombre, descripcion, periodicidad, tarifa_base,
    aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo
)
SELECT 
    rubro_id, nombre, descripcion, periodicidad, tarifa_base,
    aplica_recargo, aplica_intereses, tasa_interes, tasa_recargo
FROM dbo.Rubro
WHERE vigencia = 1;
GO

-- Dimensión: DIM_Tramite
INSERT INTO DM.DIM_Tramite (
    tramite_id, tipo_tramite, estado_tramite, 
    fecha_ingreso, fecha_resolucion, dias_resolucion
)
SELECT 
    t.tramite_id,
    tt.nombre_tipo,
    t.estado_actual,
    t.fecha_ingreso,
    t.fecha_resolucion,
    CASE 
        WHEN t.fecha_resolucion IS NOT NULL 
        THEN DATEDIFF(DAY, t.fecha_ingreso, t.fecha_resolucion)
        ELSE NULL
    END
FROM dbo.Tramite t
INNER JOIN dbo.Tipo_Tramite tt ON t.tipo_tramite_id = tt.tipo_tramite_id;
GO

-- Fin de carga de dimensiones
