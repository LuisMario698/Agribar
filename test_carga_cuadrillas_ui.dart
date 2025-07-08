// Test específico para verificar la carga de cuadrillas en la UI
// Simula exactamente lo que hace _cargarCuadrillasHabilitadas()

import 'lib/services/database_service.dart';

void main() async {
  print("=== TEST CARGA CUADRILLAS UI ===");
  print("Simulando función _cargarCuadrillasHabilitadas()...");
  print("");
  
  try {
    // Simular exactamente lo que hace la función
    final cuadrillasBD = await obtenerCuadrillasHabilitadas();
    
    print("📊 RESULTADO DE obtenerCuadrillasHabilitadas():");
    print("   Cantidad de cuadrillas: ${cuadrillasBD.length}");
    print("");
    
    if (cuadrillasBD.isEmpty) {
      print("❌ PROBLEMA: No se obtuvieron cuadrillas");
      print("   La función retorna una lista vacía");
    } else {
      print("✅ CUADRILLAS OBTENIDAS:");
      for (var i = 0; i < cuadrillasBD.length; i++) {
        var cuadrilla = cuadrillasBD[i];
        print("   ${i + 1}. ${cuadrilla}");
      }
    }
    
    print("");
    print("🔍 VERIFICACIÓN DE ESTRUCTURA:");
    if (cuadrillasBD.isNotEmpty) {
      var primera = cuadrillasBD[0];
      print("   Estructura de la primera cuadrilla:");
      primera.forEach((key, value) {
        print("     - $key: $value (${value.runtimeType})");
      });
      
      // Verificar si tiene las claves esperadas
      List<String> clavesEsperadas = ['id_cuadrilla', 'nombre'];
      print("");
      print("   Verificando claves esperadas:");
      for (String clave in clavesEsperadas) {
        bool tiene = primera.containsKey(clave);
        print("     - $clave: ${tiene ? '✅' : '❌'}");
      }
    }
    
    print("");
    print("📋 SIMULACIÓN DE setState:");
    print("   _optionsCuadrilla.clear()");
    print("   _optionsCuadrilla.addAll(cuadrillasBD)");
    print("   Resultado: _optionsCuadrilla tendrá ${cuadrillasBD.length} elementos");
    
  } catch (e) {
    print("❌ ERROR EN LA FUNCIÓN: $e");
    print("   Esto explicaría por qué no aparecen las cuadrillas");
  }
  
  print("");
  print("=== FIN DEL TEST ===");
}
