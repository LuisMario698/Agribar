import 'lib/services/registro_empleado_service.dart';

void main() async {
  print('🧪 Probando registro de empleado...');
  
  // Datos de prueba completos
  final datosEmpleado = {
    'codigo': '999',
    'nombre': 'Juan',
    'apellidoPaterno': 'Pérez',
    'apellidoMaterno': 'García',
    'curp': 'PEGJ850101HSLRNN07',
    'rfc': 'PEGJ850101',
    'nss': '12345678901',
    'estado': 'Sonora',
    
    // Datos laborales
    'tipo': 'Empleado',
    'idCuadrilla': 1,
    'fechaIngreso': '2024-01-15',
    'empresa': 'Test Company',
    'puesto': 'Operador',
    'registroPatronal': 'E6483368131',
    
    // Datos nómina
    'sueldo': 500.0,
    'domingoLaboral': 100.0,
    'descuentoComedor': 50.0,
    'descuentoInfonavit': 75.0,
  };
  
  try {
    await registrarEmpleadoEnBD(datosEmpleado);
    print('✅ Registro exitoso');
  } catch (e) {
    print('❌ Error en registro: $e');
  }
}
