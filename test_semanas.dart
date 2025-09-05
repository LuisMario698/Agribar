import 'package:agribar/services/reportes_gastos_service.dart';

void main() async {
  print('🔍 Probando solo las semanas...');
  
  final service = ReportesGastosService();
  
  try {
    final semanas = await service.obtenerSemanasDisponibles();
    print('✅ Semanas obtenidas: ${semanas.length}');
    
    for (final semana in semanas) {
      print('  - ID: ${semana['id']}');
      print('    Nombre: ${semana['nombre']}');
      print('    Autorizado por: ${semana['autorizado_por']}');
      print('    Fecha inicio: ${semana['fecha_inicio']}');
      print('    Fecha fin: ${semana['fecha_fin']}');
      print('');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
