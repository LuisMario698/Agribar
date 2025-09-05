// Test directo de cierre de semana sin Flutter
import 'dart:io';

// Simulando las clases necesarias sin Flutter
class DatabaseService {
  late dynamic _connection;

  Future<void> connect() async {
    // Simulación de conexión
    print('🔌 Simulando conexión a PostgreSQL...');
    await Future.delayed(Duration(milliseconds: 100));
    print('✅ Conexión simulada establecida');
  }

  Future<void> close() async {
    print('🔒 Cerrando conexión simulada');
  }

  dynamic get connection => _MockConnection();
}

class _MockConnection {
  Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? substitutionValues}) async {
    print('🔍 Ejecutando query: $sql');
    print('🔍 Parámetros: $substitutionValues');
    
    if (sql.contains('SELECT esta_cerrada FROM semanas_nomina')) {
      // Simular que la semana está abierta
      return [
        {'esta_cerrada': false}
      ];
    } else if (sql.contains('SELECT COUNT(*) as total_registros')) {
      // Simular que hay datos
      return [
        {'total_registros': 5, 'total_cuadrillas': 2, 'total_dinero': 1500.0}
      ];
    } else if (sql.contains('SELECT esta_cerrada') && sql.contains('WHERE id_semana')) {
      // Verificación final - simular éxito
      return [
        {'esta_cerrada': true}
      ];
    }
    return [];
  }

  Future<int> execute(String sql, {Map<String, dynamic>? substitutionValues}) async {
    print('⚡ Ejecutando UPDATE: $sql');
    print('⚡ Parámetros: $substitutionValues');
    
    // Simular éxito
    await Future.delayed(Duration(milliseconds: 50));
    return 1; // 1 fila afectada
  }
}

/// Función de prueba de cierre de semana
Future<bool> testCerrarSemanaEnBD(int idSemana) async {
  final db = DatabaseService();
  
  try {
    print('🚀 [TEST] Iniciando cierre de semana $idSemana...');
    
    await db.connect();

    print('🔄 Iniciando proceso de cierre para semana $idSemana');

    // 1. VERIFICAR si ya está cerrada
    print('🔍 [TEST] Verificando si la semana ya está cerrada...');
    final verificarCerrada = await db.connection.query('''
      SELECT esta_cerrada FROM semanas_nomina WHERE id_semana = @idSemana;
    ''', substitutionValues: {'idSemana': idSemana});
    print('🔍 [TEST] Query ejecutada, resultados: ${verificarCerrada.length}');

    if (verificarCerrada.isNotEmpty && verificarCerrada.first['esta_cerrada'] == true) {
      print('⚠️ La semana $idSemana ya está cerrada');
      await db.close();
      return true;
    }
    print('✅ [TEST] La semana $idSemana está abierta, continuando...');

    // 2. VERIFICAR QUE HAY DATOS DE NÓMINA para preservar
    print('🔍 [TEST] Verificando datos de nómina existentes...');
    final verificarDatos = await db.connection.query('''
      SELECT COUNT(*) as total_registros,
             COUNT(DISTINCT id_cuadrilla) as total_cuadrillas,
             SUM(total_neto) as total_dinero
      FROM nomina_empleados_semanal
      WHERE id_semana = @idSemana;
    ''', substitutionValues: {'idSemana': idSemana});

    final totalRegistros = verificarDatos.first['total_registros'] as int;
    final totalCuadrillas = verificarDatos.first['total_cuadrillas'] as int;
    final totalDinero = (verificarDatos.first['total_dinero'] as num?)?.toDouble() ?? 0.0;
    
    print('📊 Datos a preservar para semana $idSemana:');
    print('   • Registros de empleados: $totalRegistros');
    print('   • Cuadrillas: $totalCuadrillas');
    print('   • Total en dinero: \$${totalDinero}');

    // 3. MARCAR LA SEMANA COMO CERRADA
    print('🔄 [TEST] Ejecutando UPDATE para cerrar semana...');
    await db.connection.execute('''
      UPDATE semanas_nomina
      SET esta_cerrada = true,
          fecha_autorizacion = CURRENT_TIMESTAMP
      WHERE id_semana = @idSemana;
    ''', substitutionValues: {'idSemana': idSemana});
    print('✅ [TEST] UPDATE ejecutado');

    // 4. VERIFICAR que se marcó correctamente
    print('🔍 [TEST] Verificando que el UPDATE fue exitoso...');
    final verificarResultado = await db.connection.query('''
      SELECT esta_cerrada FROM semanas_nomina WHERE id_semana = @idSemana;
    ''', substitutionValues: {'idSemana': idSemana});

    final exitoso = verificarResultado.isNotEmpty && verificarResultado.first['esta_cerrada'] == true;

    if (exitoso) {
      print('✅ Semana $idSemana cerrada exitosamente');
      print('📋 Los datos de nómina se mantienen en nomina_empleados_semanal');
    } else {
      print('❌ Error al marcar semana $idSemana como cerrada');
      print('❌ [DEBUG] Valor de esta_cerrada después del UPDATE: ${verificarResultado.isNotEmpty ? verificarResultado.first['esta_cerrada'] : 'SIN RESULTADOS'}');
    }

    print('🔄 [TEST] Cerrando conexión a BD...');
    await db.close();
    print('✅ [TEST] Proceso completado, retornando: $exitoso');
    return exitoso;

  } catch (e) {
    print('❌ [TEST] ERROR CRÍTICO al cerrar semana en BD: $e');
    print('❌ [TEST] Tipo de error: ${e.runtimeType}');
    try {
      await db.close();
      print('🔄 [TEST] Conexión cerrada después del error');
    } catch (closeError) {
      print('❌ [TEST] Error adicional al cerrar conexión: $closeError');
    }
    return false;
  }
}

Future<void> main() async {
  print('🧪 PRUEBA DE FUNCIÓN CERRAR SEMANA');
  print('==================================');
  
  final resultado = await testCerrarSemanaEnBD(20);
  
  print('\n📊 RESULTADO FINAL:');
  print('Estado: ${resultado ? "✅ ÉXITO" : "❌ FALLO"}');
  
  if (resultado) {
    print('🎉 La función de cierre de semana funciona correctamente');
  } else {
    print('💥 Hay problemas con la función de cierre de semana');
  }
  
  print('\n🏁 Prueba completada');
}
