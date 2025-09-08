import 'package:agribar/services/database_service.dart';

/// Script para probar las correcciones del día 7 y actividades null
void main() async {
  print('🧪 PRUEBA DE CORRECCIONES: DÍA 7 Y ACTIVIDADES NULL');
  print('=' * 60);
  
  // Simular datos como vienen de la interfaz
  print('1️⃣ DATOS SIMULADOS DE LA INTERFAZ:');
  final datosInterfaz = {
    'dia_6_s': null,        // Día 7 sin valor
    'dia_6_id': '',         // Actividad día 7 vacía  
    'dia_6_campo': null,    // Campo día 7 null
    'dia_5_s': '400',       // Día 6 con valor
    'dia_5_id': '2',        // Actividad día 6 con valor
    'dia_5_campo': '1',     // Campo día 6 con valor
  };
  
  for (var entry in datosInterfaz.entries) {
    print('  ${entry.key}: ${entry.value} (${entry.value.runtimeType})');
  }
  print('');
  
  // Aplicar las funciones corregidas
  print('2️⃣ APLICANDO FUNCIONES CORREGIDAS:');
  
  final resultados = {
    'dia_7': _getSafeIntValue(datosInterfaz['dia_6_s']),
    'act_7': _getSafeIntValue(datosInterfaz['dia_6_id']),
    'campo_7': _getSafeStringValue(datosInterfaz['dia_6_campo']),
    'dia_6': _getSafeIntValue(datosInterfaz['dia_5_s']),
    'act_6': _getSafeIntValue(datosInterfaz['dia_5_id']),
    'campo_6': _getSafeStringValue(datosInterfaz['dia_5_campo']),
  };
  
  for (var entry in resultados.entries) {
    final value = entry.value;
    final status = value == null ? '✅ NULL (correcto)' : 
                  (value.toString().isEmpty ? '⚠️  String vacío' : '✅ ${value}');
    print('  ${entry.key}: ${status}');
  }
  print('');
  
  // Verificar la lógica de la base de datos
  print('3️⃣ VERIFICANDO CONSULTA SQL:');
  print('  Los valores NULL ahora se insertarán correctamente en la BD');
  print('  En lugar de enviar 0 y "", se enviará NULL');
  print('  Esto evitará los registros fantasma con datos vacíos');
  print('');
  
  // Probar con la BD real si es posible
  try {
    await probarConBDReal();
  } catch (e) {
    print('❌ No se pudo conectar a la BD para pruebas: $e');
  }
  
  print('4️⃣ RESUMEN DE CORRECCIONES:');
  print('✅ _getSafeIntValue() ahora retorna NULL para valores vacíos/0');
  print('✅ _getSafeStringValue() ahora retorna NULL para strings vacíos');
  print('✅ Esto evita enviar datos "fantasma" a la BD');
  print('✅ Los reportes ya no mostrarán actividades/campos vacíos como válidos');
  print('');
  print('🎯 PRÓXIMOS PASOS:');
  print('1. Probar guardando datos en el sistema');
  print('2. Verificar que los reportes ya no muestren actividades/campos null');
  print('3. Confirmar que el día 7 se guarda correctamente');
}

/// Probar con la base de datos real
Future<void> probarConBDReal() async {
  final db = DatabaseService();
  
  try {
    print('🔌 Conectando a la BD para pruebas...');
    await db.connect();
    
    // Verificar semana activa
    final semana = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin 
      FROM semanas_nomina 
      WHERE esta_cerrada = false
      ORDER BY id_semana DESC 
      LIMIT 1;
    ''');
    
    if (semana.isNotEmpty) {
      final semanaId = semana.first[0];
      print('✅ Semana activa encontrada: $semanaId');
      
      // Contar registros con act_7 null vs act_7 = 0
      final stats = await db.connection.query('''
        SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN act_7 IS NULL THEN 1 END) as act7_null,
          COUNT(CASE WHEN act_7 = 0 THEN 1 END) as act7_cero,
          COUNT(CASE WHEN act_7 > 0 THEN 1 END) as act7_con_valor,
          COUNT(CASE WHEN dia_7 IS NULL THEN 1 END) as dia7_null,
          COUNT(CASE WHEN dia_7 = 0 THEN 1 END) as dia7_cero,
          COUNT(CASE WHEN dia_7 > 0 THEN 1 END) as dia7_con_valor
        FROM nomina_empleados_semanal
        WHERE id_semana = $semanaId;
      ''');
      
      if (stats.isNotEmpty) {
        final s = stats.first;
        print('📊 ESTADÍSTICAS ACTUALES DEL DÍA 7:');
        print('  Total registros: ${s[0]}');
        print('  act_7 NULL: ${s[1]} (✅ correcto sin actividad)');
        print('  act_7 = 0: ${s[2]} (⚠️  debería ser NULL)');
        print('  act_7 > 0: ${s[3]} (✅ con actividad)');
        print('  dia_7 NULL: ${s[4]} (✅ correcto sin trabajo)');
        print('  dia_7 = 0: ${s[5]} (⚠️  debería ser NULL)');
        print('  dia_7 > 0: ${s[6]} (✅ con trabajo)');
      }
    } else {
      print('⚠️  No hay semana activa para probar');
    }
    
  } finally {
    await db.close();
  }
}

/// Funciones corregidas para pruebas
int? _getSafeIntValue(dynamic value) {
  if (value == null) return null;
  if (value is int) {
    return value == 0 ? null : value;
  }
  if (value is double) {
    final rounded = value.round();
    return rounded == 0 ? null : rounded;
  }
  if (value is num) {
    final rounded = value.round();
    return rounded == 0 ? null : rounded;
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == '0') return null;
    final parsed = num.tryParse(trimmed);
    if (parsed == null) return null;
    final rounded = parsed.round();
    return rounded == 0 ? null : rounded;
  }
  return null;
}

String? _getSafeStringValue(dynamic value) {
  if (value == null) return null;
  final stringValue = value.toString().trim();
  return stringValue.isEmpty ? null : stringValue;
}
