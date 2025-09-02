import 'package:agribar/services/reportes_gastos_service.dart';

Future<void> main() async {
  print('🧪 Test de actividades disponibles...');
  
  final service = ReportesGastosService();
  
  try {
    print('📋 Obteniendo todas las actividades...');
    final actividades = await service.obtenerActividadesDisponibles();
    
    print('✅ Total de actividades encontradas: ${actividades.length}');
    print('📄 Lista completa de actividades:');
    
    for (final actividad in actividades) {
      print('  - ID: ${actividad['id']}, Nombre: ${actividad['nombre']}, Clave: ${actividad['clave'] ?? 'N/A'}');
    }
    
    if (actividades.isEmpty) {
      print('⚠️ No se encontraron actividades en la base de datos');
    }
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }
}
