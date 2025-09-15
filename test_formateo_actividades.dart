void main() {
  print('🧪 PRUEBA: FORMATEO DE VALORES DE ACTIVIDADES');
  print('==============================================');
  
  // Simular la función _formatearIdOCampo (del widget principal)
  String formatearIdOCampo(dynamic valor) {
    if (valor == null) return '';
    if (valor is int) {
      if (valor == 0) return '';
      return valor.toString();
    }
    if (valor is double) {
      if (valor == 0) return '';
      if (valor % 1 == 0) {
        return valor.toInt().toString();
      }
      return valor.toStringAsFixed(0);
    }
    final s = valor.toString();
    if (s == '0') return '';
    if (RegExp(r'^\d+\.0$').hasMatch(s)) {
      return s.split('.').first;
    }
    return s;
  }
  
  // Simular la función _normalizarValorActividad (del widget hijo)
  String normalizarValorActividad(String valor) {
    if (valor.isEmpty || valor == '0') return '';
    if (valor.endsWith('.0')) {
      return valor.substring(0, valor.length - 2);
    }
    return valor;
  }

  // Casos de prueba
  List<dynamic> valores = [
    1301,      // int
    1301.0,    // double
    '1301',    // string
    '1301.0',  // string con decimal
    1306,      // otro int
    1306.0,    // otro double
    '1306',    // otro string
    '1306.0',  // otro string con decimal
    0,         // cero int
    0.0,       // cero double
    '0',       // cero string
    '0.0',     // cero string con decimal
    null,      // null
    '',        // string vacío
  ];

  print('🔍 RESULTADOS DEL FORMATEO:');
  print('┌─────────────┬─────────────────┬─────────────────────┐');
  print('│ Valor orig. │ _formatearIdO.. │ _normalizarValor... │');
  print('├─────────────┼─────────────────┼─────────────────────┤');

  for (var valor in valores) {
    final valorStr = valor?.toString() ?? 'null';
    final formateado = formatearIdOCampo(valor);
    final normalizado = normalizarValorActividad(formateado);
    
    print('│ ${valorStr.padRight(11)} │ ${formateado.padRight(15)} │ ${normalizado.padRight(19)} │');
  }
  
  print('└─────────────┴─────────────────┴─────────────────────┘');
  
  print('\n✅ CASOS ESPECÍFICOS QUE DEBERÍAN FUNCIONAR:');
  print('• Valor: 1301.0 → Formateado: "${formatearIdOCampo(1301.0)}" → Normalizado: "${normalizarValorActividad(formatearIdOCampo(1301.0))}"');
  print('• Valor: "1301.0" → Formateado: "${formatearIdOCampo("1301.0")}" → Normalizado: "${normalizarValorActividad(formatearIdOCampo("1301.0"))}"');
  print('• Valor: 1306.0 → Formateado: "${formatearIdOCampo(1306.0)}" → Normalizado: "${normalizarValorActividad(formatearIdOCampo(1306.0))}"');
  
  print('\n🎯 AHORA EL CAMPO DE ACTIVIDAD DEBERÍA MOSTRAR "1301" EN LUGAR DE "1301.0"');
}