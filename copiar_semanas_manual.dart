import 'package:postgres/postgres.dart';

void main() async {
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'agribar',
    username: 'postgres',
    password: 'Agribar',
  );

  try {
    await connection.open();
    print('Conexión establecida correctamente');

    // Verificar semanas en historial
    print('\n--- SEMANAS EN HISTORIAL ---');
    var result = await connection.query(
      'SELECT DISTINCT id_semana FROM nomina_empleados_historial ORDER BY id_semana',
    );
    print('Semanas en historial: ${result.map((r) => r[0]).toList()}');

    // Verificar semanas en semanal
    print('\n--- SEMANAS EN SEMANAL ---');
    result = await connection.query(
      'SELECT DISTINCT id_semana FROM nomina_empleados_semanal ORDER BY id_semana',
    );
    print('Semanas en semanal: ${result.map((r) => r[0]).toList()}');

    // Encontrar semanas faltantes
    var historialSemanas = (await connection.query(
      'SELECT DISTINCT id_semana FROM nomina_empleados_historial',
    )).map((r) => r[0] as int).toSet();
    
    var semanalSemanas = (await connection.query(
      'SELECT DISTINCT id_semana FROM nomina_empleados_semanal',
    )).map((r) => r[0] as int).toSet();

    var faltantes = semanalSemanas.difference(historialSemanas);
    print('\nSemanas faltantes en historial: ${faltantes.toList()..sort()}');

    // Copiar semanas faltantes una por una
    for (var semana in faltantes.toList()..sort()) {
      print('\n--- COPIANDO SEMANA $semana ---');
      
      // Contar registros en semanal para esta semana
      var countSemanal = await connection.query(
        'SELECT COUNT(*) FROM nomina_empleados_semanal WHERE id_semana = @semana',
        substitutionValues: {'semana': semana},
      );
      print('Registros en semanal para semana $semana: ${countSemanal[0][0]}');

      if ((countSemanal[0][0] as int) > 0) {
        try {
          // Copiar usando SELECT *
          var copyResult = await connection.execute('''
            INSERT INTO nomina_empleados_historial 
            SELECT * FROM nomina_empleados_semanal 
            WHERE id_semana = @semana;
          ''', substitutionValues: {'semana': semana});
          
          print('✓ Semana $semana copiada. Registros afectados: ${copyResult}');
          
          // Verificar la copia
          var countHistorial = await connection.query(
            'SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = @semana',
            substitutionValues: {'semana': semana},
          );
          print('Verificación - Registros en historial: ${countHistorial[0][0]}');
          
        } catch (e) {
          print('✗ Error copiando semana $semana: $e');
          
          // Si falla con SELECT *, intentar columna por columna
          print('Intentando copia manual...');
          try {
            var copyResult2 = await connection.execute('''
              INSERT INTO nomina_empleados_historial (
                id_empleado, id_semana, id_cuadrilla, 
                dia_1, dia_2, dia_3, dia_4, dia_5, dia_6,
                total, debe, subtotal, comedor, total_neto,
                dia_1_s, dia_2_s, dia_3_s, dia_4_s, dia_5_s, dia_6_s,
                id_actividad_1, id_actividad_2, id_actividad_3, id_actividad_4, id_actividad_5, id_actividad_6,
                id_rancho_1, id_rancho_2, id_rancho_3, id_rancho_4, id_rancho_5, id_rancho_6,
                creado_en
              )
              SELECT 
                id_empleado, id_semana, id_cuadrilla,
                dia_1, dia_2, dia_3, dia_4, dia_5, dia_6,
                total, debe, subtotal, comedor, total_neto,
                dia_1_s, dia_2_s, dia_3_s, dia_4_s, dia_5_s, dia_6_s,
                id_actividad_1, id_actividad_2, id_actividad_3, id_actividad_4, id_actividad_5, id_actividad_6,
                id_rancho_1, id_rancho_2, id_rancho_3, id_rancho_4, id_rancho_5, id_rancho_6,
                CURRENT_TIMESTAMP
              FROM nomina_empleados_semanal 
              WHERE id_semana = @semana;
            ''', substitutionValues: {'semana': semana});
            print('✓ Copia manual exitosa. Registros afectados: ${copyResult2}');
          } catch (e2) {
            print('✗ Copia manual también falló: $e2');
          }
        }
      } else {
        print('Semana $semana no tiene registros en semanal');
      }
    }

    // Verificación final
    print('\n--- VERIFICACIÓN FINAL ---');
    var finalHistorial = await connection.query(
      'SELECT DISTINCT id_semana FROM nomina_empleados_historial ORDER BY id_semana',
    );
    print('Semanas en historial después de la copia: ${finalHistorial.map((r) => r[0]).toList()}');

  } catch (e) {
    print('Error: $e');
  } finally {
    await connection.close();
    print('\nConexión cerrada');
  }
}
