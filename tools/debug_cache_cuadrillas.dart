// 🔧 Script de Debug para Cache de Cuadrillas y Función "Mantener"
// Propósito: Diagnosticar por qué las cuadrillas no se conservan al cerrar semana con "mantener"

import 'dart:io';
import 'lib/services/database_service.dart';

Future<void> main() async {
  print('=== DIAGNÓSTICO CACHE CUADRILLAS Y FUNCIÓN MANTENER ===\n');

  try {
    final db = DatabaseService();
    await db.connect();

    // 1. Verificar estructura de datos de cuadrillas
    print('1️⃣ VERIFICANDO ESTRUCTURA DE CUADRILLAS...');
    await _verificarEstructuraCuadrillas(db);

    // 2. Verificar cómo se guardan empleados en cuadrillas por semana
    print('\n2️⃣ VERIFICANDO GUARDADO DE EMPLEADOS EN CUADRILLAS...');
    await _verificarGuardadoEmpleados(db);

    // 3. Verificar si hay datos de semanas anteriores mantenidos
    print('\n3️⃣ VERIFICANDO DATOS DE SEMANAS ANTERIORES...');
    await _verificarDatosSemanas(db);

    // 4. Simular flujo de "mantener cuadrillas"
    print('\n4️⃣ SIMULANDO FLUJO DE MANTENER CUADRILLAS...');
    await _simularFlujoMantener(db);

    await db.close();
    print('\n✅ Diagnóstico completado');

  } catch (e) {
    print('❌ Error en diagnóstico: $e');
    exit(1);
  }
}

Future<void> _verificarEstructuraCuadrillas(DatabaseService db) async {
  try {
    // Verificar tabla cuadrillas
    var result = await db.connection.query('''
      SELECT c.*, 
             COUNT(cs.empleado_id) as empleados_asignados
      FROM cuadrillas c
      LEFT JOIN cuadrilla_semana cs ON c.id = cs.cuadrilla_id
      WHERE c.habilitado = true
      GROUP BY c.id, c.nombre, c.habilitado
      ORDER BY c.nombre
    ''');

    print('📋 CUADRILLAS HABILITADAS:');
    for (var cuadrilla in result) {
      print('   - ID: ${cuadrilla[0]}, Nombre: ${cuadrilla[1]}, Empleados: ${cuadrilla[3]}');
    }

  } catch (e) {
    print('❌ Error verificando cuadrillas: $e');
  }
}

Future<void> _verificarGuardadoEmpleados(DatabaseService db) async {
  try {
    // Verificar tabla cuadrilla_semana (donde se guardan las asignaciones)
    var result = await db.query('''
      SELECT cs.*, 
             c.nombre as cuadrilla_nombre,
             s.fecha_inicio, s.fecha_fin,
             e.nombre as empleado_nombre
      FROM cuadrilla_semana cs
      JOIN cuadrillas c ON cs.cuadrilla_id = c.id
      JOIN semanas s ON cs.semana_id = s.id
      JOIN empleados e ON cs.empleado_id = e.id
      ORDER BY s.fecha_inicio DESC, c.nombre, e.nombre
      LIMIT 20
    ''');

    print('📊 ÚLTIMAS ASIGNACIONES EMPLEADO-CUADRILLA-SEMANA:');
    if (result.isNotEmpty) {
      for (var asignacion in result) {
        print('   - Semana: ${asignacion['fecha_inicio']} a ${asignacion['fecha_fin']}');
        print('     Cuadrilla: ${asignacion['cuadrilla_nombre']}');
        print('     Empleado: ${asignacion['empleado_nombre']}');
        print('     ID Registro: ${asignacion['id']}');
        print('');
      }
    } else {
      print('   ⚠️ No hay asignaciones registradas en cuadrilla_semana');
    }

  } catch (e) {
    print('❌ Error verificando guardado de empleados: $e');
  }
}

Future<void> _verificarDatosSemanas(DatabaseService db) async {
  try {
    // Verificar semanas recientes y su estado
    var result = await db.query('''
      SELECT s.*, 
             COUNT(cs.empleado_id) as empleados_asignados,
             COUNT(DISTINCT cs.cuadrilla_id) as cuadrillas_con_empleados
      FROM semanas s
      LEFT JOIN cuadrilla_semana cs ON s.id = cs.semana_id
      GROUP BY s.id, s.fecha_inicio, s.fecha_fin, s.cerrada, s.cerrada_por, s.fecha_cierre
      ORDER BY s.fecha_inicio DESC
      LIMIT 10
    ''');

    print('📅 ÚLTIMAS SEMANAS:');
    for (var semana in result) {
      print('   - ID: ${semana['id']}');
      print('     Fechas: ${semana['fecha_inicio']} a ${semana['fecha_fin']}');
      print('     Estado: ${semana['cerrada'] == true ? 'CERRADA' : 'ABIERTA'}');
      if (semana['cerrada'] == true) {
        print('     Cerrada por: ${semana['cerrada_por']} el ${semana['fecha_cierre']}');
      }
      print('     Empleados asignados: ${semana['empleados_asignados']}');
      print('     Cuadrillas con empleados: ${semana['cuadrillas_con_empleados']}');
      print('');
    }

  } catch (e) {
    print('❌ Error verificando datos de semanas: $e');
  }
}

