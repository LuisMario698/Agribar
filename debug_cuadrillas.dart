// Script para diagnosticar por qué no aparecen cuadrillas
// Verificará la conexión, datos y consultas

import 'lib/services/database_service.dart';

void main() async {
  print("=== DIAGNÓSTICO CUADRILLAS ===");
  print("Verificando por qué no aparecen cuadrillas...");
  print("");
  
  final db = DatabaseService();
  
  try {
    // 1. Probar conexión
    print("1. 🔌 PROBANDO CONEXIÓN A BD...");
    await db.connect();
    print("   ✅ Conexión exitosa a PostgreSQL");
    print("");
    
    // 2. Verificar tabla cuadrillas existe
    print("2. 📋 VERIFICANDO TABLA CUADRILLAS...");
    final tablesResult = await db.connection.query('''
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'cuadrillas';
    ''');
    
    if (tablesResult.isEmpty) {
      print("   ❌ ERROR: La tabla 'cuadrillas' no existe!");
      await db.close();
      return;
    } else {
      print("   ✅ Tabla 'cuadrillas' existe");
    }
    print("");
    
    // 3. Verificar estructura de tabla
    print("3. 🏗️ ESTRUCTURA DE TABLA CUADRILLAS...");
    final columnsResult = await db.connection.query('''
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns 
      WHERE table_name = 'cuadrillas' AND table_schema = 'public'
      ORDER BY ordinal_position;
    ''');
    
    for (var row in columnsResult) {
      print("   - ${row[0]} (${row[1]}) - Null: ${row[2]}");
    }
    print("");
    
    // 4. Contar registros totales
    print("4. 📊 CONTEO TOTAL DE CUADRILLAS...");
    final countResult = await db.connection.query('''
      SELECT COUNT(*) FROM cuadrillas;
    ''');
    final totalCuadrillas = countResult[0][0];
    print("   Total de cuadrillas en BD: $totalCuadrillas");
    print("");
    
    // 5. Verificar registros con estado
    print("5. 🔍 ANÁLISIS POR ESTADO...");
    final estadoResult = await db.connection.query('''
      SELECT 
        estado,
        COUNT(*) as cantidad
      FROM cuadrillas 
      GROUP BY estado
      ORDER BY estado;
    ''');
    
    for (var row in estadoResult) {
      print("   - Estado ${row[0] ?? 'NULL'}: ${row[1]} cuadrillas");
    }
    print("");
    
    // 6. Mostrar todas las cuadrillas
    print("6. 📋 LISTADO COMPLETO DE CUADRILLAS...");
    final allResult = await db.connection.query('''
      SELECT id_cuadrilla, clave, nombre, grupo, actividad, estado
      FROM cuadrillas 
      ORDER BY id_cuadrilla;
    ''');
    
    if (allResult.isEmpty) {
      print("   ❌ No hay cuadrillas en la base de datos!");
    } else {
      for (var row in allResult) {
        print("   - ID: ${row[0]} | Clave: ${row[1]} | Nombre: ${row[2]} | Estado: ${row[5]}");
      }
    }
    print("");
    
    // 7. Ejecutar consulta exacta de obtenerCuadrillasHabilitadas
    print("7. 🎯 CONSULTA FUNCIÓN obtenerCuadrillasHabilitadas...");
    final funcionResult = await db.connection.query('''
      SELECT id_cuadrilla, nombre
      FROM cuadrillas
      WHERE estado = true
      ORDER BY nombre;
    ''');
    
    print("   Cuadrillas habilitadas encontradas: ${funcionResult.length}");
    if (funcionResult.isEmpty) {
      print("   ❌ La consulta no devuelve cuadrillas habilitadas!");
      print("   💡 Esto significa que no hay cuadrillas con estado = true");
    } else {
      for (var row in funcionResult) {
        print("   - ID: ${row[0]} | Nombre: ${row[1]}");
      }
    }
    print("");
    
    // 8. Sugerencias de solución
    if (funcionResult.isEmpty && allResult.isNotEmpty) {
      print("8. 🔧 SOLUCIÓN SUGERIDA:");
      print("   Las cuadrillas existen pero tienen estado = false o NULL");
      print("   Ejecuta este comando para habilitar todas las cuadrillas:");
      print("   UPDATE cuadrillas SET estado = true WHERE estado IS NULL OR estado = false;");
    } else if (allResult.isEmpty) {
      print("8. 🔧 SOLUCIÓN SUGERIDA:");
      print("   No hay cuadrillas en la base de datos.");
      print("   Ve a la pantalla 'Cuadrillas' y crea algunas cuadrillas nuevas.");
    } else {
      print("8. ✅ TODO PARECE ESTAR BIEN:");
      print("   Las cuadrillas existen y están habilitadas.");
      print("   El problema podría estar en la interfaz de usuario.");
    }
    
  } catch (e) {
    print("❌ ERROR AL CONECTAR O CONSULTAR BD: $e");
  } finally {
    await db.close();
  }
  
  print("");
  print("=== FIN DEL DIAGNÓSTICO ===");
}
