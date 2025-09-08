import 'lib/services/reportes_gastos_service.dart';

void main() async {
  print('🚀 PRUEBA SUPER SIMPLE DE REPORTES');
  print('=' * 40);
  
  final service = ReportesGastosService();
  
  try {
    // Solo probar obtener semanas
    print('\n📋 Obteniendo semanas...');
    final semanas = await service.obtenerSemanasDisponibles();
    
    print('Total: ${semanas.length}');
    
    // Mostrar primeras 5 semanas
    for (var i = 0; i < semanas.length && i < 5; i++) {
      final semana = semanas[i];
      print('${i+1}. Semana ${semana['id']}: ${semana['nombre']}');
    }
    
    // Buscar semana 37
    final semana37 = semanas.where((s) => s['id'] == 37).toList();
    if (semana37.isNotEmpty) {
      print('\n✅ SEMANA 37 ENCONTRADA!');
      
      // Probar reporte para semana 37
      print('Generando reporte...');
      final reporte = await service.obtenerReporteGeneralPorSemana(37);
      print('Actividades: ${reporte.length}');
      
      if (reporte.isNotEmpty) {
        print('Primera actividad: ${reporte[0]['actividad_nombre']} = \$${reporte[0]['total_pagado']}');
      }
    } else {
      print('\n❌ Semana 37 NO encontrada');
    }
    
    print('\n✅ PRUEBA COMPLETADA');
    
  } catch (e) {
    print('ERROR: $e');
  }
}
