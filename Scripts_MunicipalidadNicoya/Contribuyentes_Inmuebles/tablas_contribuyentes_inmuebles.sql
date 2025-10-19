-- =============================================
-- MÓDULO: CONTRIBUYENTES E INMUEBLES
-- Script: Creación de Tablas
-- Descripción: Tablas de contribuyentes (físicos/jurídicos) e inmuebles
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '';
PRINT '========================================';
PRINT 'MÓDULO: CONTRIBUYENTES E INMUEBLES';
PRINT '========================================';
GO

-- =============================================
-- PASO 1: ELIMINAR TODAS LAS FK QUE REFERENCIAN ESTAS TABLAS
-- =============================================

-- FK desde módulo Trámites
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Tramite_Inmueble')
    ALTER TABLE dbo.Tramite DROP CONSTRAINT FK_Tramite_Inmueble;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Tramite_Contribuyente')
    ALTER TABLE dbo.Tramite DROP CONSTRAINT FK_Tramite_Contribuyente;

-- FK desde módulo Pagos (CRÍTICO)
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Factura_Inmueble')
    ALTER TABLE dbo.Factura DROP CONSTRAINT FK_Factura_Inmueble;

-- FK internas del módulo
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ObservacionInmueble_Inmueble')
    ALTER TABLE dbo.ObservacionInmueble DROP CONSTRAINT FK_ObservacionInmueble_Inmueble;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Colindancias_Catastro')
    ALTER TABLE dbo.Colindancias DROP CONSTRAINT FK_Colindancias_Catastro;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Catastro_Inmueble')
    ALTER TABLE dbo.Catastro DROP CONSTRAINT FK_Catastro_Inmueble;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Contribuyente_Inmueble_Contribuyente')
    ALTER TABLE dbo.Contribuyente_Inmueble DROP CONSTRAINT FK_Contribuyente_Inmueble_Contribuyente;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Contribuyente_Inmueble_Inmueble')
    ALTER TABLE dbo.Contribuyente_Inmueble DROP CONSTRAINT FK_Contribuyente_Inmueble_Inmueble;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Inmueble_TipoUsoInmueble')
    ALTER TABLE dbo.Inmueble DROP CONSTRAINT FK_Inmueble_TipoUsoInmueble;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Contribuyente_juridico_Contribuyente')
    ALTER TABLE dbo.Contribuyente_juridico DROP CONSTRAINT FK_Contribuyente_juridico_Contribuyente;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Contribuyente_juridico_Representante')
    ALTER TABLE dbo.Contribuyente_juridico DROP CONSTRAINT FK_Contribuyente_juridico_Representante;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Contribuyente_fisico_Contribuyente')
    ALTER TABLE dbo.Contribuyente_fisico DROP CONSTRAINT FK_Contribuyente_fisico_Contribuyente;

-- Índices
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ObservacionInmueble_Inmueble')
    DROP INDEX IX_ObservacionInmueble_Inmueble ON dbo.ObservacionInmueble;

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Colindancias_Catastro')
    DROP INDEX IX_Colindancias_Catastro ON dbo.Colindancias;

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Catastro_Inmueble')
    DROP INDEX IX_Catastro_Inmueble ON dbo.Catastro;
GO

PRINT '✓ Restricciones FK e índices eliminados';
GO

-- =============================================
-- PASO 2: ELIMINAR TABLAS EN ORDEN CORRECTO
-- =============================================

DROP TABLE IF EXISTS dbo.ObservacionInmueble;
DROP TABLE IF EXISTS dbo.Colindancias;
DROP TABLE IF EXISTS dbo.Catastro;
DROP TABLE IF EXISTS dbo.Contribuyente_Inmueble;
DROP TABLE IF EXISTS dbo.Contribuyente_juridico;
DROP TABLE IF EXISTS dbo.Contribuyente_fisico;
DROP TABLE IF EXISTS dbo.Inmueble;
DROP TABLE IF EXISTS dbo.TipoUsoInmueble;
DROP TABLE IF EXISTS dbo.Contribuyente;
GO

