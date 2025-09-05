import 'package:agribar/services/database_service.dart';

Future<void> main() async {
  print('🧪 PRUEBA ESPECÍFICA DE CIERRE DE SEMANA');
  print('========================================');
  
  // Primero, verificar qué semanas están abiertas
  final db = DatabaseService();
  await db.connect();
  
  try {
    print('🔍 Verificando semanas abiertas...');
    final semanasAbiertas = await db.connection.query('''
      SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada
      FROM semanas_nomina
      WHERE esta_cerrada = false
      ORDER BY id_semana DESC;
    ''');
    
    print('📊 Semanas abiertas encontradas: ${semanasAbiertas.length}');
    
    if (semanasAbiertas.isEmpty) {
      print('⚠️ No hay semanas abiertas para probar el cierre');
      
      // Ver todas las semanas
      final todasSemanas = await db.connection.query('''
        SELECT id_semana, fecha_inicio, fecha_fin, esta_cerrada
        FROM semanas_nomina
        ORDER BY id_semana DESC
        LIMIT 5;
      ''');
      
      print('\n📋 Últimas 5 semanas en BD:');
      for (final semana in todasSemanas) {
        final estado = semana[3] == true ? 'CERRADA' : 'ABIERTA';
        print('  - ID: ${semana[0]}, ${semana[1]} a ${semana[2]}, Estado: $estado');
      }
      
    } else {
      // Tomar la primera semana abierta para probar
      final semanaAPrueba = semanasAbiertas.first;
      final idSemana = semanaAPrueba[0] as int;
      
      print('🎯 Probando cierre de semana ID: $idSemana');
      print('   Fechas: ${semanaAPrueba[1]} a ${semanaAPrueba[2]}');
      
      await db.close(); // Cerrar la conexión actual antes de la prueba
      
      // Probar la función cerrarSemanaEnBD directamente
      print('\n🚀 Ejecutando cerrarSemanaEnBD($idSemana)...');
      final resultado = await cerrarSemanaEnBD(idSemana);
      
      print('\n🔍 Resultado final: $resultado');
      
      if (resultado) {
        print('✅ La función reportó éxito');
      } else {
        print('❌ La función reportó fallo');
      }
      
      // Verificar el estado final en la BD
      final dbVerificacion = DatabaseService();
      await dbVerificacion.connect();
      
      final estadoFinal = await dbVerificacion.connection.query('''
        SELECT esta_cerrada, fecha_autorizacion
        FROM semanas_nomina
        WHERE id_semana = $idSemana;
      ''');
      
      if (estadoFinal.isNotEmpty) {
        final cerrada = estadoFinal.first[0] as bool;
        final fechaAuth = estadoFinal.first[1];
        print('\n🔍 Estado actual en BD:');
        print('  - esta_cerrada: $cerrada');
        print('  - fecha_autorizacion: $fechaAuth');
      }
      
      await dbVerificacion.close();
    }
    
  } catch (e) {
    print('❌ ERROR en la prueba: $e');
    print('   Tipo: ${e.runtimeType}');
    print('   Stack: ${StackTrace.current}');
  } finally {
    try {
      await db.close();
    } catch (_) {}
  }
  
  print('\n🏁 Prueba completada');
}
