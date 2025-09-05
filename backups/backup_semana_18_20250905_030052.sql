-- ====================================================================
-- BACKUP SISTEMA AGRIBAR
-- ====================================================================
-- Semana ID: 18
-- Timestamp: 20250905_030052
-- Supervisor: SUPERVISOR
-- Fecha: 2025-09-05 03:00:52
-- Registros: 2
-- Generado por: Sistema de Nóminas Agribar
-- ====================================================================

-- Limpiar datos existentes de la semana 18
DELETE FROM nomina_empleados_semanal WHERE id_semana = 18;

-- Datos de nómina de la semana 18
INSERT INTO nomina_empleados_semanal VALUES (38, 9706, 18, 2, '0.00', '0.00', '500.00', '500.00', '0.00', '0.00', '0.00', '1000.00', '0.00', '0.00', '1000.00', '1000.00', 2025-09-04 17:36:47.957597Z, 0, 0, 2, 2, 0, 0, 0, 0, 0, 3, 3, 0, 0, 0);
INSERT INTO nomina_empleados_semanal VALUES (37, 10043, 18, 2, '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', '0.00', 2025-09-04 17:36:47.860106Z, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

-- Fin del backup
