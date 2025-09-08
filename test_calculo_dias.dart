/// Test específico para verificar el problema con el cálculo de días
void main() {
  print('🧪 TEST: CÁLCULO DE DÍAS EN DATETIMERAGNE');
  print('=' * 50);
  
  // Simular una semana típica (lunes a domingo)
  final lunes = DateTime(2025, 1, 6);     // 6 enero 2025 (lunes)
  final domingo = DateTime(2025, 1, 12);  // 12 enero 2025 (domingo)
  
  print('📅 SEMANA DE PRUEBA:');
  print('  Inicio: ${lunes.day}/${lunes.month}/${lunes.year} (${_getDayName(lunes)})');
  print('  Fin: ${domingo.day}/${domingo.month}/${domingo.year} (${_getDayName(domingo)})');
  print('');
  
  print('🔍 CÁLCULOS:');
  final duration = domingo.difference(lunes);
  print('  duration.inDays: ${duration.inDays}');
  print('  duration.inDays + 1: ${duration.inDays + 1}');
  print('');
  
  // Verificar el cálculo de _numeroDias
  final numeroDias = duration.inDays + 1;
  print('📊 RESULTADO:');
  print('  _numeroDias calculado: $numeroDias');
  print('  ¿Es correcto?: ${numeroDias == 7 ? "✅ SÍ" : "❌ NO"}');
  print('');
  
  // Probar con diferentes rangos problemáticos
  print('🔍 PROBANDO CASOS PROBLEMÁTICOS:');
  
  // Caso 1: Rango de 0 días (mismo día)
  final mismoDiaD = lunes.difference(lunes);
  print('  Mismo día: ${mismoDiaD.inDays + 1} días');
  
  // Caso 2: Rango de 1 día (día siguiente)
  final unDiaD = DateTime(2025, 1, 7).difference(lunes);
  print('  1 día real: ${unDiaD.inDays + 1} días');
  
  // Caso 3: Semana incompleta (6 días)
  final seisDiasD = DateTime(2025, 1, 11).difference(lunes);
  print('  6 días reales: ${seisDiasD.inDays + 1} días');
  
  print('');
  print('🎯 DIAGNÓSTICO:');
  print('Si _numeroDias != 7, entonces:');
  print('1. La tabla no generará 7 columnas de días');
  print('2. Los datos del día 7 no se capturarán');
  print('3. Los mapeos dia_6_s → dia_7 fallarán');
  print('');
  
  // Simular el problema específico
  print('🚨 SIMULANDO EL PROBLEMA:');
  print('Si _numeroDias = $numeroDias, entonces:');
  
  print('  Días generados en interfaz:');
  for (int i = 0; i < numeroDias; i++) {
    print('    dia_${i}_s → dia_${i + 1} (BD)');
  }
  
  if (numeroDias < 7) {
    print('  ❌ PROBLEMA: No se genera dia_6_s → dia_7');
    print('  ❌ Los datos del día 7 siempre serán null/0');
  } else if (numeroDias > 7) {
    print('  ❌ PROBLEMA: Se generan más de 7 días');
    print('  ❌ Mapeo incorrecto a BD');
  } else {
    print('  ✅ Se generan exactamente 7 días');
  }
  
  print('');
  print('💡 SOLUCIÓN PROPUESTA:');
  print('  Forzar _numeroDias = 7 siempre en tabla de nómina');
  print('  O verificar que DateTimeRange siempre tenga 6 days de duration');
}

String _getDayName(DateTime date) {
  const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  return days[date.weekday - 1];
}
