// Script de debug para verificar el guardado/carga de nómina
// Este archivo ayuda a identificar el problema en la persistencia de datos

void main() {
  print("=== DEBUG NÓMINA ===");
  print("Problema: Los datos no persisten entre guardado y carga");
  print("");
  
  print("MAPEO GUARDADO (Tabla → BD):");
  print("dia_0_s (tabla) → dia_1 (BD)");
  print("dia_0_id (tabla) → act_1 (BD)");
  print("dia_1_s (tabla) → dia_2 (BD)");
  print("dia_1_id (tabla) → act_2 (BD)");
  print("...");
  print("");
  
  print("MAPEO CARGA (BD → Tabla):");
  print("dia_1 (BD) → dia_0_s (tabla)");
  print("act_1 (BD) → dia_0_id (tabla)");
  print("dia_2 (BD) → dia_1_s (tabla)");
  print("act_2 (BD) → dia_1_id (tabla)");
  print("...");
  print("");
  
  print("POSIBLES PROBLEMAS:");
  print("1. Tipos de datos inconsistentes (int vs string)");
  print("2. Campos que no se inicializan correctamente");
  print("3. Conversión de tipos errónea");
  print("4. ID de empleado, semana o cuadrilla incorrectos");
  print("");
  
  print("SOLUCIÓN:");
  print("1. Asegurar mapeo bidireccional consistente");
  print("2. Usar conversiones de tipo seguras");
  print("3. Debug con prints en guardado y carga");
  print("4. Verificar IDs en BD");
}
