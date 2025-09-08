import 'lib/services/database_service.dart';

void main() async {
  print('🔍 ANÁLISIS DE ACTIVIDADES POR SEMANA');
  print('=' * 50);
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // 1. Obtener todas las semanas cerradas
    print('\n1️⃣ Analizando semanas cerradas...');
    final semanasCerradas = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin
      FROM semanas_nomina 
      WHERE esta_cerrada = true 
      ORDER BY id_semana DESC 
      LIMIT 10
    ''');
    
    print('📊 Primeras 10 semanas cerradas:');
    
    for (var row in semanasCerradas) {
      final semanaId = row[0] as int;
      final fechaInicio = row[1] as DateTime;
      final fechaFin = row[2] as DateTime;
      
      print('\n🔍 SEMANA $semanaId (${fechaInicio.toString().split(' ')[0]} - ${fechaFin.toString().split(' ')[0]}):');
      
      // Verificar datos en tabla semanal
      final datosSemanal = await db.connection.query(
        'SELECT COUNT(*) FROM nomina_empleados_semanal WHERE id_semana = @id',
        substitutionValues: {'id': semanaId}
      );
      print('   📋 Registros semanal: ${datosSemanal.first[0]}');
      
      // Verificar actividades válidas en semanal
      if ((datosSemanal.first[0] as int) > 0) {
        final actividadesSemanal = await db.connection.query('''
          SELECT COUNT(*) FROM nomina_empleados_semanal n
          WHERE n.id_semana = @id 
          AND (
            (n.act_1 IS NOT NULL AND n.act_1 > 0) OR
            (n.act_2 IS NOT NULL AND n.act_2 > 0) OR
            (n.act_3 IS NOT NULL AND n.act_3 > 0) OR
            (n.act_4 IS NOT NULL AND n.act_4 > 0) OR
            (n.act_5 IS NOT NULL AND n.act_5 > 0) OR
            (n.act_6 IS NOT NULL AND n.act_6 > 0) OR
            (n.act_7 IS NOT NULL AND n.act_7 > 0)
          )
        ''', substitutionValues: {'id': semanaId});
        
        print('   🎯 Con actividades válidas: ${actividadesSemanal.first[0]}');
        
        // Mostrar algunas actividades de ejemplo
        final ejemploActividades = await db.connection.query('''
          SELECT act_1, act_2, act_3, dia_1, dia_2, dia_3
          FROM nomina_empleados_semanal 
          WHERE id_semana = @id 
          LIMIT 1
        ''', substitutionValues: {'id': semanaId});
        
        if (ejemploActividades.isNotEmpty) {
          final ej = ejemploActividades.first;
          print('   💼 Ejemplo: act_1=${ej[0]}/\$${ej[3]}, act_2=${ej[1]}/\$${ej[4]}, act_3=${ej[2]}/\$${ej[5]}');
        }
      }
      
      // Verificar datos en tabla historial
      final datosHistorial = await db.connection.query(
        'SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = @id',
        substitutionValues: {'id': semanaId}
      );
      print('   📚 Registros historial: ${datosHistorial.first[0]}');
      
      // Determinar si aparecerá en dropdown
      bool tieneActividadesValidas = false;
      if ((datosSemanal.first[0] as int) > 0) {
        final actSemanal = await db.connection.query('''
          SELECT COUNT(*) FROM nomina_empleados_semanal n
          WHERE n.id_semana = @id 
          AND (n.act_1 > 0 OR n.act_2 > 0 OR n.act_3 > 0 OR n.act_4 > 0 OR n.act_5 > 0 OR n.act_6 > 0 OR n.act_7 > 0)
        ''', substitutionValues: {'id': semanaId});
        
        if ((actSemanal.first[0] as int) > 0) {
          tieneActividadesValidas = true;
        }
      }
      
      if ((datosHistorial.first[0] as int) > 0 && !tieneActividadesValidas) {
        final actHistorial = await db.connection.query('''
          SELECT COUNT(*) FROM nomina_empleados_historial h
          WHERE h.id_semana = @id 
          AND (h.act_1 > 0 OR h.act_2 > 0 OR h.act_3 > 0 OR h.act_4 > 0 OR h.act_5 > 0 OR h.act_6 > 0 OR h.act_7 > 0)
        ''', substitutionValues: {'id': semanaId});
        
        if ((actHistorial.first[0] as int) > 0) {
          tieneActividadesValidas = true;
        }
      }
      
      if (tieneActividadesValidas) {
        print('   ✅ APARECERÁ en dropdown de reportes');
      } else {
        print('   ❌ NO aparecerá en dropdown (sin actividades válidas)');
      }
    }
    
    print('\n✅ ANÁLISIS COMPLETADO');
    print('💡 Solo las semanas con ✅ aparecerán en el dropdown de reportes');
    
  } catch (e, stack) {
    print('❌ Error: $e');
    print('Stack: $stack');
  } finally {
    await db.close();
  }
}
