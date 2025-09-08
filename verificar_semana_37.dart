import 'lib/services/database_service.dart';

void main() async {
  print('🔍 VERIFICANDO SEMANA 37 EN TABLA SEMANAL');
  print('=' * 50);
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // 1️⃣ Verificar si semana 37 existe y está cerrada
    print('\n1️⃣ Verificando semana 37...');
    final semanaResult = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada 
      FROM semanas_nomina 
      WHERE id_semana = 37
    ''');
    
    if (semanaResult.isEmpty) {
      print('❌ Semana 37 no existe en semanas_nomina');
      return;
    }
    
    final semana = semanaResult.first;
    print('✅ Semana 37 encontrada:');
    print('   • Fechas: ${semana[1]} - ${semana[2]}');
    print('   • Está cerrada: ${semana[3]}');
    
    // 2️⃣ Verificar datos en tabla semanal
    print('\n2️⃣ Verificando datos en nomina_empleados_semanal...');
    final datosResult = await db.connection.query('''
      SELECT COUNT(*) as registros
      FROM nomina_empleados_semanal 
      WHERE id_semana = 37
    ''');
    
    final registros = datosResult.first[0] as int;
    print('📊 Registros en tabla semanal para semana 37: $registros');
    
    if (registros == 0) {
      print('❌ No hay datos en tabla semanal para semana 37');
      
      // Verificar si están en historial
      final historialResult = await db.connection.query('''
        SELECT COUNT(*) as registros
        FROM nomina_empleados_historial 
        WHERE id_semana = 37
      ''');
      final registrosHistorial = historialResult.first[0] as int;
      print('📊 Registros en tabla historial para semana 37: $registrosHistorial');
      
      if (registrosHistorial > 0) {
        print('⚠️ Los datos están en historial, no en semanal');
        print('💡 SOLUCIÓN: Los datos necesitan estar en tabla semanal para aparecer en reportes');
      }
    } else {
      print('✅ Hay datos en tabla semanal para semana 37');
    }
    
    // 3️⃣ Probar consulta de reportes
    print('\n3️⃣ Probando consulta de reportes...');
    final reporteTest = await db.connection.query('''
      SELECT DISTINCT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.esta_cerrada
      FROM semanas_nomina s
      INNER JOIN nomina_empleados_semanal n ON s.id_semana = n.id_semana
      WHERE s.esta_cerrada = true AND s.id_semana = 37
    ''');
    
    print('📊 Semana 37 aparece en consulta de reportes: ${reporteTest.isNotEmpty}');
    
    // 4️⃣ Listar todas las semanas disponibles en reportes
    print('\n4️⃣ Semanas disponibles en reportes:');
    final semanasDisponibles = await db.connection.query('''
      SELECT DISTINCT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin
      FROM semanas_nomina s
      INNER JOIN nomina_empleados_semanal n ON s.id_semana = n.id_semana
      WHERE s.esta_cerrada = true
      ORDER BY s.id_semana DESC
    ''');
    
    print('📊 Total semanas disponibles: ${semanasDisponibles.length}');
    for (var semana in semanasDisponibles) {
      print('   • Semana ${semana[0]}: ${semana[1]} - ${semana[2]}');
    }
    
    print('\n✅ VERIFICACIÓN COMPLETADA');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
