import 'package:agribar/services/database_service.dart';
import 'package:agribar/services/reportes_service.dart';

/// Script para verificar datos y solucionar reportes
void main() async {
  print('🔍 VERIFICANDO DATOS Y SOLUCIONANDO REPORTES');
  print('=============================================');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // 1. VERIFICAR DATOS EN TODAS LAS TABLAS RELEVANTES
    print('\n📊 VERIFICANDO DATOS EN TABLAS:');
    
    final tablasYConteos = [
      'nomina_empleados_semanal',
      'nomina_empleados_historial', 
      'semanas_nomina',
      'actividades',
      'ranchos',
      'cuadrillas',
      'empleados'
    ];
    
    for (String tabla in tablasYConteos) {
      final count = await db.connection.query('SELECT COUNT(*) FROM $tabla;');
      print('   $tabla: ${count[0][0]} registros');
    }
    
    // 2. VERIFICAR CONTENIDO ESPECÍFICO DE TABLAS IMPORTANTES
    print('\n📋 CONTENIDO DE TABLAS CLAVE:');
    
    // Ranchos
    final ranchos = await db.connection.query('SELECT * FROM ranchos;');
    print('\n🏠 RANCHOS:');
    for (var rancho in ranchos) {
      print('   ID: ${rancho[0]}, Nombre: ${rancho[1]}');
    }
    
    // Actividades (primeras 10)
    final actividades = await db.connection.query('SELECT * FROM actividades LIMIT 10;');
    print('\n🏃‍♂️ ACTIVIDADES (primeras 10):');
    for (var act in actividades) {
      print('   ID: ${act[0]}, Clave: ${act[1]}, Nombre: ${act[2]}, Importe: ${act[3]}');
    }
    
    // Cuadrillas activas
    final cuadrillas = await db.connection.query('SELECT * FROM cuadrillas WHERE estado = true LIMIT 10;');
    print('\n👷‍♂️ CUADRILLAS ACTIVAS (primeras 10):');
    for (var cuad in cuadrillas) {
      print('   ID: ${cuad[0]}, Clave: ${cuad[1]}, Nombre: ${cuad[2]}, Grupo: ${cuad[3]}');
    }
    
    // Semanas de nómina
    final semanas = await db.connection.query('SELECT * FROM semanas_nomina;');
    print('\n📅 SEMANAS DE NÓMINA:');
    for (var sem in semanas) {
      print('   ID: ${sem[0]}, Inicio: ${sem[1]}, Fin: ${sem[2]}, Cerrada: ${sem[3]}');
    }
    
    // Nómina semanal (si hay datos)
    final nominaSemanal = await db.connection.query('SELECT COUNT(*) FROM nomina_empleados_semanal;');
    print('\n💰 NÓMINA SEMANAL: ${nominaSemanal[0][0]} registros');
    
    if ((nominaSemanal[0][0] as int) > 0) {
      final ejemploNomina = await db.connection.query('''
        SELECT id_nomina, id_empleado, id_semana, id_cuadrilla, 
               dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7, total,
               act_1, act_2, campo_1, campo_2
        FROM nomina_empleados_semanal LIMIT 3;
      ''');
      print('   EJEMPLOS DE REGISTROS:');
      for (var reg in ejemploNomina) {
        print('     Nómina ID: ${reg[0]}, Empleado: ${reg[1]}, Semana: ${reg[2]}, Cuadrilla: ${reg[3]}');
        print('     Días: ${reg[4]}, ${reg[5]}, ${reg[6]}, ${reg[7]}, ${reg[8]}, ${reg[9]}, ${reg[10]}');
        print('     Total: ${reg[11]}, Act1: ${reg[12]}, Act2: ${reg[13]}, Campo1: ${reg[14]}, Campo2: ${reg[15]}');
        print('     ────────────');
      }
    }
    
    // Nómina historial
    final nominaHistorial = await db.connection.query('''
      SELECT neh.*, c.nombre as cuadrilla_nombre
      FROM nomina_empleados_historial neh
      JOIN cuadrillas c ON neh.id_cuadrilla = c.id_cuadrilla
      LIMIT 5;
    ''');
    print('\n📊 NÓMINA HISTORIAL (primeros 5):');
    for (var reg in nominaHistorial) {
      print('   Empleado: ${reg[1]}, Cuadrilla: ${reg[32]}, Total: ${reg[10]}, Fecha: ${reg[15]}');
      print('   Días: ${reg[4]}, ${reg[5]}, ${reg[6]}, ${reg[7]}, ${reg[8]}, ${reg[9]}, ${reg[17]}');
      print('   ────────────');
    }
    
    await db.close();
    
    // 3. PROBAR SERVICIO DE REPORTES
    print('\n🧪 PROBANDO SERVICIO DE REPORTES:');
    
    final reportesService = ReportesService();
    
    // Ranchos
    final ranchosServicio = await reportesService.obtenerRanchos();
    print('✅ Ranchos del servicio: $ranchosServicio');
    
    // Actividades
    final actividadesServicio = await reportesService.obtenerActividades();
    print('✅ Actividades del servicio (primeras 5): ${actividadesServicio.take(5).toList()}');
    
    // Reporte general
    print('\n📊 PROBANDO REPORTE GENERAL...');
    final reporteGeneral = await reportesService.obtenerReporteGeneral();
    print('✅ Reporte general: ${reporteGeneral.length} registros');
    
    if (reporteGeneral.isNotEmpty) {
      for (var registro in reporteGeneral) {
        print('   - Rancho: ${registro['rancho']}');
        print('     Actividad: ${registro['actividad']}');
        print('     Empleados: ${registro['empleados_involucrados']}');
        print('     Gasto Total: \$${registro['gasto_total']}');
        print('     ────────────────────');
      }
    } else {
      print('   ⚠️ No se obtuvieron datos en el reporte general');
    }
    
    // Resumen
    final resumen = await reportesService.obtenerResumenGeneral();
    print('\n📈 RESUMEN GENERAL:');
    print('   - Total empleados: ${resumen['total_empleados']}');
    print('   - Ranchos activos: ${resumen['ranchos_activos']}');
    print('   - Días trabajados: ${resumen['dias_trabajados']}');
    print('   - Monto total: \$${resumen['monto_total']}');
    
  } catch (e) {
    print('❌ ERROR: $e');
    print('Stack trace: ${StackTrace.current}');
  }
  
  print('\n🏁 VERIFICACIÓN COMPLETADA');
}
