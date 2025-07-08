// Test simple para verificar obtenerCuadrillasHabilitadas

import 'lib/services/database_service.dart';

void main() async {
  print("=== TEST SIMPLE CUADRILLAS ===");
  
  try {
    print("🔍 Llamando obtenerCuadrillasHabilitadas()...");
    final resultado = await obtenerCuadrillasHabilitadas();
    
    print("✅ Resultado obtenido:");
    print("   Cantidad: ${resultado.length}");
    print("   Tipo: ${resultado.runtimeType}");
    
    if (resultado.isEmpty) {
      print("❌ PROBLEMA: Lista vacía");
    } else {
      print("📋 Elementos:");
      for (int i = 0; i < resultado.length; i++) {
        print("   [$i] ${resultado[i]}");
        print("       Tipo elemento: ${resultado[i].runtimeType}");
        print("       Claves: ${resultado[i].keys.toList()}");
      }
    }
    
  } catch (e, stackTrace) {
    print("❌ ERROR: $e");
    print("📍 Stack trace: $stackTrace");
  }
  
  print("=== FIN TEST ===");
}
