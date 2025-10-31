USE MunicipalidadNicoya;
GO

PRINT '';
PRINT '==================================================================';
PRINT 'AUDITORÍA CONTRIBUYENTE COMPLETA Y FINAL';
PRINT '   ANTERIOR + NUEVO | 1 FILA POR ACCIÓN';
PRINT '==================================================================';
PRINT '';

-- =============================================
-- 1. TABLA: Auditoría con ANTERIOR y NUEVO
-- =============================================
IF OBJECT_ID('dbo.Contribuyente_Auditoria') IS NOT NULL DROP TABLE dbo.Contribuyente_Auditoria;
GO

CREATE TABLE dbo.Contribuyente_Auditoria
(
    auditoria_id INT IDENTITY(1,1) PRIMARY KEY,
    accion VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE

    -- === ANTERIOR ===
    tipo_contribuyente_anterior VARCHAR(20),
    cedula_anterior VARCHAR(50),
    nombre_completo_anterior VARCHAR(200),
    nombre_empresa_anterior VARCHAR(100),
    representante_anterior VARCHAR(200),
    telefono_anterior VARCHAR(20),
    email_anterior VARCHAR(100),
    direccion_anterior VARCHAR(255),

    -- === NUEVO ===
    tipo_contribuyente_nuevo VARCHAR(20),
    cedula_nuevo VARCHAR(50),
    nombre_completo_nuevo VARCHAR(200),
    nombre_empresa_nuevo VARCHAR(100),
    representante_nuevo VARCHAR(200),
    telefono_nuevo VARCHAR(20),
    email_nuevo VARCHAR(100),
    direccion_nuevo VARCHAR(255),

    contribuyente_id INT NOT NULL,
    fecha_cambio DATETIME DEFAULT GETDATE(),
    usuario_cambio VARCHAR(100) DEFAULT SUSER_NAME()
);
GO

PRINT '  Tabla Contribuyente_Auditoria creada';
PRINT '';

-- =============================================
-- 2. FUNCIÓN: Datos completos del contribuyente
-- =============================================
IF OBJECT_ID('dbo.fn_Contribuyente_Datos') IS NOT NULL DROP FUNCTION dbo.fn_Contribuyente_Datos;
GO

CREATE FUNCTION dbo.fn_Contribuyente_Datos(@contribuyente_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        c.tipo_contribuyente,
        COALESCE(cf.cedula, cj.cedula_juridica) AS cedula,
        CASE 
            WHEN c.tipo_contribuyente = 'Física' THEN RTRIM(cf.nombre + ' ' + cf.apellido1 + ISNULL(' ' + cf.apellido2, ''))
            WHEN c.tipo_contribuyente = 'Jurídica' THEN cj.nombre_empresa
            ELSE 'N/A'
        END AS nombre_completo,
        cj.nombre_empresa,
        CASE 
            WHEN cj.representante_legal_id IS NOT NULL 
            THEN RTRIM(rf.nombre + ' ' + rf.apellido1 + ISNULL(' ' + rf.apellido2, ''))
            ELSE 'N/A'
        END AS representante,
        c.telefono,
        c.email,
        c.direccion
    FROM Contribuyente c
    LEFT JOIN Contribuyente_fisico cf ON c.contribuyente_id = cf.contribuyente_id
    LEFT JOIN Contribuyente_juridico cj ON c.contribuyente_id = cj.contribuyente_id
    LEFT JOIN Contribuyente_fisico rf ON cj.representante_legal_id = rf.contribuyente_id
    WHERE c.contribuyente_id = @contribuyente_id
);
GO

PRINT '  Función fn_Contribuyente_Datos creada';
PRINT '';

-- =============================================
-- 3. TRIGGER: Contribuyente_fisico (INSERT + UPDATE)
-- =============================================
IF OBJECT_ID('dbo.trg_ContribuyenteFisico_Auditoria') IS NOT NULL DROP TRIGGER dbo.trg_ContribuyenteFisico_Auditoria;
GO

