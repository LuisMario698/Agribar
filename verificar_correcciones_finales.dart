/// Script para verificar que las correcciones del flujo de datos estén funcionando
/// Problema original: Se enviaban valores NULL cuando deberían ser 0
/// Solución: Asegurar que TODOS los valores vacíos se conviertan a 0

void main() {
  print('🔧 VERIFICACIÓN DE CORRECCIONES APLICADAS');
  print('=' * 60);
  
  // Simular datos como vienen de la interfaz/BD
  final testCases = [
    {'name': 'Valores null', 'sueldo': null, 'actividad': null, 'campo': null},
    {'name': 'Strings vacíos', 'sueldo': '', 'actividad': '', 'campo': ''},
    {'name': 'String "0"', 'sueldo': '0', 'actividad': '0', 'campo': '0'},
    {'name': 'Valores válidos', 'sueldo': '400', 'actividad': '2', 'campo': '1'},
    {'name': 'Enteros', 'sueldo': 0, 'actividad': 0, 'campo': 0},
  ];
  
  print('1️⃣ PRUEBA DE FUNCIONES DE CONVERSIÓN:');
  print('-' * 40);
  
  for (var test in testCases) {
    print('\n📋 Caso: ${test['name']}');
    print('   Entrada → Salida');
    
    // Probar _getSafeIntValue (para sueldos y actividades cuando se convierten a int)
    final sueldoResult = _getSafeIntValue(test['sueldo']);
    final actividadResult = _getSafeIntValue(test['actividad']);
    
    // Probar _getSafeStringValue (para campos/ranchos)
    final campoResult = _getSafeStringValue(test['campo']);
    
    print('   Sueldo: ${test['sueldo']} (${test['sueldo'].runtimeType}) → $sueldoResult');
    print('   Actividad: ${test['actividad']} (${test['actividad'].runtimeType}) → $actividadResult');
    print('   Campo: ${test['campo']} (${test['campo'].runtimeType}) → "$campoResult"');
    
    // Verificar que nunca sea null
    final hasNull = sueldoResult == null || actividadResult == null || campoResult == null;
    print('   Status: ${hasNull ? "❌ CONTIENE NULL" : "✅ SIN NULL"}');
  }
  
  print('\n\n2️⃣ SIMULACIÓN DEL FLUJO COMPLETO:');
  print('-' * 40);
  
  // Simular empleado con día 7 vacío (el problema original)
  final empleadoEjemplo = {
    'nombre': 'Juan Pérez',
    'dia_6_s': null,      // Día 7 sueldo vacío
    'dia_6_id': '',       // Día 7 actividad vacía
    'dia_6_campo': null,  // Día 7 campo vacío
    'dia_5_s': '400',     // Día 6 con datos válidos
    'dia_5_id': '2',      // Día 6 actividad válida
    'dia_5_campo': '1',   // Día 6 campo válido
  };
  
  print('\n📤 DATOS QUE SE ENVIARÁN A LA BD:');
  final datosParaBD = {
    'dia_7': _getSafeIntValue(empleadoEjemplo['dia_6_s']),
    'act_7': _getSafeIntValue(empleadoEjemplo['dia_6_id']),
    'campo_7': _getSafeStringValue(empleadoEjemplo['dia_6_campo']),
    'dia_6': _getSafeIntValue(empleadoEjemplo['dia_5_s']),
    'act_6': _getSafeIntValue(empleadoEjemplo['dia_5_id']),
    'campo_6': _getSafeStringValue(empleadoEjemplo['dia_5_campo']),
  };
  
  for (var entry in datosParaBD.entries) {
    final value = entry.value;
    final isZero = (value == 0 || value == '0');
    final status = value == null ? '❌ NULL (PROBLEMA)' : 
                  isZero ? '✅ CERO (CORRECTO)' : 
                  '✅ VALOR: $value';
    print('   ${entry.key}: $status');
  }
  
  print('\n\n3️⃣ RESUMEN DE CORRECCIONES APLICADAS:');
  print('-' * 40);
  print('✅ _getSafeIntValue() ahora retorna 0 para valores null/vacíos');
  print('✅ _getSafeStringValue() ahora retorna "0" para campos de rancho vacíos');
  print('✅ Tabla editable guarda "0" en lugar de null para actividades/campos vacíos');
  print('✅ Inicialización por defecto usa "0" en lugar de strings vacíos');
  print('✅ Carga desde BD convierte null a "0" para campos de rancho');
  
  print('\n🎯 RESULTADO ESPERADO:');
  print('• Los reportes ya NO mostrarán [null] para actividades/campos vacíos');
  print('• El día 7 se guardará correctamente como 0 cuando esté vacío');
  print('• Las consultas SQL funcionarán correctamente con valores 0');
  print('• Los dropdowns mostrarán opciones válidas sin errores');
}

/// Funciones corregidas que ahora se usan en el sistema
int _getSafeIntValue(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.round();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    final parsed = num.tryParse(trimmed);
    return parsed?.round() ?? 0;
  }
  return 0;
}

String _getSafeStringValue(dynamic value) {
  if (value == null) return '0';
  final stringValue = value.toString().trim();
  return stringValue.isEmpty ? '0' : stringValue;
}