PRINT '✓ Tablas eliminadas';
GO



-- =============================================
-- ELIMINAR TABLAS ADICIONALES
-- =============================================

IF OBJECT_ID('dbo.ObservacionInmueble', 'U') IS NOT NULL
    DROP TABLE dbo.ObservacionInmueble;
GO

IF OBJECT_ID('dbo.Colindancias', 'U') IS NOT NULL
    DROP TABLE dbo.Colindancias;
GO

IF OBJECT_ID('dbo.Catastro', 'U') IS NOT NULL
    DROP TABLE dbo.Catastro;
GO



IF OBJECT_ID('dbo.Contribuyente_Inmueble', 'U') IS NOT NULL
    DROP TABLE dbo.Contribuyente_Inmueble;
GO

IF OBJECT_ID('dbo.Inmueble', 'U') IS NOT NULL
    DROP TABLE dbo.Inmueble;
GO

IF OBJECT_ID('dbo.Contribuyente_juridico', 'U') IS NOT NULL
    DROP TABLE dbo.Contribuyente_juridico;
GO

IF OBJECT_ID('dbo.Contribuyente_fisico', 'U') IS NOT NULL
    DROP TABLE dbo.Contribuyente_fisico;
GO

IF OBJECT_ID('dbo.Contribuyente', 'U') IS NOT NULL
    DROP TABLE dbo.Contribuyente;
GO

IF OBJECT_ID('dbo.TipoUsoInmueble', 'U') IS NOT NULL
    DROP TABLE dbo.TipoUsoInmueble;
GO

-- =============================================
-- TABLA: Contribuyente (Padre)
-- =============================================
CREATE TABLE dbo.Contribuyente
(
    contribuyente_id INT IDENTITY(1,1) NOT NULL,
    tipo_contribuyente VARCHAR(20) NOT NULL,
    telefono VARCHAR(20) NULL,
    email VARCHAR(100) NULL,
    direccion VARCHAR(255) NULL,
    
    CONSTRAINT PK_Contribuyente PRIMARY KEY (contribuyente_id),
    CONSTRAINT CK_Contribuyente_Tipo CHECK (tipo_contribuyente IN ('Física', 'Jurídica')),
    CONSTRAINT CK_Contribuyente_Email CHECK (email LIKE '%@%' OR email IS NULL)
);
GO

PRINT '✓ Tabla Contribuyente creada';
GO

-- =============================================
-- TABLA: Contribuyente_fisico (Hija)
-- =============================================
CREATE TABLE dbo.Contribuyente_fisico
(
    contribuyentes_fisicos_id INT IDENTITY(1,1) NOT NULL,
    contribuyente_id INT NOT NULL,
    cedula VARCHAR(20) NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido1 VARCHAR(50) NOT NULL,
    apellido2 VARCHAR(50) NOT NULL,
    
    CONSTRAINT PK_Contribuyente_fisico PRIMARY KEY (contribuyentes_fisicos_id),
    CONSTRAINT FK_Contribuyente_fisico_Contribuyente 
        FOREIGN KEY (contribuyente_id) REFERENCES dbo.Contribuyente(contribuyente_id)
        ON DELETE CASCADE,
    CONSTRAINT UQ_Contribuyente_fisico_Cedula UNIQUE (cedula),
    CONSTRAINT UQ_Contribuyente_fisico_Contribuyente UNIQUE (contribuyente_id)
);
GO

PRINT '✓ Tabla Contribuyente_fisico creada';
GO

