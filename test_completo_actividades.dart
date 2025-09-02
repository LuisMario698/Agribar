import 'lib/services/reportes_gastos_service.dart';

void main() async {
  final service = ReportesGastosService();
  
  try {
    print('=== Verificando datos disponibles ===');
    
    // Obtener semanas disponibles
    final semanas = await service.obtenerSemanasDisponibles();
    print('Semanas disponibles: ${semanas.length}');
    
    if (semanas.isNotEmpty) {
      final semana = semanas.first;
      print('Primera semana: ID=${semana['id']}, ${semana['nombre']}');
      
      // Obtener actividades disponibles
      final actividades = await service.obtenerActividadesDisponibles();
      print('Actividades disponibles: ${actividades.length}');
      
      if (actividades.isNotEmpty) {
        final actividad = actividades.first;
        print('Primera actividad: ID=${actividad['id']}, ${actividad['nombre']}');
        
        // Probar el reporte por actividad
        print('\n=== Probando reporte por actividad ===');
        final datos = await service.obtenerReportePorActividad(
          semana['id'], 
          actividad['id']
        );
        
        print('Datos obtenidos: ${datos.length} registros');
        
        if (datos.isEmpty) {
          print('No hay datos para esta combinación. Probando con más actividades...');
          
          // Probar con las primeras 3 actividades
          for (int i = 0; i < 3 && i < actividades.length; i++) {
            final act = actividades[i];
            print('\nProbando actividad: ${act['nombre']} (ID: ${act['id']})');
            
            final datosAct = await service.obtenerReportePorActividad(
              semana['id'], 
              act['id']
            );
            
            print('Registros encontrados: ${datosAct.length}');
            
            if (datosAct.isNotEmpty) {
              print('¡Datos encontrados!');
              for (var dato in datosAct.take(2)) {
                print('  - Cuadrilla: ${dato['cuadrilla_nombre']} (${dato['cuadrilla_clave']})');
                print('  - Empleados: ${dato['empleados_unicos']}');
                print('  - Total: \$${dato['total_pagado']}');
              }
              break;
            }
          }
        } else {
          for (var dato in datos.take(3)) {
            print('---');
            print('Clave Cuadrilla: ${dato['cuadrilla_clave']}');
            print('Nombre Cuadrilla: ${dato['cuadrilla_nombre']}');
            print('Empleados: ${dato['empleados_unicos']}');
            print('Total Pagado: ${dato['total_pagado']}');
          }
        }
      }
    }
    
  } catch (e) {
    print('Error: $e');
  }
}
