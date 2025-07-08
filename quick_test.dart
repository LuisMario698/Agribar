// Verificación rápida de estructura de datos

import 'lib/services/database_service.dart';

void main() async {
  print("Verificando obtenerCuadrillasHabilitadas()...");
  
  final result = await obtenerCuadrillasHabilitadas();
  print("Cantidad: ${result.length}");
  
  if (result.isNotEmpty) {
    print("Primera cuadrilla: ${result[0]}");
    print("Claves: ${result[0].keys.toList()}");
  }
}
