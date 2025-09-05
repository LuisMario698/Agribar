import 'package:postgres/postgres.dart';

void main() async {
  print('=== DEBUG GUARDADO CUADRILLAS - SIMULACIÓN SIMPLE ===');
  
  try {
    // Configuración de conexión
    final connection = PostgreSQLConnection(
      'localhost',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: '123456789',
    );
    
    await connection.open();
    print('✅ Conectado a la base de datos');
    
    // Verificar datos existentes
    print('\n1. Verificando empleados existentes en cuadrillas...');
    final empleadosExistentes = await connection.query(
      'SELECT semana_id, cuadrilla_id, empleado_id FROM nomina_empleados_semanal ORDER BY cuadrilla_id, empleado_id LIMIT 10'
    );
    
    print('Empleados encontrados: ${empleadosExistentes.length}');
    for (final row in empleadosExistentes) {
      print('  Semana: ${row[0]}, Cuadrilla: ${row[1]}, Empleado: ${row[2]}');
    }
    
    // Simulación del proceso de guardado que está fallando
    print('\n2. Simulando proceso de guardado de cuadrilla...');
    
    // Obtener una semana activa
    final semanasActivas = await connection.query(
      'SELECT id FROM nomina_semanas WHERE estado = true ORDER BY fecha_inicio DESC LIMIT 1'
    );
    
    if (semanasActivas.isEmpty) {
      print('❌ No hay semanas activas');
      await connection.close();
      return;
    }
    
    final semanaId = semanasActivas.first[0];
    print('Semana activa encontrada: $semanaId');
    
    // Obtener cuadrillas disponibles
    final cuadrillas = await connection.query(
      'SELECT id, nombre FROM cuadrillas WHERE activo = true ORDER BY id LIMIT 5'
    );
    
    print('Cuadrillas disponibles: ${cuadrillas.length}');
    for (final row in cuadrillas) {
      print('  ID: ${row[0]}, Nombre: ${row[1]}');
    }
    
    // Obtener empleados disponibles
    final empleados = await connection.query(
      'SELECT id, nombre FROM empleados WHERE activo = true ORDER BY id LIMIT 10'
    );
    
    print('Empleados disponibles: ${empleados.length}');
    for (final row in empleados) {
      print('  ID: ${row[0]}, Nombre: ${row[1]}');
    }
    
    // Simulación del guardado problemático
    print('\n3. Simulando guardado de empleados en cuadrilla...');
    
    if (cuadrillas.isNotEmpty && empleados.isNotEmpty) {
      final cuadrillaId = cuadrillas.first[0];
      final empleadoId = empleados.first[0];
      
      print('Intentando asignar empleado $empleadoId a cuadrilla $cuadrillaId en semana $semanaId');
      
      try {
        // Verificar si ya existe el registro
        final existeRegistro = await connection.query(
          'SELECT COUNT(*) FROM nomina_empleados_semanal WHERE semana_id = @semana AND cuadrilla_id = @cuadrilla AND empleado_id = @empleado',
          substitutionValues: {
            'semana': semanaId,
            'cuadrilla': cuadrillaId,
            'empleado': empleadoId,
          }
        );
        
        final count = existeRegistro.first[0] as int;
        print('Registros existentes: $count');
        
        if (count == 0) {
          // Intentar insertar
          print('Insertando nuevo registro...');
          await connection.query(
            'INSERT INTO nomina_empleados_semanal (semana_id, cuadrilla_id, empleado_id) VALUES (@semana, @cuadrilla, @empleado)',
            substitutionValues: {
              'semana': semanaId,
              'cuadrilla': cuadrillaId,
              'empleado': empleadoId,
            }
          );
          print('✅ Registro insertado exitosamente');
          
          // Limpiar el registro de prueba
          await connection.query(
            'DELETE FROM nomina_empleados_semanal WHERE semana_id = @semana AND cuadrilla_id = @cuadrilla AND empleado_id = @empleado',
            substitutionValues: {
              'semana': semanaId,
              'cuadrilla': cuadrillaId,
              'empleado': empleadoId,
            }
          );
          print('🧹 Registro de prueba eliminado');
        } else {
          print('ℹ️ El registro ya existe, no se insertó');
        }
        
      } catch (e) {
        print('❌ Error en el guardado: $e');
        print('Stack trace: ${e is Error ? e.stackTrace : 'No disponible'}');
      }
    }
    
    // Verificar constraints y triggers
    print('\n4. Verificando constraints de la tabla...');
    final constraints = await connection.query('''
      SELECT 
        tc.constraint_name, 
        tc.constraint_type,
        kcu.column_name
      FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
      WHERE tc.table_name = 'nomina_empleados_semanal'
      ORDER BY tc.constraint_type, tc.constraint_name
    ''');
    
    print('Constraints encontrados:');
    for (final row in constraints) {
      print('  ${row[0]} (${row[1]}) en columna ${row[2]}');
    }
    
    // Verificar triggers
    print('\n5. Verificando triggers...');
    final triggers = await connection.query('''
      SELECT trigger_name, event_manipulation, action_statement
      FROM information_schema.triggers 
      WHERE event_object_table = 'nomina_empleados_semanal'
    ''');
    
    print('Triggers encontrados: ${triggers.length}');
    for (final row in triggers) {
      print('  ${row[0]} - ${row[1]}');
      print('    Acción: ${row[2]}');
    }
    
    await connection.close();
    print('\n✅ Debug completado');
    
  } catch (e) {
    print('❌ Error general: $e');
    print('Stack trace: ${e is Error ? e.stackTrace : 'No disponible'}');
  }
}