-- =============================================
-- TABLA: Contribuyente_juridico (Hija)
-- =============================================
CREATE TABLE dbo.Contribuyente_juridico
(
    contribuyentes_fisicos_id INT IDENTITY(1,1) NOT NULL,
    contribuyente_id INT NOT NULL,
    cedula_juridica VARCHAR(50) NOT NULL,
    nombre_empresa VARCHAR(50) NOT NULL,
    representante_legal_id INT NOT NULL,
    
    CONSTRAINT PK_Contribuyente_juridico PRIMARY KEY (contribuyentes_fisicos_id),
    CONSTRAINT FK_Contribuyente_juridico_Contribuyente 
        FOREIGN KEY (contribuyente_id) REFERENCES dbo.Contribuyente(contribuyente_id)
        ON DELETE CASCADE,
    CONSTRAINT FK_Contribuyente_juridico_Representante 
        FOREIGN KEY (representante_legal_id) REFERENCES dbo.Contribuyente_fisico(contribuyentes_fisicos_id),
    CONSTRAINT UQ_Contribuyente_juridico_Cedula UNIQUE (cedula_juridica),
    CONSTRAINT UQ_Contribuyente_juridico_Contribuyente UNIQUE (contribuyente_id)
);
GO

PRINT '✓ Tabla Contribuyente_juridico creada';
GO

-- =============================================
-- TABLA CATÁLOGO: TipoUsoInmueble
-- =============================================
CREATE TABLE dbo.TipoUsoInmueble
(
    tipo_uso_inmueble_id INT IDENTITY(1,1) NOT NULL,
    nombre_uso VARCHAR(50) NOT NULL,
    descripcion VARCHAR(300) NULL,
    
    CONSTRAINT PK_TipoUsoInmueble PRIMARY KEY (tipo_uso_inmueble_id),
    CONSTRAINT UQ_TipoUsoInmueble_Nombre UNIQUE (nombre_uso)
);
GO

-- Insertar tipos de uso comunes
INSERT INTO TipoUsoInmueble (nombre_uso, descripcion) VALUES
('Residencial', 'Vivienda familiar o multifamiliar'),
('Comercial', 'Establecimientos comerciales, tiendas, oficinas'),
('Industrial', 'Fábricas, bodegas, instalaciones industriales'),
('Agrícola', 'Terrenos para cultivo o ganadería'),
('Mixto', 'Uso residencial y comercial combinado'),
('Baldío', 'Terreno sin construcción ni uso específico'),
('Institucional', 'Escuelas, hospitales, iglesias, edificios públicos'),
('Recreativo', 'Parques, centros deportivos, áreas verdes');
GO

PRINT '✓ Tabla TipoUsoInmueble creada con datos iniciales';
GO

-- =============================================
-- TABLA: Inmueble
-- =============================================
CREATE TABLE dbo.Inmueble
(
    inmueble_id INT IDENTITY(1,1) NOT NULL,
    direccion_exacta VARCHAR(255) NOT NULL,
    area_terreno DECIMAL(10,2) NOT NULL,
    valor_fiscal DECIMAL(18,2) NOT NULL,
    estado_ocupacional VARCHAR(50) NULL,
    tipo_uso_inmueble_id INT NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT PK_Inmueble PRIMARY KEY (inmueble_id),
    CONSTRAINT FK_Inmueble_TipoUsoInmueble 
        FOREIGN KEY (tipo_uso_inmueble_id) 
        REFERENCES dbo.TipoUsoInmueble(tipo_uso_inmueble_id),
    CONSTRAINT CK_Inmueble_AreaTerreno CHECK (area_terreno > 0),
    CONSTRAINT CK_Inmueble_ValorFiscal CHECK (valor_fiscal >= 0)
);
GO

PRINT '✓ Tabla Inmueble creada';
GO

