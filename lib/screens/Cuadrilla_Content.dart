// Archivo: Cuadrilla_Content.dart
// Pantalla para la gestión de cuadrillas en el sistema Agribar
// Documentación y estructura profesionalizada
import 'package:flutter/material.dart';
import 'cuadrillas/widgets/CuadrillaForm.dart';
import 'cuadrillas/widgets/CuadrillaSearchBar.dart';
import 'cuadrillas/widgets/CuadrillaDataTable.dart';
import '../widgets/widgets.dart';

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
      CustomSnackBar.showError(context, 'Por favor llena todos los campos.');
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
    bool? result = await AuthDialog.show(
      context: context,
      title: 'Autenticación de Supervisor',
      onValidate: _validarCredencialesSupervisor,
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
          final bool habilitado = cuadrillas[originalIndex]['habilitado'];
          CustomSnackBar.showSuccess(
            context,
            'Cuadrilla ${habilitado ? "habilitada" : "deshabilitada"} correctamente',
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
                    CuadrillaForm(
                      claveController: claveController,
                      nombreController: nombreController,
                      grupoController: grupoController,
                      actividadSeleccionada: actividadSeleccionada,
                      actividades: actividades,
                      onActividadChanged: (value) {
                        setState(() {
                          actividadSeleccionada = value;
                        });
                      },
                      onCrear: _crearCuadrilla,
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
                    // Barra de búsqueda modular
                    CuadrillaSearchBar(
                      controller: searchController,
                      onSearchPressed: _buscarCuadrilla,
                    ),
                    const SizedBox(height: 24),
                    // Tabla modular de cuadrillas
                    Card(
                      color: Colors.white,
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 350,
                          child: Scrollbar(
                            controller: _tableScrollController,
                            thumbVisibility: true,
                            child: ListView(
                              controller: _tableScrollController,
                              children: [
                                CuadrillaDataTable(
                                  cuadrillas: cuadrillasFiltradas,
                                  onToggleHabilitado: _toggleHabilitado,
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
