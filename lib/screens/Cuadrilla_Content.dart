// Archivo: Cuadrilla_Content.dart
// Pantalla para la gestión de cuadrillas en el sistema Agribar
// Documentación y estructura profesionalizada
import 'package:flutter/material.dart';

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

  // Lista de cuadrillas (mock data) ahora con estado habilitado/deshabilitado
  final List<Map<String, dynamic>> cuadrillas = [
    {
      'nombre': 'Indirectos',
      'clave': '000001+390',
      'grupo': 'Grupo Baranzini',
      'actividad': 'Destajo',
      'habilitado': true,
    },
    {
      'nombre': 'Linea 1',
      'clave': '000002+390',
      'grupo': 'Grupo Baranzini',
      'actividad': 'Destajo',
      'habilitado': true,
    },
    {
      'nombre': 'Linea 3',
      'clave': '000003+390',
      'grupo': 'Grupo Baranzini',
      'actividad': 'Destajo',
      'habilitado': true,
    },
  ];

  // Lista filtrada para mostrar en la tabla
  List<Map<String, dynamic>> cuadrillasFiltradas = [];

  @override
  void initState() {
    super.initState();
    cuadrillasFiltradas = List.from(cuadrillas);
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

  // Crea una nueva cuadrilla y la agrega a la lista
  void _crearCuadrilla() {
    if (claveController.text.isEmpty ||
        nombreController.text.isEmpty ||
        grupoController.text.isEmpty ||
        actividadSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos.')),
      );
      return;
    }
    setState(() {
      cuadrillas.add({
        'nombre': nombreController.text,
        'clave': claveController.text,
        'grupo': grupoController.text,
        'actividad': actividadSeleccionada!,
        'habilitado': true, // Por defecto, nueva cuadrilla está habilitada
      });
      _buscarCuadrilla();
      claveController.clear();
      nombreController.clear();
      grupoController.clear();
      actividadSeleccionada = null;
    });
  }

  // Validar credenciales de supervisor
  bool _validarCredencialesSupervisor(String usuario, String password) {
    return usuario == "supervisor" && password == "1234";
  }

  // Función para cambiar el estado de habilitado/deshabilitado
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
        // Encuentra la cuadrilla en la lista original usando la clave
        String clave = cuadrillasFiltradas[index]['clave'];
        int originalIndex = cuadrillas.indexWhere((c) => c['clave'] == clave);

        if (originalIndex != -1) {
          cuadrillas[originalIndex]['habilitado'] =
              !cuadrillas[originalIndex]['habilitado'];

          // Mostrar mensaje de confirmación
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cuadrilla ${cuadrillas[originalIndex]['habilitado'] ? "habilitada" : "deshabilitada"} correctamente',
              ),
              backgroundColor:
                  cuadrillas[originalIndex]['habilitado']
                      ? Colors.green
                      : Colors.orange,
            ),
          );

          _buscarCuadrilla(); // Actualiza la lista filtrada
        }
      });
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
                                  dataRowColor: MaterialStateProperty.resolveWith<
                                    Color?
                                  >((Set<MaterialState> states) {
                                    // Cambiar color de fondo si está deshabilitado
                                    final rowIndex =
                                        states.contains(MaterialState.selected)
                                            ? states.toList().indexOf(
                                              MaterialState.selected,
                                            )
                                            : -1;
                                    if (rowIndex != -1 &&
                                        rowIndex < cuadrillasFiltradas.length) {
                                      return cuadrillasFiltradas[rowIndex]['habilitado'] ==
                                              false
                                          ? Colors.grey[100]
                                          : null;
                                    }
                                    return null;
                                  }),
                                  border: TableBorder.all(
                                    color: Colors.grey.shade400,
                                    width: 1,
                                    style: BorderStyle.solid,
                                  ),
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'Nombre',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Clave',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Grupo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Actividad',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Estado',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows:
                                      cuadrillasFiltradas.asMap().entries.map((
                                        entry,
                                      ) {
                                        final index = entry.key;
                                        final cuadrilla = entry.value;
                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                cuadrilla['nombre'],
                                                style: TextStyle(
                                                  color:
                                                      cuadrilla['habilitado'] ==
                                                              false
                                                          ? Colors.grey[600]
                                                          : null,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                cuadrilla['clave'],
                                                style: TextStyle(
                                                  color:
                                                      cuadrilla['habilitado'] ==
                                                              false
                                                          ? Colors.grey[600]
                                                          : null,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                cuadrilla['grupo'],
                                                style: TextStyle(
                                                  color:
                                                      cuadrilla['habilitado'] ==
                                                              false
                                                          ? Colors.grey[600]
                                                          : null,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                cuadrilla['actividad'],
                                                style: TextStyle(
                                                  color:
                                                      cuadrilla['habilitado'] ==
                                                              false
                                                          ? Colors.grey[600]
                                                          : null,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                width: 120,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        cuadrilla['habilitado']
                                                            ? Color(
                                                              0xFFE53935,
                                                            ) // Rojo para deshabilitar
                                                            : Color(
                                                              0xFF0B7A2F,
                                                            ), // Verde para habilitar
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed:
                                                      () => _toggleHabilitado(
                                                        index,
                                                      ),
                                                  child: Text(
                                                    cuadrilla['habilitado']
                                                        ? 'Deshabilitar'
                                                        : 'Habilitar',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                    ),
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
