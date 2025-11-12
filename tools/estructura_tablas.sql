-- Consulta directa para ver estructura de tablas
SELECT 
    table_name,
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('nomina_empleados_historial', 'nomina_empleados_semanal')
ORDER BY table_name, ordinal_position;

-- ====================================================================
-- MIGRACIÓN A numeric(10,2) PARA CAMPOS MONETARIOS / SUELDOS
-- Ejecutar esta sección una sola vez en la base de datos productiva.
-- Ajusta los nombres de columnas según existan realmente.
-- Se asume Postgres (ajustar sintaxis si es MySQL u otro motor).
-- ====================================================================

-- NOTA: Usa transacción para seguridad.
BEGIN;

-- Tabla semanal
-- Campos por día (sueldo): dia_0_s ... dia_6_s
DO $$
DECLARE
        i INT;
        col TEXT;
BEGIN
    FOR i IN 0..6 LOOP
        col := 'dia_' || i || '_s';
        EXECUTE format('ALTER TABLE nomina_empleados_semanal ALTER COLUMN %I TYPE numeric(10,2) USING %I::numeric(10,2);', col, col);
    END LOOP;
END $$;

-- Campos principales monetarios
ALTER TABLE nomina_empleados_semanal 
    ALTER COLUMN total TYPE numeric(10,2) USING total::numeric(10,2),
    ALTER COLUMN subtotal TYPE numeric(10,2) USING subtotal::numeric(10,2),
    ALTER COLUMN totalNeto TYPE numeric(10,2) USING totalNeto::numeric(10,2),
    ALTER COLUMN comedor TYPE numeric(10,2) USING comedor::numeric(10,2),
    ALTER COLUMN debe TYPE numeric(10,2) USING debe::numeric(10,2);

-- Historial (si replica misma estructura)
DO $$
DECLARE
        i INT;
        col TEXT;
BEGIN
    FOR i IN 0..6 LOOP
        col := 'dia_' || i || '_s';
        EXECUTE format('ALTER TABLE nomina_empleados_historial ALTER COLUMN %I TYPE numeric(10,2) USING %I::numeric(10,2);', col, col);
    END LOOP;
END $$;

ALTER TABLE nomina_empleados_historial 
    ALTER COLUMN total TYPE numeric(10,2) USING total::numeric(10,2),
    ALTER COLUMN subtotal TYPE numeric(10,2) USING subtotal::numeric(10,2),
    ALTER COLUMN totalNeto TYPE numeric(10,2) USING totalNeto::numeric(10,2),
    ALTER COLUMN comedor TYPE numeric(10,2) USING comedor::numeric(10,2),
    ALTER COLUMN debe TYPE numeric(10,2) USING debe::numeric(10,2);

COMMIT;

-- Verificación rápida post-migración
SELECT column_name, data_type, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE table_name = 'nomina_empleados_semanal'
    AND column_name IN ('total','subtotal','totalneto','comedor','debe','dia_0_s','dia_1_s','dia_2_s','dia_3_s','dia_4_s','dia_5_s','dia_6_s')
ORDER BY column_name;

