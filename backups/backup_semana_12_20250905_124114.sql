-- ====================================================================
-- BACKUP SISTEMA AGRIBAR
-- ====================================================================
-- Semana ID: 12
-- Timestamp: 20250905_124114
-- Supervisor: SUPERVISOR
-- Fecha: 2025-09-05 12:41:14
-- Registros: 2
-- Generado por: Sistema de Nóminas Agribar
-- ====================================================================

-- Limpiar datos existentes de la semana 12
DELETE FROM nomina_empleados_semanal WHERE id_semana = 12;

-- Datos de nómina de la semana 12
INSERT INTO nomina_empleados_semanal VALUES (9, 9706, 12, 78, '500.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '500.00', '0.00', '0.00', '500.00', '500.00', 2025-09-04 02:27:03.479311Z, 3, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0);
INSERT INTO nomina_empleados_semanal VALUES (8, 10043, 12, 78, '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', 2025-09-04 02:27:03.352489Z, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

-- Fin del backup
