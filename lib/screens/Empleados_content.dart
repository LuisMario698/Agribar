import 'package:flutter/material.dart';

class EmpleadosContent extends StatefulWidget {
  @override
  State<EmpleadosContent> createState() => _EmpleadosContentState();
}

class _EmpleadosContentState extends State<EmpleadosContent> {
  int _selectedTabIndex = 0;
  final ScrollController _tabScrollController = ScrollController();

  // Datos de la tabla (editable)
  List<List<String>> empleadosData = [
    [
      '*390',
      'Juan Carlos',
      'Rodríguez',
      'Fierro',
      'JOSE FRANCISCO GONZALES REA',
      '241.00',
      'Fijo',
    ],
    [
      '000001*390',
      'Celestino',
      'Hernandez',
      'Martinez',
      'Indirectos',
      '2375.00',
      'Fijo',
    ],
    ['000002*390', 'Ines', 'Cruz', 'Quiroz', 'Indirectos', '2375.00', 'Fijo'],
    [
      '000003*390',
      'Feliciano',
      'Cruz',
      'Quiroz',
      'Indirectos',
      '2375.00',
      'Fijo',
    ],
    [
      '000003*390',
      'Refugio Socorro',
      'Ramirez',
      'Carre--o',
      'Indirectos',
      '2375.00',
      'Fijo',
    ],
    [
      '000004*390',
      'Adela',
      'Rodriguez',
      'Ramirez',
      'Indirectos',
      '2375.00',
      'Fijo',
    ],
  ];

  final List<String> empleadosHeaders = [
    'Clave',
    'Nombre',
    'Apellido Paterno',
    'Apellido Materno',
    'Cuadrilla',
    'Sueldo',
    'Tipo',
  ];

  final List<String> tabTitles = [
    'General',
    'Registro',
    'Registro del Sistema',
  ];

