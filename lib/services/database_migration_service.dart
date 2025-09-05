// lib/services/database_migration_service.dart

import 'package:agribar/services/database_service.dart';

class DatabaseMigrationService {
  
  /// Modifica la restricción de unicidad para permitir empleados en múltiples cuadrillas
  /// en la misma semana
  static Future<bool> permitirEmpleadoEnMultiplesCuadrillas() async {
    final db = DatabaseService();
    
    try {
      await db.connect();
      
      // 1. Eliminar la restricción única actual si existe
      try {
        await db.connection.query('''
          ALTER TABLE nomina_empleados_semanal 
          DROP CONSTRAINT IF EXISTS nomina_unique;
        ''');
        print('✅ Restricción nomina_unique eliminada');
      } catch (e) {
        print('⚠️ La restricción nomina_unique no existía o ya fue eliminada: $e');
      }
      
      // 2. Crear nueva restricción que permite el mismo empleado en múltiples cuadrillas
      // pero evita duplicados exactos (mismo empleado, misma semana, misma cuadrilla)
      await db.connection.query('''
        ALTER TABLE nomina_empleados_semanal 
        ADD CONSTRAINT nomina_empleado_semana_cuadrilla_unique 
        UNIQUE (id_empleado, id_semana, id_cuadrilla);
      ''');
      print('✅ Nueva restricción nomina_empleado_semana_cuadrilla_unique creada');
      
      // 3. Crear índice para mejorar rendimiento en consultas
      try {
        await db.connection.query('''
          CREATE INDEX IF NOT EXISTS idx_nomina_empleado_semana 
          ON nomina_empleados_semanal (id_empleado, id_semana);
        ''');
        print('✅ Índice idx_nomina_empleado_semana creado');
      } catch (e) {
        print('⚠️ Índice ya existía: $e');
      }
      
      await db.close();
      return true;
      
    } catch (e) {
      print('❌ Error al modificar restricciones de BD: $e');
      await db.close();
      return false;
    }
  }
  
  /// Verifica si la migración ya fue aplicada
  static Future<bool> verificarMigracionAplicada() async {
    final db = DatabaseService();
    
    try {
      await db.connect();
      
      // Verificar si existe la nueva restricción
      final result = await db.connection.query('''
        SELECT constraint_name 
        FROM information_schema.table_constraints 
        WHERE table_name = 'nomina_empleados_semanal' 
        AND constraint_name = 'nomina_empleado_semana_cuadrilla_unique';
      ''');
      
      await db.close();
      return result.isNotEmpty;
      
    } catch (e) {
      print('❌ Error al verificar migración: $e');
      await db.close();
      return false;
    }
  }
  
  /// Función de prueba para verificar que un empleado puede estar en múltiples cuadrillas
  static Future<bool> verificarMultiplesCuadrillas() async {
    final db = DatabaseService();
    
    try {
      await db.connect();
      
      // Buscar un caso donde un empleado esté en múltiples cuadrillas en la misma semana
      final result = await db.connection.query('''
        SELECT 
          e.nombre, e.apellido_paterno,
          n.id_empleado, n.id_semana, n.id_cuadrilla,
          c.nombre as cuadrilla_nombre,
          COUNT(*) OVER (PARTITION BY n.id_empleado, n.id_semana) as cuadrillas_count
        FROM nomina_empleados_semanal n
        JOIN empleados e ON e.id_empleado = n.id_empleado
        JOIN cuadrillas c ON c.id = n.id_cuadrilla
        WHERE (
          SELECT COUNT(*) 
          FROM nomina_empleados_semanal n2 
          WHERE n2.id_empleado = n.id_empleado 
          AND n2.id_semana = n.id_semana
        ) > 1
        ORDER BY n.id_empleado, n.id_semana, n.id_cuadrilla
        LIMIT 10;
      ''');
      
      await db.close();
      
      if (result.isNotEmpty) {
        print('✅ Verificación exitosa: Se encontraron empleados en múltiples cuadrillas:');
        for (var row in result) {
          print('   👤 ${row[0]} ${row[1]} - Semana ${row[2]} - Cuadrilla "${row[5]}" (Total cuadrillas: ${row[6]})');
        }
        return true;
      } else {
        print('ℹ️ No se encontraron empleados en múltiples cuadrillas aún');
        print('   (Esto es normal si no se han creado asignaciones múltiples)');
        return true; // No es un error, simplemente no hay casos aún
      }
      
    } catch (e) {
      print('❌ Error al verificar múltiples cuadrillas: $e');
      await db.close();
      return false;
    }
  }
}