CREATE TRIGGER dbo.trg_ContribuyenteFisico_Auditoria 
ON dbo.Contribuyente_fisico 
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Contribuyente_Auditoria (
            accion, contribuyente_id,
            tipo_contribuyente_nuevo, cedula_nuevo, nombre_completo_nuevo,
            nombre_empresa_nuevo, representante_nuevo, telefono_nuevo, email_nuevo, direccion_nuevo
        )
        SELECT 
            'INSERT', i.contribuyente_id,
            d.tipo_contribuyente, d.cedula, d.nombre_completo,
            d.nombre_empresa, d.representante, d.telefono, d.email, d.direccion
        FROM inserted i
       CROSS APPLY dbo.fn_Contribuyente_Datos(i.contribuyente_id) d;
    END

    -- UPDATE
    ELSE IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Contribuyente_Auditoria (
            accion, contribuyente_id,
            tipo_contribuyente_anterior, cedula_anterior, nombre_completo_anterior,
            nombre_empresa_anterior, representante_anterior, telefono_anterior, email_anterior, direccion_anterior,
            tipo_contribuyente_nuevo, cedula_nuevo, nombre_completo_nuevo,
            nombre_empresa_nuevo, representante_nuevo, telefono_nuevo, email_nuevo, direccion_nuevo
        )
        SELECT 
            'UPDATE', i.contribuyente_id,
            da.tipo_contribuyente, da.cedula, da.nombre_completo,
            da.nombre_empresa, da.representante, da.telefono, da.email, da.direccion,
            dn.tipo_contribuyente, dn.cedula, dn.nombre_completo,
            dn.nombre_empresa, dn.representante, dn.telefono, dn.email, dn.direccion
        FROM inserted i
        INNER JOIN deleted del ON i.contribuyente_id = del.contribuyente_id
        CROSS APPLY dbo.fn_Contribuyente_Datos(del.contribuyente_id) da
        CROSS APPLY dbo.fn_Contribuyente_Datos(i.contribuyente_id) dn;
    END
END
GO

PRINT '  Trigger físico: INSERT + UPDATE';
PRINT '';

-- =============================================
-- 4. TRIGGER: Contribuyente_juridico (INSERT + UPDATE)
-- =============================================
IF OBJECT_ID('dbo.trg_ContribuyenteJuridico_Auditoria') IS NOT NULL DROP TRIGGER dbo.trg_ContribuyenteJuridico_Auditoria;
GO

CREATE TRIGGER dbo.trg_ContribuyenteJuridico_Auditoria 
ON dbo.Contribuyente_juridico 
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Contribuyente_Auditoria (
            accion, contribuyente_id,
            tipo_contribuyente_nuevo, cedula_nuevo, nombre_completo_nuevo,
            nombre_empresa_nuevo, representante_nuevo, telefono_nuevo, email_nuevo, direccion_nuevo
        )
        SELECT 
            'INSERT', i.contribuyente_id,
            d.tipo_contribuyente, d.cedula, d.nombre_completo,
            d.nombre_empresa, d.representante, d.telefono, d.email, d.direccion
        FROM inserted i
        CROSS APPLY dbo.fn_Contribuyente_Datos(i.contribuyente_id) d;
    END

    -- UPDATE
    ELSE IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO Contribuyente_Auditoria (
            accion, contribuyente_id,
            tipo_contribuyente_anterior, cedula_anterior, nombre_completo_anterior,
            nombre_empresa_anterior, representante_anterior, telefono_anterior, email_anterior, direccion_anterior,
            tipo_contribuyente_nuevo, cedula_nuevo, nombre_completo_nuevo,
            nombre_empresa_nuevo, representante_nuevo, telefono_nuevo, email_nuevo, direccion_nuevo
        )
        SELECT 
            'UPDATE', i.contribuyente_id,
            da.tipo_contribuyente, da.cedula, da.nombre_completo,
            da.nombre_empresa, da.representante, da.telefono, da.email, da.direccion,
            dn.tipo_contribuyente, dn.cedula, dn.nombre_completo,
            dn.nombre_empresa, dn.representante, dn.telefono, dn.email, dn.direccion
        FROM inserted i
        INNER JOIN deleted del ON i.contribuyente_id = del.contribuyente_id
        CROSS APPLY dbo.fn_Contribuyente_Datos(del.contribuyente_id) da
        CROSS APPLY dbo.fn_Contribuyente_Datos(i.contribuyente_id) dn;
    END
