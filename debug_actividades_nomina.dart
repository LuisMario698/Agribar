import 'package:postgres/postgres.dart';
import 'dart:io';

void main() async {
  print('🔍 ANÁLISIS: Problema de guardado de actividades en nómina');
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

    // 1. Verificar actividades disponibles en la tabla
    print('\n📝 1. Actividades disponibles en BD:');
    final actividades = await connection.query('''
      SELECT id_actividad, clave, nombre, importe
      FROM actividades 
      ORDER BY clave 
      LIMIT 10
    ''');
    
    print('   Total actividades: ${actividades.length}');
    for (final act in actividades) {
      print('   - ID: ${act[0]}, Clave: ${act[1]}, Nombre: ${act[2]}, Importe: ${act[3]}');
    }

    // 2. Verificar si hay datos de nómina semanal recientes
    print('\n📊 2. Datos recientes en nomina_empleados_semanal:');
    final nominaReciente = await connection.query('''
      SELECT id_nomina, id_empleado, id_semana, id_cuadrilla,
             act_1, act_2, act_3, act_4, act_5, act_6, act_7,
             dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7,
             fecha_actualizacion
      FROM nomina_empleados_semanal 
      ORDER BY fecha_actualizacion DESC 
      LIMIT 5
    ''');
    
    print('   Registros recientes: ${nominaReciente.length}');
    for (final reg in nominaReciente) {
      print('   - ID: ${reg[0]}, Empleado: ${reg[1]}, Semana: ${reg[2]}, Cuadrilla: ${reg[3]}');
      print('     Actividades: ${reg[4]}, ${reg[5]}, ${reg[6]}, ${reg[7]}, ${reg[8]}, ${reg[9]}, ${reg[10]}');
      print('     Días: ${reg[11]}, ${reg[12]}, ${reg[13]}, ${reg[14]}, ${reg[15]}, ${reg[16]}, ${reg[17]}');
      print('     Fecha: ${reg[18]}');
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
      print('   ❌ NO se encontraron actividades guardadas en nomina_empleados_semanal');
      print('   🔍 Esto indica que las actividades NO se están guardando correctamente');
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

    // 4. Verificar registros problemáticos (solo sueldos sin actividades)
    print('\n🚨 4. Registros con sueldos pero sin actividades:');
    final problemasRegistros = await connection.query('''
      SELECT id_nomina, id_empleado, id_semana,
             COALESCE(dia_1,0) + COALESCE(dia_2,0) + COALESCE(dia_3,0) + 
             COALESCE(dia_4,0) + COALESCE(dia_5,0) + COALESCE(dia_6,0) + COALESCE(dia_7,0) as total_sueldos,
             COALESCE(act_1,0) + COALESCE(act_2,0) + COALESCE(act_3,0) + 
             COALESCE(act_4,0) + COALESCE(act_5,0) + COALESCE(act_6,0) + COALESCE(act_7,0) as total_actividades
      FROM nomina_empleados_semanal 
      WHERE (COALESCE(dia_1,0) + COALESCE(dia_2,0) + COALESCE(dia_3,0) + 
             COALESCE(dia_4,0) + COALESCE(dia_5,0) + COALESCE(dia_6,0) + COALESCE(dia_7,0)) > 0
        AND (COALESCE(act_1,0) + COALESCE(act_2,0) + COALESCE(act_3,0) + 
             COALESCE(act_4,0) + COALESCE(act_5,0) + COALESCE(act_6,0) + COALESCE(act_7,0)) = 0
      ORDER BY id_nomina DESC
      LIMIT 10
    ''');
    
    if (problemasRegistros.isEmpty) {
      print('   ✅ No se encontraron registros con sueldos sin actividades');
    } else {
      print('   ⚠️ Registros con sueldos pero SIN actividades: ${problemasRegistros.length}');
      for (final reg in problemasRegistros) {
        print('     - ID: ${reg[0]}, Empleado: ${reg[1]}, Semana: ${reg[2]}');
        print('       Total sueldos: ${reg[3]}, Total actividades: ${reg[4]}');
      }
      
      print('\n🎯 DIAGNÓSTICO: Las actividades NO se están guardando correctamente');
      print('   - Los sueldos sí se guardan (hay registros con dia_X > 0)');
      print('   - Las actividades NO se guardan (act_X = 0 siempre)');
      print('   - Problema probable en _obtenerIdParaGuardar() o en el mapeo clave→ID');
    }

    // 5. Simular el mapeo de actividades como en el código
    print('\n🔧 5. Simulando mapeo de actividades (como en _cargarMappingActividades):');
    final actividadesMapping = await connection.query('''
      SELECT id_actividad, clave, nombre 
      FROM actividades 
      ORDER BY clave
      LIMIT 5
    ''');
    
    Map<String, int> claveAIdMap = {};
    for (final act in actividadesMapping) {
      final id = act[0] as int;
      final clave = act[1]?.toString() ?? '';
      if (clave.isNotEmpty) {
        claveAIdMap[clave] = id;
      }
    }
    
    print('   Mapeo clave → ID cargado:');
    claveAIdMap.forEach((clave, id) {
      print('     "$clave" → $id');
    });
    
    // Simular _obtenerIdParaGuardar
    print('\n🧪 6. Simulando _obtenerIdParaGuardar:');
    final testValues = ['1301', '1302', '1303', '1304', '', '0', null];
    for (final valor in testValues) {
      int result = 0;
      if (valor != null) {
        final s = valor.toString().trim();
        if (s.isNotEmpty && s != '0') {
          if (claveAIdMap.containsKey(s)) {
            result = claveAIdMap[s]!;
          } else {
            final posibleId = int.tryParse(s);
            if (posibleId != null && posibleId > 0) {
              result = posibleId;
            }
          }
        }
      }
      print('     Valor: "$valor" → ID: $result');
    }

    await connection.close();
    print('\n✅ Análisis completado');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}