-- =============================================
-- TABLA RELACIÓN N:M: Contribuyente_Inmueble
-- =============================================
CREATE TABLE dbo.Contribuyente_Inmueble
(
    contribuyente_inmueble_id INT IDENTITY(1,1) NOT NULL,
    contribuyente_id INT NOT NULL,
    inmueble_id INT NOT NULL,
    porcentaje_propiedad DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    fecha_registro DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT PK_Contribuyente_Inmueble PRIMARY KEY (contribuyente_inmueble_id),
    CONSTRAINT FK_Contribuyente_Inmueble_Contribuyente 
        FOREIGN KEY (contribuyente_id) 
        REFERENCES dbo.Contribuyente(contribuyente_id)
        ON DELETE CASCADE,
    CONSTRAINT FK_Contribuyente_Inmueble_Inmueble 
        FOREIGN KEY (inmueble_id) 
        REFERENCES dbo.Inmueble(inmueble_id)
        ON DELETE CASCADE,
    CONSTRAINT CK_Contribuyente_Inmueble_Porcentaje 
        CHECK (porcentaje_propiedad > 0 AND porcentaje_propiedad <= 100),
    CONSTRAINT UQ_Contribuyente_Inmueble 
        UNIQUE (contribuyente_id, inmueble_id)
);
GO

PRINT '✓ Tabla Contribuyente_Inmueble creada';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ MÓDULO CONTRIBUYENTES E INMUEBLES';
PRINT '  Todas las tablas creadas exitosamente';
PRINT '========================================';
GO

use MunicipalidadNicoya
go
-- =============================================
-- TABLA: Catastro
-- =============================================
CREATE TABLE dbo.Catastro
(
    catastro_id INT IDENTITY(1,1) NOT NULL,
    numero_plano_catastral VARCHAR(50) NOT NULL,
    area_catastral VARCHAR(100) NULL,
    fecha_inscripcion DATE NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Activo',
    inmueble_id INT NOT NULL,
    
    CONSTRAINT PK_Catastro PRIMARY KEY (catastro_id),
    CONSTRAINT FK_Catastro_Inmueble 
        FOREIGN KEY (inmueble_id) REFERENCES dbo.Inmueble(inmueble_id)
        ON DELETE CASCADE,
    CONSTRAINT UQ_Catastro_NumeroPlano UNIQUE (numero_plano_catastral),
    CONSTRAINT CK_Catastro_Estado CHECK (estado IN ('Activo', 'Inactivo', 'En Revisión'))
);
GO

CREATE INDEX IX_Catastro_Inmueble ON dbo.Catastro(inmueble_id);
GO

PRINT '✓ Tabla Catastro creada';
GO

-- =============================================
-- TABLA: Colindancias
-- =============================================
CREATE TABLE dbo.Colindancias
(
    colindancias_id INT IDENTITY(1,1) NOT NULL,
    punto_cardinal VARCHAR(10) NOT NULL,
    colindante VARCHAR(255) NOT NULL,
    catastro_id INT NOT NULL,
    
    CONSTRAINT PK_Colindancias PRIMARY KEY (colindancias_id),
    CONSTRAINT FK_Colindancias_Catastro 
        FOREIGN KEY (catastro_id) REFERENCES dbo.Catastro(catastro_id)
        ON DELETE CASCADE,
    CONSTRAINT CK_Colindancias_PuntoCardinal 
        CHECK (punto_cardinal IN ('Norte', 'Sur', 'Este', 'Oeste'))
);
GO

CREATE INDEX IX_Colindancias_Catastro ON dbo.Colindancias(catastro_id);
GO

PRINT '✓ Tabla Colindancias creada';
GO

-- =============================================
-- TABLA: ObservacionInmueble
-- =============================================
CREATE TABLE dbo.ObservacionInmueble
(
    observacion_inmueble_id INT IDENTITY(1,1) NOT NULL,
    fecha DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    descripcion VARCHAR(300) NOT NULL,
    inmueble_id INT NOT NULL,
    
    
    CONSTRAINT PK_ObservacionInmueble PRIMARY KEY (observacion_inmueble_id),
    CONSTRAINT FK_ObservacionInmueble_Inmueble 
        FOREIGN KEY (inmueble_id) REFERENCES dbo.Inmueble(inmueble_id)
        ON DELETE CASCADE,
    CONSTRAINT CK_ObservacionInmueble_Descripcion 
        CHECK (LEN(TRIM(descripcion)) > 0)
   
);
GO

