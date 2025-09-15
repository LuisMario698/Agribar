import 'package:postgres/postgres.dart';
import 'dart:io';

void main() async {
  print('🔍 VERIFICACIÓN: Mapeo Clave → ID de actividades');
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

    // 1. Mostrar el mapeo completo Clave → ID
    print('\n📋 1. Mapeo completo Clave → ID desde tabla actividades:');
    final actividades = await connection.query('''
      SELECT id_actividad, clave, nombre 
      FROM actividades 
      ORDER BY CAST(clave AS INTEGER)
      LIMIT 15
    ''');
    
    Map<String, int> claveAIdMap = {};
    print('   CLAVE    →  ID   | NOMBRE');
    print('   ' + '-' * 45);
    
    for (final actividad in actividades) {
      final id = actividad[0] as int;
      final clave = actividad[1]?.toString() ?? '';
      final nombre = actividad[2]?.toString() ?? '';
      
      if (clave.isNotEmpty) {
        claveAIdMap[clave] = id;
        print('   ${clave.padLeft(8)} → ${id.toString().padLeft(4)} | $nombre');
      }
    }

    // 2. Simular función _obtenerIdParaGuardar con claves comunes
    print('\n🧪 2. Probando conversión Clave → ID:');
    
    int obtenerIdParaGuardar(dynamic valor) {
      if (valor == null) return 0;
      String s = valor.toString().trim();
      if (s.isEmpty || s == '0') return 0;
      
      // Normalizar (quitar .0)
      if (s.endsWith('.0')) {
        s = s.substring(0, s.length - 2);
      }
      
      // Si coincide como clave conocida → devolver ID
      if (claveAIdMap.containsKey(s)) {
        return claveAIdMap[s]!;
      }
      
      // Si es número válido → aceptar como ID directo
      final posibleId = int.tryParse(s);
      if (posibleId != null && posibleId > 0) {
        return posibleId;
      }
      
      return 0;
    }
    
    final clavesComunes = ['1301', '1302', '1304', '1306', '1', '1101', '1301.0', '1304.0'];
    
    for (final clave in clavesComunes) {
      final id = obtenerIdParaGuardar(clave);
      String nombre = 'No encontrada';
      if (id > 0) {
        final actividadInfo = actividades.where((act) => act[0] == id);
        if (actividadInfo.isNotEmpty) {
          nombre = actividadInfo.first[2].toString();
        }
      }
      
      if (id > 0) {
        print('   ✅ Clave "$clave" → ID $id ($nombre)');
      } else {
        print('   ❌ Clave "$clave" → ID $id (Sin mapeo)');
      }
    }

    // 3. Verificar qué IDs están realmente guardados en BD
    print('\n📊 3. IDs de actividades guardados en nomina_empleados_semanal:');
    final idsGuardados = await connection.query('''
      SELECT DISTINCT actividad_id, COUNT(*) as veces
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
      ) actividades_usadas
      GROUP BY actividad_id
      ORDER BY actividad_id
    ''');
    
    print('   ID guardado → Info en tabla actividades');
    print('   ' + '-' * 50);
    
    for (final idGuardado in idsGuardados) {
      final id = idGuardado[0];
      final veces = idGuardado[1];
      
      // Buscar info en tabla actividades  
      final infoActividad = await connection.query('''
        SELECT clave, nombre FROM actividades WHERE id_actividad = @id
      ''', substitutionValues: {'id': id});
      
      if (infoActividad.isNotEmpty) {
        final clave = infoActividad.first[0];
        final nombre = infoActividad.first[1];
        print('   ID $id → Clave "$clave" | $nombre (usado ${veces}x)');
      } else {
        print('   ID $id → ⚠️ NO ENCONTRADO en tabla actividades (usado ${veces}x)');
      }
    }

    // 4. Verificar registros recientes y ver qué está pasando
    print('\n🔍 4. Análisis de registros recientes:');
    final registrosRecientes = await connection.query('''
      SELECT id_nomina, id_empleado, id_semana,
             act_1, act_2, act_3, act_4, act_5, act_6, act_7,
             actualizado_en
      FROM nomina_empleados_semanal 
      ORDER BY actualizado_en DESC NULLS LAST, id_nomina DESC
      LIMIT 5
    ''');
    
    print('   Últimos 5 registros:');
    for (final reg in registrosRecientes) {
      final idNomina = reg[0];
      final idEmpleado = reg[1];
      final idSemana = reg[2];
      final actividades = [reg[3], reg[4], reg[5], reg[6], reg[7], reg[8], reg[9]];
      final fecha = reg[10];
      
      print('   📋 ID: $idNomina, Empleado: $idEmpleado, Semana: $idSemana');
      print('       Actividades: $actividades');
      print('       Fecha: $fecha');
      
      // Contar actividades válidas
      final actividadesValidas = actividades.where((act) => act != null && act > 0).length;
      if (actividadesValidas == 0) {
        print('       ⚠️ SIN ACTIVIDADES - Este registro tiene el problema');
      } else {
        print('       ✅ $actividadesValidas actividades guardadas');
      }
      print('');
    }

    // 5. Simular el proceso completo: UI → Conversión → BD
    print('\n🎯 5. Simulación completa UI → Conversión → BD:');
    print('   Flujo: Usuario ve CLAVE → Sistema convierte a ID → BD guarda ID');
    print('');
    
    final simulacionDatos = {
      'dia_0_id': '1301',    // Usuario ve y captura clave "1301"
      'dia_1_id': '1304.0',  // Sistema a veces agrega .0
      'dia_2_id': '1302',    // Otra clave común
    };
    
    for (final entry in simulacionDatos.entries) {
      final campo = entry.key;
      final claveCapturada = entry.value;
      final idConvertido = obtenerIdParaGuardar(claveCapturada);
      
      // Buscar info de la actividad
      String infoActividad = 'Desconocida';
      if (idConvertido > 0) {
        final infoQuery = await connection.query('''
          SELECT clave, nombre FROM actividades WHERE id_actividad = @id
        ''', substitutionValues: {'id': idConvertido});
        
        if (infoQuery.isNotEmpty) {
          final clave = infoQuery.first[0];
          final nombre = infoQuery.first[1];
          infoActividad = 'Clave "$clave" - $nombre';
        }
      }
      
      print('   $campo: "$claveCapturada" → ID $idConvertido ($infoActividad)');
    }

    await connection.close();
    print('\n✅ Verificación completada');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}