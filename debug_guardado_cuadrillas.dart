import 'package:postgres/postgres.dart';

Future<void> main() async {
  print('🔍 Diagnosticando problemas de guardado de cuadrillas...');
  
  PostgreSQLConnection connection = PostgreSQLConnection(
    'localhost',
    5432,
    'AGRIBAR',
    username: 'postgres',
    password: 'admin',
  );
  
  try {
    await connection.open();
    print('✅ Conectado a la base de datos');
    
    // 1. Verificar semana activa
    print('\n📅 1. Verificando semana activa:');
    final semanaActiva = await connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada
      FROM semanas_nomina 
      WHERE esta_cerrada = false
      ORDER BY id_semana DESC
      LIMIT 1
    ''');
    
    if (semanaActiva.isEmpty) {
      print('❌ No hay semana activa (abierta)');
      return;
    }
    
    final semanaId = semanaActiva.first[0] as int;
    print('✅ Semana activa: $semanaId (${semanaActiva.first[1]} a ${semanaActiva.first[2]})');
    
    // 2. Verificar transacciones activas
    print('\n🔄 2. Verificando transacciones activas:');
    final transacciones = await connection.query('''
      SELECT pid, state, query_start, query 
      FROM pg_stat_activity 
      WHERE datname = 'AGRIBAR' AND state != 'idle'
      ORDER BY query_start
    ''');
    
    print('  📊 Transacciones activas: ${transacciones.length}');
    for (final trans in transacciones) {
      print('    - PID: ${trans[0]}, Estado: ${trans[1]}, Query: ${trans[3]?.toString().substring(0, 50) ?? 'N/A'}...');
    }
    
    // 3. Verificar locks en la base de datos
    print('\n🔒 3. Verificando locks:');
    final locks = await connection.query('''
      SELECT DISTINCT l.relation::regclass, l.mode, l.granted
      FROM pg_locks l
      WHERE l.relation IS NOT NULL
      ORDER BY l.relation::regclass
    ''');
    
    print('  🔐 Locks encontrados: ${locks.length}');
    for (final lock in locks) {
      print('    - Tabla: ${lock[0]}, Modo: ${lock[1]}, Otorgado: ${lock[2]}');
    }
    
    // 4. Verificar integridad de tablas críticas
    print('\n🏗️ 4. Verificando integridad de tablas:');
    
    final tablasCriticas = ['nomina_empleados_semanal', 'empleados', 'cuadrillas', 'semanas_nomina'];
    for (final tabla in tablasCriticas) {
      try {
        final count = await connection.query('SELECT COUNT(*) FROM $tabla');
        print('  ✅ $tabla: ${count.first[0]} registros');
      } catch (e) {
        print('  ❌ $tabla: Error - $e');
      }
    }
    
    // 5. Simular inserción de empleado en cuadrilla
    print('\n🧪 5. Prueba de inserción:');
    try {
      await connection.execute('BEGIN');
      
      // Intentar insertar un empleado de prueba
      await connection.execute('''
        INSERT INTO nomina_empleados_semanal (id_empleado, id_semana, id_cuadrilla)
        VALUES (1, @semanaId, 1)
        ON CONFLICT (id_empleado, id_semana, id_cuadrilla) DO NOTHING
      ''', substitutionValues: {'semanaId': semanaId});
      
      print('  ✅ Inserción de prueba exitosa');
      
      await connection.execute('ROLLBACK'); // Deshacer la prueba
      print('  🔄 Prueba deshecha (rollback)');
      
    } catch (e) {
      print('  ❌ Error en inserción de prueba: $e');
      await connection.execute('ROLLBACK');
    }
    
    // 6. Verificar restricciones de la tabla
    print('\n🔍 6. Verificando restricciones:');
    final restricciones = await connection.query('''
      SELECT conname, contype, pg_get_constraintdef(oid) as definition
      FROM pg_constraint 
      WHERE conrelid = 'nomina_empleados_semanal'::regclass
      ORDER BY conname
    ''');
    
    for (final rest in restricciones) {
      print('  📝 ${rest[0]} (${rest[1]}): ${rest[2]}');
    }
    
    // 7. Verificar permisos
    print('\n🔑 7. Verificando permisos de usuario:');
    final permisos = await connection.query('''
      SELECT table_name, privilege_type
      FROM information_schema.table_privileges 
      WHERE grantee = current_user 
        AND table_schema = 'public'
        AND table_name IN ('nomina_empleados_semanal', 'empleados', 'cuadrillas')
      ORDER BY table_name, privilege_type
    ''');
    
    for (final perm in permisos) {
      print('  🔓 ${perm[0]}: ${perm[1]}');
    }
    
    // 8. Verificar empleados disponibles
    print('\n👥 8. Empleados disponibles:');
    final empleados = await connection.query('''
      SELECT id_empleado, nombre 
      FROM empleados 
      ORDER BY id_empleado 
      LIMIT 10
    ''');
    
    print('  📋 Primeros 10 empleados:');
    for (final emp in empleados) {
      print('    - ID: ${emp[0]}, Nombre: ${emp[1]}');
    }
    
  } catch (e) {
    print('❌ Error durante el diagnóstico: $e');
  } finally {
    await connection.close();
  }
}