CREATE INDEX IX_ObservacionInmueble_Inmueble ON dbo.ObservacionInmueble(inmueble_id);
GO

PRINT '✓ Tabla ObservacionInmueble creada';
GO

PRINT '';
PRINT '========================================';
PRINT '✓ TABLAS CREADAS';
PRINT '  - Catastro';
PRINT '  - Colindancias';
PRINT '  - ObservacionInmueble';
PRINT '========================================';
GO







-- =============================================
-- TABLA: Servicio_Inmueble
-- Descripción: Configuración permanente de servicios por inmueble
-- Propósito: Define QUÉ servicios tiene contratados cada inmueble
--            para la generación automática de facturas trimestrales
-- =============================================

USE MunicipalidadNicoya;
GO

PRINT '';
PRINT '========================================';
PRINT '🏗️ CREACIÓN DE TABLA: Servicio_Inmueble';
PRINT '========================================';
PRINT '';

-- =============================================
-- 1. ELIMINAR TABLA SI EXISTE (para recrear limpia)
-- =============================================

IF OBJECT_ID('dbo.Servicio_Inmueble', 'U') IS NOT NULL
BEGIN
    PRINT '⚠️  La tabla Servicio_Inmueble ya existe';
    PRINT '   Eliminando para recrear...';
    DROP TABLE dbo.Servicio_Inmueble;
    PRINT '   ✓ Tabla eliminada';
    PRINT '';
END

-- =============================================
-- 2. CREAR TABLA SERVICIO_INMUEBLE
-- =============================================

PRINT '📦 Creando tabla Servicio_Inmueble...';
GO

CREATE TABLE dbo.Servicio_Inmueble (
    -- Identificador único
    servicio_inmueble_id INT IDENTITY(1,1) NOT NULL,
    
    -- Relaciones
    inmueble_id INT NOT NULL,
    rubro_id INT NOT NULL,
    
    -- Estado del servicio
    activo BIT NOT NULL DEFAULT 1,
    
    -- Control de fechas
    fecha_inicio DATE NOT NULL DEFAULT GETDATE(),
    fecha_fin DATE NULL,
    
    -- Tarifa personalizada (opcional)
    tarifa_personalizada DECIMAL(12,2) NULL,
    
    -- Observaciones
    observaciones VARCHAR(300) NULL,
    
    -- =============================================
    -- CONSTRAINT: Clave primaria
    -- =============================================
    CONSTRAINT PK_ServicioInmueble 
        PRIMARY KEY CLUSTERED (servicio_inmueble_id),
    
    -- =============================================
    -- CONSTRAINT: Claves foráneas (relaciones)
    -- =============================================
    
    -- Relación con Inmueble (N:1)
    CONSTRAINT FK_ServicioInmueble_Inmueble 
        FOREIGN KEY (inmueble_id) 
        REFERENCES dbo.Inmueble(inmueble_id)
        ON DELETE CASCADE,  -- Si eliminas inmueble, eliminas sus servicios
    
    -- Relación con Rubro (N:1)
    CONSTRAINT FK_ServicioInmueble_Rubro 
        FOREIGN KEY (rubro_id) 
        REFERENCES dbo.Rubro(rubro_id)
        ON DELETE NO ACTION,  -- No permitir eliminar rubro si tiene servicios activos
    
    -- =============================================
    -- CONSTRAINT: Un inmueble NO puede tener el mismo servicio duplicado
    -- =============================================
    CONSTRAINT UQ_ServicioInmueble_InmuebleRubro 
        UNIQUE (inmueble_id, rubro_id),
    
    -- =============================================
    -- CONSTRAINT: Validación de fechas
    -- =============================================
    CONSTRAINT CHK_ServicioInmueble_FechaFin 
        CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    
    -- =============================================
    -- CONSTRAINT: Tarifa personalizada no puede ser negativa
    -- =============================================
    CONSTRAINT CHK_ServicioInmueble_TarifaPersonalizada 
        CHECK (tarifa_personalizada IS NULL OR tarifa_personalizada >= 0)
);

