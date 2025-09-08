import 'lib/services/database_service.dart';

void main() async {
  print('🔍 DIAGNÓSTICO SIMPLE DE SEMANA 37');
  print('=' * 40);
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // 1️⃣ ¿Existe la semana 37?
    print('\n1️⃣ Verificando semana 37...');
    final semana = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada 
      FROM semanas_nomina 
      WHERE id_semana = 37
    ''');
    
    if (semana.isEmpty) {
      print('❌ Semana 37 NO EXISTE en semanas_nomina');
      return;
    }
    
    print('✅ Semana 37 existe:');
    print('   • Fechas: ${semana.first[1]} - ${semana.first[2]}');
    print('   • Cerrada: ${semana.first[3]}');
    
    // 2️⃣ ¿Dónde están los datos?
    print('\n2️⃣ Ubicación de datos...');
    
    final semanal = await db.connection.query('SELECT COUNT(*) FROM nomina_empleados_semanal WHERE id_semana = 37');
    final historial = await db.connection.query('SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = 37');
    
    final countSemanal = semanal.first[0] as int;
    final countHistorial = historial.first[0] as int;
    
    print('   • En tabla semanal: $countSemanal registros');
    print('   • En tabla historial: $countHistorial registros');
    
    // 3️⃣ ¿Aparece en consulta de reportes?
    print('\n3️⃣ Consulta de reportes...');
    
    final consulta1 = await db.connection.query('''
      SELECT COUNT(*) FROM semanas_nomina s
      INNER JOIN nomina_empleados_semanal n ON s.id_semana = n.id_semana
      WHERE s.esta_cerrada = true AND s.id_semana = 37
    ''');
    
    final consulta2 = await db.connection.query('''
      SELECT COUNT(*) FROM semanas_nomina s
      INNER JOIN nomina_empleados_historial h ON s.id_semana = h.id_semana
      WHERE s.esta_cerrada = true AND s.id_semana = 37
    ''');
    
    print('   • Con JOIN semanal: ${consulta1.first[0]} registros');
    print('   • Con JOIN historial: ${consulta2.first[0]} registros');
    
    // 4️⃣ Listar todas las semanas que SÍ aparecen
    print('\n4️⃣ Semanas que SÍ aparecen en reportes:');
    
    final semanasConDatos = await db.connection.query('''
      SELECT DISTINCT s.id_semana, s.fecha_inicio, s.fecha_fin
      FROM semanas_nomina s
      WHERE s.esta_cerrada = true
      AND (
        EXISTS (SELECT 1 FROM nomina_empleados_semanal n WHERE n.id_semana = s.id_semana)
        OR
        EXISTS (SELECT 1 FROM nomina_empleados_historial h WHERE h.id_semana = s.id_semana)
      )
      ORDER BY s.id_semana DESC
      LIMIT 10
    ''');
    
    for (var row in semanasConDatos) {
      print('   • Semana ${row[0]}: ${row[1]} - ${row[2]}');
    }
    
    print('\n✅ DIAGNÓSTICO COMPLETADO');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
