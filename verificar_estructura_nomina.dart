import 'package:postgres/postgres.dart';
import 'dart:io';

void main() async {
  print('🔍 VERIFICACIÓN: Estructura tabla nomina_empleados_semanal');
  print('=' * 60);

  try {
    // Conectar a PostgreSQL
    final connection = PostgreSQLConnection(
      'localhost',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: 'admin',
    );

    await connection.open();
    print('✅ Conexión establecida con PostgreSQL');

    // 1. Verificar estructura de la tabla
    print('\n📋 1. Estructura de nomina_empleados_semanal:');
    final estructura = await connection.query('''
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_semanal'
      ORDER BY ordinal_position
    ''');
    
    print('   Columnas de la tabla:');
    for (final col in estructura) {
      print('   - ${col[0]} (${col[1]}) ${col[2] == 'YES' ? 'NULL' : 'NOT NULL'}');
    }

    // 2. Verificar datos recientes (sin usar fecha_actualizacion)
    print('\n📊 2. Datos recientes en nomina_empleados_semanal:');
    final nominaReciente = await connection.query('''
      SELECT id_nomina, id_empleado, id_semana, id_cuadrilla,
             act_1, act_2, act_3, act_4, act_5, act_6, act_7,
             dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7
      FROM nomina_empleados_semanal 
      ORDER BY id_nomina DESC 
      LIMIT 5
    ''');
    
    print('   Registros recientes: ${nominaReciente.length}');
    for (final reg in nominaReciente) {
      print('   - ID: ${reg[0]}, Empleado: ${reg[1]}, Semana: ${reg[2]}, Cuadrilla: ${reg[3]}');
      print('     Actividades: [${reg[4]}, ${reg[5]}, ${reg[6]}, ${reg[7]}, ${reg[8]}, ${reg[9]}, ${reg[10]}]');
      print('     Días: [${reg[11]}, ${reg[12]}, ${reg[13]}, ${reg[14]}, ${reg[15]}, ${reg[16]}, ${reg[17]}]');
      print('');
    }

    // 3. Verificar actividades que están siendo guardadas
    print('\n🎯 3. Análisis de actividades guardadas:');
    final actividadesUsadas = await connection.query('''
      SELECT DISTINCT actividad_id, COUNT(*) as veces_usado
      FROM (
        SELECT act_1 as actividad_id FROM nomina_empleados_semanal WHERE act_1 > 0
        UNION ALL
        SELECT act_2 as actividad_id FROM nomina_empleados_semanal WHERE act_2 > 0
        UNION ALL
        SELECT act_3 as actividad_id FROM nomina_empleados_semanal WHERE act_3 > 0
        UNION ALL
        SELECT act_4 as actividad_id FROM nomina_empleados_semanal WHERE act_4 > 0
        UNION ALL
        SELECT act_5 as actividad_id FROM nomina_empleados_semanal WHERE act_5 > 0
        UNION ALL
        SELECT act_6 as actividad_id FROM nomina_empleados_semanal WHERE act_6 > 0
        UNION ALL
        SELECT act_7 as actividad_id FROM nomina_empleados_semanal WHERE act_7 > 0
      ) actividades_query
      GROUP BY actividad_id
      ORDER BY actividad_id
    ''');
    
    if (actividadesUsadas.isEmpty) {
      print('   ❌ NO se encontraron actividades guardadas (todos los act_X son 0 o NULL)');
      print('   🔍 Esto confirma que las actividades NO se están guardando');
    } else {
      print('   ✅ Actividades encontradas en nomina_empleados_semanal:');
      for (final act in actividadesUsadas) {
        final actId = act[0];
        final vecesUsado = act[1];
        
        // Buscar info de la actividad
        final infoActividad = await connection.query('''
          SELECT clave, nombre FROM actividades WHERE id_actividad = @id
        ''', substitutionValues: {'id': actId});
        
        if (infoActividad.isNotEmpty) {
          final clave = infoActividad.first[0];
          final nombre = infoActividad.first[1];
          print('     - ID: $actId, Clave: $clave, Nombre: $nombre (usado $vecesUsado veces)');
        } else {
          print('     - ID: $actId (⚠️ no encontrada en tabla actividades, usado $vecesUsado veces)');
        }
      }
    }

    // 4. Verificar registros con sueldos
    print('\n💰 4. Registros con sueldos (para confirmar que otros datos sí se guardan):');
    final registrosConSueldos = await connection.query('''
      SELECT id_nomina, id_empleado, id_semana,
             COALESCE(dia_1,0) + COALESCE(dia_2,0) + COALESCE(dia_3,0) + 
             COALESCE(dia_4,0) + COALESCE(dia_5,0) + COALESCE(dia_6,0) + COALESCE(dia_7,0) as total_sueldos
      FROM nomina_empleados_semanal 
      WHERE (COALESCE(dia_1,0) + COALESCE(dia_2,0) + COALESCE(dia_3,0) + 
             COALESCE(dia_4,0) + COALESCE(dia_5,0) + COALESCE(dia_6,0) + COALESCE(dia_7,0)) > 0
      ORDER BY id_nomina DESC
      LIMIT 5
    ''');
    
    if (registrosConSueldos.isEmpty) {
      print('   ❌ NO se encontraron registros con sueldos');
      print('   🔍 Esto indicaría que NINGÚN dato se está guardando');
    } else {
      print('   ✅ Registros con sueldos encontrados: ${registrosConSueldos.length}');
      for (final reg in registrosConSueldos) {
        print('     - ID: ${reg[0]}, Empleado: ${reg[1]}, Semana: ${reg[2]}, Total: ${reg[3]}');
      }
    }

    await connection.close();
    print('\n✅ Verificación completada');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}