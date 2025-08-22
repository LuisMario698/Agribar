import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔍 Explorando todas las semanas y sus datos de ranchos...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // Ver todas las semanas disponibles
    print('📋 Todas las semanas en la base de datos:');
    final semanas = await db.connection.query('''
      SELECT 
        id_semana,
        fecha_inicio,
        fecha_fin,
        esta_cerrada,
        autorizado_por
      FROM semanas_nomina 
      ORDER BY id_semana DESC
    ''');
    
    for (final semana in semanas) {
      print('  - Semana ${semana[0]}: ${semana[1]} a ${semana[2]} (${semana[3] ? 'Cerrada' : 'Abierta'}) ${semana[4] ?? ''}');
    }
    
    // Verificar datos de ranchos en cada semana
    for (final semana in semanas) {
      final semanaId = semana[0] as int;
      final fechaInicio = semana[1] as DateTime;
      
      print('\n🔍 Analizando semana $semanaId (${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}):');
      
      // Contar registros totales
      final totalRegistros = await db.connection.query('''
        SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = $semanaId
      ''');
      print('  📊 Total registros: ${totalRegistros.first[0]}');
      
      // Contar registros con ranchos asignados
      final conRanchos = await db.connection.query('''
        SELECT COUNT(*) 
        FROM nomina_empleados_historial 
        WHERE id_semana = $semanaId 
          AND (campo_1 <> 0 OR campo_2 <> 0 OR campo_3 <> 0 OR campo_4 <> 0 OR 
               campo_5 <> 0 OR campo_6 <> 0 OR campo_7 <> 0)
      ''');
      print('  🏞️ Con ranchos: ${conRanchos.first[0]}');
      
      // Ver actividades presentes
      final actividades = await db.connection.query('''
        SELECT DISTINCT
          CASE 
            WHEN act_1 <> 0 THEN act_1
            WHEN act_2 <> 0 THEN act_2
            WHEN act_3 <> 0 THEN act_3
            WHEN act_4 <> 0 THEN act_4
            WHEN act_5 <> 0 THEN act_5
            WHEN act_6 <> 0 THEN act_6
            WHEN act_7 <> 0 THEN act_7
          END as actividad_id
        FROM nomina_empleados_historial 
        WHERE id_semana = $semanaId
          AND (act_1 <> 0 OR act_2 <> 0 OR act_3 <> 0 OR act_4 <> 0 OR 
               act_5 <> 0 OR act_6 <> 0 OR act_7 <> 0)
        ORDER BY actividad_id
      ''');
      
      print('  ⚒️ Actividades: ${actividades.map((r) => r[0]).where((id) => id != null).join(', ')}');
      
      // Ver ranchos presentes
      final ranchos = await db.connection.query('''
        SELECT DISTINCT
          CASE 
            WHEN campo_1 <> 0 THEN campo_1
            WHEN campo_2 <> 0 THEN campo_2
            WHEN campo_3 <> 0 THEN campo_3
            WHEN campo_4 <> 0 THEN campo_4
            WHEN campo_5 <> 0 THEN campo_5
            WHEN campo_6 <> 0 THEN campo_6
            WHEN campo_7 <> 0 THEN campo_7
          END as rancho_id
        FROM nomina_empleados_historial 
        WHERE id_semana = $semanaId
          AND (campo_1 <> 0 OR campo_2 <> 0 OR campo_3 <> 0 OR campo_4 <> 0 OR 
               campo_5 <> 0 OR campo_6 <> 0 OR campo_7 <> 0)
        ORDER BY rancho_id
      ''');
      
      print('  🏞️ Ranchos: ${ranchos.map((r) => r[0]).where((id) => id != null).join(', ')}');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
