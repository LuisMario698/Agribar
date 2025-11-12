import 'lib/services/database_service.dart';

void main() async {
  print('🔍 VERIFICACIÓN DIRECTA DE BD');
  print('=' * 30);
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // 1. ¿Existe semana 37?
    print('\n1. Semana 37 en BD:');
    final semana37 = await db.connection.query(
      'SELECT id_semana, esta_cerrada FROM semanas_nomina WHERE id_semana = 37'
    );
    
    if (semana37.isEmpty) {
      print('❌ NO EXISTE');
      await db.close();
      return;
    }
    
    print('✅ EXISTE - Cerrada: ${semana37.first[1]}');
    
    // 2. ¿Datos en semanal?
    final semanal = await db.connection.query(
      'SELECT COUNT(*) FROM nomina_empleados_semanal WHERE id_semana = 37'
    );
    print('2. Datos semanal: ${semanal.first[0]}');
    
    // 3. ¿Datos en historial?
    final historial = await db.connection.query(
      'SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = 37'
    );
    print('3. Datos historial: ${historial.first[0]}');
    
    // 4. Total semanas cerradas
    final totalCerradas = await db.connection.query(
      'SELECT COUNT(*) FROM semanas_nomina WHERE esta_cerrada = true'
    );
    print('4. Total cerradas: ${totalCerradas.first[0]}');
    
    // 5. Semanas con datos
    final conDatos = await db.connection.query('''
      SELECT COUNT(DISTINCT s.id_semana) 
      FROM semanas_nomina s 
      WHERE s.esta_cerrada = true 
      AND (
        EXISTS(SELECT 1 FROM nomina_empleados_semanal n WHERE n.id_semana = s.id_semana)
        OR
        EXISTS(SELECT 1 FROM nomina_empleados_historial h WHERE h.id_semana = s.id_semana)
      )
    ''');
    print('5. Cerradas con datos: ${conDatos.first[0]}');
    
    print('\n✅ VERIFICACIÓN COMPLETADA');
    
  } catch (e) {
    print('ERROR: $e');
  } finally {
    await db.close();
  }
}
