// Archivo: Cuadrilla_Content.dart
// Pantalla para la gestión de cuadrillas en el sistema Agribar
// Documentación y estructura profesionalizada
import 'package:flutter/material.dart';
import '../services/registrarCuadrillaEnBD.dart';
import '../services/cargarCuadrillasDesdeBD.dart';
import '../services/auth_validation_service.dart';
import '../services/control_usuario_service.dart';
// Widget principal de la pantalla de cuadrillas
class CuadrillaContent extends StatefulWidget {
  const CuadrillaContent({Key? key}) : super(key: key);

  @override
  State<CuadrillaContent> createState() => _CuadrillaContentState();
}

class _CuadrillaContentState extends State<CuadrillaContent> {
  // Controladores para los campos de texto
  final TextEditingController claveController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController grupoController = TextEditingController();
  String? actividadSeleccionada;
  final List<String> actividades = ['Destajo', 'Otra'];

  final TextEditingController searchController = TextEditingController();
  final ScrollController _tableScrollController = ScrollController();

  // Controladores para el diálogo de autenticación
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  // Servicio de autenticación con base de datos
  final AuthValidationService _authService = AuthValidationService();
  final ControlUsuarioService _controlUsuario = ControlUsuarioService();

  // Lista de cuadrillas (mock data) ahora con estado habilitado/deshabilitado
  

  // Lista filtrada para mostrar en la tabla
  List<Map<String, dynamic>> cuadrillasFiltradas = [];
  List<Map<String, dynamic>> cuadrillas = [];
  @override
  void initState() {
    super.initState();
    cargarCuadrillas();
    cuadrillasFiltradas = List.from(cuadrillas);
  }
Future<void> cargarCuadrillas() async {
  final datos = await obtenerCuadrillasDesdeBD();
  setState(() {
    cuadrillas = datos;
    cuadrillasFiltradas = List.from(datos);
  });
}
  // Filtra las cuadrillas según el texto de búsqueda
  void _buscarCuadrilla() {
    String query = searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        cuadrillasFiltradas = List.from(cuadrillas);
      } else {
        cuadrillasFiltradas =
            cuadrillas
                .where((c) => c['nombre']!.toLowerCase().contains(query))
                .toList();
      }
    });
  }
