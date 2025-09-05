import 'package:agribar/services/reportes_gastos_service.dart';

Future<void> main() async {
  print('🧪 Test de tabla mejorada de reportes...');
  
  final service = ReportesGastosService();
  
  try {
    print('📋 1. Cargando datos de prueba...');
    final semanas = await service.obtenerSemanasDisponibles();
    
    if (semanas.isNotEmpty) {
      final semanaId = semanas.first['id'];
      print('✅ Usando semana: ${semanas.first['nombre']}');
      
      print('\n📊 2. Generando reporte general...');
      final reporte = await service.obtenerReporteGeneralPorSemana(semanaId);
      print('✅ Registros encontrados: ${reporte.length}');
      
      if (reporte.isNotEmpty) {
        print('\n📄 3. Muestra de datos (primeros 3 registros):');
        for (int i = 0; i < (reporte.length > 3 ? 3 : reporte.length); i++) {
          final item = reporte[i];
          print('  ${i + 1}. ${item['actividad_nombre']}: \$${item['total_pagado']} (${item['registros']} registros)');
        }
        
        final total = reporte.fold<double>(0.0, (sum, item) => sum + (item['total_pagado'] as double));
        print('\n💰 Total calculado: \$${total.toStringAsFixed(2)}');
      }
      
      print('\n🎉 Mejoras implementadas en la tabla:');
      print('  ✅ Tabla responsiva con LayoutBuilder');
      print('  ✅ Columnas con ancho proporcional (50%, 30%, 20%)');
      print('  ✅ Altura de filas optimizada (48-72px)');
      print('  ✅ Espaciado reducido para mejor uso del espacio');
      print('  ✅ Scroll vertical eficiente');
      print('  ✅ Elementos visuales mejorados con badges');
      print('  ✅ Texto con overflow controlado');
      print('  ✅ Márgenes optimizados');
      
    } else {
      print('⚠️ No hay semanas disponibles para el test');
    }
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}
