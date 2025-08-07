import 'package:agribar/services/database_service.dart';
import 'package:agribar/services/reportes_service.dart';

/// Script de debug para verificar datos en reportes
void main() async {
  print('🔍 INICIANDO DEBUG DE REPORTES');
  print('================================');
  
  // 1. Verificar conexión a base de datos
  final db = DatabaseService();
  try {
    await db.connect();
    print('✅ Conexión a base de datos exitosa');
  } catch (e) {
    print('❌ Error de conexión: $e');
    return;
  }
  
  // 2. Verificar tablas básicas
  print('\n📋 VERIFICANDO TABLAS BÁSICAS:');
  
  try {
    // Contar empleados
    final empleadosResult = await db.connection.query('SELECT COUNT(*) FROM empleados;');
    print('👥 Empleados: ${empleadosResult[0][0]}');
    
    // Contar cuadrillas
    final cuadrillasResult = await db.connection.query('SELECT COUNT(*) FROM cuadrillas WHERE estado = true;');
    print('👷‍♂️ Cuadrillas activas: ${cuadrillasResult[0][0]}');
    
    // Contar actividades
    final actividadesResult = await db.connection.query('SELECT COUNT(*) FROM actividades;');
    print('🏃‍♂️ Actividades: ${actividadesResult[0][0]}');
    
    // Contar ranchos
    final ranchosResult = await db.connection.query('SELECT COUNT(*) FROM ranchos;');
    print('🏠 Ranchos: ${ranchosResult[0][0]}');
    
    // Contar semanas
    final semanasResult = await db.connection.query('SELECT COUNT(*) FROM semanas_nomina;');
    print('📅 Semanas de nómina: ${semanasResult[0][0]}');
    
    // Contar registros de nómina
    final nominaResult = await db.connection.query('SELECT COUNT(*) FROM nomina_empleados_historial;');
    print('💰 Registros de nómina historial: ${nominaResult[0][0]}');
    
    // También verificar nomina_empleados_semanal
    final nominaSemanaleResult = await db.connection.query('SELECT COUNT(*) FROM nomina_empleados_semanal;');
    print('� Registros de nómina semanal: ${nominaSemanaleResult[0][0]}');
    
  } catch (e) {
    print('❌ Error al verificar tablas: $e');
  }
  
  // 3. Verificar datos específicos de reportes
  print('\n📊 VERIFICANDO DATOS PARA REPORTES:');
  
  try {
    // Obtener algunas actividades
    final actividadesQuery = await db.connection.query('SELECT nombre FROM actividades LIMIT 5;');
    print('🏃‍♂️ Primeras 5 actividades:');
    for (var row in actividadesQuery) {
      print('   - ${row[0]}');
    }
    
    // Obtener algunos ranchos
    final ranchosQuery = await db.connection.query('SELECT nombre FROM ranchos LIMIT 5;');
    print('🏠 Primeros 5 ranchos:');
    for (var row in ranchosQuery) {
      print('   - ${row[0]}');
    }
    
    // Verificar si hay datos de nómina con todas las relaciones
    final nominaConRelacionesQuery = await db.connection.query('''
      SELECT COUNT(*) as total,
             COUNT(DISTINCT neh.id_empleado) as empleados_distintos,
             COUNT(DISTINCT neh.id_cuadrilla) as cuadrillas_distintas,
             SUM(neh.total) as total_gastado
      FROM nomina_empleados_historial neh
      JOIN empleados e ON neh.id_empleado = e.id_empleado
      JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla;
    ''');
    
    if (nominaConRelacionesQuery.isNotEmpty) {
      final row = nominaConRelacionesQuery.first;
      print('💰 DATOS DE NÓMINA CON RELACIONES:');
      print('   - Registros totales: ${row[0]}');
      print('   - Empleados distintos: ${row[1]}');
      print('   - Cuadrillas distintas: ${row[2]}');
      print('   - Total gastado: \$${row[3]}');
    }
    
  } catch (e) {
    print('❌ Error al verificar datos específicos: $e');
  }
  
  await db.close();
  
  // 4. Probar el servicio de reportes
  print('\n🧪 PROBANDO SERVICIO DE REPORTES:');
  
  final reportesService = ReportesService();
  
  try {
    // Probar obtener ranchos
    final ranchos = await reportesService.obtenerRanchos();
    print('🏠 Ranchos obtenidos: ${ranchos.length} - $ranchos');
    
    // Probar obtener actividades
    final actividades = await reportesService.obtenerActividades();
    print('🏃‍♂️ Actividades obtenidas: ${actividades.length} - $actividades');
    
    // Probar reporte general
    final reporteGeneral = await reportesService.obtenerReporteGeneral();
    print('📊 Reporte general: ${reporteGeneral.length} registros');
    if (reporteGeneral.isNotEmpty) {
      print('   Primer registro: ${reporteGeneral.first}');
    }
    
  } catch (e) {
    print('❌ Error al probar servicio de reportes: $e');
  }
  
  print('\n🏁 DEBUG COMPLETADO');
}
