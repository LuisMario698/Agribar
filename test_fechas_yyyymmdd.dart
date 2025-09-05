import 'package:agribar/services/reportes_service.dart';

/// Test específico para verificar manejo de fechas YYYYMMDD
void main() async {
  print('🗓️ === TEST FORMATO FECHAS YYYYMMDD ===');
  print('=====================================');

  final reportesService = ReportesService();

  try {
    // Test 1: Sin filtros de fecha
    print('\n1️⃣ REPORTE SIN FILTROS DE FECHA:');
    final reporteSinFiltro = await reportesService.obtenerReporteGeneral();
    print('✅ Registros sin filtro: ${reporteSinFiltro.length}');
    if (reporteSinFiltro.isNotEmpty) {
      print('   Ejemplo: ${reporteSinFiltro.first['rancho']} - \$${reporteSinFiltro.first['gasto_total']}');
    }

    // Test 2: Con filtro de fecha de hace 7 días
    print('\n2️⃣ REPORTE CON FILTRO DE FECHA (últimos 7 días):');
    final DateTime fechaFin = DateTime.now();
    final DateTime fechaInicio = fechaFin.subtract(Duration(days: 7));
    
    print('   📅 Fecha inicio: ${fechaInicio.year}-${fechaInicio.month.toString().padLeft(2, '0')}-${fechaInicio.day.toString().padLeft(2, '0')}');
    print('   📅 Fecha fin: ${fechaFin.year}-${fechaFin.month.toString().padLeft(2, '0')}-${fechaFin.day.toString().padLeft(2, '0')}');
    print('   📊 Formato YYYYMMDD inicio: ${fechaInicio.year}${fechaInicio.month.toString().padLeft(2, '0')}${fechaInicio.day.toString().padLeft(2, '0')}');
    print('   📊 Formato YYYYMMDD fin: ${fechaFin.year}${fechaFin.month.toString().padLeft(2, '0')}${fechaFin.day.toString().padLeft(2, '0')}');

    final reporteConFecha = await reportesService.obtenerReporteGeneral(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
    
    print('✅ Registros con filtro de fecha: ${reporteConFecha.length}');
    if (reporteConFecha.isNotEmpty) {
      print('   📊 RESULTADOS FILTRADOS:');
      for (var registro in reporteConFecha) {
        print('   - ${registro['rancho']} | ${registro['actividad']} | \$${registro['gasto_total']}');
      }
    } else {
      print('   ⚠️ No hay registros en el rango de fechas especificado');
    }

    // Test 3: Con filtro de fecha muy específico (hoy)
    print('\n3️⃣ REPORTE FILTRADO PARA HOY:');
    final DateTime hoy = DateTime.now();
    final reporteHoy = await reportesService.obtenerReporteGeneral(
      fechaInicio: hoy,
      fechaFin: hoy,
    );
    
    print('✅ Registros para hoy (${hoy.year}${hoy.month.toString().padLeft(2, '0')}${hoy.day.toString().padLeft(2, '0')}): ${reporteHoy.length}');

    // Test 4: Resumen general para verificar totales
    print('\n4️⃣ RESUMEN GENERAL PARA VERIFICACIÓN:');
    final resumen = await reportesService.obtenerResumenGeneral();
    print('✅ Resumen:');
    print('   👷 Total empleados: ${resumen['total_empleados']}');
    print('   🏡 Ranchos activos: ${resumen['ranchos_activos']}');
    print('   📅 Días trabajados: ${resumen['dias_trabajados']}');
    print('   💰 Monto total: \$${resumen['monto_total']}');

    print('\n🎉 === PRUEBAS DE FECHA COMPLETADAS ===');

  } catch (e, stackTrace) {
    print('❌ ERROR EN PRUEBAS: $e');
    print('🔍 Stack trace: $stackTrace');
  }
}