Future<void> _simularFlujoMantener(DatabaseService db) async {
  try {
    // Verificar si existe una semana cerrada reciente
    var semanaCerrada = await db.query('''
      SELECT s.*, 
             COUNT(cs.empleado_id) as empleados_mantenidos
      FROM semanas s
      LEFT JOIN cuadrilla_semana cs ON s.id = cs.semana_id
      WHERE s.cerrada = true
      GROUP BY s.id, s.fecha_inicio, s.fecha_fin, s.cerrada, s.cerrada_por, s.fecha_cierre
      ORDER BY s.fecha_cierre DESC
      LIMIT 1
    ''');

    if (semanaCerrada.isEmpty) {
      print('⚠️ No hay semanas cerradas para simular el flujo');
      return;
    }

    var ultimaSemanaCerrada = semanaCerrada.first;
    print('🔍 ANALIZANDO ÚLTIMA SEMANA CERRADA:');
    print('   - ID: ${ultimaSemanaCerrada['id']}');
    print('   - Fechas: ${ultimaSemanaCerrada['fecha_inicio']} a ${ultimaSemanaCerrada['fecha_fin']}');
    print('   - Empleados que se deberían mantener: ${ultimaSemanaCerrada['empleados_mantenidos']}');

    // Verificar si existe una semana posterior que haya heredado esos empleados
    var semanasPosterior = await db.query('''
      SELECT s.*, 
             COUNT(cs.empleado_id) as empleados_actuales
      FROM semanas s
      LEFT JOIN cuadrilla_semana cs ON s.id = cs.semana_id
      WHERE s.fecha_inicio > ?
      GROUP BY s.id, s.fecha_inicio, s.fecha_fin, s.cerrada
      ORDER BY s.fecha_inicio ASC
      LIMIT 3
    ''', [ultimaSemanaCerrada['fecha_fin']]);

    print('\n🔄 SEMANAS POSTERIORES:');
    if (semanasPosterior.isNotEmpty) {
      for (var semana in semanasPosterior) {
        print('   - ID: ${semana['id']}');
        print('     Fechas: ${semana['fecha_inicio']} a ${semana['fecha_fin']}');
        print('     Empleados actuales: ${semana['empleados_actuales']}');
        print('     Estado: ${semana['cerrada'] == true ? 'CERRADA' : 'ABIERTA'}');
        
        // Verificar si los empleados coinciden (indicaría que se mantuvieron)
        if (semana['empleados_actuales'] > 0) {
          var empleadosDetalle = await db.query('''
            SELECT c.nombre as cuadrilla, e.nombre as empleado
            FROM cuadrilla_semana cs
            JOIN cuadrillas c ON cs.cuadrilla_id = c.id
            JOIN empleados e ON cs.empleado_id = e.id
            WHERE cs.semana_id = ?
            ORDER BY c.nombre, e.nombre
          ''', [semana['id']]);
          
          print('     Empleados asignados:');
          for (var emp in empleadosDetalle) {
            print('       - ${emp['cuadrilla']}: ${emp['empleado']}');
          }
        }
        print('');
      }
    } else {
      print('   ⚠️ No hay semanas posteriores');
    }

    // Verificar si hay cuadrillas "huérfanas" sin empleados
    var cuadrillasSinEmpleados = await db.query('''
      SELECT c.nombre, c.id
      FROM cuadrillas c
      WHERE c.habilitado = true
      AND NOT EXISTS (
        SELECT 1 FROM cuadrilla_semana cs 
        WHERE cs.cuadrilla_id = c.id 
        AND cs.semana_id = (SELECT id FROM semanas WHERE cerrada = false ORDER BY fecha_inicio DESC LIMIT 1)
      )
    ''');

    print('\n🚫 CUADRILLAS SIN EMPLEADOS EN SEMANA ACTUAL:');
    if (cuadrillasSinEmpleados.isNotEmpty) {
      for (var cuadrilla in cuadrillasSinEmpleados) {
        print('   - ${cuadrilla['nombre']} (ID: ${cuadrilla['id']})');
      }
      print('\n💡 Estas cuadrillas podrían indicar que la función "mantener" no está funcionando correctamente');
    } else {
      print('   ✅ Todas las cuadrillas tienen empleados asignados');
    }

  } catch (e) {
    print('❌ Error simulando flujo mantener: $e');
  }
}