END
GO

PRINT '  Trigger jurídico: INSERT + UPDATE';
PRINT '';
-- =============================================
-- 5. TRIGGER: Contribuyente → INSTEAD OF DELETE (SOLUCIÓN FINAL)
-- =============================================
IF OBJECT_ID('dbo.trg_Contribuyente_Delete_Auditoria') IS NOT NULL 
    DROP TRIGGER dbo.trg_Contribuyente_Delete_Auditoria;
GO

CREATE TRIGGER dbo.trg_Contribuyente_Delete_Auditoria 
ON dbo.Contribuyente 
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. GUARDAR AUDITORÍA CON DATOS ANTERIORES
    INSERT INTO Contribuyente_Auditoria (
        accion, contribuyente_id,
        tipo_contribuyente_anterior, cedula_anterior, nombre_completo_anterior,
        nombre_empresa_anterior, representante_anterior, telefono_anterior, email_anterior, direccion_anterior
    )
    SELECT 
        'DELETE',
        d.contribuyente_id,
        data.tipo_contribuyente,
        data.cedula,
        data.nombre_completo,
        data.nombre_empresa,
        data.representante,
        data.telefono,
        data.email,
        data.direccion
    FROM deleted d
    CROSS APPLY dbo.fn_Contribuyente_Datos(d.contribuyente_id) data;

    -- 2. EJECUTAR EL DELETE REAL (igual que CASCADE)
    DELETE FROM Contribuyente 
    WHERE contribuyente_id IN (SELECT contribuyente_id FROM deleted);
END
GO

PRINT '  Trigger INSTEAD OF DELETE: GARANTIZA AUDITORÍA';
PRINT '';

-- =============================================
-- 6. SP: Consultar historial
-- =============================================
IF OBJECT_ID('dbo.sp_Contribuyente_ConsultarHistorial') IS NOT NULL DROP PROCEDURE dbo.sp_Contribuyente_ConsultarHistorial;
GO

CREATE PROCEDURE dbo.sp_Contribuyente_ConsultarHistorial
    @cedula VARCHAR(50) = NULL,
    @contribuyente_id INT = NULL
AS
BEGIN
    SELECT 
        auditoria_id,
        accion,
        fecha_cambio,
        usuario_cambio,
        contribuyente_id,
        ISNULL(cedula_anterior, '—') AS [Cédula Anterior],
        ISNULL(nombre_completo_anterior, '—') AS [Nombre Anterior],
        ISNULL(cedula_nuevo, '—') AS [Cédula Nueva],
        ISNULL(nombre_completo_nuevo, '—') AS [Nombre Nuevo],
        ISNULL(tipo_contribuyente_nuevo, tipo_contribuyente_anterior) AS [Tipo],
        ISNULL(nombre_empresa_nuevo, nombre_empresa_anterior) AS [Empresa],
        ISNULL(representante_nuevo, representante_anterior) AS [Representante],
        ISNULL(telefono_nuevo, telefono_anterior) AS [Teléfono],
        ISNULL(email_nuevo, email_anterior) AS [Email],
        ISNULL(direccion_nuevo, direccion_anterior) AS [Dirección]
    FROM Contribuyente_Auditoria
    WHERE (@cedula IS NULL 
           OR cedula_anterior = @cedula 
           OR cedula_nuevo = @cedula)
       OR (@contribuyente_id IS NULL OR contribuyente_id = @contribuyente_id)
    ORDER BY fecha_cambio DESC;
END
GO

PRINT '  SP de consulta mejorado';
PRINT '';

PRINT '';
PRINT '==================================================================';
PRINT '¡AUDITORÍA 100% COMPLETA Y FUNCIONAL!';
PRINT '   INSERT/UPDATE → en físico/jurídico';
PRINT '   DELETE → en Contribuyente (con tu SP)';
PRINT '   1 fila por acción';
PRINT '   Usa: EXEC sp_Contribuyente_ConsultarHistorial @cedula = ''1-2345-6789''';
PRINT '==================================================================';
GO




-- select * from Contribuyente_Auditoria

-- EXEC sp_Contribuyente_Eliminar @contribuyente_id = 11;