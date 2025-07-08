import 'package:flutter/material.dart';
import 'lib/services/database_service.dart';

void main() async {
  print('🚀 === PRUEBA FINAL - CARGA DE CUADRILLAS ===');
  
  try {
    // Simular la inicialización de Flutter para plugins nativos
    WidgetsFlutterBinding.ensureInitialized();
    
    print('\n1. Probando obtenerCuadrillasHabilitadas()...');
    final cuadrillas = await obtenerCuadrillasHabilitadas();
    
    print('✅ Cuadrillas obtenidas: ${cuadrillas.length}');
    print('📋 Lista de cuadrillas:');
    for (var i = 0; i < cuadrillas.length; i++) {
      final cuadrilla = cuadrillas[i];
      print('   ${i + 1}. ${cuadrilla['nombre']} (ID: ${cuadrilla['id']})');
    }
    
    print('\n2. Simulando el flujo de carga en Nomina_screen...');
    List<Map<String, dynamic>> _optionsCuadrilla = [];
    
    // Simular _cargarCuadrillasHabilitadas()
    print('   - Limpiando lista...');
    _optionsCuadrilla.clear();
    
    print('   - Agregando cuadrillas de BD...');
    _optionsCuadrilla.addAll(cuadrillas);
    
    print('✅ _optionsCuadrilla tiene ${_optionsCuadrilla.length} elementos');
    print('📋 Cuadrillas disponibles para dropdown:');
    for (var i = 0; i < _optionsCuadrilla.length; i++) {
      final cuadrilla = _optionsCuadrilla[i];
      print('   ${i + 1}. ${cuadrilla['nombre']} (ID: ${cuadrilla['id']})');
    }
    
    print('\n✅ RESULTADO: Las cuadrillas deberían aparecer correctamente en el dropdown');
    
  } catch (e) {
    print('❌ Error durante la prueba: $e');
  }
}
