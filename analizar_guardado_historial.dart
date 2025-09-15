import 'lib/services/database_service.dart';

void main() async {
  print('🔍 ANÁLISIS: GUARDADO SEMANAL VS HISTORIAL');
  print('==========================================');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    // 1. Verificar estructura de ambas tablas
    print('📋 ESTRUCTURA DE TABLAS:');
    print('\n1️⃣ TABLA nomina_empleados_semanal:');
    final estructuraSemanal = await db.connection.query('''
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_semanal' 
      AND column_name LIKE '%dia_%'
      ORDER BY ordinal_position;
    ''');
    
    for (var col in estructuraSemanal) {
      print('  • ${col[0]}: ${col[1]} (nullable: ${col[2]}, default: ${col[3] ?? 'null'})');
    }
    
    print('\n2️⃣ TABLA nomina_empleados_historial:');
    final estructuraHistorial = await db.connection.query('''
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_historial' 
      AND column_name LIKE '%dia_%'
      ORDER BY ordinal_position;
    ''');
    
    for (var col in estructuraHistorial) {
      print('  • ${col[0]}: ${col[1]} (nullable: ${col[2]}, default: ${col[3] ?? 'null'})');
    }
    
    // 2. Buscar registros con valores 0.50 en semanal
    print('\n🔍 REGISTROS CON 0.50 EN SEMANAL:');
    final registrosSemanal = await db.connection.query('''
      SELECT id_nomina, id_empleado, id_semana, 
             dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7
      FROM nomina_empleados_semanal
      WHERE dia_1 = 0.50 OR dia_2 = 0.50 OR dia_3 = 0.50 OR 
            dia_4 = 0.50 OR dia_5 = 0.50 OR dia_6 = 0.50 OR dia_7 = 0.50
      ORDER BY id_nomina DESC
      LIMIT 5;
    ''');
    
    if (registrosSemanal.isEmpty) {
      print('  ❌ No se encontraron registros con 0.50');
      
      // Buscar cualquier registro para debug
      final cualquierRegistro = await db.connection.query('''
        SELECT id_nomina, id_empleado, id_semana, 
               dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7
        FROM nomina_empleados_semanal
        WHERE dia_1 > 0 OR dia_2 > 0 OR dia_3 > 0 OR dia_4 > 0 OR dia_5 > 0 OR dia_6 > 0 OR dia_7 > 0
        ORDER BY id_nomina DESC
        LIMIT 3;
      ''');
      
      print('  📊 Registros con valores > 0:');
      for (var reg in cualquierRegistro) {
        print('    • ID: ${reg[0]}, Emp: ${reg[1]}, Sem: ${reg[2]}');
        print('      Días: ${reg[3]}, ${reg[4]}, ${reg[5]}, ${reg[6]}, ${reg[7]}, ${reg[8]}, ${reg[9]}');
      }
    } else {
      print('  ✅ Registros encontrados:');
      for (var reg in registrosSemanal) {
        print('    • ID: ${reg[0]}, Emp: ${reg[1]}, Sem: ${reg[2]}');
        print('      Días: ${reg[3]}, ${reg[4]}, ${reg[5]}, ${reg[6]}, ${reg[7]}, ${reg[8]}, ${reg[9]}');
        
        // Buscar el mismo empleado/semana en historial
        final enHistorial = await db.connection.query('''
          SELECT id, dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7
          FROM nomina_empleados_historial
          WHERE id_empleado = @emp AND id_semana = @sem;
        ''', substitutionValues: {'emp': reg[1], 'sem': reg[2]});
        
        if (enHistorial.isNotEmpty) {
          final hist = enHistorial.first;
          print('      🔄 En historial: ${hist[1]}, ${hist[2]}, ${hist[3]}, ${hist[4]}, ${hist[5]}, ${hist[6]}, ${hist[7]}');
          
          // Comparar valores
          for (int i = 1; i <= 7; i++) {
            final semanal = reg[i + 2]; // +2 porque reg[0]=id, reg[1]=emp, reg[2]=sem
            final historial = hist[i];
            if (semanal != historial) {
              print('        ⚠️ DIFERENCIA en día $i: semanal=$semanal, historial=$historial');
            }
          }
        } else {
          print('      ❌ No encontrado en historial');
        }
      }
    }
    
    // 3. Verificar tipos de datos exactos
    print('\n🧪 VERIFICACIÓN DE TIPOS DE DATOS:');
    final tipoDatosSemanal = await db.connection.query('''
      SELECT data_type, numeric_precision, numeric_scale
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_semanal' 
      AND column_name = 'dia_1';
    ''');
    
    final tipoDatosHistorial = await db.connection.query('''
      SELECT data_type, numeric_precision, numeric_scale
      FROM information_schema.columns 
      WHERE table_name = 'nomina_empleados_historial' 
      AND column_name = 'dia_1';
    ''');
    
    if (tipoDatosSemanal.isNotEmpty && tipoDatosHistorial.isNotEmpty) {
      final semanal = tipoDatosSemanal.first;
      final historial = tipoDatosHistorial.first;
      
      print('  • Semanal dia_1: ${semanal[0]} (precisión: ${semanal[1]}, escala: ${semanal[2]})');
      print('  • Historial dia_1: ${historial[0]} (precisión: ${historial[1]}, escala: ${historial[2]})');
      
      if (semanal[0] != historial[0] || semanal[1] != historial[1] || semanal[2] != historial[2]) {
        print('  ⚠️ DIFERENCIAS EN TIPOS DE DATOS DETECTADAS');
      } else {
        print('  ✅ Tipos de datos idénticos');
      }
    }
    
  } catch (e) {
    print('❌ Error en análisis: $e');
  } finally {
    await db.close();
  }
}