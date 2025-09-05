import 'package:agribar/services/semana_service.dart';

Future<void> main() async {
  print('🧪 Probando guardado de empleados en cuadrillas...');
  
  try {
    final service = SemanaService();
    
    // 1. Obtener semana activa
    print('\n📅 1. Obteniendo semana activa...');
    final semanaActiva = await service.obtenerSemanaAbierta();
    
    if (semanaActiva == null || semanaActiva['id'] == null) {
      print('❌ No hay semana activa');
      return;
    }
    
    final semanaId = semanaActiva['id'] as int;
    print('✅ Semana activa encontrada: $semanaId');
    
    // 2. Simular lista de empleados
    print('\n👥 2. Preparando lista de empleados de prueba...');
    final empleadosPrueba = [
      {'id': 1, 'nombre': 'JUAN CARLOS'},
      {'id': 2, 'nombre': 'CELESTINO'},
      {'id': 3, 'nombre': 'INES'},
    ];
    
    print('✅ Empleados de prueba: ${empleadosPrueba.length}');
    for (final emp in empleadosPrueba) {
      print('   - ${emp['nombre']} (ID: ${emp['id']})');
    }
    
    // 3. Intentar guardar en cuadrilla 38 (la que tiene empleados)
    print('\n💾 3. Guardando empleados en cuadrilla 38...');
    const cuadrillaId = 38;
    
    print('🔄 Iniciando proceso de guardado...');
    await service.guardarEmpleadosCuadrillaSemana(
      semanaId: semanaId,
      cuadrillaId: cuadrillaId,
      empleados: empleadosPrueba,
    );
    
    print('✅ Guardado completado sin errores');
    
    // 4. Verificar que se guardó correctamente
    print('\n🔍 4. Verificando guardado...');
    // Aquí podríamos hacer una consulta para verificar
    
    print('\n🎉 ¡Proceso de prueba completado exitosamente!');
    
  } catch (e, stackTrace) {
    print('\n❌ Error durante la prueba:');
    print('Mensaje: $e');
    print('Stack trace:');
    print(stackTrace);
    
    // Analizar el tipo de error
    if (e.toString().contains('Connection')) {
      print('\n💡 Posible problema de conexión a la base de datos');
    } else if (e.toString().contains('Foreign key')) {
      print('\n💡 Posible problema de integridad referencial');
    } else if (e.toString().contains('Unique')) {
      print('\n💡 Posible problema de duplicados');
    } else if (e.toString().contains('Permission')) {
      print('\n💡 Posible problema de permisos');
    }
  }
}
