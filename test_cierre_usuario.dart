// Test para verificar que el cierre de semana registra correctamente el usuario
import 'lib/services/database_service.dart';

void main() async {
  print('🧪 Iniciando test de cierre de semana con usuario específico...');
  
  try {
    // Probar el cierre de semana con un usuario específico
    final testUsuario = 'USUARIO_TEST_MARIO';
    final testSemanaId = 20; // Usar una semana de prueba
    
    print('📋 Parámetros de prueba:');
    print('   - Usuario: $testUsuario');
    print('   - Semana ID: $testSemanaId');
    
    // Llamar a la función de cierre con el usuario específico
    final resultado = await cerrarSemanaEnBD(testSemanaId, autorizadoPor: testUsuario);
    
    print('🔄 Resultado del cierre: $resultado');
    
    if (resultado) {
      print('✅ El cierre fue exitoso');
      
      // Verificar que el usuario se guardó correctamente
      final db = DatabaseService();
      await db.connect();
      
      final verificacion = await db.connection.query('''
        SELECT autorizado_por, fecha_autorizacion, esta_cerrada
        FROM semanas_nomina 
        WHERE id_semana = @semanaId;
      ''', substitutionValues: {'semanaId': testSemanaId});
      
      if (verificacion.isNotEmpty) {
        final autorizadoPor = verificacion.first[0];
        final fechaAutorizacion = verificacion.first[1];
        final estaCerrada = verificacion.first[2];
        
        print('📊 Verificación en base de datos:');
        print('   - autorizado_por: $autorizadoPor');
        print('   - fecha_autorizacion: $fechaAutorizacion');
        print('   - esta_cerrada: $estaCerrada');
        
        if (autorizadoPor == testUsuario) {
          print('✅ ¡EL USUARIO SE GUARDÓ CORRECTAMENTE!');
        } else {
          print('❌ ERROR: El usuario guardado ($autorizadoPor) no coincide con el esperado ($testUsuario)');
        }
      } else {
        print('❌ ERROR: No se encontró la semana en la base de datos');
      }
      
      await db.close();
    } else {
      print('❌ El cierre falló');
    }
    
  } catch (e) {
    print('❌ Error en el test: $e');
  }
  
  print('🧪 Test completado');
}
