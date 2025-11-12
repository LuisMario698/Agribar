import 'package:postgres/postgres.dart';
import 'dart:io';

void main() async {
  print('🧪 PRUEBA: Simular proceso completo de guardado con debug');
  print('=' * 60);

  try {
    // 1. Simular carga de mapas como en _cargarMappingActividades
    print('\n🔄 1. Simulando _cargarMappingActividades...');
    final connection = PostgreSQLConnection(
      'localhost',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: 'admin',
    );

    await connection.open();
    
    final actividades = await connection.query(
      'SELECT id_actividad, clave, nombre FROM actividades ORDER BY clave'
    );
    
    print('📦 DEBUG: Encontradas ${actividades.length} actividades en BD');
    
    Map<String, int> claveAIdMap = {};
    Map<int, String> idAClaveMap = {};
    Map<String, String> claveANombreMap = {};
    
    for (final actividad in actividades) {
      final id = actividad[0] as int;
      final clave = actividad[1]?.toString() ?? '';
      final nombre = actividad[2]?.toString() ?? '';
      
      if (clave.isNotEmpty) {
        claveAIdMap[clave] = id;
        idAClaveMap[id] = clave;
        claveANombreMap[clave] = nombre;
      }
    }
    
    print('✅ DEBUG: Mapeo cargado - ${claveAIdMap.length} claves disponibles');
    
    // Verificar claves específicas
    final clavesImportantes = ['1301', '1302', '1304', '1306'];
    for (final clave in clavesImportantes) {
      if (claveAIdMap.containsKey(clave)) {
        print('   ✅ Clave "$clave" → ID ${claveAIdMap[clave]} (${claveANombreMap[clave]})');
      } else {
        print('   ❌ Clave "$clave" NO ENCONTRADA');
      }
    }

    // 2. Simular función _obtenerIdParaGuardar con debug
    print('\n🔍 2. Simulando _obtenerIdParaGuardar con diferentes valores:');
    
    int obtenerIdParaGuardarConDebug(dynamic valor) {
      if (valor == null) return 0;
      String s = valor.toString().trim();
      if (s.isEmpty || s == '0') return 0;
      
      // Normalizar
      if (s.endsWith('.0')) {
        s = s.substring(0, s.length - 2);
      }
      
      print('   🔍 Procesando valor="$s", mapSize=${claveAIdMap.length}');
      
      // Si coincide como clave conocida -> devolver ID
      if (claveAIdMap.containsKey(s)) {
        final id = claveAIdMap[s]!;
        print('     ✅ Clave "$s" encontrada → ID $id (${claveANombreMap[s]})');
        return id;
      } else {
        print('     ❌ Clave "$s" NO encontrada en mapeo');
      }
      
      // Si es número válido -> aceptar como ID directo
      final posibleId = int.tryParse(s);
      if (posibleId != null && posibleId > 0) {
        print('     ⚠️ Usando "$s" como ID directo → $posibleId (PUEDE SER INCORRECTO)');
        return posibleId;
      }
      
      print('     ❌ No se pudo convertir "$s" → devolviendo 0');
      return 0;
    }

    // Probar con valores típicos de la UI
    final valoresPrueba = [
      '1301',      // Clave válida
      '1301.0',    // Clave válida con .0  
      '1304',      // Otra clave válida
      '1304.0',    // Otra clave válida con .0
      '9999',      // Clave inexistente (debería devolver ID directo)
      '',          // Vacío
      null,        // Null
    ];
    
    for (final valor in valoresPrueba) {
      print('\n   🧪 Probando: "$valor"');
      final resultado = obtenerIdParaGuardarConDebug(valor);
      print('     📤 RESULTADO FINAL: $resultado');
    }

    // 3. Simular guardado completo
    print('\n💾 3. Simulando datos como los recibe guardarNomina():');
    
    // Datos simulados como llegan desde la tabla editable
    final empleadoSimulado = {
      'id': 9999,
      'dia_0_id': '1301',    // Lunes - debe convertirse a ID 2
      'dia_0_s': 500.0,
      'dia_0_campo': '1',
      'dia_1_id': '1304.0',  // Martes - debe convertirse a ID 15  
      'dia_1_s': 600.0,
      'dia_1_campo': '2',
      'dia_2_id': '',        // Miércoles - vacío
      'dia_2_s': 0.0,
      'dia_2_campo': '0',
      // ... otros días vacíos
    };
    
    // Simular el mapeo que hace guardarNomina()
    final dataBD = {
      'id_empleado': empleadoSimulado['id'],
      'id_semana': 999,
      'id_cuadrilla': 1,
      'act_1': obtenerIdParaGuardarConDebug(empleadoSimulado['dia_0_id']),  // 1301 → 2
      'dia_1': empleadoSimulado['dia_0_s'],
      'campo_1': int.tryParse(empleadoSimulado['dia_0_campo'].toString()) ?? 0,
      'act_2': obtenerIdParaGuardarConDebug(empleadoSimulado['dia_1_id']),  // 1304.0 → 15
      'dia_2': empleadoSimulado['dia_1_s'],
      'campo_2': int.tryParse(empleadoSimulado['dia_1_campo'].toString()) ?? 0,
      'act_3': obtenerIdParaGuardarConDebug(empleadoSimulado['dia_2_id']),  // '' → 0
      // ... otros campos
    };
    
    print('\n   📋 Datos mapeados para BD:');
    print('     UI: dia_0_id="${empleadoSimulado['dia_0_id']}" → BD: act_1=${dataBD['act_1']}');
    print('     UI: dia_1_id="${empleadoSimulado['dia_1_id']}" → BD: act_2=${dataBD['act_2']}');
    print('     UI: dia_2_id="${empleadoSimulado['dia_2_id']}" → BD: act_3=${dataBD['act_3']}');
    
    // Verificar si los IDs son correctos
    print('\n   🎯 Verificación de conversión:');
    if (dataBD['act_1'] == 2) {
      print('     ✅ act_1 correcto: "1301" → ID 2 (JEFE DE LINEA)');
    } else {
      print('     ❌ act_1 incorrecto: esperado ID 2, obtenido ${dataBD['act_1']}');
    }
    
    if (dataBD['act_2'] == 15) {
      print('     ✅ act_2 correcto: "1304.0" → ID 15 (EMPACADOR)');
    } else {
      print('     ❌ act_2 incorrecto: esperado ID 15, obtenido ${dataBD['act_2']}');
    }
    
    if (dataBD['act_3'] == 0) {
      print('     ✅ act_3 correcto: "" → ID 0 (sin actividad)');
    } else {
      print('     ❌ act_3 incorrecto: esperado ID 0, obtenido ${dataBD['act_3']}');
    }

    await connection.close();
    print('\n✅ Simulación completada');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}