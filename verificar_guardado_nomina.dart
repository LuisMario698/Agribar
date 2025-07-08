import 'package:agribar/services/database_service.dart';

// SCRIPT PARA VERIFICAR EL GUARDADO Y CARGA DE DATOS DE NÓMINA
// ===========================================================

void main() async {
  print('🔍 Iniciando verificación de guardado y carga de nómina...\n');
  
  final db = DatabaseService();
  
  try {
    await db.connect();
    print('✅ Conexión establecida\n');
    
    // 1. Verificar datos actuales en nomina_empleados_semanal
    print('📋 1. DATOS ACTUALES EN LA TABLA nomina_empleados_semanal:');
    final existingData = await db.connection.query('''
      SELECT 
        n.id_nomina,
        n.id_empleado,
        n.id_semana,
        n.id_cuadrilla,
        e.nombre,
        n.dia_1, n.dia_2, n.dia_3, n.dia_4, n.dia_5, n.dia_6, n.dia_7,
        n.total, n.debe, n.subtotal, n.comedor, n.total_neto
      FROM nomina_empleados_semanal n
      LEFT JOIN empleados e ON e.id_empleado = n.id_empleado
      ORDER BY n.id_semana DESC, n.id_cuadrilla, e.nombre
      LIMIT 10;
    ''');
    
    if (existingData.isEmpty) {
      print('   ❌ No hay datos en la tabla nomina_empleados_semanal');
    } else {
      print('   ✅ Se encontraron ${existingData.length} registros:');
      for (var row in existingData) {
        print('   - ID: ${row[0]} | Empleado: ${row[4]} | Semana: ${row[2]} | Cuadrilla: ${row[3]}');
        print('     Días: ${row[5]}, ${row[6]}, ${row[7]}, ${row[8]}, ${row[9]}, ${row[10]}, ${row[11]}');
        print('     Total: ${row[12]}, Debe: ${row[13]}, Subtotal: ${row[14]}, Comedor: ${row[15]}, Neto: ${row[16]}');
        print('');
      }
    }
    
    // 2. Verificar semanas activas
    print('📅 2. SEMANAS DISPONIBLES:');
    final semanas = await db.connection.query('''
      SELECT id, fechainicio, fechafin, cerrada
      FROM semanas
      ORDER BY fechainicio DESC
      LIMIT 5;
    ''');
    
    for (var row in semanas) {
      print('   - ID: ${row[0]} | ${row[1]} a ${row[2]} | Cerrada: ${row[3]}');
    }
    print('');
    
    // 3. Verificar cuadrillas disponibles
    print('👥 3. CUADRILLAS DISPONIBLES:');
    final cuadrillas = await db.connection.query('''
      SELECT id, nombre
      FROM cuadrillas
      ORDER BY id;
    ''');
    
    for (var row in cuadrillas) {
      print('   - ID: ${row[0]} | Nombre: ${row[1]}');
    }
    print('');
    
    // 4. Verificar empleados en cuadrillas
    print('🔗 4. EMPLEADOS EN CUADRILLAS (últimos registros):');
    final empleadosCuadrillas = await db.connection.query('''
      SELECT 
        ec.id_empleado,
        ec.id_cuadrilla,
        ec.id_semana,
        e.nombre,
        c.nombre as cuadrilla_nombre
      FROM empleados_cuadrillas ec
      LEFT JOIN empleados e ON e.id_empleado = ec.id_empleado
      LEFT JOIN cuadrillas c ON c.id = ec.id_cuadrilla
      ORDER BY ec.id_semana DESC, ec.id_cuadrilla
      LIMIT 10;
    ''');
    
    if (empleadosCuadrillas.isEmpty) {
      print('   ❌ No hay empleados asignados a cuadrillas');
    } else {
      print('   ✅ Se encontraron ${empleadosCuadrillas.length} asignaciones:');
      for (var row in empleadosCuadrillas) {
        print('   - Empleado: ${row[3]} | Cuadrilla: ${row[4]} | Semana: ${row[2]}');
      }
    }
    print('');
    
    // 5. Simular datos de prueba si no hay datos
    if (existingData.isEmpty && semanas.isNotEmpty && cuadrillas.isNotEmpty) {
      print('🧪 5. INSERTANDO DATOS DE PRUEBA...');
      
      final idSemana = semanas.first[0];
      final idCuadrilla = cuadrillas.first[0];
      final idEmpleado = 1; // Asumiendo que existe el empleado con ID 1
      
      print('   Insertando datos para: Semana=$idSemana, Cuadrilla=$idCuadrilla, Empleado=$idEmpleado');
      
      await db.connection.query('''
        INSERT INTO nomina_empleados_semanal (
          id_empleado, id_semana, id_cuadrilla,
          act_1, dia_1, act_2, dia_2, act_3, dia_3, act_4, dia_4,
          act_5, dia_5, act_6, dia_6, act_7, dia_7,
          total, debe, subtotal, comedor, total_neto
        ) VALUES (
          @idEmp, @idSemana, @idCuadrilla,
          1, 100, 1, 120, 1, 110, 1, 0,
          1, 0, 1, 0, 1, 0,
          330, 50, 280, 25, 255
        )
        ON CONFLICT (id_empleado, id_semana, id_cuadrilla) 
        DO UPDATE SET
          dia_1 = 100, dia_2 = 120, dia_3 = 110,
          total = 330, debe = 50, subtotal = 280, comedor = 25, total_neto = 255;
      ''', substitutionValues: {
        'idEmp': idEmpleado,
        'idSemana': idSemana,
        'idCuadrilla': idCuadrilla,
      });
      
      print('   ✅ Datos de prueba insertados');
      
      // Verificar que se insertaron
      final verificacion = await db.connection.query('''
        SELECT dia_1, dia_2, dia_3, total, debe, subtotal, comedor, total_neto
        FROM nomina_empleados_semanal
        WHERE id_empleado = @idEmp AND id_semana = @idSemana AND id_cuadrilla = @idCuadrilla;
      ''', substitutionValues: {
        'idEmp': idEmpleado,
        'idSemana': idSemana,
        'idCuadrilla': idCuadrilla,
      });
      
      if (verificacion.isNotEmpty) {
        final row = verificacion.first;
        print('   ✅ Verificación exitosa:');
        print('      Días: ${row[0]}, ${row[1]}, ${row[2]}');
        print('      Total: ${row[3]}, Debe: ${row[4]}, Subtotal: ${row[5]}, Comedor: ${row[6]}, Neto: ${row[7]}');
      } else {
        print('   ❌ Error: No se pudieron insertar los datos de prueba');
      }
    }
    
  } catch (e) {
    print('❌ Error durante la verificación: $e');
  } finally {
    await db.close();
    print('\n🔌 Conexión cerrada');
  }
}
