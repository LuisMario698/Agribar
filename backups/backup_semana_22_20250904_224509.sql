-- ====================================================================
-- BACKUP SISTEMA AGRIBAR
-- ====================================================================
-- Semana ID: 22
-- Timestamp: 20250904_224509
-- Supervisor: SUPERVISOR
-- Fecha: 2025-09-04 22:45:09
-- Registros: 3
-- Generado por: Sistema de Nóminas Agribar
-- ====================================================================

-- Limpiar datos existentes de la semana 22
DELETE FROM nomina_empleados_semanal WHERE id_semana = 22;

-- Datos de nómina de la semana 22
INSERT INTO nomina_empleados_semanal VALUES (65, 1, 22, 2, '0.00', '0.00', '500.00', '0.00', '0.00', '0.00', '0.00', '500.00', '0.00', '0.00', '500.00', '500.00', 2025-09-05 05:44:14.210885Z, 0, 0, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0);
INSERT INTO nomina_empleados_semanal VALUES (63, 9706, 22, 2, '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', 2025-09-05 05:30:09.879280Z, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
INSERT INTO nomina_empleados_semanal VALUES (64, 10043, 22, 2, '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', 2025-09-05 05:30:10.017983Z, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

-- Fin del backup
