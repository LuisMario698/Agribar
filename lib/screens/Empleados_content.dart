/// Módulo de gestión de empleados del sistema Agribar.
/// Permite visualizar, agregar, editar y eliminar información de empleados,
/// así como gestionar sus datos personales y laborales.

import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/registro_empleado_service.dart';
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
  int _selectedTabIndex = 0; // Índice de la pestaña seleccionada
  final ScrollController _tabScrollController = ScrollController();

  /// Datos de los empleados en formato tabular
  /// Cada lista representa una fila con los siguientes campos:
  /// 1. Clave (ID único)
  /// 2. Nombre
  /// 3. Apellido paterno
  /// 4. Apellido materno
  /// 5. Supervisor/Área
  /// 6. Salario
  /// 7. Tipo de pago
  List<Map<String, dynamic>> empleadosData = [];

  final List<String> empleadosHeaders = [
    'Clave',
    'Nombre',
    'Apellido Paterno',
    'Apellido Materno',
    'curp',
    'rfc',
    'Estado',
    'Habilitado',
  ];

  final List<String> tabTitles = ['General', 'Registro'];

  // Keys para medir cada tab
  final List<GlobalKey> _tabKeys = List.generate(4, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    cargarEmpleadosDesdeBD();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setIndicator());
  }

  Future<void> cargarEmpleadosDesdeBD() async {
    try {
      final db = DatabaseService();
      await db.connect();

      final results = await db.connection.query('''
       
   SELECT codigo,nombre,apellido_paterno,apellido_materno, curp,rfc,estado_origen, habilitado FROM public.empleados
ORDER BY id_empleado ASC LIMIT 100 OFFSET 0;
    ''');

      setState(() {
        empleadosData =
            results
                .map(
                  (row) => {
                    'clave': row[0],
                    'nombre': row[1],
                    'apellidoPaterno': row[2],
                    'apellidoMaterno': row[3],
                    'cuadrilla': row[4],
                    'sueldo':  row[5],
                    'tipo': row[6],
                    'habilitado': row[7],
                  },
                )
                .toList();
      });

      await db.close();
    } catch (e) {
      print('Error al cargar empleados: $e' );
    }
  }

  void _onTabSelected(int index) {
    setState(() => _selectedTabIndex = index);
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
    // Recargar datos desde la base de datos para mantener sincronización
    await cargarEmpleadosDesdeBD();

    setState(() {
      _selectedTabIndex = 0; // Regresa a la pestaña General
    });
  }

  // Controladores para el diálogo de autenticación
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  // Validar credenciales de supervisor
  bool _validarCredencialesSupervisor(String usuario, String password) {
    return usuario == "supervisor" && password == "1234";
  }

  // Método para cambiar el estado de habilitado/deshabilitado
  Future<void> _toggleHabilitado(int index) async {
    // Mostrar diálogo de autenticación
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Autenticación de Supervisor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userController,
                decoration: InputDecoration(labelText: 'Usuario'),
              ),
              TextField(
                controller: passController,
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Aceptar'),
              onPressed: () {
                if (_validarCredencialesSupervisor(
                  userController.text,
                  passController.text,
                )) {
                  Navigator.of(context).pop(true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Credenciales inválidas'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  Navigator.of(context).pop(false);
                }
              },
            ),
          ],
        );
      },
    );

    // Si la autenticación fue exitosa, cambiar el estado
    if (result == true) {
      setState(() {
        empleadosData[index]['habilitado'] =
            !empleadosData[index]['habilitado'];
      });

      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Empleado ${empleadosData[index]['habilitado'] ? "habilitado" : "deshabilitado"} correctamente',
          ),
          backgroundColor:
              empleadosData[index]['habilitado'] ? Colors.green : Colors.orange,
        ),
      );
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
    return EmpleadosGeneralTab(
      empleadosData: empleadosData,
      empleadosHeaders: empleadosHeaders,
      toggleHabilitado: _toggleHabilitado,
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
  final TextEditingController empresaController = TextEditingController();
  final TextEditingController puestoController = TextEditingController();
  String cuadrilla = '';
  String tipoEmpleado = '';
  DateTime? fechaIngreso;
  final TextEditingController fechaIngresoController = TextEditingController();

  final TextEditingController sueldoController = TextEditingController();
  bool domingoLaboral = false;
  final TextEditingController domingoLaboralMontoController =
      TextEditingController();
  bool descuentoComedor = false;
  final TextEditingController descuentoComedorController =
      TextEditingController();
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
      final nuevoCodigo = await generarSiguienteCodigoEmpleado();
      final nuevoEmpleado = {
        'codigo': nuevoCodigo,
        'nombre': nombreController.text,
        'apellidoPaterno': apellidoPaternoController.text,
        'apellidoMaterno': apellidoMaternoController.text,
        'curp': curpController.text,
        'rfc': rfcController.text,
        'nss': nssController.text,
        'estado': estadoOrigen,

        'tipo': tipoEmpleado,
        'idCuadrilla':
            int.tryParse(cuadrilla) ?? null, // si cuadrilla es ID numérico
        'fechaIngreso': fechaIngreso?.toIso8601String().split('T').first ?? '',
        'empresa': empresaController.text,
        'puesto': puestoController.text,
        'registroPatronal': registroPatronalController.text,

        'sueldo': double.tryParse(sueldoController.text) ?? 0.0,
        'domingoLaboral':
            domingoLaboral
                ? double.tryParse(domingoLaboralMontoController.text) ?? 0.0
                : 0.0,
        'descuentoComedor':
            descuentoComedor
                ? double.tryParse(descuentoComedorController.text) ?? 0.0
                : 0.0,
        'descuentoInfonavit':
            double.tryParse(descuentoInfonavitController.text) ?? 0.0,
      };
      await registrarEmpleadoEnBD(nuevoEmpleado);

      // Llamar al callback para agregar el empleado a la lista en memoria
      widget.onEmpleadoRegistrado([
        nuevoCodigo,
        nombreController.text,
        apellidoPaternoController.text, apellidoMaternoController.text,
        cuadrilla,
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
      "SELECT codigo FROM empleados WHERE codigo ~ '^EMP[0-9]+\$' ORDER BY CAST(SUBSTRING(codigo FROM 4) AS INTEGER) DESC LIMIT 1;",
    );

    await db.close();

    if (result.isEmpty) return 'EMP001';

    final ultimoCodigo = result.first[0] as String;
    final numero = int.parse(ultimoCodigo.substring(3));
    final siguienteNumero = numero + 1;
    return 'EMP${siguienteNumero.toString().padLeft(3, '0')}';
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
    empresaController.clear();
    puestoController.clear();
    cuadrilla = '';
    tipoEmpleado = '';
    fechaIngreso = null;
    fechaIngresoController.clear();
    sueldoController.clear();
    domingoLaboral = false;
    domingoLaboralMontoController.clear();
    descuentoComedor = false;
    descuentoComedorController.clear();
    descuentoInfonavitController.clear();
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
            // Tipo de Empleado
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
                    'Tipo de Empleado',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: DropdownButtonFormField<String>(
                        value: tipoEmpleado.isEmpty ? null : tipoEmpleado,
                        items:
                            ["Temporal", "Fijo"]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) => setState(() => tipoEmpleado = v ?? ''),
                        decoration: InputDecoration(
                          labelText: "Tipo",
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
            ), // Cuadrilla
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
                    'Cuadrilla',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: DropdownButtonFormField<String>(
                        value: cuadrilla.isEmpty ? null : cuadrilla,
                        items:
                            ["Cuadrilla 1", "Cuadrilla 2", "Cuadrilla 3"]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => cuadrilla = v ?? ''),
                        decoration: InputDecoration(
                          labelText: "Cuadrilla",
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
            ), // Fecha de Ingreso
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
                    'Fecha de Ingreso',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
                              labelText: 'Fecha',
                              filled: true,
                              fillColor: grisInput,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Empresa
            Container(
              width: 320,
              height: 140,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Empresa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: _customInput(empresaController, '', grisInput),
                    ),
                  ),
                ],
              ),
            ),
            // Puesto
            Container(
              width: 320,
              height: 140,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Puesto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: _customInput(puestoController, '', grisInput),
                    ),
                  ),
                ],
              ),
            ),
            // Registro Patronal
            Container(
              width: 320,
              height: 140,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registro Patronal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: _customInput(
                        registroPatronalController,
                        '',
                        grisInput,
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
            // Sueldo
            Container(
              width: 320,
              height: 140,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sueldo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Center(
                      child: _customInput(sueldoController, '', grisInput),
                    ),
                  ),
                ],
              ),
            ),
            // Domingo Laboral
            Container(
              width: 320,
              height: 140,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Domingo Laboral',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch(
                        value: domingoLaboral,
                        onChanged: (v) => setState(() => domingoLaboral = v),
                        activeColor: verde,
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Row(
                        children: [
                          Expanded(
                            child: _customInput(
                              domingoLaboralMontoController,
                              '',
                              grisInput,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '/ hr',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Descuento Comedor
            Container(
              width: 320,
              height: 140,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Descuento Comedor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch(
                        value: descuentoComedor,
                        onChanged: (v) => setState(() => descuentoComedor = v),
                        activeColor: verde,
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Row(
                        children: [
                          Expanded(
                            child: _customInput(
                              descuentoComedorController,
                              '',
                              grisInput,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '%',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ), // Descuento Infonavit
            Container(
              width: 290,
              height: 100,
              decoration: cardDecoration,
              padding: cardPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Descuento Infonavit',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: descuentoInfonavitController.text.isNotEmpty,
                    onChanged:
                        (v) => setState(() {
                          if (v == true) {
                            descuentoInfonavitController.text = '5.0';
                          } else {
                            descuentoInfonavitController.clear();
                          }
                        }),
                    activeColor: verde,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customInput(
    TextEditingController controller,
    String label,
    Color fillColor, {
    Widget? prefix,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefix: prefix,
        suffix: suffix,
      ),
    );
  }
}
