import 'dart:io';
import 'package:postgres/postgres.dart';

void main() async {
  print('🔧 PRUEBA: Verificando precisión de decimales en cierre de semana');
  print('=' * 60);

  try {
    // Conectar a PostgreSQL
    final connection = PostgreSQLConnection(
      'localhost',
      5432,
      'agribar_db',
      username: 'postgres',
      password: '123456',
    );

    await connection.open();
    print('✅ Conexión establecida con PostgreSQL');

    // 1. Buscar datos existentes en semanal con decimales
    print('\n📊 Buscando registros con decimales en tabla semanal...');
    final registrosSemanal = await connection.query('''
      SELECT id_empleado, id_semana, id_cuadrilla, 
             dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7,
             total, debe, subtotal, comedor, total_neto
      FROM nomina_empleados_semanal 
      WHERE (dia_1::text LIKE '%.5%' OR dia_2::text LIKE '%.5%' OR 
             dia_3::text LIKE '%.5%' OR dia_4::text LIKE '%.5%' OR 
             dia_5::text LIKE '%.5%' OR dia_6::text LIKE '%.5%' OR 
             dia_7::text LIKE '%.5%' OR
             total::text LIKE '%.5%' OR debe::text LIKE '%.5%' OR 
             subtotal::text LIKE '%.5%' OR comedor::text LIKE '%.5%' OR 
             total_neto::text LIKE '%.5%')
      LIMIT 3
    ''');

    if (registrosSemanal.isEmpty) {
      print('⚠️  No se encontraron registros con decimales .5 para probar');
      
      // Crear un registro de prueba
      print('\n➕ Creando registro de prueba con decimales...');
      await connection.query('''
        INSERT INTO nomina_empleados_semanal (
          id_empleado, id_semana, id_cuadrilla,
          dia_1, dia_2, dia_3, total, subtotal, total_neto,
          fecha_actualizacion
        ) VALUES (
          9999, 999, 1,
          0.50, 1.25, 2.75, 4.50, 4.50, 4.50,
          CURRENT_TIMESTAMP
        )
        ON CONFLICT (id_empleado, id_semana, id_cuadrilla) 
        DO UPDATE SET
          dia_1 = 0.50, dia_2 = 1.25, dia_3 = 2.75,
          total = 4.50, subtotal = 4.50, total_neto = 4.50
      ''');
      
      print('✅ Registro de prueba creado: empleado 9999, semana 999');
      
      // Volver a consultar
      final nuevoRegistro = await connection.query('''
        SELECT id_empleado, id_semana, id_cuadrilla, 
               dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7,
               total, debe, subtotal, comedor, total_neto
        FROM nomina_empleados_semanal 
        WHERE id_empleado = 9999 AND id_semana = 999
      ''');
      
      if (nuevoRegistro.isNotEmpty) {
        final reg = nuevoRegistro.first;
        print('\n📋 Registro de prueba creado:');
        print('   Empleado: ${reg[0]}, Semana: ${reg[1]}, Cuadrilla: ${reg[2]}');
        print('   Día 1: ${reg[3]}, Día 2: ${reg[4]}, Día 3: ${reg[5]}');
        print('   Total: ${reg[8]}, Subtotal: ${reg[10]}, Total Neto: ${reg[12]}');
        
        // Probar función _parseDouble (simulada)
        print('\n🧪 Probando conservación de decimales:');
        double testValue = 0.50;
        print('   Valor original: $testValue');
        print('   Sin .round(): $testValue');
        print('   Con .round(): ${testValue.round()} ← PROBLEMA ANTERIOR');
        
        print('\n✅ El fix debería conservar 0.50 en lugar de convertir a 1.00');
      }
    } else {
      print('✅ Encontrados ${registrosSemanal.length} registros con decimales:');
      for (final reg in registrosSemanal) {
        print('   Empleado: ${reg[0]}, Semana: ${reg[1]}');
        print('   Días: ${reg[3]}, ${reg[4]}, ${reg[5]}, ${reg[6]}, ${reg[7]}, ${reg[8]}, ${reg[9]}');
        print('   Totales: ${reg[10]}, ${reg[11]}, ${reg[12]}, ${reg[13]}, ${reg[14]}');
        print('   ---');
      }
    }

    await connection.close();
    print('\n✅ Prueba completada');
    print('\n💡 Ahora puedes probar cerrando la semana 999 para verificar');
    print('   que los decimales se conserven correctamente en historial.');
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}