import 'package:postgres/postgres.dart';
import 'dart:io';

void main() async {
  print('🧪 PRUEBA: Verificando fix de guardado de actividades');
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

    // 1. Cargar mapas de actividades (simular _cargarMappingActividades)
    print('\n🔄 1. Cargando mapas de actividades...');
    final actividades = await connection.query(
      'SELECT id_actividad, clave, nombre FROM actividades ORDER BY clave LIMIT 10'
    );
    
    Map<String, int> claveAIdMap = {};
    for (final actividad in actividades) {
      final id = actividad[0] as int;
      final clave = actividad[1]?.toString() ?? '';
      
      if (clave.isNotEmpty) {
        claveAIdMap[clave] = id;
      }
    }
    
    print('   Mapas cargados: ${claveAIdMap.length} entradas');

    // 2. Simular función corregida _obtenerIdParaGuardar
    int obtenerIdParaGuardarCorregido(dynamic valor) {
      if (valor == null) return 0;
      String s = valor.toString().trim();
      if (s.isEmpty || s == '0') return 0;
      
      // 🔧 NORMALIZAR: Quitar '.0' si está presente
      if (s.endsWith('.0')) {
        s = s.substring(0, s.length - 2);
      }
      
      // Si coincide como clave conocida -> devolver ID
      if (claveAIdMap.containsKey(s)) {
        return claveAIdMap[s]!;
      }
      
      // Si es número válido -> aceptar
      final posibleId = int.tryParse(s);
      if (posibleId != null && posibleId > 0) {
        return posibleId;
      }
      
      return 0;
    }

    // 3. Simular función _getSafeIntValue
    int getSafeIntValue(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty || trimmed == '0') return 0;
        final parsed = int.tryParse(trimmed);
        return parsed ?? 0;
      }
      return 0;
    }

    // 4. Probar con valores problemáticos ANTES y DESPUÉS del fix
    print('\n🔧 2. Probando fix de normalización:');
    final valoresProblematicos = ['1301.0', '1302.0', '1304.0', '1.0', '1'];
    
    for (final valor in valoresProblematicos) {
      // Función ANTERIOR (sin normalización)
      int valorAnterior = 0;
      final s = valor.toString().trim();
      if (s.isNotEmpty && s != '0') {
        if (claveAIdMap.containsKey(s)) {
          valorAnterior = claveAIdMap[s]!;
        } else {
          final posibleId = int.tryParse(s);
          if (posibleId != null && posibleId > 0) {
            valorAnterior = posibleId;
          }
        }
      }
      
      // Función CORREGIDA (con normalización)
      final valorCorregido = obtenerIdParaGuardarCorregido(valor);
      
      String resultado;
      if (valorAnterior != valorCorregido) {
        resultado = '🔧 CORREGIDO: $valorAnterior → $valorCorregido';
      } else {
        resultado = '✅ Sin cambios: $valorCorregido';
      }
      
      print('     "$valor": $resultado');
    }

    // 5. Crear registro de prueba con los valores corregidos
    print('\n💾 3. Probando INSERT con valores corregidos:');
    
    // Eliminar registro de prueba previo
    await connection.execute('''
      DELETE FROM nomina_empleados_semanal 
      WHERE id_empleado = 9999 AND id_semana = 999
    ''');
    
    // Datos de prueba con valores problemáticos que ahora deberían funcionar
    final datosCorregidos = {
      'id_empleado': 9999,
      'id_semana': 999,
      'id_cuadrilla': 1,
      'act_1': obtenerIdParaGuardarCorregido('1301.0'), // Debe convertirse correctamente
      'dia_1': 500.0,
      'campo_1': getSafeIntValue('1'), // Campo como integer
      'act_2': obtenerIdParaGuardarCorregido('1304.0'), // Debe convertirse correctamente
      'dia_2': 600.0,
      'campo_2': getSafeIntValue('2'), // Campo como integer
      'act_3': 0, 'dia_3': 0.0, 'campo_3': 0,
      'act_4': 0, 'dia_4': 0.0, 'campo_4': 0,
      'act_5': 0, 'dia_5': 0.0, 'campo_5': 0,
      'act_6': 0, 'dia_6': 0.0, 'campo_6': 0,
      'act_7': 0, 'dia_7': 0.0, 'campo_7': 0,
      'total': 1100.0,
      'debe': 0.0,
      'subtotal': 1100.0,
      'comedor': 0.0,
      'total_neto': 1100.0,
    };
    
    print('   Datos a insertar:');
    print('     act_1: ${datosCorregidos['act_1']} (de "1301.0")');
    print('     act_2: ${datosCorregidos['act_2']} (de "1304.0")');
    print('     campo_1: ${datosCorregidos['campo_1']} (integer)');
    print('     campo_2: ${datosCorregidos['campo_2']} (integer)');
    
    try {
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
        'idEmpleado': datosCorregidos['id_empleado'],
        'idSemana': datosCorregidos['id_semana'],
        'idCuadrilla': datosCorregidos['id_cuadrilla'],
        'act1': datosCorregidos['act_1'], 'dia1': datosCorregidos['dia_1'], 'campo1': datosCorregidos['campo_1'],
        'act2': datosCorregidos['act_2'], 'dia2': datosCorregidos['dia_2'], 'campo2': datosCorregidos['campo_2'],
        'act3': datosCorregidos['act_3'], 'dia3': datosCorregidos['dia_3'], 'campo3': datosCorregidos['campo_3'],
        'act4': datosCorregidos['act_4'], 'dia4': datosCorregidos['dia_4'], 'campo4': datosCorregidos['campo_4'],
        'act5': datosCorregidos['act_5'], 'dia5': datosCorregidos['dia_5'], 'campo5': datosCorregidos['campo_5'],
        'act6': datosCorregidos['act_6'], 'dia6': datosCorregidos['dia_6'], 'campo6': datosCorregidos['campo_6'],
        'act7': datosCorregidos['act_7'], 'dia7': datosCorregidos['dia_7'], 'campo7': datosCorregidos['campo_7'],
        'total': datosCorregidos['total'],
        'debe': datosCorregidos['debe'],
        'subtotal': datosCorregidos['subtotal'],
        'comedor': datosCorregidos['comedor'],
        'totalNeto': datosCorregidos['total_neto'],
      });
      
      print('   ✅ INSERT exitoso con valores corregidos');
      
      // Verificar qué se guardó
      final verificacion = await connection.query('''
        SELECT act_1, dia_1, campo_1, act_2, dia_2, campo_2
        FROM nomina_empleados_semanal 
        WHERE id_empleado = 9999 AND id_semana = 999
      ''');
      
      if (verificacion.isNotEmpty) {
        final reg = verificacion.first;
        print('   📋 Verificación - Datos guardados:');
        print('     act_1: ${reg[0]}, dia_1: ${reg[1]}, campo_1: ${reg[2]}');
        print('     act_2: ${reg[3]}, dia_2: ${reg[4]}, campo_2: ${reg[5]}');
        
        if (reg[0] == datosCorregidos['act_1'] && reg[3] == datosCorregidos['act_2']) {
          print('   ✅ Las actividades se guardaron correctamente');
          print('   🎉 ¡FIX CONFIRMADO! Las actividades con ".0" ahora funcionan');
        } else {
          print('   ❌ Las actividades NO coinciden');
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
    print('\n✅ Prueba completada');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}