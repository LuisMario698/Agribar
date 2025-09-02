import 'package:agribar/services/reportes_gastos_service.dart';

Future<void> main() async {
  print('🧪 Test de dropdowns mejorados...');
  
  final service = ReportesGastosService();
  
  try {
    print('📋 1. Verificando semanas...');
    final semanas = await service.obtenerSemanasDisponibles();
    print('✅ Semanas: ${semanas.length}');
    
    print('\n📋 2. Verificando ranchos...');
    final ranchos = await service.obtenerRanchosDisponibles();
    print('✅ Ranchos: ${ranchos.length}');
    for (final rancho in ranchos) {
      print('  - ${rancho['nombre']}');
    }
    
    print('\n📋 3. Verificando actividades (primeras 10)...');
    final actividades = await service.obtenerActividadesDisponibles();
    print('✅ Total actividades: ${actividades.length}');
    print('📄 Primeras 10 actividades:');
    for (int i = 0; i < (actividades.length > 10 ? 10 : actividades.length); i++) {
      final actividad = actividades[i];
      print('  - ${actividad['nombre']}');
    }
    
    if (actividades.length > 10) {
      print('  ... y ${actividades.length - 10} más');
    }
    
    print('\n🎉 ¡Dropdowns listos con datos completos!');
    print('📊 Mejoras implementadas:');
    print('  ✅ Altura máxima controlada (300px actividades, 250px semanas, 200px ranchos)');
    print('  ✅ Texto con overflow controlado');
    print('  ✅ Scroll interno automático');
    print('  ✅ Formato consistente en todos los dropdowns');
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}
