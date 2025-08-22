import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔧 Creando trigger automático corregido...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    print('📋 1. Verificando función existente...');
    
    // La función ya existe, pero voy a recrearla para asegurarme
    await db.connection.execute('''
      CREATE OR REPLACE FUNCTION asignar_ranchos_automaticamente()
      RETURNS TRIGGER AS \$\$
      BEGIN
        -- Asignar ranchos basado en el ID de actividad para cada día
        -- Algoritmo: actividad_id % 3 determina el rancho
        -- 1 = San Francisco, 2 = San Valentín, 0 = Santa Amalia
        
        NEW.campo_1 = CASE 
          WHEN NEW.act_1 = 0 OR NEW.act_1 IS NULL THEN 0
          WHEN NEW.act_1 % 3 = 1 THEN 1  -- San Francisco
          WHEN NEW.act_1 % 3 = 2 THEN 2  -- San Valentín  
          WHEN NEW.act_1 % 3 = 0 THEN 3  -- Santa Amalia
        END;
        
        NEW.campo_2 = CASE 
          WHEN NEW.act_2 = 0 OR NEW.act_2 IS NULL THEN 0
          WHEN NEW.act_2 % 3 = 1 THEN 1
          WHEN NEW.act_2 % 3 = 2 THEN 2
          WHEN NEW.act_2 % 3 = 0 THEN 3
        END;
        
        NEW.campo_3 = CASE 
          WHEN NEW.act_3 = 0 OR NEW.act_3 IS NULL THEN 0
          WHEN NEW.act_3 % 3 = 1 THEN 1
          WHEN NEW.act_3 % 3 = 2 THEN 2
          WHEN NEW.act_3 % 3 = 0 THEN 3
        END;
        
        NEW.campo_4 = CASE 
          WHEN NEW.act_4 = 0 OR NEW.act_4 IS NULL THEN 0
          WHEN NEW.act_4 % 3 = 1 THEN 1
          WHEN NEW.act_4 % 3 = 2 THEN 2
          WHEN NEW.act_4 % 3 = 0 THEN 3
        END;
        
        NEW.campo_5 = CASE 
          WHEN NEW.act_5 = 0 OR NEW.act_5 IS NULL THEN 0
          WHEN NEW.act_5 % 3 = 1 THEN 1
          WHEN NEW.act_5 % 3 = 2 THEN 2
          WHEN NEW.act_5 % 3 = 0 THEN 3
        END;
        
        NEW.campo_6 = CASE 
          WHEN NEW.act_6 = 0 OR NEW.act_6 IS NULL THEN 0
          WHEN NEW.act_6 % 3 = 1 THEN 1
          WHEN NEW.act_6 % 3 = 2 THEN 2
          WHEN NEW.act_6 % 3 = 0 THEN 3
        END;
        
        NEW.campo_7 = CASE 
          WHEN NEW.act_7 = 0 OR NEW.act_7 IS NULL THEN 0
          WHEN NEW.act_7 % 3 = 1 THEN 1
          WHEN NEW.act_7 % 3 = 2 THEN 2
          WHEN NEW.act_7 % 3 = 0 THEN 3
        END;
        
        RETURN NEW;
      END;
      \$\$ LANGUAGE plpgsql;
    ''');
    
    print('✅ Función actualizada');
    
    print('\n📋 2. Eliminando triggers anteriores...');
    await db.connection.execute('''
      DROP TRIGGER IF EXISTS trigger_asignar_ranchos ON nomina_empleados_historial;
    ''');
    
    await db.connection.execute('''
      DROP TRIGGER IF EXISTS trigger_asignar_ranchos ON nomina_empleados_semanal;
    ''');
    
    print('\n📋 3. Creando triggers para ambas tablas...');
    
    // Trigger para nomina_empleados_historial (tabla histórica)
    await db.connection.execute('''
      CREATE TRIGGER trigger_asignar_ranchos_historial
        BEFORE INSERT OR UPDATE ON nomina_empleados_historial
        FOR EACH ROW
        EXECUTE FUNCTION asignar_ranchos_automaticamente();
    ''');
    
    // Trigger para nomina_empleados_semanal (tabla activa)
    await db.connection.execute('''
      CREATE TRIGGER trigger_asignar_ranchos_semanal
        BEFORE INSERT OR UPDATE ON nomina_empleados_semanal
        FOR EACH ROW
        EXECUTE FUNCTION asignar_ranchos_automaticamente();
    ''');
    
    print('✅ Triggers creados para ambas tablas');
    
    print('\n🧪 4. Probando el trigger...');
    
    // Limpiar registros de prueba anteriores
    await db.connection.execute('''
      DELETE FROM nomina_empleados_historial 
      WHERE id_empleado = 99999
    ''');
    
    // Insertar registro de prueba
    await db.connection.execute('''
      INSERT INTO nomina_empleados_historial (
        id_empleado, id_semana, id_cuadrilla,
        act_1, dia_1,
        act_2, dia_2,
        act_3, dia_3
      ) VALUES (
        99999, 99, 1,
        2, 100,  -- JEFE DE LINEA (2 % 3 = 2 → San Valentín)
        3, 200,  -- JEFE DE EMPAQUE (3 % 3 = 0 → Santa Amalia)
        4, 300   -- CADENERO (4 % 3 = 1 → San Francisco)
      )
    ''');
    
    // Verificar que los ranchos se asignaron automáticamente
    final resultado = await db.connection.query('''
      SELECT 
        act_1, campo_1,
        act_2, campo_2,
        act_3, campo_3
      FROM nomina_empleados_historial 
      WHERE id_empleado = 99999 AND id_semana = 99
    ''');
    
    if (resultado.isNotEmpty) {
      final row = resultado.first;
      print('✅ Trigger funcionando:');
      print('  - Actividad ${row[0]} → Rancho ${row[1]} (esperado: 2-San Valentín)');
      print('  - Actividad ${row[2]} → Rancho ${row[3]} (esperado: 3-Santa Amalia)');
      print('  - Actividad ${row[4]} → Rancho ${row[5]} (esperado: 1-San Francisco)');
      
      // Verificar que las asignaciones son correctas
      final correcto1 = row[0] == 2 && row[1] == 2; // JEFE DE LINEA → San Valentín
      final correcto2 = row[2] == 3 && row[3] == 3; // JEFE DE EMPAQUE → Santa Amalia  
      final correcto3 = row[4] == 4 && row[5] == 1; // CADENERO → San Francisco
      
      if (correcto1 && correcto2 && correcto3) {
        print('\n🎉 ¡Trigger configurado CORRECTAMENTE!');
      } else {
        print('\n❌ Error en las asignaciones del trigger');
      }
    }
    
    // Limpiar registro de prueba
    await db.connection.execute('''
      DELETE FROM nomina_empleados_historial 
      WHERE id_empleado = 99999
    ''');
    
    print('\n🎉 ¡SISTEMA AUTOMÁTICO ACTIVADO!');
    print('📋 Ahora los ranchos se asignarán automáticamente para:');
    print('  ✅ Nuevas nóminas en nomina_empleados_historial');
    print('  ✅ Nuevas nóminas en nomina_empleados_semanal');
    print('  ✅ Actualizaciones de registros existentes');
    print('  ✅ Sin necesidad de ejecutar scripts manuales');
    print('\n📊 Reglas de asignación:');
    print('  🏞️ Actividades con ID % 3 = 1 → San Francisco');
    print('  🏞️ Actividades con ID % 3 = 2 → San Valentín');
    print('  🏞️ Actividades con ID % 3 = 0 → Santa Amalia');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