// Crear cuadrilla *****----------------------******
  void _crearCuadrilla() async {
  if (nombreController.text.isEmpty ||
      grupoController.text.isEmpty ||
      actividadSeleccionada == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Por favor llena todos los campos.')),
    );
    return;
  }

  final nuevaClave = await generarSiguienteClaveCuadrilla();

  final nuevaCuadrilla = {
    'clave': nuevaClave,
    'nombre': nombreController.text,
    'grupo': grupoController.text,
    'actividad': actividadSeleccionada!,
    'estado': true,
  };

  await registrarCuadrillaEnBD(nuevaCuadrilla);

  setState(() {
    claveController.text = nuevaClave;
    cuadrillas.add(nuevaCuadrilla);
    _buscarCuadrilla();
    nombreController.clear();
    grupoController.clear();
    actividadSeleccionada = null;
  });
}
  // Función para cambiar el estado de habilitado/deshabilitado
  Future<void> _toggleHabilitado(int index) async {
    // Mostrar diálogo de autenticación con validación por base de datos
    Map<String, dynamic>? userData = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.security, color: Color(0xFF0B7A2F)),
              SizedBox(width: 12),
              Text('Autenticación Requerida'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Solo administradores y supervisores pueden cambiar el estado de las cuadrillas.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              TextField(
                controller: userController,
                decoration: InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0B7A2F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Validar'),
              onPressed: () async {
                // Primero intentar con el nuevo sistema de base de datos
                var userData = await _authService.validarCredencialesConPermisos(
                  userController.text,
                  passController.text,
                );

                // Si falla, intentar con el sistema anterior como respaldo
                if (userData == null) {
                  try {
                    final resultado = await _controlUsuario.validarCredencialesConTipo(
                      userController.text,
                      passController.text,
                    );
                    
                    if (resultado != null && (resultado['tipo'] == 'Administrador' || resultado['tipo'] == 'Supervisor')) {
                      userData = {
                        'nombre_usuario': userController.text,
                        'rol_descripcion': resultado['tipo'],
                        'puede_gestionar': true,
                      };
                    }
                  } catch (e) {
                    // Error silencioso
                  }
                }

                if (userData != null) {
                  Navigator.of(context).pop(userData);
                } else {
                  // Mostrar error sin cerrar el diálogo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Credenciales inválidas o sin permisos suficientes\nRevisa la consola para más detalles'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );

    // Si la autenticación fue exitosa, cambiar el estado
    if (userData != null) {
      final cuadrilla = cuadrillasFiltradas[index];
      final clave = cuadrilla['clave'];
      final estadoActual = cuadrilla['habilitado'] ?? true;
      final nuevoEstado = !estadoActual;

      // Actualizar en la base de datos
      final actualizado = await _authService.actualizarEstadoCuadrilla(clave, nuevoEstado);

      if (actualizado) {
        // Recargar datos desde la base de datos para asegurar consistencia
        await cargarCuadrillas();
        
        // Mostrar mensaje de confirmación con información del usuario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cuadrilla ${nuevoEstado ? "habilitada" : "deshabilitada"} por ${userData['nombre_usuario']} (${userData['rol_descripcion']})',
            ),
            backgroundColor: nuevoEstado ? Colors.green : Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el estado en la base de datos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Limpiar los controladores
    userController.clear();
    passController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 800;
            final cardWidth =
                (isSmallScreen ? constraints.maxWidth * 0.9 : 1400).toDouble();

            return Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Container(
                constraints: BoxConstraints(maxWidth: cardWidth),
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      'Gestión de Cuadrillas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 32),
                    // Formulario para crear cuadrillas
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Campo Clave
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Clave'),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: claveController,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.grey[200],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Campo Nombre
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Nombre'),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: nombreController,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.grey[200],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Campo Grupo
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Grupo'),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: grupoController,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.grey[200],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Campo Actividad
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Actividad'),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: actividadSeleccionada,
                                      items:
                                          actividades
                                              .map(
                                                (a) => DropdownMenuItem(
                                                  value: a,
                                                  child: Text(a),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          actividadSeleccionada = value;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.grey[200],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      hint: const Text('Nombre'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0B7A2F),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _crearCuadrilla,
                              child: const Text(
                                'Crear',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Catalogo de Cuadrillas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B7A2F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Barra de búsqueda
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar',
                              filled: true,
                              fillColor: Color.fromARGB(59, 139, 139, 139),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(0xFF00923F),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: _buscarCuadrilla,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Tabla de cuadrillas
                    Card(
                      color: Colors.white,
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 350, // Altura máxima visible de la tabla
                          child: Scrollbar(
                            controller: _tableScrollController,
                            thumbVisibility: true,
                            child: ListView(
                              controller: _tableScrollController,
                              children: [
                                DataTable(
  headingRowColor: MaterialStateProperty.all(
    Color(0xFFE0E0E0),
  ),
  dataRowColor: MaterialStateProperty.resolveWith<Color?>(
    (Set<MaterialState> states) {
      final rowIndex = states.contains(MaterialState.selected)
          ? states.toList().indexOf(MaterialState.selected)
          : -1;
      if (rowIndex != -1 && rowIndex < cuadrillasFiltradas.length) {
        final habilitado = cuadrillasFiltradas[rowIndex]['habilitado'] ?? true;
        return !habilitado ? Colors.grey[100] : null;
      }
      return null;
    },
  ),
  border: TableBorder.all(
    color: Colors.grey.shade400,
    width: 1,
    style: BorderStyle.solid,
  ),
  columns: const [
    DataColumn(label: Text('Nombre', style: TextStyle(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Clave', style: TextStyle(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Grupo', style: TextStyle(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Actividad', style: TextStyle(fontWeight: FontWeight.bold))),
    DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
  ],
  rows: cuadrillasFiltradas.asMap().entries.map((entry) {
    final index = entry.key;
    final cuadrilla = entry.value;
    final habilitado = cuadrilla['habilitado'] ?? true;

    return DataRow(
      cells: [
        DataCell(
          Text(
            cuadrilla['nombre'],
            style: TextStyle(color: !habilitado ? Colors.grey[600] : null),
          ),
        ),
        DataCell(
          Text(
            cuadrilla['clave'],
            style: TextStyle(color: !habilitado ? Colors.grey[600] : null),
          ),
        ),
        DataCell(
          Text(
            cuadrilla['grupo'],
            style: TextStyle(color: !habilitado ? Colors.grey[600] : null),
          ),
        ),
        DataCell(
          Text(
            cuadrilla['actividad'],
            style: TextStyle(color: !habilitado ? Colors.grey[600] : null),
          ),
        ),
        DataCell(
          Container(
            width: 120,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: habilitado
                    ? Color(0xFF0B7A2F) // verde para habilitado
                    : Color(0xFFE53935), // rojo para deshabilitado
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _toggleHabilitado(index),
              child: Text(
                habilitado ? 'Sí' : 'No',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }).toList(),
),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/* 
🔧 CONFIGURACIÓN DE PERMISOS PARA HABILITAR/DESHABILITAR CUADRILLAS

CONFIGURACIÓN ACTUAL:
- ✅ Administradores (ID: 2) pueden gestionar cuadrillas
- ✅ Supervisores (ID: 1) pueden gestionar cuadrillas
- ❌ Capturistas (ID: 3) NO pueden gestionar cuadrillas

CARACTERÍSTICAS DEL SISTEMA:
- ✅ Validación contra base de datos real
- ✅ Verificación de roles y permisos
- ✅ Actualización del estado en PostgreSQL
- ✅ Mensajes informativos con usuario que realizó el cambio
- ✅ Manejo de errores y validaciones
- ✅ Interfaz mejorada para autenticación
- ✅ Recarga automática desde base de datos

ROLES EN BASE DE DATOS:
- Administrador: ID = 2, acceso_cuadrillas = true
- Supervisor: ID = 1, acceso_cuadrillas = true  
- Capturista: ID = 3, acceso_cuadrillas = false

TABLA DE PERMISOS:
┌─────────────────┬─────────────┬─────────────┬─────────────┐
│ ROL             │ CUADRILLAS  │ EMPLEADOS   │ NÓMINA      │
├─────────────────┼─────────────┼─────────────┼─────────────┤
│ Administrador   │ ✅ Sí        │ ✅ Sí        │ ✅ Sí        │
│ Supervisor      │ ✅ Sí        │ ✅ Sí        │ ✅ Sí        │
│ Capturista      │ ❌ No        │ ❌ No        │ ✅ Sí        │
└─────────────────┴─────────────┴─────────────┴─────────────┘

NOTA: Este mismo sistema se puede aplicar a la gestión de empleados
      modificando la función actualizarEstadoEmpleado() del servicio.
*/
