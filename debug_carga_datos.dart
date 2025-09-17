import 'package:postgres/postgres.dart';
import 'dart:io';

void main() async {
  print('🔍 DEBUG: Verificando datos guardados vs datos cargados');
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

    // 1. Verificar datos más recientes en nomina_empleados_semanal
    print('\n📊 1. Datos recientes en nomina_empleados_semanal:');
    final datos = await connection.query('''
      SELECT id_nomina, id_empleado, id_semana, id_cuadrilla,
             dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7,
             act_1, act_2, act_3, act_4, act_5, act_6, act_7,
             campo_1, campo_2, campo_3, campo_4, campo_5, campo_6, campo_7,
             total, debe, subtotal, comedor, total_neto
      FROM nomina_empleados_semanal 
      WHERE (dia_1 IS NOT NULL AND dia_1 != 0) OR 
            (dia_2 IS NOT NULL AND dia_2 != 0) OR
            (dia_3 IS NOT NULL AND dia_3 != 0) OR
            (dia_4 IS NOT NULL AND dia_4 != 0) OR
            (dia_5 IS NOT NULL AND dia_5 != 0) OR
            (dia_6 IS NOT NULL AND dia_6 != 0) OR
            (dia_7 IS NOT NULL AND dia_7 != 0)
      ORDER BY id_nomina DESC 
      LIMIT 3
    ''');
    
    if (datos.isEmpty) {
      print('   ❌ No se encontraron registros con sueldos');
    } else {
      print('   ✅ Registros con sueldos encontrados: ${datos.length}');
      for (final reg in datos) {
        print('   - ID: ${reg[0]}, Empleado: ${reg[1]}, Semana: ${reg[2]}, Cuadrilla: ${reg[3]}');
        print('     Días: ${reg[4]}, ${reg[5]}, ${reg[6]}, ${reg[7]}, ${reg[8]}, ${reg[9]}, ${reg[10]}');
        print('     Actividades: ${reg[11]}, ${reg[12]}, ${reg[13]}, ${reg[14]}, ${reg[15]}, ${reg[16]}, ${reg[17]}');
        print('     Campos: ${reg[18]}, ${reg[19]}, ${reg[20]}, ${reg[21]}, ${reg[22]}, ${reg[23]}, ${reg[24]}');
        print('     Totales: total=${reg[25]}, debe=${reg[26]}, subtotal=${reg[27]}, comedor=${reg[28]}, total_neto=${reg[29]}');
        print('');
      }
    }

    // 2. Simular función _norm() como está en el código
    String simulateNorm(dynamic v) {
      final s = v?.toString() ?? '0';
      if (s.contains('.')) return s; // ya tiene decimales
      final soloDigitos = RegExp(r'^\d{5,}$');
      if (soloDigitos.hasMatch(s)) {
        final d = double.tryParse(s) ?? 0.0;
        if (d < 1000000) {
          final ajustado = d / 100.0;
          if (ajustado < 10000) {
            return ajustado.toStringAsFixed(2);
          }
        }
      }
      return s; // sin cambio
    }

    // 3. Probar función _norm con diferentes valores
    print('\n🧪 2. Probando función _norm() con valores típicos:');
    final testValues = [
      0.50,     // Decimal normal
      '0.50',   // String decimal
      500,      // Entero
      '500',    // String entero
      50000,    // Entero grande (5 dígitos)
      '50000',  // String grande (5 dígitos)
      0,        // Cero
      '0',      // String cero
      null,     // Null
    ];
    
    for (final valor in testValues) {
      final resultado = simulateNorm(valor);
      print('     $valor (${valor.runtimeType}) → "$resultado"');
    }

    // 4. Si hay datos, simular carga completa
    if (datos.isNotEmpty) {
      print('\n🔄 3. Simulando carga de datos como en obtenerNominaEmpleadosDeCuadrilla:');
      final registro = datos.first;
      
      print('   Datos originales de BD:');
      print('     dia_1: ${registro[4]} (${registro[4].runtimeType})');
      print('     dia_2: ${registro[5]} (${registro[5].runtimeType})');
      print('     dia_3: ${registro[6]} (${registro[6].runtimeType})');
      
      print('   Datos después de _norm():');
      print('     dia_1 → dia_0_s: "${simulateNorm(registro[4])}"');
      print('     dia_2 → dia_1_s: "${simulateNorm(registro[5])}"');
      print('     dia_3 → dia_2_s: "${simulateNorm(registro[6])}"');
      
      // Verificar si la normalización es el problema
      final dia1Original = registro[4];
      final dia1Normalizado = simulateNorm(registro[4]);
      
      if (dia1Original.toString() != dia1Normalizado) {
        print('   ⚠️ DIFERENCIA DETECTADA en dia_1:');
        print('     Original: $dia1Original');
        print('     Normalizado: $dia1Normalizado');
      } else {
        print('   ✅ No hay diferencia en normalización para dia_1');
      }
    }

    // 5. Verificar tipos de datos en la BD
    print('\n🔍 4. Verificando tipos de datos en la BD:');
    final tiposDatos = await connection.query('''
      SELECT column_name, data_type, numeric_precision, numeric_scale
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_semanal' 
        AND column_name LIKE 'dia_%'
      ORDER BY column_name
    ''');
    
    for (final col in tiposDatos) {
      print('     ${col[0]}: ${col[1]} (precisión: ${col[2]}, escala: ${col[3]})');
    }

    await connection.close();
    print('\n✅ Debug completado');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}