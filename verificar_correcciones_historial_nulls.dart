import 'lib/services/database_service.dart';

Future<void> main() async {
  print('🔧 VERIFICANDO CORRECCIONES PARA HISTORIAL - PROBLEMA DE NULLS');
  print('================================================================');
  
  try {
    final db = DatabaseService();
    await db.connect();

    // 1. Verificar estructura de ambas tablas
    print('\n1️⃣ VERIFICANDO ESTRUCTURA DE TABLAS...');
    
    final columnasHistorial = await db.connection.query('''
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_historial' 
      ORDER BY ordinal_position;
    ''');
    
    final columnasSemanal = await db.connection.query('''
      SELECT column_name FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_semanal' 
      ORDER BY ordinal_position;
    ''');
    
    print('\n📋 Columnas en nomina_empleados_historial:');
    for (var col in columnasHistorial) {
      print('  • ${col[0]}');
    }
    
    print('\n📋 Columnas en nomina_empleados_semanal:');
    for (var col in columnasSemanal) {
      print('  • ${col[0]}');
    }

    // 2. Verificar datos de ejemplo en semanal (para copiar al historial)
    print('\n2️⃣ VERIFICANDO DATOS EN TABLA SEMANAL...');
    
    final datosSemanal = await db.connection.query('''
      SELECT id_empleado, id_semana, 
             dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7,
             act_1, act_2, act_3, act_4, act_5, act_6, act_7,
             campo_1, campo_2, campo_3, campo_4, campo_5, campo_6, campo_7
      FROM nomina_empleados_semanal 
      LIMIT 3;
    ''');

    print('\n🔍 Datos en nomina_empleados_semanal (primeros 3 registros):');
    for (var row in datosSemanal) {
      print('  Empleado ${row[0]} (Semana ${row[1]}):');
      print('    Días: ${row[2]} ${row[3]} ${row[4]} ${row[5]} ${row[6]} ${row[7]} ${row[8]}');
      print('    Actividades: ${row[9]} ${row[10]} ${row[11]} ${row[12]} ${row[13]} ${row[14]} ${row[15]}');
      print('    Campos: "${row[16]}" "${row[17]}" "${row[18]}" "${row[19]}" "${row[20]}" "${row[21]}" "${row[22]}"');
      print('');
    }

    // 3. Verificar datos existentes en historial (problema de nulls)
    print('\n3️⃣ VERIFICANDO PROBLEMA DE NULLS EN HISTORIAL...');
    
    final problemasHistorial = await db.connection.query('''
      SELECT COUNT(*) as total,
             SUM(CASE WHEN dia_7 IS NULL THEN 1 ELSE 0 END) as dia7_null,
             SUM(CASE WHEN act_7 IS NULL THEN 1 ELSE 0 END) as act7_null,
             SUM(CASE WHEN campo_7 IS NULL THEN 1 ELSE 0 END) as campo7_null,
             SUM(CASE WHEN act_1 IS NULL THEN 1 ELSE 0 END) as act1_null,
             SUM(CASE WHEN campo_1 IS NULL THEN 1 ELSE 0 END) as campo1_null
      FROM nomina_empleados_historial;
    ''');

    if (problemasHistorial.isNotEmpty) {
      var stats = problemasHistorial.first;
      print('📊 ESTADÍSTICAS DE NULLS EN HISTORIAL:');
      print('  Total registros: ${stats[0]}');
      print('  ❌ dia_7 NULL: ${stats[1]} registros');
      print('  ❌ act_7 NULL: ${stats[2]} registros');
      print('  ❌ campo_7 NULL: ${stats[3]} registros');
      print('  ❌ act_1 NULL: ${stats[4]} registros');
      print('  ❌ campo_1 NULL: ${stats[5]} registros');
    }

    // 4. Mostrar registros problemáticos específicos
    print('\n4️⃣ REGISTROS PROBLEMÁTICOS EN HISTORIAL...');
    
    final registrosProblematicos = await db.connection.query('''
      SELECT id_empleado, id_semana, dia_7, act_7, campo_7
      FROM nomina_empleados_historial 
      WHERE dia_7 IS NULL OR act_7 IS NULL OR campo_7 IS NULL
      LIMIT 5;
    ''');

    print('🔍 Registros con NULLs en historial (primeros 5):');
    for (var row in registrosProblematicos) {
      print('  Empleado ${row[0]} (Semana ${row[1]}): dia_7=${row[2]}, act_7=${row[3]}, campo_7="${row[4]}"');
    }

    // 5. Simular la función de conversión _parseDouble e _parseInt
    print('\n5️⃣ SIMULANDO FUNCIONES DE CONVERSIÓN...');
    
    // Función _parseDouble
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? 0.0;
      }
      if (value is bool) return value ? 1.0 : 0.0;
      return 0.0;
    }

    // Función _parseInt
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      if (value is bool) return value ? 1 : 0;
      return 0;
    }

    // Probar conversiones con valores problemáticos
    var valoresPrueba = [null, "", "0", 0, 5.5, true, false];
    print('🧪 PRUEBAS DE CONVERSIÓN:');
    for (var valor in valoresPrueba) {
      double convertidoDouble = parseDouble(valor);
      int convertidoInt = parseInt(valor);
      String convertidoString = valor?.toString() ?? "0";
      print('  $valor → double: $convertidoDouble, int: $convertidoInt, string: "$convertidoString"');
    }

    print('\n✅ CORRECCIONES APLICADAS:');
    print('1. ✅ Agregado dia_7 al INSERT de database_service.dart');
    print('2. ✅ Agregadas actividades (act_1 a act_7) al INSERT');
    print('3. ✅ Agregados campos (campo_1 a campo_7) al INSERT');
    print('4. ✅ Todas las conversiones NULL → 0 implementadas');
    print('5. ✅ SELECT actualizado para incluir todos los campos');
    print('6. ✅ Función nomina_supervisor_auth_widget.dart corregida');
    
    print('\n🎯 PRÓXIMO PASO:');
    print('   Cierra una semana para probar las correcciones');
    print('   Los datos deberían copiarse SIN nulls al historial');

    await db.close();
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
