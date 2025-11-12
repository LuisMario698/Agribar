import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔍 Diagnosticando el guardado de empleados en cuadrillas...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // 1. Verificar la semana activa
    print('\n📅 1. Verificando semana activa:');
    final semanaActiva = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada
      FROM semanas_nomina 
      WHERE esta_cerrada = false
      ORDER BY id_semana DESC
      LIMIT 1
    ''');
    
    if (semanaActiva.isEmpty) {
      print('❌ No hay semana activa (abierta)');
      return;
    }
    
    final semanaId = semanaActiva.first[0] as int;
    print('✅ Semana activa: $semanaId (${semanaActiva.first[1]} a ${semanaActiva.first[2]})');
    
    // 2. Verificar cuadrillas disponibles
    print('\n🧑‍🤝‍🧑 2. Verificando cuadrillas:');
    final cuadrillas = await db.connection.query('''
      SELECT id_cuadrilla, nombre 
      FROM cuadrillas 
      ORDER BY id_cuadrilla
    ''');
    
    print('✅ Cuadrillas disponibles: ${cuadrillas.length}');
    for (final cuadrilla in cuadrillas) {
      print('  - ID: ${cuadrilla[0]}, Nombre: ${cuadrilla[1]}');
    }
    
    // 3. Verificar empleados en cuadrillas para la semana activa
    print('\n👥 3. Verificando empleados asignados a cuadrillas en semana $semanaId:');
    final empleadosEnCuadrillas = await db.connection.query('''
      SELECT 
        c.id_cuadrilla,
        c.nombre as cuadrilla_nombre,
        COUNT(nes.id_empleado) as total_empleados,
        STRING_AGG(e.nombre || ' (' || nes.id_empleado || ')', ', ') as empleados
      FROM cuadrillas c
      LEFT JOIN nomina_empleados_semanal nes ON c.id_cuadrilla = nes.id_cuadrilla AND nes.id_semana = @semanaId
      LEFT JOIN empleados e ON nes.id_empleado = e.id_empleado
      GROUP BY c.id_cuadrilla, c.nombre
      ORDER BY c.id_cuadrilla
    ''', substitutionValues: {'semanaId': semanaId});
    
    for (final row in empleadosEnCuadrillas) {
      final cuadrillaId = row[0];
      final cuadrillaNombre = row[1];
      final totalEmpleados = row[2];
      final empleados = row[3] ?? 'Ninguno';
      
      print('  📋 Cuadrilla $cuadrillaId ($cuadrillaNombre): $totalEmpleados empleados');
      if (totalEmpleados > 0) {
        print('    👥 Empleados: $empleados');
      }
    }
    
    // 4. Verificar actividades asignadas en la semana activa
    print('\n⚒️ 4. Verificando actividades en nómina para semana $semanaId:');
    final actividadesEnNomina = await db.connection.query('''
      SELECT 
        COUNT(*) as total_registros,
        COUNT(CASE WHEN act_1 > 0 THEN 1 END) as con_act_1,
        COUNT(CASE WHEN act_2 > 0 THEN 1 END) as con_act_2,
        COUNT(CASE WHEN act_3 > 0 THEN 1 END) as con_act_3,
        COUNT(CASE WHEN act_4 > 0 THEN 1 END) as con_act_4,
        COUNT(CASE WHEN act_5 > 0 THEN 1 END) as con_act_5,
        COUNT(CASE WHEN act_6 > 0 THEN 1 END) as con_act_6,
        COUNT(CASE WHEN act_7 > 0 THEN 1 END) as con_act_7
      FROM nomina_empleados_semanal 
      WHERE id_semana = @semanaId
    ''', substitutionValues: {'semanaId': semanaId});
    
    if (actividadesEnNomina.isNotEmpty) {
      final row = actividadesEnNomina.first;
      print('  📊 Total registros nómina: ${row[0]}');
      print('  📅 Con actividades por día:');
      for (int i = 1; i <= 7; i++) {
        print('    - Día $i (act_$i): ${row[i]} registros');
      }
    }
    
    // 5. Verificar estructura de la tabla nomina_empleados_semanal
    print('\n🏗️ 5. Estructura de tabla nomina_empleados_semanal:');
    final estructura = await db.connection.query('''
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_semanal'
      ORDER BY ordinal_position
    ''');
    
    for (final col in estructura) {
      print('  - ${col[0]}: ${col[1]}');
    }
    
    // 6. Verificar últimos registros insertados
    print('\n🔄 6. Últimos 5 registros en nomina_empleados_semanal:');
    final ultimosRegistros = await db.connection.query('''
      SELECT 
        nes.id_empleado,
        e.nombre,
        nes.id_cuadrilla,
        c.nombre as cuadrilla,
        nes.act_1, nes.act_2, nes.act_3,
        nes.dia_1, nes.dia_2, nes.dia_3
      FROM nomina_empleados_semanal nes
      LEFT JOIN empleados e ON nes.id_empleado = e.id_empleado
      LEFT JOIN cuadrillas c ON nes.id_cuadrilla = c.id_cuadrilla
      WHERE nes.id_semana = @semanaId
      ORDER BY nes.id_nomina DESC
      LIMIT 5
    ''', substitutionValues: {'semanaId': semanaId});
    
    for (final reg in ultimosRegistros) {
      print('  👤 ${reg[1]} (ID: ${reg[0]}) - Cuadrilla: ${reg[3]} (ID: ${reg[2]})');
      print('    Actividades: [${reg[4]}, ${reg[5]}, ${reg[6]}]');
      print('    Salarios: [${reg[7]}, ${reg[8]}, ${reg[9]}]');
    }
    
    // 7. Verificar mapeo de actividades por clave
    print('\n🔍 7. Verificando actividades disponibles:');
    final actividades = await db.connection.query('''
      SELECT id_actividad, clave, nombre, importe
      FROM actividades 
      ORDER BY clave
    ''');
    
    print('  📝 Actividades disponibles: ${actividades.length}');
    for (final act in actividades) {
      print('    - ID: ${act[0]}, Clave: ${act[1]}, Nombre: ${act[2]}, Importe: ${act[3]}');
    }
    
    // 8. Verificar si las actividades se están guardando por ID o por clave
    print('\n🎯 8. Verificando cómo se guardan las actividades:');
    final actividadesUsadas = await db.connection.query('''
      SELECT DISTINCT
        UNNEST(ARRAY[act_1, act_2, act_3, act_4, act_5, act_6, act_7]) as actividad_id
      FROM nomina_empleados_semanal 
      WHERE id_semana = @semanaId
        AND UNNEST(ARRAY[act_1, act_2, act_3, act_4, act_5, act_6, act_7]) > 0
      ORDER BY actividad_id
    ''', substitutionValues: {'semanaId': semanaId});
    
    print('  🎯 IDs de actividades usadas en nómina:');
    for (final actId in actividadesUsadas) {
      final idActividad = actId[0];
      
      // Buscar la actividad correspondiente
      final actividadInfo = await db.connection.query('''
        SELECT clave, nombre 
        FROM actividades 
        WHERE id_actividad = @actId
      ''', substitutionValues: {'actId': idActividad});
      
      if (actividadInfo.isNotEmpty) {
        print('    - ID: $idActividad -> Clave: ${actividadInfo.first[0]}, Nombre: ${actividadInfo.first[1]}');
      } else {
        print('    - ID: $idActividad -> ❌ NO ENCONTRADA EN TABLA ACTIVIDADES');
      }
    }
    
  } catch (e) {
    print('❌ Error durante el diagnóstico: $e');
  } finally {
    await db.close();
  }
}
