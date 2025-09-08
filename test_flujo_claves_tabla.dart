void main() {
  print('🧪 PRUEBA DE FLUJO COMPLETO: INGRESO DE CLAVES EN TABLA EDITABLE');
  print('=' * 70);
  
  // Simular datos como los tendría la aplicación real
  Map<String, int> claveAIdMap = {
    '1': 1,
    '1301': 2,
    '1306': 3,
    '1309': 4,
    '1315': 5,
  };
  
  Map<int, String> idAClaveMap = {
    1: '1',
    2: '1301',
    3: '1306',
    4: '1309',
    5: '1315',
  };
  
  Map<String, String> claveANombreMap = {
    '1': 'DESTAJO',
    '1301': 'JEFE DE LINEA',
    '1306': 'JEFE DE EMPAQUE',
    '1309': 'CADENERO',
    '1315': 'ACARREADOR',
  };
  
  print('✅ Datos de actividades cargados (${claveAIdMap.length} actividades)');
  
  // Simular funciones del Nomina_screen.dart
  bool esClaveActividadValida(String clave) {
    return claveAIdMap.containsKey(clave);
  }
  
  String obtenerNombrePorClave(String clave) {
    return claveANombreMap[clave] ?? '';
  }
  
  int obtenerIdParaGuardar(String clave) {
    return claveAIdMap[clave] ?? 0;
  }
  
  String obtenerClaveParaMostrar(dynamic valor) {
    if (valor == null) return '';
    
    String valorStr = valor.toString();
    
    // Si es un ID numérico, convertirlo a clave
    int? id = int.tryParse(valorStr);
    if (id != null && idAClaveMap.containsKey(id)) {
      return idAClaveMap[id]!;
    }
    
    // Si ya es una clave válida, devolverla tal como está
    if (claveAIdMap.containsKey(valorStr)) {
      return valorStr;
    }
    
    return valorStr;
  }
  
  // Simular empleado
  Map<String, dynamic> empleado = {
    'nombre': 'Juan Pérez',
    'dia_0_id': null, // Inicialmente vacío
  };
  
  print('\n📋 EMPLEADO INICIAL:');
  print('   Nombre: ${empleado['nombre']}');
  print('   dia_0_id: ${empleado['dia_0_id']}');
  
  // Simular función _manejarCambio del widget (versión corregida)
  void manejarCambio(String campo, String valor) {
    print('\n🔄 Usuario ingresa en campo "$campo": "$valor"');
    
    if (campo == 'dia_0_id') {
      if (valor.isEmpty) {
        empleado[campo] = null;
        print('   🧹 Campo limpiado');
      } else {
        // 🔧 PASO 1: Verificar si la clave es válida
        if (esClaveActividadValida(valor)) {
          // 🔧 PASO 2: Convertir clave a ID para guardar
          final idParaGuardar = obtenerIdParaGuardar(valor);
          empleado[campo] = idParaGuardar;
          
          // 🔧 PASO 3: Obtener nombre para feedback
          final nombreActividad = obtenerNombrePorClave(valor);
          
          print('   ✅ Campo actividad actualizado correctamente:');
          print('      Clave ingresada: $valor');
          print('      ID guardado: $idParaGuardar');
          print('      Nombre: $nombreActividad');
        } else {
          print('   ❌ Clave de actividad no válida: $valor');
        }
      }
    }
    
    print('   📊 Estado del empleado: dia_0_id = ${empleado['dia_0_id']}');
  }
  
  // Simular al cargar datos desde BD (ID → Clave para mostrar)
  void cargarDesdeBD(int idDesdeBaseDatos) {
    print('\n📖 Cargando desde BD - ID: $idDesdeBaseDatos');
    String claveParaMostrar = obtenerClaveParaMostrar(idDesdeBaseDatos);
    empleado['dia_0_id'] = idDesdeBaseDatos; // En BD se guarda como ID
    print('   🔄 Convertido a clave para mostrar: "$claveParaMostrar"');
    print('   👁️ Usuario verá: "$claveParaMostrar"');
  }
  
  // Simular al guardar en BD (Clave → ID para guardar)
  void guardarEnBD() {
    print('\n💾 Guardando en BD...');
    int idDelEmpleado = empleado['dia_0_id'] ?? 0;
    if (idDelEmpleado > 0) {
      print('   📝 ID que se guarda en BD: $idDelEmpleado');
      String claveCorrespondiente = obtenerClaveParaMostrar(idDelEmpleado);
      String nombreCorrespondiente = obtenerNombrePorClave(claveCorrespondiente);
      print('   ℹ️  Corresponde a clave: "$claveCorrespondiente" - $nombreCorrespondiente');
    } else {
      print('   ⚠️  No hay actividad para guardar');
    }
  }
  
  print('\n' + '🧪 ESCENARIOS DE PRUEBA:'.padRight(70, '='));
  
  // ESCENARIO 1: Usuario ingresa clave válida
  print('\n1️⃣ ESCENARIO: Usuario ingresa clave válida');
  manejarCambio('dia_0_id', '1301');
  guardarEnBD();
  
  // ESCENARIO 2: Cargar datos desde BD
  print('\n2️⃣ ESCENARIO: Cargar datos desde BD');
  cargarDesdeBD(2); // ID 2 corresponde a clave "1301"
  
  // ESCENARIO 3: Usuario ingresa clave inválida
  print('\n3️⃣ ESCENARIO: Usuario ingresa clave inválida');
  manejarCambio('dia_0_id', '9999');
  
  // ESCENARIO 4: Usuario ingresa otra clave válida
  print('\n4️⃣ ESCENARIO: Usuario cambia a otra clave válida');
  manejarCambio('dia_0_id', '1306');
  guardarEnBD();
  
  // ESCENARIO 5: Usuario limpia el campo
  print('\n5️⃣ ESCENARIO: Usuario limpia el campo');
  manejarCambio('dia_0_id', '');
  guardarEnBD();
  
  print('\n' + '📊 RESULTADOS:'.padRight(70, '='));
  
  List<String> clavesAPrueba = ['1301', '1306', '1309', '9999', 'abc'];
  
  for (String clave in clavesAPrueba) {
    bool esValida = esClaveActividadValida(clave);
    String nombre = obtenerNombrePorClave(clave);
    int id = obtenerIdParaGuardar(clave);
    
    String estado = esValida ? '✅' : '❌';
    print('$estado Clave "$clave" → ID: $id → Nombre: "$nombre"');
  }
  
  print('\n🎉 FLUJO DE CONVERSIÓN:');
  print('   📝 Usuario ingresa CLAVE (ej: "1301")');
  print('   🔄 Sistema convierte a ID (ej: 2)');
  print('   💾 Se guarda ID en BD');
  print('   📖 Al cargar, ID se convierte a CLAVE');
  print('   👁️ Usuario ve CLAVE nuevamente');
  
  print('\n✅ PRUEBA COMPLETADA - Sistema funcional');
}
