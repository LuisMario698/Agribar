import 'package:agribar/services/database_service.dart';
import 'package:agribar/services/reportes_service.dart';

/// Script para debug específico de reportes
void main() async {
  print('🚀 PROBANDO REPORTES EN VIVO');
  print('==============================');
  
  final reportesService = ReportesService();
  
  try {
    print('\n1️⃣ PROBANDO OBTENER RANCHOS:');
    final ranchos = await reportesService.obtenerRanchos();
    print('✅ Ranchos obtenidos: ${ranchos.length}');
    for (var rancho in ranchos) {
      print('   - $rancho');
    }
    
    print('\n2️⃣ PROBANDO OBTENER ACTIVIDADES:');
    final actividades = await reportesService.obtenerActividades();
    print('✅ Actividades obtenidas: ${actividades.length}');
    print('   Primeras 5:');
    for (int i = 0; i < (actividades.length > 5 ? 5 : actividades.length); i++) {
      print('   - ${actividades[i]}');
    }
    
    print('\n3️⃣ PROBANDO REPORTE GENERAL:');
    final reporteGeneral = await reportesService.obtenerReporteGeneral();
    print('✅ Reporte general: ${reporteGeneral.length} registros');
    if (reporteGeneral.isNotEmpty) {
      print('   📊 DATOS:');
      for (var registro in reporteGeneral) {
        print('   - Rancho: ${registro['rancho']}');
        print('     Actividad: ${registro['actividad']}');
        print('     Empleados: ${registro['empleados_involucrados']}');
        print('     Gasto Total: \$${registro['gasto_total']}');
        print('     ────────────────────');
      }
    } else {
      print('   ⚠️ No hay datos en reporte general');
    }
    
    print('\n4️⃣ PROBANDO REPORTE POR RANCHO:');
    if (ranchos.length > 1) {
      final ranchoEjemplo = ranchos[1]; // No usar "Todos"
      final reportePorRancho = await reportesService.obtenerReportePorRancho(
        rancho: ranchoEjemplo
      );
      print('✅ Reporte por rancho "$ranchoEjemplo": ${reportePorRancho.length} registros');
      if (reportePorRancho.isNotEmpty) {
        for (var registro in reportePorRancho) {
          print('   - Actividad: ${registro['actividad']}');
          print('     Empleados: ${registro['empleados']}');
          print('     Gasto Total: \$${registro['gasto_total']}');
          print('     ────────────────────');
        }
      }
    }
    
    print('\n5️⃣ PROBANDO RESUMEN GENERAL:');
    final resumen = await reportesService.obtenerResumenGeneral();
    print('✅ Resumen obtenido:');
    print('   - Total empleados: ${resumen['total_empleados']}');
    print('   - Ranchos activos: ${resumen['ranchos_activos']}');
    print('   - Días trabajados: ${resumen['dias_trabajados']}');
    print('   - Monto total: \$${resumen['monto_total']}');
    print('   - Actividades realizadas: ${resumen['actividades_realizadas']}');
    
    print('\n6️⃣ VERIFICANDO DATOS DIRECTOS DE BD:');
    final db = DatabaseService();
    await db.connect();
    
    // Verificar datos específicos para entender el problema
    final queryTest = await db.connection.query('''
      SELECT 
        neh.id_empleado,
        neh.id_cuadrilla,
        c.nombre as cuadrilla_nombre,
        neh.total,
        neh.fecha_cierre
      FROM nomina_empleados_historial neh
      JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
      ORDER BY neh.fecha_cierre DESC
      LIMIT 5;
    ''');
    
    print('✅ Últimos 5 registros de nómina:');
    for (var row in queryTest) {
      print('   - Empleado ID: ${row[0]}, Cuadrilla: ${row[2]}, Total: \$${row[3]}, Fecha: ${row[4]}');
    }
    
    await db.close();
    
  } catch (e) {
    print('❌ ERROR DURANTE LAS PRUEBAS: $e');
    print('   Stack trace: ${StackTrace.current}');
  }
  
  print('\n🏁 FIN DEL DEBUG');
}
