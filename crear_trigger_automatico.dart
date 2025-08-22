import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🔧 Creando trigger automático para asignación de ranchos...');
  
  final db = DatabaseService();
  await db.connect();
  
  try {
    print('📋 1. Creando función para asignar ranchos automáticamente...');
    
    // Crear la función que asigna ranchos
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
    
    print('✅ Función creada exitosamente');
    
    print('\n📋 2. Eliminando trigger anterior si existe...');
    await db.connection.execute('''
      DROP TRIGGER IF EXISTS trigger_asignar_ranchos ON nomina_empleados_historial;
    ''');
    
    print('\n📋 3. Creando trigger automático...');
    await db.connection.execute('''
      CREATE TRIGGER trigger_asignar_ranchos
        BEFORE INSERT OR UPDATE ON nomina_empleados_historial
        FOR EACH ROW
        EXECUTE FUNCTION asignar_ranchos_automaticamente();
    ''');
    
    print('✅ Trigger creado exitosamente');
    
    print('\n🧪 4. Probando el trigger con un registro de prueba...');
    
    // Verificar que no existe el registro de prueba
    await db.connection.execute('''
      DELETE FROM nomina_empleados_historial 
      WHERE id_empleado = 99999 AND id_semana = 99
    ''');
    
    // Insertar un registro de prueba
    await db.connection.execute('''
      INSERT INTO nomina_empleados_historial (
        id_empleado, id_semana, cuadrilla,
        act_1, dia_1,
        act_2, dia_2,
        act_3, dia_3
      ) VALUES (
        99999, 99, 'TEST',
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
        print('\n🎉 ¡Trigger configurado correctamente!');
      } else {
        print('\n❌ Error en las asignaciones del trigger');
      }
    }
    
    // Limpiar registro de prueba
    await db.connection.execute('''
      DELETE FROM nomina_empleados_historial 
      WHERE id_empleado = 99999 AND id_semana = 99
    ''');
    
    print('\n📋 5. Aplicando el trigger a registros existentes sin ranchos...');
    
    // Actualizar registros existentes que no tienen ranchos asignados
    final updated = await db.connection.execute('''
      UPDATE nomina_empleados_historial 
      SET 
        campo_1 = campo_1,  -- Esto activará el trigger
        updated_at = NOW()
      WHERE (campo_1 = 0 OR campo_1 IS NULL OR
             campo_2 = 0 OR campo_2 IS NULL OR
             campo_3 = 0 OR campo_3 IS NULL OR
             campo_4 = 0 OR campo_4 IS NULL OR
             campo_5 = 0 OR campo_5 IS NULL OR
             campo_6 = 0 OR campo_6 IS NULL OR
             campo_7 = 0 OR campo_7 IS NULL)
        AND (act_1 <> 0 OR act_2 <> 0 OR act_3 <> 0 OR act_4 <> 0 OR 
             act_5 <> 0 OR act_6 <> 0 OR act_7 <> 0)
    ''');
    
    print('✅ Registros actualizados: $updated');
    
    print('\n🎉 ¡Sistema automático configurado exitosamente!');
    print('📋 Ahora los ranchos se asignarán automáticamente para:');
    print('  - Nuevas nóminas que se creen');
    print('  - Registros existentes que se actualicen');
    print('  - Sin necesidad de ejecutar scripts manuales');
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