PRINT '   ✓ Tabla creada exitosamente';
PRINT '';

-- =============================================
-- 3. CREAR ÍNDICES PARA OPTIMIZACIÓN
-- =============================================

PRINT '📊 Creando índices de optimización...';
GO

-- Índice para buscar servicios activos de un inmueble
CREATE NONCLUSTERED INDEX IDX_ServicioInmueble_Inmueble_Activo
    ON dbo.Servicio_Inmueble(inmueble_id, activo)
    INCLUDE (rubro_id, tarifa_personalizada)
    WHERE activo = 1;

PRINT '   ✓ IDX_ServicioInmueble_Inmueble_Activo creado';

-- Índice para buscar qué inmuebles tienen un servicio específico
CREATE NONCLUSTERED INDEX IDX_ServicioInmueble_Rubro_Activo
    ON dbo.Servicio_Inmueble(rubro_id, activo)
    INCLUDE (inmueble_id)
    WHERE activo = 1;

PRINT '   ✓ IDX_ServicioInmueble_Rubro_Activo creado';

-- Índice para consultas por fecha
CREATE NONCLUSTERED INDEX IDX_ServicioInmueble_FechaInicio
    ON dbo.Servicio_Inmueble(fecha_inicio)
    INCLUDE (inmueble_id, rubro_id, activo);

PRINT '   ✓ IDX_ServicioInmueble_FechaInicio creado';

PRINT '';

-- =============================================
-- 4. DOCUMENTACIÓN DE LA TABLA
-- =============================================

PRINT '========================================';
PRINT '📖 DOCUMENTACIÓN';
PRINT '========================================';
PRINT '';
PRINT 'Tabla: Servicio_Inmueble';
PRINT '';
PRINT 'Propósito:';
PRINT '  Almacena la configuración PERMANENTE de servicios';
PRINT '  que tiene contratados cada inmueble.';
PRINT '';
PRINT 'Columnas:';
PRINT '  - servicio_inmueble_id: ID único (autoincremental)';
PRINT '  - inmueble_id: FK → Inmueble (¿PARA CUÁL inmueble?)';
PRINT '  - rubro_id: FK → Rubro (¿QUÉ servicio tiene?)';
PRINT '  - activo: 1=Activo, 0=Desactivado';
PRINT '  - fecha_inicio: Desde cuándo tiene el servicio';
PRINT '  - fecha_fin: Cuándo se desactivó (NULL si activo)';
PRINT '  - tarifa_personalizada: Tarifa especial (anula tarifa del rubro)';
PRINT '  - observaciones: Notas adicionales';
PRINT '';
PRINT 'Relaciones:';
PRINT '  ┌─────────────┐';
PRINT '  │  Inmueble   │';
PRINT '  └──────┬──────┘';
PRINT '         │ 1';
PRINT '         │';
PRINT '         │ N';
PRINT '  ┌──────┴────────────┐      N  ┌─────────┐';
PRINT '  │ Servicio_Inmueble │◄────────┤  Rubro  │';
PRINT '  └───────────────────┘      1  └─────────┘';
PRINT '';
PRINT 'Restricciones:';
PRINT '  ✓ Un inmueble NO puede tener duplicado el mismo servicio';
PRINT '  ✓ fecha_fin debe ser >= fecha_inicio';
PRINT '  ✓ tarifa_personalizada no puede ser negativa';
PRINT '  ✓ Si eliminas inmueble → se eliminan sus servicios (CASCADE)';
PRINT '  ✓ NO puedes eliminar rubro si tiene servicios activos';
PRINT '';

-- =============================================
-- 5. EJEMPLOS DE USO
-- =============================================

