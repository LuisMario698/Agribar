import 'lib/services/database_service.dart';

void main() async {
  print('🔍 DEBUG ESPECÍFICO: HISTORIAL SEMANAS CERRADAS\n');

  final db = DatabaseService();
  
  try {
    await db.connect();
    
    // 1. Obtener UNA semana cerrada específica para debuggear
    print('1. 📅 OBTENIENDO UNA SEMANA CERRADA PARA DEBUGGEAR:');
    final semanaEjemplo = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada
      FROM semanas_nomina 
      WHERE esta_cerrada = true
      ORDER BY fecha_inicio DESC
      LIMIT 1;
    ''');
    
    if (semanaEjemplo.isEmpty) {
      print('❌ No hay semanas cerradas');
      return;
    }
    
    final semanaId = semanaEjemplo.first[0];
    print('✅ Debuggeando semana ID: $semanaId');
    print('   Fechas: ${semanaEjemplo.first[1]} al ${semanaEjemplo.first[2]}');
    
    // 2. Verificar datos de nómina para esta semana
    print('\n2. 💰 DATOS DE NÓMINA PARA ESTA SEMANA:');
    final datosNomina = await db.connection.query('''
      SELECT 
        COUNT(*) as total_registros,
        COUNT(DISTINCT id_cuadrilla) as cuadrillas_diferentes,
        COUNT(DISTINCT id_empleado) as empleados_diferentes,
        SUM(total_neto) as suma_total_neto,
        SUM(total) as suma_total
      FROM nomina_empleados_semanal
      WHERE id_semana = @semanaId;
    ''', substitutionValues: {'semanaId': semanaId});
    
    if (datosNomina.isNotEmpty) {
      final datos = datosNomina.first;
      print('   📊 Total registros: ${datos[0]}');
      print('   📊 Cuadrillas diferentes: ${datos[1]}');
      print('   📊 Empleados diferentes: ${datos[2]}');
      print('   📊 Suma total_neto: \$${datos[3] ?? 0.0}');
      print('   📊 Suma total: \$${datos[4] ?? 0.0}');
    }
    
    // 3. Ver registros específicos
    print('\n3. 📋 REGISTROS ESPECÍFICOS (PRIMEROS 5):');
    final registros = await db.connection.query('''
      SELECT 
        id_nomina,
        id_empleado,
        id_cuadrilla,
        total,
        total_neto,
        dia_1, dia_2, dia_3
      FROM nomina_empleados_semanal
      WHERE id_semana = @semanaId
      ORDER BY id_nomina
      LIMIT 5;
    ''', substitutionValues: {'semanaId': semanaId});
    
    for (var reg in registros) {
      print('   • Nómina ID: ${reg[0]}, Empleado: ${reg[1]}, Cuadrilla: ${reg[2]}');
      print('     Total: \$${reg[3]}, Total Neto: \$${reg[4]}');
      print('     Días: ${reg[5]}, ${reg[6]}, ${reg[7]}');
      print('     ──────────────');
    }
    
    // 4. Probar la función obtenerCuadrillasDatosCompletos directamente
    print('\n4. 🧪 PROBANDO obtenerCuadrillasDatosCompletos():');
    final cuadrillasCompletas = await obtenerCuadrillasDatosCompletos(semanaId);
    
    print('   Resultado: ${cuadrillasCompletas.length} cuadrillas encontradas');
    for (int i = 0; i < cuadrillasCompletas.length; i++) {
      final cuad = cuadrillasCompletas[i];
      print('   • Cuadrilla ${i + 1}: ${cuad['nombre']}');
      print('     Empleados: ${cuad['empleados']?.length ?? 0}');
      print('     Total: \$${cuad['total'] ?? 0.0}');
    }
    
    // 5. Verificar cuadrillas que tienen empleados para esta semana
    print('\n5. 🎯 CUADRILLAS CON EMPLEADOS PARA ESTA SEMANA:');
    final cuadrillasConEmpleados = await db.connection.query('''
      SELECT 
        c.id_cuadrilla,
        c.nombre,
        COUNT(nes.id_empleado) as total_empleados,
        SUM(nes.total_neto) as total_dinero
      FROM cuadrillas c
      JOIN nomina_empleados_semanal nes ON c.id_cuadrilla = nes.id_cuadrilla
      WHERE nes.id_semana = @semanaId
      GROUP BY c.id_cuadrilla, c.nombre
      ORDER BY c.nombre;
    ''', substitutionValues: {'semanaId': semanaId});
    
    for (var cuad in cuadrillasConEmpleados) {
      print('   • ${cuad[1]} (ID: ${cuad[0]}): ${cuad[2]} empleados, \$${cuad[3]}');
    }
    
  } catch (e) {
    print('❌ Error: $e');
    print('Stack trace: ${StackTrace.current}');
  } finally {
    await db.close();
  }
}
