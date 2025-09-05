// 🔧 Script de Debug para Problema de Cache de Cuadrillas
// Propósito: Diagnosticar por qué las cuadrillas no se conservan al cerrar semana con "mantener"

import 'dart:io';
import 'lib/services/database_service.dart';

Future<void> main() async {
  print('=== DIAGNÓSTICO PROBLEMA CONSERVAR CUADRILLAS ===\n');

  try {
    final db = DatabaseService();
    await db.connect();

    // 1. Verificar el problema específico del flujo "mantener"
    print('1️⃣ ANALIZANDO PROBLEMA DEL FLUJO "MANTENER"...\n');
    
    print('🔍 El problema reportado es:');
    print('   - Al cerrar semana y elegir "conservar/mantener cuadrillas"');
    print('   - Las cuadrillas NO se quedan guardadas en el sistema');
    print('   - Antes funcionaba por cache, pero ya no\n');

    // 2. Verificar semanas recientes
    print('2️⃣ VERIFICANDO SEMANAS RECIENTES...');
    await _verificarSemanas(db);

    // 3. Verificar asignaciones de empleados a cuadrillas
    print('\n3️⃣ VERIFICANDO ASIGNACIONES CUADRILLA-EMPLEADO...');
    await _verificarAsignaciones(db);

    // 4. Analizar el problema del cache
    print('\n4️⃣ ANALIZANDO PROBLEMA DEL CACHE...');
    _analizarProblemaCache();

    await db.close();
    print('\n✅ Diagnóstico completado');

  } catch (e) {
    print('❌ Error en diagnóstico: $e');
    exit(1);
  }
}

Future<void> _verificarSemanas(DatabaseService db) async {
  try {
    var connection = db.connection;
    
    var semanas = await connection.query('''
      SELECT id, fecha_inicio, fecha_fin, cerrada, cerrada_por, fecha_cierre
      FROM semanas
      ORDER BY fecha_inicio DESC
      LIMIT 5
    ''');

    print('📅 ÚLTIMAS 5 SEMANAS:');
    for (var semana in semanas) {
      print('   - ID: ${semana[0]}, Fechas: ${semana[1]} a ${semana[2]}');
      print('     Estado: ${semana[3] == true ? 'CERRADA' : 'ABIERTA'}');
      if (semana[3] == true) {
        print('     Cerrada por: ${semana[4]} el ${semana[5]}');
      }
    }

  } catch (e) {
    print('❌ Error verificando semanas: $e');
  }
}

Future<void> _verificarAsignaciones(DatabaseService db) async {
  try {
    var connection = db.connection;
    
    // Verificar asignaciones recientes
    var asignaciones = await connection.query('''
      SELECT cs.semana_id, cs.cuadrilla_id, cs.empleado_id,
             c.nombre as cuadrilla_nombre,
             e.nombre as empleado_nombre,
             s.fecha_inicio, s.fecha_fin
      FROM cuadrilla_semana cs
      JOIN cuadrillas c ON cs.cuadrilla_id = c.id
      JOIN empleados e ON cs.empleado_id = e.id
      JOIN semanas s ON cs.semana_id = s.id
      ORDER BY s.fecha_inicio DESC, c.nombre
      LIMIT 15
    ''');

    print('👥 ÚLTIMAS ASIGNACIONES EMPLEADO-CUADRILLA:');
    if (asignaciones.isNotEmpty) {
      String? semanaActual;
      for (var asig in asignaciones) {
        String fechas = '${asig[5]} a ${asig[6]}';
        if (semanaActual != fechas) {
          semanaActual = fechas;
          print('\n   📅 Semana: $fechas');
        }
        print('     - ${asig[3]}: ${asig[4]}');
      }
    } else {
      print('   ⚠️ NO HAY ASIGNACIONES REGISTRADAS');
      print('   💡 Esto podría indicar que el problema es en el guardado');
    }

    // Verificar cuadrillas sin empleados en semana actual
    var cuadrillasSinEmpleados = await connection.query('''
      SELECT c.nombre, c.id
      FROM cuadrillas c
      WHERE c.habilitado = true
      AND NOT EXISTS (
        SELECT 1 FROM cuadrilla_semana cs 
        JOIN semanas s ON cs.semana_id = s.id
        WHERE cs.cuadrilla_id = c.id 
        AND s.cerrada = false
      )
    ''');

    print('\n🚫 CUADRILLAS SIN EMPLEADOS EN SEMANA ABIERTA:');
    if (cuadrillasSinEmpleados.isNotEmpty) {
      for (var cuadrilla in cuadrillasSinEmpleados) {
        print('   - ${cuadrilla[0]} (ID: ${cuadrilla[1]})');
      }
    } else {
      print('   ✅ Todas las cuadrillas tienen empleados (o no hay semana abierta)');
    }

  } catch (e) {
    print('❌ Error verificando asignaciones: $e');
  }
}

void _analizarProblemaCache() {
  print('🔍 ANÁLISIS DEL PROBLEMA:');
  print('');
  print('📋 FLUJO ACTUAL "MANTENER CUADRILLAS":');
  print('   1. Usuario arma cuadrillas en _optionsCuadrilla');
  print('   2. Usuario cierra semana y elige "mantener"');
  print('   3. Sistema guarda cuadrillas en _cuadrillasTemporales');
  print('   4. Sistema resetea _optionsCuadrilla');
  print('   5. Usuario selecciona nueva semana');
  print('   6. Sistema debería copiar _cuadrillasTemporales a nueva semana');
  print('   7. Sistema debería cargar cuadrillas con empleados asignados');
  print('');
  print('🐛 POSIBLES PUNTOS DE FALLA:');
  print('   A. _cuadrillasTemporales se pierde entre cierre y nueva semana');
  print('   B. _copiarCuadrillasANuevaSemana() no se ejecuta correctamente');
  print('   C. Cache se invalida antes de copiar los datos');
  print('   D. No se guardan las asignaciones en tabla cuadrilla_semana');
  print('   E. _cargarEmpleadosDeCuadrillas() no encuentra los datos guardados');
  print('');
  print('🔧 PASOS PARA SOLUCIONAR:');
  print('   1. Verificar orden de ejecución en _cerrarSemanaActual()');
  print('   2. Asegurar que _cuadrillasTemporales persiste');
  print('   3. Verificar que _copiarCuadrillasANuevaSemana() se ejecuta');
  print('   4. Confirmar que se guardan datos en cuadrilla_semana');
  print('   5. No invalidar cache antes de copiar datos');
  print('');
  print('⚡ SOLUCIÓN PROPUESTA:');
  print('   - Mover _invalidarCacheCuadrillas() DESPUÉS de _copiarCuadrillasANuevaSemana()');
  print('   - Agregar más logs para rastrear _cuadrillasTemporales');
  print('   - Verificar que SemanaService.guardarEmpleadosCuadrillaSemana() funciona');
}
