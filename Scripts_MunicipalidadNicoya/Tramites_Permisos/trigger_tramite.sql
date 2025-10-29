CREATE TRIGGER dbo.trg_factura_actualiza_tramite_finalizado
ON dbo.Factura
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- =============================================================
    -- OBJETIVO:
    -- Cuando una factura cambie su estado a 'Pagada' y tenga un tramite_id,
    -- actualizar el estado_actual del trámite a 'Finalizado'.
    -- =============================================================

    UPDATE t
    SET 
        t.estado_actual = 'Finalizado',
        t.fecha_resolucion = GETDATE()   -- opcional: registrar fecha de cierre
    FROM dbo.Tramite t
    INNER JOIN INSERTED i ON t.tramite_id = i.tramite_id
    INNER JOIN DELETED d ON i.factura_id = d.factura_id
    WHERE 
        -- Solo si el estado cambió a 'Pagada'
        i.estado_factura = 'Pagada'
        AND d.estado_factura <> 'Pagada'
        -- Solo si la factura está vinculada a un trámite (no a inmueble)
        AND i.tramite_id IS NOT NULL;
END;
GO

PRINT '✓ Trigger trg_factura_actualiza_tramite_finalizado creado exitosamente';
GO
