import 'package:postgres/postgres.dart';

void main() async {
  print('🔧 COPIANDO SEMANAS FALTANTES DE SEMANAL A HISTORIAL\n');
  
  // Conectar a PostgreSQL
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'agribar_bd',
    username: 'postgres',
    password: '12345'
  );
  
  try {
    await connection.open();
    print('✅ Conexión establecida\n');
    
    // 1. Verificar qué semanas están en semanal pero no en historial
    print('📋 VERIFICANDO SEMANAS FALTANTES:');
    final semanasFaltantes = await connection.query('''
      SELECT DISTINCT s.id_semana, s.fecha_inicio, s.fecha_fin, s.esta_cerrada
      FROM nomina_empleados_semanal ns
      INNER JOIN semanas_nomina s ON s.id_semana = ns.id_semana
      WHERE ns.id_semana NOT IN (
        SELECT DISTINCT id_semana 
        FROM nomina_empleados_historial 
        WHERE id_semana IS NOT NULL
      )
      AND s.esta_cerrada = true
      ORDER BY s.id_semana;
    ''');
    
    print('Semanas cerradas que faltan en historial: ${semanasFaltantes.length}');
    
    if (semanasFaltantes.isEmpty) {
      print('✅ No hay semanas faltantes');
      return;
    }
    
    for (var row in semanasFaltantes) {
      final idSemana = row[0];
      final fechaInicio = row[1].toString().substring(0, 10);
      final fechaFin = row[2].toString().substring(0, 10);
      final cerrada = row[3];
      print('- Semana $idSemana: $fechaInicio a $fechaFin (Cerrada: $cerrada)');
    }
    
    // 2. Copiar cada semana faltante
    print('\n🔄 COPIANDO SEMANAS...');
    
    for (var row in semanasFaltantes) {
      final idSemana = row[0];
      print('\n📋 Procesando semana $idSemana...');
      
      // Verificar cuántos registros hay en semanal
      final conteoSemanal = await connection.query('''
        SELECT COUNT(*) FROM nomina_empleados_semanal WHERE id_semana = @idSemana;
      ''', substitutionValues: {'idSemana': idSemana});
      
      final totalRegistros = conteoSemanal.first[0] as int;
      print('   Registros en semanal: $totalRegistros');
      
      if (totalRegistros == 0) {
        print('   ⚠️ No hay datos para copiar');
        continue;
      }
      
      // Eliminar datos existentes en historial para esta semana (por si acaso)
      await connection.execute('''
        DELETE FROM nomina_empleados_historial WHERE id_semana = @idSemana;
      ''', substitutionValues: {'idSemana': idSemana});
      
      // Copiar datos de semanal a historial
      final resultadoCopia = await connection.execute('''
        INSERT INTO nomina_empleados_historial (
          id_empleado, id_semana, id_cuadrilla, id_rancho,
          dia_1, dia_2, dia_3, dia_4, dia_5, dia_6,
          total, debe, subtotal, comedor, total_neto,
          dia_1_s, dia_2_s, dia_3_s, dia_4_s, dia_5_s, dia_6_s,
          campo_1, campo_2, campo_3, campo_4, campo_5, campo_6, campo_7,
          actividad_1, actividad_2, actividad_3, actividad_4, actividad_5, actividad_6,
          created_at, updated_at
        )
        SELECT 
          id_empleado, id_semana, id_cuadrilla, id_rancho,
          dia_1, dia_2, dia_3, dia_4, dia_5, dia_6,
          total, debe, subtotal, comedor, total_neto,
          dia_1_s, dia_2_s, dia_3_s, dia_4_s, dia_5_s, dia_6_s,
          campo_1, campo_2, campo_3, campo_4, campo_5, campo_6, campo_7,
          actividad_1, actividad_2, actividad_3, actividad_4, actividad_5, actividad_6,
          created_at, updated_at
        FROM nomina_empleados_semanal 
        WHERE id_semana = @idSemana;
      ''', substitutionValues: {'idSemana': idSemana});
      
      print('   ✅ Copiados $resultadoCopia registros a historial');
    }
    
    // 3. Verificar resultado final
    print('\n📊 VERIFICACIÓN FINAL:');
    final verificacionFinal = await connection.query('''
      SELECT DISTINCT id_semana 
      FROM nomina_empleados_historial 
      WHERE id_semana IS NOT NULL
      ORDER BY id_semana DESC
      LIMIT 10;
    ''');
    
    print('Últimas semanas en historial:');
    for (var row in verificacionFinal) {
      print('- Semana ${row[0]}');
    }
    
    print('\n✅ Proceso completado');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await connection.close();
    print('🔄 Conexión cerrada');
  }
}
