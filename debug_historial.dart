import 'lib/services/database_service.dart';

void main() async {
  print('🔍 DEBUGGING HISTORIAL DE SEMANAS\n');

  final db = DatabaseService();
  
  try {
    await db.connect();
    
    // 1. Verificar semanas en la BD
    print('1. 📋 SEMANAS EN LA BASE DE DATOS:');
    final semanas = await db.connection.query('''
      SELECT 
        id_semana,
        fecha_inicio,
        fecha_fin,
        esta_cerrada,
        creado_en
      FROM semanas_nomina
      ORDER BY fecha_inicio DESC;
    ''');
    
    if (semanas.isEmpty) {
      print('❌ No hay semanas en la tabla semanas_nomina');
    } else {
      for (var semana in semanas) {
        print('   • ID: ${semana[0]}, Inicio: ${semana[1]}, Fin: ${semana[2]}, Cerrada: ${semana[3]}, Creada: ${semana[4]}');
      }
    }
    
    // 2. Verificar datos de nómina
    print('\n2. 💰 DATOS DE NÓMINA POR SEMANA:');
    for (var semana in semanas) {
      final semanaId = semana[0];
      final empleados = await db.connection.query('''
        SELECT COUNT(*) as total_empleados,
               SUM(total_neto) as total_nomina
        FROM nomina_empleados_semanal
        WHERE id_semana = @semanaId;
      ''', substitutionValues: {'semanaId': semanaId});
      
      if (empleados.isNotEmpty) {
        final totalEmpleados = empleados.first[0] ?? 0;
        final totalNomina = empleados.first[1] ?? 0.0;
        print('   • Semana ID $semanaId: $totalEmpleados empleados, Total: \$${totalNomina}');
        
        // Ver cuadrillas específicas
        final cuadrillas = await db.connection.query('''
          SELECT 
            c.nombre,
            COUNT(nes.id_empleado) as empleados_count,
            SUM(nes.total_neto) as total_cuadrilla
          FROM cuadrillas c
          JOIN nomina_empleados_semanal nes ON c.id_cuadrilla = nes.id_cuadrilla
          WHERE nes.id_semana = @semanaId
          GROUP BY c.id_cuadrilla, c.nombre
          ORDER BY c.nombre;
        ''', substitutionValues: {'semanaId': semanaId});
        
        for (var cuadrilla in cuadrillas) {
          print('     - ${cuadrilla[0]}: ${cuadrilla[1]} empleados, Total: \$${cuadrilla[2]}');
        }
      }
    }
    
    // 3. Verificar estructura de tablas
    print('\n3. 🏗️ ESTRUCTURA DE TABLAS:');
    
    // Verificar columnas de nomina_empleados_semanal
    final columnas = await db.connection.query('''
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_semanal' 
      ORDER BY ordinal_position;
    ''');
    
    print('   Columnas en nomina_empleados_semanal:');
    for (var col in columnas) {
      print('     - ${col[0]} (${col[1]})');
    }
    
    // 4. Probar función obtenerSemanasCerradas
    print('\n4. 🧪 PROBANDO FUNCIÓN obtenerSemanasCerradas:');
    final semanasCerradas = await obtenerSemanasCerradas();
    
    print('   Resultado: ${semanasCerradas.length} semanas cerradas');
    for (var i = 0; i < semanasCerradas.length; i++) {
      final semana = semanasCerradas[i];
      print('   • Semana $i:');
      print('     - ID: ${semana['id']}');
      print('     - Fechas: ${semana['fechaInicio']} - ${semana['fechaFin']}');
      print('     - Cuadrillas: ${(semana['cuadrillas'] as List).length}');
      print('     - Total: \$${semana['totalSemana']}');
      
      final cuadrillas = semana['cuadrillas'] as List;
      for (var j = 0; j < cuadrillas.length; j++) {
        final cuadrilla = cuadrillas[j];
        print('       - ${cuadrilla['nombre']}: ${cuadrilla['empleados']?.length ?? 0} empleados, Total: \$${cuadrilla['total']}');
      }
    }
    
    await db.close();
    
  } catch (e) {
    print('❌ Error durante debugging: $e');
    await db.close();
  }
}
