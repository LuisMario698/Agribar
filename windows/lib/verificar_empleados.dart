// Archivo temporal para verificar empleados en la base de datos

import 'package:agribar/services/database_service.dart';

void main() async {
  print('🔍 Verificando empleados en la base de datos...');
  
  try {
    // 1. Verificar todos los empleados
    final db = DatabaseService();
    await db.connect();
    
    print('\n📊 1. TOTAL DE EMPLEADOS EN LA TABLA:');
    final totalEmpleados = await db.connection.query('SELECT COUNT(*) FROM empleados');
    print('   Total empleados en tabla "empleados": ${totalEmpleados[0][0]}');
    
    print('\n📊 2. EMPLEADOS CON DATOS LABORALES:');
    final empleadosConDatos = await db.connection.query('''
      SELECT COUNT(*) 
      FROM empleados e 
      JOIN datos_laborales dl ON e.id_empleado = dl.id_empleado
    ''');
    print('   Empleados con datos laborales: ${empleadosConDatos[0][0]}');
    
    print('\n📊 3. EMPLEADOS HABILITADOS:');
    final empleadosHabilitados = await db.connection.query('''
      SELECT COUNT(*) 
      FROM empleados e 
      JOIN datos_laborales dl ON e.id_empleado = dl.id_empleado 
      WHERE dl.deshabilitado = false
    ''');
    print('   Empleados habilitados (deshabilitado = false): ${empleadosHabilitados[0][0]}');
    
    print('\n📋 4. LISTA DE EMPLEADOS HABILITADOS:');
    final listaEmpleados = await db.connection.query('''
      SELECT 
        e.id_empleado,
        e.nombre ||' '|| e.apellido_paterno ||' '|| e.apellido_materno as nombre,
        dl.puesto,
        dl.deshabilitado
      FROM empleados e
      JOIN datos_laborales dl ON e.id_empleado = dl.id_empleado
      WHERE dl.deshabilitado = false
      ORDER BY e.nombre
    ''');
    
    for (int i = 0; i < listaEmpleados.length; i++) {
      final row = listaEmpleados[i];
      print('   ${i + 1}. ID: ${row[0]} | ${row[1]} | Puesto: ${row[2]} | Deshabilitado: ${row[3]}');
    }
    
    print('\n📋 5. EMPLEADOS DESHABILITADOS (SI LOS HAY):');
    final empleadosDeshabilitados = await db.connection.query('''
      SELECT 
        e.id_empleado,
        e.nombre ||' '|| e.apellido_paterno ||' '|| e.apellido_materno as nombre,
        dl.puesto,
        dl.deshabilitado
      FROM empleados e
      JOIN datos_laborales dl ON e.id_empleado = dl.id_empleado
      WHERE dl.deshabilitado = true
      ORDER BY e.nombre
    ''');
    
    if (empleadosDeshabilitados.isEmpty) {
      print('   No hay empleados deshabilitados');
    } else {
      for (int i = 0; i < empleadosDeshabilitados.length; i++) {
        final row = empleadosDeshabilitados[i];
        print('   ${i + 1}. ID: ${row[0]} | ${row[1]} | Puesto: ${row[2]} | Deshabilitado: ${row[3]}');
      }
    }
    
    await db.close();
    
    print('\n✅ Verificación completada');
    
  } catch (e) {
    print('❌ Error al verificar empleados: $e');
  }
}
