import 'lib/services/database_service.dart';

void main() async {
  print('🔧 CORRECCIÓN AUTOMÁTICA DE SEMANAS PARA REPORTES');
  print('=' * 50);
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // 1️⃣ Identificar semanas cerradas con datos solo en historial
    print('\n1️⃣ Identificando semanas con problema...');
    
    final problemaSemanas = await db.connection.query('''
      SELECT DISTINCT s.id_semana, s.fecha_inicio, s.fecha_fin
      FROM semanas_nomina s
      INNER JOIN nomina_empleados_historial h ON s.id_semana = h.id_semana
      WHERE s.esta_cerrada = true
      AND NOT EXISTS (
        SELECT 1 FROM nomina_empleados_semanal n WHERE n.id_semana = s.id_semana
      )
      ORDER BY s.id_semana DESC
    ''');
    
    print('📊 Semanas con datos solo en historial: ${problemaSemanas.length}');
    
    if (problemaSemanas.isEmpty) {
      print('✅ No hay semanas con problemas - todos los datos están disponibles');
      return;
    }
    
    // Mostrar las semanas problemáticas
    for (var row in problemaSemanas) {
      print('   ⚠️  Semana ${row[0]}: ${row[1]} - ${row[2]} (solo en historial)');
    }
    
    // 2️⃣ Opción de corrección: Copiar datos de historial a semanal
    print('\n2️⃣ Iniciando corrección automática...');
    
    int semanasCorregidas = 0;
    
    for (var row in problemaSemanas) {
      final semanaId = row[0] as int;
      
      try {
        print('🔄 Corrigiendo semana $semanaId...');
        
        // Copiar datos de historial a semanal
        await db.connection.query('''
          INSERT INTO nomina_empleados_semanal (
            id_semana, id_empleado, id_cuadrilla, cuadrilla,
            act_1, dia_1, campo_1,
            act_2, dia_2, campo_2,
            act_3, dia_3, campo_3,
            act_4, dia_4, campo_4,
            act_5, dia_5, campo_5,
            act_6, dia_6, campo_6,
            act_7, dia_7, campo_7
          )
          SELECT 
            id_semana, id_empleado, id_cuadrilla, cuadrilla,
            act_1, COALESCE(dia_1, 0), campo_1,
            act_2, COALESCE(dia_2, 0), campo_2,
            act_3, COALESCE(dia_3, 0), campo_3,
            act_4, COALESCE(dia_4, 0), campo_4,
            act_5, COALESCE(dia_5, 0), campo_5,
            act_6, COALESCE(dia_6, 0), campo_6,
            act_7, COALESCE(dia_7, 0), campo_7
          FROM nomina_empleados_historial
          WHERE id_semana = @semanaId
        ''', substitutionValues: {'semanaId': semanaId});
        
        // Verificar que la copia fue exitosa
        final verificacion = await db.connection.query('''
          SELECT COUNT(*) FROM nomina_empleados_semanal WHERE id_semana = @semanaId
        ''', substitutionValues: {'semanaId': semanaId});
        
        final registrosCopiados = verificacion.first[0] as int;
        print('   ✅ Semana $semanaId: $registrosCopiados registros copiados');
        semanasCorregidas++;
        
      } catch (e) {
        print('   ❌ Error corrigiendo semana $semanaId: $e');
      }
    }
    
    print('\n📊 RESUMEN:');
    print('   • Semanas detectadas con problema: ${problemaSemanas.length}');
    print('   • Semanas corregidas exitosamente: $semanasCorregidas');
    
    if (semanasCorregidas > 0) {
      print('\n✅ CORRECCIÓN COMPLETADA');
      print('💡 Los reportes ahora deberían mostrar todas las semanas cerradas');
    } else {
      print('\n⚠️ NO SE PUDO CORREGIR EL PROBLEMA');
    }
    
    // 3️⃣ Verificar resultado final
    print('\n3️⃣ Verificando resultado...');
    final verificacionFinal = await db.connection.query('''
      SELECT COUNT(DISTINCT s.id_semana) as total_semanas
      FROM semanas_nomina s
      WHERE s.esta_cerrada = true
      AND (
        EXISTS (SELECT 1 FROM nomina_empleados_semanal n WHERE n.id_semana = s.id_semana)
        OR
        EXISTS (SELECT 1 FROM nomina_empleados_historial h WHERE h.id_semana = s.id_semana)
      )
    ''');
    
    final totalSemanasDisponibles = verificacionFinal.first[0] as int;
    print('📊 Total semanas ahora disponibles para reportes: $totalSemanasDisponibles');
    
  } catch (e) {
    print('❌ Error durante la corrección: $e');
  } finally {
    await db.close();
  }
}
