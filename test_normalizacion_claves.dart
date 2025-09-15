void main() {
  print('🧪 PRUEBA: NORMALIZACIÓN DE CLAVES DE ACTIVIDADES');
  print('================================================');
  
  // Simular el mapeo clave -> nombre (como en la tabla de actividades)
  Map<String, String> claveANombreMap = {
    '1': 'DESTAJO',
    '1301': 'JEFE DE LINEA',
    '1306': 'JEFE DE EMPAQUE',
    '1309': 'CADENERO',
    '1315': 'TAPADORA',
    '1313': 'ARMADONDE CAJAS',
    '1305': 'LIMPIEZA',
    '1316': 'ENCARGADO C.F',
    '1326': 'LAVADOR NOCTURNO',
    '1311': 'LAVADOR',
    '1317': 'AYUDANTE C.F',
    '1104': 'DESHIERBE',
    '1507': 'EMBOLSADO',
    '1303': 'SORTEADOR',
    '1304': 'EMPACADOR',
    '112': 'AYUDANTE DE REGADOR',
  };

  // Casos de prueba con valores que podrían llegar del widget editable
  List<dynamic> casosPrueba = [
    '1301',      // Correcto
    '1301.0',    // Con decimal
    1301,        // Como entero
    1301.0,      // Como double
    '1306',      // Otra clave correcta
    '1306.0',    // Con decimal
    '0',         // Cero
    '0.0',       // Cero con decimal
    null,        // Null
    '',          // String vacío
    '9999',      // Clave que no existe
    '9999.0',    // Clave que no existe con decimal
  ];

  print('🔍 PROBANDO NORMALIZACIÓN Y BÚSQUEDA:');
  print('┌──────────────┬──────────────┬────────────────────┐');
  print('│ Valor orig.  │ Normalizado  │ Resultado          │');
  print('├──────────────┼──────────────┼────────────────────┤');

  for (var caso in casosPrueba) {
    String resultado;
    
    if (caso == null || caso.toString() == '0' || caso.toString().isEmpty) {
      resultado = 'actividad';
    } else {
      // 🔧 LÓGICA CORREGIDA: Normalizar la clave antes de buscar
      final claveRaw = caso.toString();
      final clave = claveRaw.contains('.') ? claveRaw.split('.')[0] : claveRaw;
      
      if (claveANombreMap.containsKey(clave)) {
        resultado = claveANombreMap[clave]!;
      } else {
        resultado = 'no existe';
      }
    }
    
    final casoStr = caso?.toString() ?? 'null';
    final normalizado = caso == null || caso.toString() == '0' || caso.toString().isEmpty 
        ? 'N/A' 
        : (caso.toString().contains('.') ? caso.toString().split('.')[0] : caso.toString());
    
    print('│ ${casoStr.padRight(12)} │ ${normalizado.padRight(12)} │ ${resultado.padRight(18)} │');
  }
  
  print('└──────────────┴──────────────┴────────────────────┘');
  
  print('\n✅ CASOS ESPECÍFICOS:');
  print('• "1301.0" → "${_normalizarClave("1301.0")}" → ${claveANombreMap[_normalizarClave("1301.0")] ?? "no existe"}');
  print('• "1306.0" → "${_normalizarClave("1306.0")}" → ${claveANombreMap[_normalizarClave("1306.0")] ?? "no existe"}');
  print('• "1301" → "${_normalizarClave("1301")}" → ${claveANombreMap[_normalizarClave("1301")] ?? "no existe"}');
  
  print('\n🎯 LA CORRECCIÓN DEBERÍA SOLUCIONAR EL PROBLEMA');
}

// Función auxiliar para normalizar claves
String _normalizarClave(String claveRaw) {
  return claveRaw.contains('.') ? claveRaw.split('.')[0] : claveRaw;
}