import 'package:postgres/postgres.dart';
import 'dart:io';

void main() async {
  print('🔍 DEBUG: Simulando proceso completo de guardado de actividades');
  print('=' * 70);

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

    // 1. Simular carga de mapas de actividades (como _cargarMappingActividades)
    print('\n🔄 1. Cargando mapas de actividades...');
    final actividades = await connection.query(
      'SELECT id_actividad, clave, nombre FROM actividades ORDER BY clave'
    );
    
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
    
    print('   Mapa clave → ID cargado: ${claveAIdMap.length} entradas');
    print('   Primeras 5 entradas:');
    int contador = 0;
    claveAIdMap.forEach((clave, id) {
      if (contador < 5) {
        print('     "$clave" → $id (${claveANombreMap[clave]})');
        contador++;
      }
    });

    // 2. Simular función _obtenerIdParaGuardar
    print('\n🧪 2. Simulando _obtenerIdParaGuardar con valores típicos:');
    final testValues = [
      '1301',      // Clave válida
      '1302',      // Otra clave válida  
      '1',         // Clave válida
      '1304',      // Clave válida
      '9999',      // Clave inexistente
      '',          // String vacío
      '0',         // String "0"
      null,        // Null
      1301,        // Número (como viene de la UI a veces)
      '1301.0',    // String con decimal (problema común)
    ];
    
    // Función simulada _obtenerIdParaGuardar
    int obtenerIdParaGuardar(dynamic valor) {
      if (valor == null) return 0;
      final s = valor.toString().trim();
      if (s.isEmpty || s == '0') return 0;
      
      // 1) Si coincide como clave conocida -> devolver ID
      if (claveAIdMap.containsKey(s)) {
        return claveAIdMap[s]!;
      }
      
      // 2) Si s es número y además es un ID que conocemos -> aceptar
      final posibleId = int.tryParse(s);
      if (posibleId != null && posibleId > 0) {
        return posibleId;
      }
      
      return 0;
    }
    
    for (final valor in testValues) {
      final resultado = obtenerIdParaGuardar(valor);
      final descripcion = resultado > 0 
          ? (idAClaveMap[resultado] != null 
             ? '✅ → ${idAClaveMap[resultado]} (${claveANombreMap[idAClaveMap[resultado]]})'
             : '⚠️ → ID directo')
          : '❌ → Sin actividad';
      print('     "$valor" → ID: $resultado $descripcion');
    }

    // 3. Verificar si hay problema con la normalización de valores
    print('\n🔧 3. Probando normalización de valores (problema del .0):');
    final problematicValues = ['1301.0', '1302.0', '1304.0'];
    for (final valor in problematicValues) {
      // Sin normalización
      final sinNormalizar = obtenerIdParaGuardar(valor);
      
      // Con normalización (quitar .0)
      final valorNormalizado = valor.replaceAll('.0', '');
      final conNormalizar = obtenerIdParaGuardar(valorNormalizado);
      
      print('     "$valor" sin normalizar → $sinNormalizar');
      print('     "$valor" normalizado a "$valorNormalizado" → $conNormalizar');
      
      if (sinNormalizar != conNormalizar) {
        print('     ⚠️ DIFERENCIA DETECTADA - La normalización es necesaria');
      }
    }

    // 4. Verificar cómo llegan los datos desde la tabla editable
    print('\n📊 4. Simulando datos como llegan desde la tabla editable:');
    
    // Datos simulados como llegan desde empleado['dia_X_id']
    final datosSimulados = {
      'dia_0_id': '1301',    // Lunes
      'dia_1_id': '',        // Martes (vacío)
      'dia_2_id': '1304.0',  // Miércoles (con .0)
      'dia_3_id': null,      // Jueves (null)
      'dia_4_id': '0',       // Viernes (string "0")
      'dia_5_id': '1302',    // Sábado
      'dia_6_id': '1',       // Domingo
    };
    
    print('   Procesando datos simulados de empleado:');
    for (int day = 0; day < 7; day++) {
      final key = 'dia_${day}_id';
      final valor = datosSimulados[key];
      final id = obtenerIdParaGuardar(valor);
      final nombreDia = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'][day];
      
      String estado;
      if (id > 0) {
        final clave = idAClaveMap[id];
        final nombre = clave != null ? claveANombreMap[clave] : 'Desconocida';
        estado = '✅ ID: $id (${nombre})';
      } else {
        estado = '❌ Sin actividad';
      }
      
      print('     $nombreDia ($key): "$valor" → $estado');
    }

    // 5. Crear registro de prueba para verificar si el INSERT funciona
    print('\n💾 5. Probando INSERT con datos simulados:');
    
    final datosInsert = {
      'id_empleado': 9999,  // ID de prueba
      'id_semana': 999,     // Semana de prueba
      'id_cuadrilla': 1,    // Cuadrilla de prueba
      'act_1': obtenerIdParaGuardar('1301'),
      'dia_1': 500.0,
      'campo_1': 'Rancho1',
      'act_2': obtenerIdParaGuardar('1304'),
      'dia_2': 600.0,
      'campo_2': 'Rancho2',
      'act_3': 0, 'dia_3': 0.0, 'campo_3': '0',
      'act_4': 0, 'dia_4': 0.0, 'campo_4': '0',
      'act_5': 0, 'dia_5': 0.0, 'campo_5': '0',
      'act_6': 0, 'dia_6': 0.0, 'campo_6': '0',
      'act_7': 0, 'dia_7': 0.0, 'campo_7': '0',
      'total': 1100.0,
      'debe': 0.0,
      'subtotal': 1100.0,
      'comedor': 0.0,
      'total_neto': 1100.0,
    };
    
    print('   Datos a insertar:');
    print('     act_1: ${datosInsert['act_1']}, dia_1: ${datosInsert['dia_1']}');
    print('     act_2: ${datosInsert['act_2']}, dia_2: ${datosInsert['dia_2']}');
    
    try {
      // Eliminar registro de prueba previo si existe
      await connection.execute('''
        DELETE FROM nomina_empleados_semanal 
        WHERE id_empleado = 9999 AND id_semana = 999
      ''');
      
      // Insertar registro de prueba
      await connection.execute('''
        INSERT INTO nomina_empleados_semanal (
          id_empleado, id_semana, id_cuadrilla,
          act_1, dia_1, campo_1,
          act_2, dia_2, campo_2,
          act_3, dia_3, campo_3,
          act_4, dia_4, campo_4,
          act_5, dia_5, campo_5,
          act_6, dia_6, campo_6,
          act_7, dia_7, campo_7,
          total, debe, subtotal, comedor, total_neto
        ) VALUES (
          @idEmpleado, @idSemana, @idCuadrilla,
          @act1, @dia1, @campo1,
          @act2, @dia2, @campo2,
          @act3, @dia3, @campo3,
          @act4, @dia4, @campo4,
          @act5, @dia5, @campo5,
          @act6, @dia6, @campo6,
          @act7, @dia7, @campo7,
          @total, @debe, @subtotal, @comedor, @totalNeto
        )
      ''', substitutionValues: {
        'idEmpleado': datosInsert['id_empleado'],
        'idSemana': datosInsert['id_semana'],
        'idCuadrilla': datosInsert['id_cuadrilla'],
        'act1': datosInsert['act_1'], 'dia1': datosInsert['dia_1'], 'campo1': datosInsert['campo_1'],
        'act2': datosInsert['act_2'], 'dia2': datosInsert['dia_2'], 'campo2': datosInsert['campo_2'],
        'act3': datosInsert['act_3'], 'dia3': datosInsert['dia_3'], 'campo3': datosInsert['campo_3'],
        'act4': datosInsert['act_4'], 'dia4': datosInsert['dia_4'], 'campo4': datosInsert['campo_4'],
        'act5': datosInsert['act_5'], 'dia5': datosInsert['dia_5'], 'campo5': datosInsert['campo_5'],
        'act6': datosInsert['act_6'], 'dia6': datosInsert['dia_6'], 'campo6': datosInsert['campo_6'],
        'act7': datosInsert['act_7'], 'dia7': datosInsert['dia_7'], 'campo7': datosInsert['campo_7'],
        'total': datosInsert['total'],
        'debe': datosInsert['debe'],
        'subtotal': datosInsert['subtotal'],
        'comedor': datosInsert['comedor'],
        'totalNeto': datosInsert['total_neto'],
      });
      
      print('   ✅ INSERT exitoso');
      
      // Verificar qué se guardó
      final verificacion = await connection.query('''
        SELECT act_1, dia_1, act_2, dia_2
        FROM nomina_empleados_semanal 
        WHERE id_empleado = 9999 AND id_semana = 999
      ''');
      
      if (verificacion.isNotEmpty) {
        final reg = verificacion.first;
        print('   📋 Verificación - Guardado:');
        print('     act_1: ${reg[0]}, dia_1: ${reg[1]}');
        print('     act_2: ${reg[2]}, dia_2: ${reg[3]}');
        
        if (reg[0] == datosInsert['act_1'] && reg[2] == datosInsert['act_2']) {
          print('   ✅ Las actividades se guardaron correctamente');
        } else {
          print('   ❌ Las actividades NO coinciden con lo esperado');
        }
      }
      
      // Limpiar registro de prueba
      await connection.execute('''
        DELETE FROM nomina_empleados_semanal 
        WHERE id_empleado = 9999 AND id_semana = 999
      ''');
      
    } catch (e) {
      print('   ❌ Error en INSERT: $e');
    }

    await connection.close();
    print('\n✅ Debug completado');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}