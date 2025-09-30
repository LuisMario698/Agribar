/// Módulo de gestión de empleados del sistema Agribar.
/// Permite visualizar, agregar, editar y eliminar información de empleados,
/// así como gestionar sus datos personales y laborales.

import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/registro_empleado_service.dart';
import '../services/cargarEmpleadosDesdeBD.dart';
import '../services/auth_validation_service.dart';
import '../services/control_usuario_service.dart';
import 'EmpleadosGeneralTab.dart';

/// Widget principal de la sección de empleados.
/// Implementa una interfaz con pestañas para organizar diferentes aspectos
/// de la gestión de empleados.
class EmpleadosContent extends StatefulWidget {
  @override
  State<EmpleadosContent> createState() => _EmpleadosContentState();
}

/// Estado del widget EmpleadosContent que maneja:
/// - Selección de pestañas
/// - Datos de empleados
/// - Scroll de la interfaz
class _EmpleadosContentState extends State<EmpleadosContent> {
  int _selectedTabIndex = 0;
  final ScrollController _tabScrollController = ScrollController();

  // Controladores para el diálogo de autenticación
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  // Servicios
  final AuthValidationService _authService = AuthValidationService();
  final ControlUsuarioService _controlUsuario = ControlUsuarioService();

  // Estado de carga
  List<Map<String, dynamic>> empleadosData = [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false;

  final List<String> empleadosHeaders = [
    'Clave',
    'Nombre',
    'Apellido Paterno',
    'Apellido Materno',
    'curp',
    'rfc',
    'Estado',
    'Habilitado',
    'Acciones',
  ];

  final List<String> tabTitles = ['General', 'Registro'];

  // Keys para medir cada tab
  final List<GlobalKey> _tabKeys = List.generate(4, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEmpleadosOptimizado();
      _setIndicator();
    });
  }

  /// Método optimizado para cargar empleados
  Future<void> _cargarEmpleadosOptimizado({bool forzarRecarga = false}) async {
    if (_isLoading) return; // Evitar múltiples cargas simultáneas
    
    setState(() {
      _isLoading = true;
    });

    try {
      final empleados = await obtenerEmpleadosDesdeBD(forzarRecarga: forzarRecarga);
      if (mounted) {
        setState(() {
          empleadosData = empleados;
          _hasLoadedOnce = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar empleados: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> cargarEmpleadosDesdeBD({bool forzarRecarga = false}) async {
    return _cargarEmpleadosOptimizado(forzarRecarga: forzarRecarga);
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTabIndex = index);
    
    // Solo cargar si no se ha cargado antes y es la pestaña General
    if (index == 0 && !_hasLoadedOnce) {
      _cargarEmpleadosOptimizado();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _setIndicator());
    // Desplazamiento animado para centrar la pestaña
    RenderBox? box =
        _tabKeys[index].currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      double tabCenter = box.localToGlobal(Offset.zero).dx + box.size.width / 2;
      double screenWidth = MediaQuery.of(context).size.width;
      double offset = tabCenter - screenWidth / 2;
      _tabScrollController.animateTo(
        _tabScrollController.offset + offset,
        duration: Duration(milliseconds: 350),
        curve: Curves.ease,
      );
    }
  }

  void _setIndicator() {
    final key = _tabKeys[_selectedTabIndex];
    final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? parentBox = context.findRenderObject() as RenderBox?;
    if (box != null && parentBox != null) {
      box.localToGlobal(Offset.zero, ancestor: parentBox);
      setState(() {});
    }
  }

  void agregarEmpleado(List<String> nuevoEmpleado) async {
    await _cargarEmpleadosOptimizado(forzarRecarga: true);
    setState(() {
      _selectedTabIndex = 0;
    });
  }

  // Método para cambiar el estado de habilitado/deshabilitado con autenticación
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
                'Solo administradores y supervisores pueden cambiar el estado de los empleados.',
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
                    
                    // Verificar si es Supervisor (1) o Administrador (2)
                    if (resultado != null && (resultado['rol_id'] == 1 || resultado['rol_id'] == 2)) {
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
                      content: Text('Credenciales incorrectas o sin permisos suficientes'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
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
      final empleado = empleadosData[index];
      final idEmpleado = empleado['id_empleado'] as int;
      final estadoActual = empleado['habilitado'] as bool;
      final nuevoEstado = !estadoActual;

      print('🔄 Cambiando estado del empleado ${empleado['clave']}: $estadoActual → $nuevoEstado');

      // Actualizar en la base de datos
      final success = await _authService.actualizarEstadoEmpleado(idEmpleado, nuevoEstado);
      
      if (success) {
        print('✅ Estado actualizado exitosamente en BD');
        
        // Actualizar el estado local directamente sin recargar toda la tabla
        setState(() {
          empleadosData[index]['habilitado'] = nuevoEstado;
        });

        // Mostrar mensaje de confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Empleado ${nuevoEstado ? "habilitado" : "deshabilitado"} correctamente',
            ),
            backgroundColor: nuevoEstado ? Color(0xFF0B7A2F) : Colors.orange,
          ),
        );
      } else {
        print('❌ Error al actualizar estado en BD');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el estado del empleado'),
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
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth * 0.95; // Usar 95% del ancho disponible

          return Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Container(
              constraints: BoxConstraints(maxWidth: cardWidth),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TabBar visual mejorado
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFF3F1EA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      child: Row(
                        children: List.generate(tabTitles.length, (i) {
                          return _EmpleadosTab(
                            text: tabTitles[i],
                            selected: _selectedTabIndex == i,
                            onTap: () => _onTabSelected(i),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Contenido según la pestaña seleccionada
                    Expanded(child: _buildTabContent()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildGeneralTab();
      case 1:
        return _buildRegistroTab();
      default:
        return _buildGeneralTab();
    }
  }

  Widget _buildGeneralTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0B7A2F)),
            SizedBox(height: 16),
            Text('Cargando empleados...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Tabla de empleados
        Expanded(
          child: EmpleadosGeneralTab(
            empleadosData: empleadosData,
            empleadosHeaders: empleadosHeaders,
            toggleHabilitado: _toggleHabilitado,
            onEmpleadoActualizado: () => _cargarEmpleadosOptimizado(forzarRecarga: true),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistroTab() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: Color(0xFFE5E5E5),
        width: double.infinity,
        child: RegistroEmpleadoWizard(onEmpleadoRegistrado: agregarEmpleado),
      ),
    );
  }
}

class _EmpleadosTab extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _EmpleadosTab({
    Key? key,
    required this.text,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color verde = Color(0xFF5BA829);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: selected ? verde : Colors.grey[600],
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            if (selected)
              Container(
                height: 8,
                width: 60,
                decoration: BoxDecoration(
                  color: verde,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            if (!selected) SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class RegistroEmpleadoWizard extends StatefulWidget {
  final void Function(List<String>) onEmpleadoRegistrado;
  const RegistroEmpleadoWizard({Key? key, required this.onEmpleadoRegistrado})
    : super(key: key);

  @override
  State<RegistroEmpleadoWizard> createState() => _RegistroEmpleadoWizardState();
}

class _RegistroEmpleadoWizardState extends State<RegistroEmpleadoWizard> {
  int _currentStep = 0;
  final int totalSteps = 3;

  // Controladores para los campos de ejemplo
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoPaternoController =
      TextEditingController();
  final TextEditingController apellidoMaternoController =
      TextEditingController();
  final TextEditingController rfcController = TextEditingController();
  final TextEditingController curpController = TextEditingController();
  String estadoOrigen = '';
  final TextEditingController nssController = TextEditingController();

  final TextEditingController registroPatronalController =
      TextEditingController();
  String registroPatronalSeleccionado = ''; // 🔧 Variable específica para dropdown de registro patronal
  bool mostrarMensajeUbicacion = false; // 🔧 Para mostrar mensaje de ubicación
  String ubicacionSeleccionada = ''; // 🔧 Para guardar la ubicación
  
  // 🔧 Variables para cargar datos dinámicamente
  List<Map<String, dynamic>> cuadrillasDisponibles = [];
  List<String> registrosPatronalesDisponibles = ["E6483368131", "E5920112136"];
  bool isLoadingCuadrillas = false;

  // 🔧 Variables para selector de código de empleado
  List<String> _codigosDisponibles = [];
  String? _codigoSeleccionado;
  bool _cargandoCodigos = false;
  bool _modoCodigoPersonalizado = false;

  @override
  void initState() {
    super.initState();
    _cargarCuadrillasDisponibles();
    _cargarCodigosDisponibles();
  }

  /// Carga los códigos disponibles desde la base de datos
  Future<void> _cargarCodigosDisponibles() async {
    setState(() {
      _cargandoCodigos = true;
    });

    try {
      final db = DatabaseService();
      await db.connect();

      // Obtener códigos ya asignados
      final resultadoExistentes = await db.connection.query(
        'SELECT codigo FROM empleados ORDER BY CAST(codigo AS INTEGER)'
      );

      final codigosExistentes = resultadoExistentes.map((row) => row[0].toString()).toSet();

      // Generar lista de códigos disponibles (del 1 al 9999)
      final codigosDisponibles = <String>[];
      for (int i = 1; i <= 9999; i++) {
        final codigo = i.toString();
        if (!codigosExistentes.contains(codigo)) {
          codigosDisponibles.add(codigo);
        }
      }

      await db.close();

      if (mounted) {
        setState(() {
          _codigosDisponibles = codigosDisponibles;
          _cargandoCodigos = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar códigos disponibles: $e');
      if (mounted) {
        setState(() {
          _cargandoCodigos = false;
        });
      }
    }
  }

  /// Carga las cuadrillas disponibles desde la base de datos
  Future<void> _cargarCuadrillasDisponibles() async {
    if (isLoadingCuadrillas) return;
    
    setState(() {
      isLoadingCuadrillas = true;
    });

    try {
      final db = DatabaseService();
      await db.connect();
      
      final result = await db.connection.query('''
        SELECT id, nombre, clave 
        FROM cuadrillas 
        WHERE habilitado = true 
        ORDER BY nombre
      ''');
      
      await db.close();
      
      if (mounted) {
        setState(() {
          cuadrillasDisponibles = result.map((row) => {
            'id': row[0],
            'nombre': row[1],
            'clave': row[2],
          }).toList();
          isLoadingCuadrillas = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar cuadrillas: $e');
      if (mounted) {
        setState(() {
          // Fallback a cuadrillas predeterminadas
          cuadrillasDisponibles = [
            {'id': 1, 'nombre': 'Cuadrilla 1', 'clave': '001'},
            {'id': 2, 'nombre': 'Cuadrilla 2', 'clave': '002'},
            {'id': 3, 'nombre': 'Cuadrilla 3', 'clave': '003'},
          ];
          isLoadingCuadrillas = false;
        });
      }
    }
  }
  DateTime? fechaIngreso;
  final TextEditingController fechaIngresoController = TextEditingController();

  final TextEditingController sueldoController = TextEditingController();
  final TextEditingController descuentoInfonavitController =
      TextEditingController();

  // Lista de estados de México
  final List<String> estadosMexico = [
    'Aguascalientes',
    'Baja California',
    'Baja California Sur',
    'Campeche',
    'Chiapas',
    'Chihuahua',
    'Ciudad de México',
    'Coahuila',
    'Colima',
    'Durango',
    'Estado de México',
    'Guanajuato',
    'Guerrero',
    'Hidalgo',
    'Jalisco',
    'Michoacán',
    'Morelos',
    'Nayarit',
    'Nuevo León',
    'Oaxaca',
    'Puebla',
    'Querétaro',
    'Quintana Roo',
    'San Luis Potosí',
    'Sinaloa',
    'Sonora',
    'Tabasco',
    'Tamaulipas',
    'Tlaxcala',
    'Veracruz',
    'Yucatán',
    'Zacatecas',
  ];

  Future<void> _nextStep() async {
    if (_currentStep < totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Usar el código seleccionado o del campo de texto, o generar uno automático
      String nuevoCodigo;
      if (_modoCodigoPersonalizado && codigoController.text.isNotEmpty) {
        nuevoCodigo = codigoController.text.trim();
      } else if (_codigoSeleccionado != null) {
        nuevoCodigo = _codigoSeleccionado!;
      } else {
        nuevoCodigo = await generarSiguienteCodigoEmpleado();
      }

      final nuevoEmpleado = {
        'codigo': nuevoCodigo,
        'nombre': nombreController.text,
        'apellidoPaterno': apellidoPaternoController.text,
        'apellidoMaterno': apellidoMaternoController.text,
        'curp': curpController.text,
        'rfc': rfcController.text,
        'nss': nssController.text,
        'estado': estadoOrigen,

        // Campos laborales con valores por defecto
        'tipo': 'Temporal', // Valor por defecto
        'idCuadrilla': null, // Se asignará posteriormente en nómina
        'fechaIngreso': fechaIngreso?.toIso8601String().split('T').first ?? '',
        'empresa': 'AGRIBAR', // Valor por defecto
        'puesto': 'Operador', // Valor por defecto
        'registroPatronal': registroPatronalSeleccionado.isNotEmpty 
            ? registroPatronalSeleccionado 
            : 'E6483368131', // Valor por defecto

        // Campos de nómina simplificados
        'sueldo': double.tryParse(sueldoController.text) ?? 0.0,
        'domingoLaboral': 0.0, // Campo eliminado, valor por defecto
        'descuentoComedor': 0.0, // Campo eliminado, valor por defecto
        'descuentoInfonavit': double.tryParse(descuentoInfonavitController.text) ?? 0.0,
      };
      await registrarEmpleadoEnBD(nuevoEmpleado);

      // Llamar al callback para agregar el empleado a la lista en memoria
      widget.onEmpleadoRegistrado([
        nuevoCodigo,
        nombreController.text,
        apellidoPaternoController.text, apellidoMaternoController.text,
        'General', // Valor por defecto para cuadrilla
        sueldoController.text,
        '', // Eliminamos tipoDescuentoInfonavit
      ]);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('¡Registro completado!')));

      setState(() => _currentStep = 0);
      _limpiarCampos();
    }
  }

  Future<String> generarSiguienteCodigoEmpleado() async {
    final db = DatabaseService();
    await db.connect();

    final result = await db.connection.query(
      "SELECT codigo FROM empleados ORDER BY CAST(codigo AS INTEGER) DESC LIMIT 1;",
    );

    await db.close();

     // Si no hay empleados, regresa '1'
  if (result.isEmpty) return '1';

  final ultimoCodigo = result.first[0] as String;
  final numero = int.parse(ultimoCodigo);
  final siguienteNumero = numero + 1;
  return siguienteNumero.toString();
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _limpiarCampos() {
    codigoController.clear();
    nombreController.clear();
    apellidoPaternoController.clear();
    apellidoMaternoController.clear();
    rfcController.clear();
    curpController.clear();
    estadoOrigen = '';
    nssController.clear();
    registroPatronalController.clear();
    fechaIngreso = null;
    fechaIngresoController.clear();
    sueldoController.clear();
    descuentoInfonavitController.clear();
    
    // Limpiar variables del selector de código
    _codigoSeleccionado = null;
    _modoCodigoPersonalizado = false;
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Color verde = Color(0xFF8AB531);
    final Color grisFondo = Color(0xFFE5E5E5);
    final Color grisInput = Color(0xFFF3F1EA);

    return Container(
      color: grisFondo,
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(height: 24),
          // Barra de pasos custom
          _buildStepBar(verde),
          SizedBox(height: 32),
          // Card del formulario
          Expanded(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95, // Usar 95% del ancho de pantalla
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: _buildStepContent(_currentStep, grisInput, verde),
                ),
              ),
            ),
          ),
          // Botones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _currentStep == 0
                    ? ElevatedButton.icon(
                      onPressed: () {
                        // Cancelar acción
                      },
                      icon: Icon(Icons.cancel, color: Color(0xFF0B7A2F)),
                      label: Text(
                        'Cancelar',
                        style: TextStyle(color: Color(0xFF0B7A2F)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: verde,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: verde),
                        ),
                        elevation: 0,
                      ),
                    )
                    : ElevatedButton.icon(
                      onPressed: _prevStep,
                      icon: Icon(Icons.arrow_back, color: Color(0xFF0B7A2F)),
                      label: Text(
                        'Anterior',
                        style: TextStyle(color: Color(0xFF0B7A2F)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: verde,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(color: verde),
                        ),
                        elevation: 0,
                      ),
                    ),
                ElevatedButton.icon(
                  onPressed: _nextStep,
                  icon: Icon(
                    _currentStep == totalSteps - 1
                        ? Icons.check
                        : Icons.arrow_forward,
                    color: Colors.white,
                  ),
                  label: Text(
                    _currentStep == totalSteps - 1 ? 'Terminar' : 'Siguiente',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0B7A2F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBar(Color verde) {
    List<String> titles = [
      'Datos Personales',
      'Datos Laborales',
      'Datos de Nómina',
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(titles.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Línea entre círculos
          return Container(
            width: 60,
            height: 4,
            color:
                i ~/ 2 < _currentStep ? Color(0xFF0B7A2F) : Color(0xFFBFC3C7),
          );
        } else {
          int idx = i ~/ 2;
          return Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    idx <= _currentStep ? Color(0xFF0B7A2F) : Color(0xFFBFC3C7),
                child: Text(
                  '${idx + 1}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 8),
              Text(
                titles[idx],
                style: TextStyle(
                  color:
                      idx <= _currentStep
                          ? Color(0xFF0B7A2F)
                          : Color(0xFFBFC3C7),
                  fontWeight:
                      idx == _currentStep ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _buildStepContent(int step, Color grisInput, Color verde) {
    switch (step) {
      case 0:
        return _datosPersonales(grisInput);
      case 1:
        return _datosLaborales(grisInput);
      case 2:
        return _datosNomina(grisInput, verde);
      default:
        return Container();
    }
  }

  Widget _datosPersonales(Color grisInput) {
    // Estilo de tarjeta
    BoxDecoration cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    );
    EdgeInsets cardPadding = const EdgeInsets.all(16);

    return Center(
      child: Container(
        width: 800,
        height: 600,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 32,
          runSpacing: 32,
          children: [
            // Apellido Paterno
            Container(
              width: 290,
              height: 100,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Apellido Paterno',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: _customInput(
                        apellidoPaternoController,
                        '',
                        grisInput,
                      ),
                    ),
                  ),
                ],
              ),
            ), // Apellido Materno
            Container(
              width: 290,
              height: 100,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Apellido Materno',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: _customInput(
                        apellidoMaternoController,
                        '',
                        grisInput,
                      ),
                    ),
                  ),
                ],
              ),
            ), // Nombre
            Container(
              width: 290,
              height: 100,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nombre',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: _customInput(nombreController, '', grisInput),
                    ),
                  ),
                ],
              ),
            ), // CURP
            Container(
              width: 290,
              height: 100,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CURP',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: _customInput(curpController, '', grisInput),
                    ),
                  ),
                ],
              ),
            ), // RFC
            Container(
              width: 290,
              height: 100,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RFC',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: _customInput(rfcController, '', grisInput),
                    ),
                  ),
                ],
              ),
            ), // NSS
            Container(
              width: 290,
              height: 100,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'NSS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: _customInput(nssController, '', grisInput),
                    ),
                  ),
                ],
              ),
            ), // Estado de Origen
            Container(
              width: 290,
              height: 100,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estado de Origen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: DropdownButtonFormField<String>(
                        value: estadoOrigen.isEmpty ? null : estadoOrigen,
                        items:
                            estadosMexico
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) => setState(() => estadoOrigen = v ?? ''),
                        decoration: InputDecoration(
                          labelText: "Estado",
                          filled: true,
                          fillColor: grisInput,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datosLaborales(Color grisInput) {
    // Estilo de tarjeta mejorado
    BoxDecoration cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
    EdgeInsets cardPadding = const EdgeInsets.all(24);

    return Center(
      child: Container(
        width: 700,
        height: 500,
        child: Column(
          children: [
            // Título de la sección
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 48,
                    color: Color(0xFF0B7A2F),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Datos Laborales',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B7A2F),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Información relacionada con el trabajo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Cards organizadas en fila
            Expanded(
              child: Row(
                children: [
                  // Fecha de Ingreso
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: cardDecoration,
                      padding: cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Color(0xFF0B7A2F),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Fecha de Ingreso',
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B7A2F),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Center(
                              child: GestureDetector(
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: fechaIngreso ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      fechaIngreso = picked;
                                      fechaIngresoController.text =
                                          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                                    });
                                  }
                                },
                                child: AbsorbPointer(
                                  child: TextField(
                                    controller: fechaIngresoController,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: grisInput,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      suffixIcon: Icon(
                                        Icons.calendar_today,
                                        color: Color(0xFF0B7A2F),
                                      ),
                                      hintText: 'Seleccionar fecha',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 24),
                  
                  // Registro Patronal
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: cardDecoration,
                      padding: cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                color: Color(0xFF0B7A2F),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Registro Patronal',
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B7A2F),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                // Dropdown
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    value: registroPatronalSeleccionado.isEmpty ? null : registroPatronalSeleccionado,
                                    items:
                                        ["E6483368131", "E5920112136"]
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(e),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) => setState(() {
                                      registroPatronalSeleccionado = v ?? '';
                                      // Mostrar mensaje según la opción seleccionada
                                      if (v == "E6483368131") {
                                        mostrarMensajeUbicacion = true;
                                        ubicacionSeleccionada = 'Hermosillo';
                                      } else if (v == "E5920112136") {
                                        mostrarMensajeUbicacion = true;
                                        ubicacionSeleccionada = 'Caborca';
                                      } else {
                                        mostrarMensajeUbicacion = false;
                                        ubicacionSeleccionada = '';
                                      }
                                    }),
                                    decoration: InputDecoration(
                                      labelText: "Seleccionar",
                                      filled: true,
                                      fillColor: grisInput,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                // Mensaje de ubicación
                                Expanded(
                                  flex: 2,
                                  child: AnimatedOpacity(
                                    opacity: mostrarMensajeUbicacion ? 1.0 : 0.0,
                                    duration: Duration(milliseconds: 300),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: ubicacionSeleccionada == 'Hermosillo' 
                                            ? Colors.blue.shade50 
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: ubicacionSeleccionada == 'Hermosillo' 
                                              ? Colors.blue.shade200 
                                              : Colors.green.shade200,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 20,
                                            color: ubicacionSeleccionada == 'Hermosillo' 
                                                ? Colors.blue.shade600
                                                : Colors.green.shade600,
                                          ),
                                          SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              ubicacionSeleccionada,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: ubicacionSeleccionada == 'Hermosillo' 
                                                    ? Colors.blue.shade700
                                                    : Colors.green.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datosNomina(Color grisInput, Color verde) {
    // Estilo de tarjeta mejorado
    BoxDecoration cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
    EdgeInsets cardPadding = const EdgeInsets.all(24);

    return Center(
      child: Container(
        width: 700,
        height: 500,
        child: Column(
          children: [
            // Título de la sección
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 48,
                    color: Color(0xFF0B7A2F),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Información Salarial',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B7A2F),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sueldo y descuentos del empleado',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Cards organizadas en columna
            Expanded(
              child: Column(
                children: [
                  // Selector de código de empleado
                  Container(
                    width: double.infinity,
                    height: 140,
                    decoration: cardDecoration,
                    padding: cardPadding,
                    child: _buildCodigoSelectorRegistro(grisInput, verde),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Row con sueldo y descuento
                  Expanded(
                    child: Row(
                      children: [
                        // Sueldo
                        Expanded(
                          child: Container(
