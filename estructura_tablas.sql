-- Consulta directa para ver estructura de tablas
SELECT 
    table_name,
    column_name, 
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('nomina_empleados_historial', 'nomina_empleados_semanal')
ORDER BY table_name, ordinal_position;
