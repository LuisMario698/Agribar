import 'lib/services/database_service.dart';

void main() async {
  print('🧪 PRUEBA: CONVERSIÓN DE CLAVES A IDS AL GUARDAR');
  print('===============================================');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // 1. Verificar tabla de actividades
    print('📋 TABLA DE ACTIVIDADES:');
    final actividades = await db.connection.query('''
      SELECT id_actividad, clave, nombre 
      FROM actividades 
      ORDER BY id_actividad;
    ''');
    
    print('ID\tClave\tNombre');
    print('--\t-----\t------');
    Map<String, int> claveAIdMap = {};
    for (var act in actividades) {
      final id = act[0];
      final clave = act[1];
      final nombre = act[2];
      print('$id\t$clave\t$nombre');
      
      if (clave != null) {
        claveAIdMap[clave.toString()] = id;
      }
    }
    
    print('\n🔍 MAPEO CLAVE → ID:');
    claveAIdMap.forEach((clave, id) {
      print('  "$clave" → ID $id');
    });
    
    // 2. Probar conversiones específicas
    print('\n🧪 PRUEBAS DE CONVERSIÓN:');
    
    // Función de prueba (simulando _obtenerIdParaGuardar)
    int obtenerIdParaProbar(dynamic valor) {
      if (valor == null) return 0;
      final s = valor.toString().trim();
      if (s.isEmpty || s == '0') return 0;
      
      // Si coincide como clave conocida -> devolver ID
      if (claveAIdMap.containsKey(s)) {
        return claveAIdMap[s]!;
      }
      
      // Si es número y es un ID válido
      final posibleId = int.tryParse(s);
      if (posibleId != null && posibleId > 0) {
        return posibleId;
      }
      
      return 0;
    }
    
    // Casos de prueba
    final casosPrueba = [
      "1",      // DESTAJO
      "1301",   // JEFE DE LINEA  
      "1306",   // JEFE DE EMPAQUE
      "1309",   // CADENERO
      "1315",   // TAPADORA
      "112",    // AYUDANTE DE REGADOR
      null,     // NULL
      "",       // String vacío
      "0",      // Cero string
      "9999",   // ID que no existe
      "XXXX"    // Clave que no existe
    ];
    
    for (var caso in casosPrueba) {
      final resultado = obtenerIdParaProbar(caso);
      print('  "$caso" → ID $resultado');
    }
    
    // 3. Verificar registros actuales en nomina_empleados_semanal
    print('\n📊 REGISTROS ACTUALES EN NOMINA_EMPLEADOS_SEMANAL:');
    final registrosActuales = await db.connection.query('''
      SELECT id_nomina, id_empleado, id_semana, 
             act_1, act_2, act_3, act_4, act_5, act_6, act_7
      FROM nomina_empleados_semanal 
      ORDER BY id_nomina DESC 
      LIMIT 5;
    ''');
    
    print('ID_Nomina\tEmpleado\tSemana\tAct1\tAct2\tAct3\tAct4\tAct5\tAct6\tAct7');
    for (var reg in registrosActuales) {
      print('${reg[0]}\t\t${reg[1]}\t${reg[2]}\t${reg[3]}\t${reg[4]}\t${reg[5]}\t${reg[6]}\t${reg[7]}\t${reg[8]}\t${reg[9]}');
    }
    
    print('\n✅ Análisis completado');
    
  } catch (e) {
    print('❌ Error en la prueba: $e');
  } finally {
    await db.close();
  }
}