  // Keys para medir cada tab
  final List<GlobalKey> _tabKeys = List.generate(4, (_) => GlobalKey());
  double _indicatorLeft = 0;
  double _indicatorWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setIndicator());
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
      final tabPosition = box.localToGlobal(Offset.zero, ancestor: parentBox);
      setState(() {
        _indicatorLeft = tabPosition.dx;
        _indicatorWidth = box.size.width;
      });
    }
  }

  void agregarEmpleado(List<String> nuevoEmpleado) {
    setState(() {
      empleadosData.add(nuevoEmpleado);
      _selectedTabIndex = 0; // Opcional: regresa a la pestaña General
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TabBar visual mejorado con barrita verde bajo la pestaña activa
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color(0xFFF3F1EA),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildGeneralTab();
      case 1:
        return _buildRegistroTab();
      case 2:
        return _buildRegistroSistemaTab();
      default:
        return _buildGeneralTab();
    }
  }

  Widget _buildGeneralTab() {
    // Calcula cuántas filas vacías hay que agregar
    int minRows = 20;
    int extraRows =
        empleadosData.length < minRows ? minRows - empleadosData.length : 0;
    return Column(
      children: [
        // Métricas
        Row(
          children: [
            _EmpleadosMetricCard(
              title: 'Empleados activos',
              value: '87',
              icon: Icons.person,
            ),
            SizedBox(width: 32),
            _EmpleadosMetricCard(
              title: 'Empleados inactivos',
              value: '87',
              icon: Icons.person,
            ),
          ],
        ),
        SizedBox(height: 32),
        // Tabla NO editable y con bordes redondeados
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
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
              padding: EdgeInsets.all(0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          border: TableBorder.all(
                            color: Color(0xFFE5E5E5),
                            width: 1.2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          headingRowColor: MaterialStateProperty.all(
                            Color(0xFFF3F3F3),
                          ),
                          columnSpacing: 24,
                          columns:
                              empleadosHeaders
                                  .map(
                                    (header) => DataColumn(
                                      label: Text(
                                        header,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          rows: [
                            ...List.generate(empleadosData.length, (rowIdx) {
                              return DataRow(
                                cells: List.generate(empleadosHeaders.length, (
                                  colIdx,
                                ) {
                                  return DataCell(
                                    Container(
                                      width: 140,
                                      child: Text(
                                        empleadosData[rowIdx][colIdx],
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            }),
                            // Filas vacías
                            ...List.generate(extraRows, (i) {
                              return DataRow(
                                cells: List.generate(empleadosHeaders.length, (
                                  colIdx,
                                ) {
                                  return DataCell(
                                    Container(
                                      width: 140,
                                      child: Text(
                                        '',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
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

  Widget _buildRegistroSistemaTab() {
    return Center(child: Text('Contenido de Registro del Sistema'));
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

class _EmpleadosMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _EmpleadosMetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(width: 18),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
  bool inactivo = false;
  bool deshabilitado = false;

  final TextEditingController sueldoController = TextEditingController();
  bool domingoLaboral = false;
  final TextEditingController domingoLaboralMontoController =
      TextEditingController();
  bool descuentoComedor = false;
  final TextEditingController descuentoComedorController =
      TextEditingController();
  String tipoDescuentoInfonavit = '';
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

  // Tipos de descuento INFONAVIT
  final List<String> tiposDescuentoInfonavit = [
    'Porcentaje',
    'Cuota fija',
    'Veces salario mínimo (VSM)',
    'Descuento extraordinario',
  ];

  void _nextStep() {
    if (_currentStep < totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      // Al terminar, agrega el empleado
      widget.onEmpleadoRegistrado([
        codigoController.text,
        nombreController.text,
        apellidoPaternoController.text,
        apellidoMaternoController.text,
        cuadrilla,
        sueldoController.text,
        tipoEmpleado,
      ]);
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('¡Registro completado!')));
      _limpiarCampos();
    }
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
    inactivo = false;
    deshabilitado = false;
    sueldoController.clear();
    domingoLaboral = false;
    domingoLaboralMontoController.clear();
    descuentoComedor = false;
    descuentoComedorController.clear();
    tipoDescuentoInfonavit = '';
    descuentoInfonavitController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_currentStep + 1) / totalSteps;
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
                width: 900,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStepContent(_currentStep, grisInput, verde),
                    ],
                  ),
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
                      icon: Icon(Icons.cancel, color: verde),
                      label: Text('Cancelar', style: TextStyle(color: verde)),
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
                      icon: Icon(Icons.arrow_back, color: verde),
                      label: Text('Anterior', style: TextStyle(color: verde)),
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
                    backgroundColor: verde,
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
            color: i ~/ 2 < _currentStep ? verde : Color(0xFFBFC3C7),
          );
        } else {
          int idx = i ~/ 2;
          return Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    idx <= _currentStep ? verde : Color(0xFFBFC3C7),
                child: Text(
                  '${idx + 1}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 8),
              Text(
                titles[idx],
                style: TextStyle(
                  color: idx <= _currentStep ? verde : Color(0xFFBFC3C7),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Código (más pequeño)
        Row(
          children: [
            Flexible(
              flex:
                  1, // Puedes cambiar este valor para hacer el campo 'Código' más chico o grande
              child: _customInput(codigoController, 'Codigo', grisInput),
            ),
            // Si quieres que el campo sea aún más chico, reduce el flex
            Expanded(flex: 2, child: Container()), // Espacio vacío para alinear
          ],
        ),
        SizedBox(height: 28), // Más espacio entre filas
        // Fila 2: Apellido Paterno, Apellido Materno, Nombre
        Row(
          children: [
            Expanded(
              child: _customInput(
                apellidoPaternoController,
                'Apellido Paterno',
                grisInput,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _customInput(
                apellidoMaternoController,
                'Apellido Materno',
                grisInput,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _customInput(nombreController, 'Nombre', grisInput),
            ),
          ],
        ),
        SizedBox(height: 28),
        // Fila 3: CURP, RFC
        Row(
          children: [
            Expanded(child: _customInput(curpController, 'CURP', grisInput)),
            SizedBox(width: 16),
            Expanded(child: _customInput(rfcController, 'RFC', grisInput)),
          ],
        ),
        SizedBox(height: 28),
        // Fila 4: NSS, Estado de Origen
        Row(
          children: [
            Expanded(child: _customInput(nssController, 'NSS', grisInput)),
            SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: estadoOrigen.isEmpty ? null : estadoOrigen,
                items:
                    estadosMexico
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) => setState(() => estadoOrigen = v ?? ''),
                decoration: InputDecoration(
                  labelText: "Estado de Origen",
                  filled: true,
                  fillColor: grisInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _datosLaborales(Color grisInput) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Tipo, Cuadrilla, Fecha de Ingreso
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: tipoEmpleado.isEmpty ? null : tipoEmpleado,
                items:
                    ["Temporal", "Fijo"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) => setState(() => tipoEmpleado = v ?? ''),
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
            SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: cuadrilla.isEmpty ? null : cuadrilla,
                items:
                    ["Cuadrilla 1", "Cuadrilla 2", "Cuadrilla 3"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
            SizedBox(width: 16),
            Expanded(
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
                      labelText: 'Fecha de Ingreso',
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
          ],
        ),
        SizedBox(height: 28),
        // Fila 2: Empresa, Puesto, Registro Patronal
        Row(
          children: [
            Expanded(
              child: _customInput(empresaController, 'Empresa', grisInput),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _customInput(puestoController, 'Puesto', grisInput),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _customInput(
                registroPatronalController,
                'Registro Patronal',
                grisInput,
              ),
            ),
          ],
        ),
        SizedBox(height: 28),
        // Fila 3: Inactivo, Deshabilitado
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SwitchListTile(
                title: Text("Inactivo"),
                value: inactivo,
                onChanged: (v) => setState(() => inactivo = v),
                activeColor: Color(0xFF8AB531),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: SwitchListTile(
                title: Text("Deshabilitado"),
                value: deshabilitado,
                onChanged: (v) => setState(() => deshabilitado = v),
                activeColor: Color(0xFF8AB531),
              ),
            ),
            SizedBox(width: 16),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }

  Widget _datosNomina(Color grisInput, Color verde) {
    // Estilo de tarjeta
    BoxDecoration cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
      ],
    );
    EdgeInsets cardPadding = const EdgeInsets.all(24);

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 32,
        runSpacing: 32,
        children: [
          // Sueldo
          Container(
            width: 320,
            decoration: cardDecoration,
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sueldo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                _customInput(sueldoController, '', grisInput),
              ],
            ),
          ),
          // Domingo Laboral
          Container(
            width: 320,
            decoration: cardDecoration,
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(height: 12),
                Row(
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
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Descuento Comedor
          Container(
            width: 320,
            decoration: cardDecoration,
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                SizedBox(height: 12),
                Row(
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
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Tipo Descuento Infonavit y % Descuento Infonavit
          Container(
            width: 320,
            decoration: cardDecoration,
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo Descuento Infonavit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value:
                      tipoDescuentoInfonavit.isEmpty
                          ? null
                          : tipoDescuentoInfonavit,
                  items:
                      tiposDescuentoInfonavit
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged:
                      (v) => setState(() => tipoDescuentoInfonavit = v ?? ''),
                  decoration: InputDecoration(
                    labelText: "Nombre",
                    filled: true,
                    fillColor: grisInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Descuento Infonavit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _customInput(
                        descuentoInfonavitController,
                        '',
                        grisInput,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '%',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
