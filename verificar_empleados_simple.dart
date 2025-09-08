import 'package:postgres/postgres.dart';

Future<void> main() async {
  print('🔍 Verificando empleados en cuadrillas...');
  
  PostgreSQLConnection connection = PostgreSQLConnection(
    'localhost',
    5432,
    'AGRIBAR',
    username: 'postgres',
    password: 'admin',
  );
  
  try {
    await connection.open();
    print('✅ Conectado a la base de datos');
    
    // 1. Verificar semana activa
    print('\n📅 1. Verificando semana activa:');
    final semanaActiva = await connection.query('''
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
    
    // 2. Verificar empleados en cuadrillas
    print('\n👥 2. Empleados en cuadrillas para semana $semanaId:');
    final empleadosEnCuadrillas = await connection.query('''
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
    
    // 3. Verificar actividades con IDs en nómina
    print('\n⚒️ 3. IDs de actividades usadas en nómina:');
    final actividadesUsadas = await connection.query('''
      SELECT DISTINCT
        UNNEST(ARRAY[act_1, act_2, act_3, act_4, act_5, act_6, act_7]) as actividad_id
      FROM nomina_empleados_semanal 
      WHERE id_semana = @semanaId
        AND UNNEST(ARRAY[act_1, act_2, act_3, act_4, act_5, act_6, act_7]) > 0
      ORDER BY actividad_id
    ''', substitutionValues: {'semanaId': semanaId});
    
    print('  🎯 IDs de actividades encontradas: ${actividadesUsadas.length}');
    for (final actId in actividadesUsadas) {
      final idActividad = actId[0];
      
      // Buscar la actividad correspondiente
      final actividadInfo = await connection.query('''
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
    
    // 4. Verificar problema específico: actividades guardadas por clave vs ID
    print('\n🔍 4. Verificando mapeo clave-ID de actividades:');
    final todasActividades = await connection.query('''
      SELECT id_actividad, clave, nombre
      FROM actividades 
      ORDER BY clave
    ''');
    
    print('  📝 Actividades disponibles: ${todasActividades.length}');
    for (final act in todasActividades) {
      print('    - ID: ${act[0]}, Clave: ${act[1]}, Nombre: ${act[2]}');
    }
    
    // 5. Verificar si hay empleados guardados pero no están apareciendo
    print('\n🔍 5. Verificando registros detallados en nomina_empleados_semanal:');
    final registrosDetallados = await connection.query('''
      SELECT 
        nes.id_empleado,
        e.nombre,
        nes.id_cuadrilla,
        c.nombre as cuadrilla,
        nes.act_1, nes.act_2, nes.act_3
      FROM nomina_empleados_semanal nes
      LEFT JOIN empleados e ON nes.id_empleado = e.id_empleado
      LEFT JOIN cuadrillas c ON nes.id_cuadrilla = c.id_cuadrilla
      WHERE nes.id_semana = @semanaId
      ORDER BY nes.id_cuadrilla, nes.id_empleado
      LIMIT 10
    ''', substitutionValues: {'semanaId': semanaId});
    
    print('  📊 Primeros 10 registros:');
    for (final reg in registrosDetallados) {
      print('    👤 ${reg[1] ?? 'Sin nombre'} (ID: ${reg[0]}) - Cuadrilla: ${reg[3] ?? 'Sin cuadrilla'} (ID: ${reg[2]})');
      print('      Actividades: [${reg[4] ?? 0}, ${reg[5] ?? 0}, ${reg[6] ?? 0}]');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await connection.close();
  }
}
