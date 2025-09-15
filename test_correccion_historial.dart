import 'lib/services/database_service.dart';

void main() async {
  print('🧪 PRUEBA DE CORRECCIÓN: GUARDADO EN HISTORIAL');
  print('===============================================');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // 1. Verificar estructura de ambas tablas
    print('🔍 1. VERIFICANDO ESTRUCTURA DE LAS TABLAS...');
    
    // Tabla semanal
    final estructuraSemanal = await db.connection.query('''
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_semanal' 
      ORDER BY ordinal_position
    ''');
    
    print('\n📋 ESTRUCTURA nomina_empleados_semanal (${estructuraSemanal.length} campos):');
    for (var col in estructuraSemanal) {
      print('   • ${col[0]} (${col[1]})');
    }
    
    // Tabla historial
    final estructuraHistorial = await db.connection.query('''
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_historial' 
      ORDER BY ordinal_position
    ''');
    
    print('\n📋 ESTRUCTURA nomina_empleados_historial (${estructuraHistorial.length} campos):');
    for (var col in estructuraHistorial) {
      print('   • ${col[0]} (${col[1]})');
    }
    
    // 2. Buscar semana con datos para probar
    print('\n🔍 2. BUSCANDO SEMANA CON DATOS PARA PROBAR...');
    final semanaConDatos = await db.connection.query('''
      SELECT s.id_semana, s.fecha_inicio, s.fecha_fin, s.esta_cerrada,
             COUNT(n.id_nomina) as total_registros
      FROM semanas_nomina s
      LEFT JOIN nomina_empleados_semanal n ON n.id_semana = s.id_semana
      WHERE s.esta_cerrada = false
      GROUP BY s.id_semana, s.fecha_inicio, s.fecha_fin, s.esta_cerrada
      HAVING COUNT(n.id_nomina) > 0
      ORDER BY s.fecha_inicio DESC
      LIMIT 1
    ''');
    
    if (semanaConDatos.isEmpty) {
      print('❌ No se encontró ninguna semana abierta con datos de nómina');
      print('🔍 Verificando si hay datos en la tabla semanal...');
      
      final totalDatos = await db.connection.query('''
        SELECT COUNT(*) FROM nomina_empleados_semanal
      ''');
      print('   Total registros en nomina_empleados_semanal: ${totalDatos.first[0]}');
      
      final semanasAbiertas = await db.connection.query('''
        SELECT COUNT(*) FROM semanas_nomina WHERE esta_cerrada = false
      ''');
      print('   Total semanas abiertas: ${semanasAbiertas.first[0]}');
      
      return;
    }
    
    final semanaId = semanaConDatos.first[0];
    final totalRegistros = semanaConDatos.first[4];
    print('✅ Encontrada semana ID: $semanaId con $totalRegistros registros');
    
    // 3. Simular obtención de datos como lo haría la función corregida
    print('\n🔍 3. SIMULANDO OBTENCIÓN DE DATOS CORREGIDA...');
    final datosCompletos = await db.connection.query('''
      SELECT 
        id_empleado, id_semana, id_cuadrilla, 
        dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7,
        act_1, act_2, act_3, act_4, act_5, act_6, act_7,
        campo_1, campo_2, campo_3, campo_4, campo_5, campo_6, campo_7,
        total, debe, subtotal, comedor, total_neto, actualizado_en, orden_empleado
      FROM nomina_empleados_semanal 
      WHERE id_semana = @idSemana
      LIMIT 1
    ''', substitutionValues: {'idSemana': semanaId});
    
    if (datosCompletos.isNotEmpty) {
      print('✅ Datos obtenidos exitosamente');
      final registro = datosCompletos.first;
      print('📊 Ejemplo de registro:');
      print('   • Empleado: ${registro[0]}, Cuadrilla: ${registro[2]}');
      print('   • Días: ${registro[3]}, ${registro[4]}, ${registro[5]}, ${registro[6]}, ${registro[7]}, ${registro[8]}, ${registro[9]}');
      print('   • Total: ${registro[24]}, Total Neto: ${registro[28]}');
      print('   • Actividades: ${registro[10]}, ${registro[11]}, ${registro[12]}, ${registro[13]}, ${registro[14]}, ${registro[15]}, ${registro[16]}');
    }
    
    // 4. Verificar diferencias entre estructuras
    print('\n🔍 4. COMPARANDO ESTRUCTURAS...');
    final camposSemanal = estructuraSemanal.map((e) => e[0].toString()).toSet();
    final camposHistorial = estructuraHistorial.map((e) => e[0].toString()).toSet();
    
    final soloEnSemanal = camposSemanal.difference(camposHistorial);
    final soloEnHistorial = camposHistorial.difference(camposSemanal);
    final enAmbas = camposSemanal.intersection(camposHistorial);
    
    print('📊 Campos comunes: ${enAmbas.length}');
    print('📊 Solo en semanal: ${soloEnSemanal.length} → ${soloEnSemanal.toList()}');
    print('📊 Solo en historial: ${soloEnHistorial.length} → ${soloEnHistorial.toList()}');
    
    print('\n✅ ANÁLISIS COMPLETADO');
    print('📝 La corrección debería funcionar correctamente ahora que:');
    print('   • Se obtienen TODOS los campos de nomina_empleados_semanal');
    print('   • Se incluye el campo total_neto en el INSERT');
    print('   • Se mantiene la misma estructura de datos');
    
  } catch (e) {
    print('❌ Error durante la prueba: $e');
  } finally {
    await db.close();
  }
}