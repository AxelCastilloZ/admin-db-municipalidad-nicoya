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
        t.fecha_resolucion = GETDATE() 
    FROM dbo.Tramite t
    INNER JOIN INSERTED i ON t.tramite_id = i.tramite_id
    INNER JOIN DELETED d ON i.factura_id = d.factura_id
    WHERE 
        
        i.estado_factura = 'Pagada'
        AND d.estado_factura <> 'Pagada'
        
        AND i.tramite_id IS NOT NULL;
END;
GO

PRINT ' Trigger trg_factura_actualiza_tramite_finalizado creado exitosamente';
GO