PRINT '========================================';
PRINT '📝 EJEMPLOS DE USO';
PRINT '========================================';
PRINT '';
PRINT '-- Ejemplo 1: Agregar servicios a un inmueble';
PRINT 'INSERT INTO Servicio_Inmueble (inmueble_id, rubro_id, activo)';
PRINT 'VALUES ';
PRINT '  (123, 1, 1),  -- Impuesto territorial';
PRINT '  (123, 2, 1),  -- Recolección basura';
PRINT '  (123, 3, 1);  -- Alumbrado público';
PRINT '';
PRINT '-- Ejemplo 2: Consultar servicios activos de un inmueble';
PRINT 'SELECT ';
PRINT '    si.servicio_inmueble_id,';
PRINT '    r.nombre AS servicio,';
PRINT '    si.fecha_inicio,';
PRINT '    si.tarifa_personalizada';
PRINT 'FROM Servicio_Inmueble si';
PRINT 'INNER JOIN Rubro r ON si.rubro_id = r.rubro_id';
PRINT 'WHERE si.inmueble_id = 123';
PRINT '  AND si.activo = 1;';
PRINT '';
PRINT '-- Ejemplo 3: Desactivar un servicio';
PRINT 'UPDATE Servicio_Inmueble';
PRINT 'SET activo = 0,';
PRINT '    fecha_fin = GETDATE()';
PRINT 'WHERE inmueble_id = 123';
PRINT '  AND rubro_id = 3;  -- Desactivar alumbrado';
PRINT '';
PRINT '-- Ejemplo 4: Reactivar un servicio';
PRINT 'UPDATE Servicio_Inmueble';
PRINT 'SET activo = 1,';
PRINT '    fecha_fin = NULL,';
PRINT '    fecha_inicio = GETDATE()';
PRINT 'WHERE inmueble_id = 123';
PRINT '  AND rubro_id = 3;';
PRINT '';

-- =============================================
-- 6. VERIFICACIÓN FINAL
-- =============================================

PRINT '========================================';
PRINT '✅ VERIFICACIÓN';
PRINT '========================================';
PRINT '';

-- Verificar que la tabla existe
IF OBJECT_ID('dbo.Servicio_Inmueble', 'U') IS NOT NULL
    PRINT '✓ Tabla Servicio_Inmueble creada correctamente';
ELSE
    PRINT '✗ ERROR: La tabla NO se creó';

-- Verificar relaciones (FK)
IF EXISTS (
    SELECT 1 FROM sys.foreign_keys 
    WHERE name = 'FK_ServicioInmueble_Inmueble'
)
    PRINT '✓ FK con Inmueble creada correctamente';
ELSE
    PRINT '✗ ERROR: FK con Inmueble NO existe';

IF EXISTS (
    SELECT 1 FROM sys.foreign_keys 
    WHERE name = 'FK_ServicioInmueble_Rubro'
)
    PRINT '✓ FK con Rubro creada correctamente';
ELSE
    PRINT '✗ ERROR: FK con Rubro NO existe';

-- Verificar restricción UNIQUE
IF EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'UQ_ServicioInmueble_InmuebleRubro'
)
    PRINT '✓ Restricción UNIQUE creada correctamente';
ELSE
    PRINT '✗ ERROR: Restricción UNIQUE NO existe';

-- Contar índices
DECLARE @cant_indices INT;
SELECT @cant_indices = COUNT(*) 
FROM sys.indexes 
WHERE object_id = OBJECT_ID('dbo.Servicio_Inmueble')
  AND name IS NOT NULL;

PRINT '✓ Total de índices creados: ' + CAST(@cant_indices AS VARCHAR);

PRINT '';
PRINT '========================================';
PRINT '🎉 TABLA SERVICIO_INMUEBLE LISTA';
PRINT '========================================';
PRINT '';
PRINT 'Próximos pasos:';
PRINT '  1. Crear SPs para gestionar servicios';
PRINT '  2. Crear SP de generación automática de facturas';
PRINT '  3. Configurar Job trimestral';
PRINT '';
GO




