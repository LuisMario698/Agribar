// Archivo: CuadrillaContent.dart
// Pantalla para la gestión de cuadrillas en el sistema Agribar
// Documentación y estructura profesionalizada
import 'package:flutter/material.dart';
import 'widgets/CuadrillaForm.dart';
import 'widgets/CuadrillaSearchBar.dart';
import 'widgets/CuadrillaDataTable.dart';
import '../../widgets/widgets.dart';

class CuadrillaContent extends StatefulWidget {
  const CuadrillaContent({Key? key}) : super(key: key);

  @override
  State<CuadrillaContent> createState() => _CuadrillaContentState();
}

class _CuadrillaContentState extends State<CuadrillaContent> {
  final TextEditingController claveController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController grupoController = TextEditingController();
  String? actividadSeleccionada;
  final List<String> actividades = ['Destajo', 'Otra'];

  final TextEditingController searchController = TextEditingController();
  final ScrollController _tableScrollController = ScrollController();

  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

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

  List<Map<String, dynamic>> cuadrillasFiltradas = [];

  @override
  void initState() {
    super.initState();
    cuadrillasFiltradas = List.from(cuadrillas);
  }

  void _buscarCuadrilla() {
    String query = searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        cuadrillasFiltradas = List.from(cuadrillas);
      } else {
        cuadrillasFiltradas =
            cuadrillas.where((c) => c['nombre']!.toLowerCase().contains(query)).toList();
      }
    });
  }

  void _crearCuadrilla() {
    if (claveController.text.isEmpty ||
        nombreController.text.isEmpty ||
        grupoController.text.isEmpty ||
        actividadSeleccionada == null) {
      CustomSnackBar.showError(context, 'Por favor llena todos los campos.');
      return;
    }
    else{
      CustomSnackBar.showSuccess(context, 'Cuadrilla creada correctamente');
    }
    
    setState(() {
      cuadrillas.add({
        'nombre': nombreController.text,
        'clave': claveController.text,
        'grupo': grupoController.text,
        'actividad': actividadSeleccionada!,
        'habilitado': true,
      });
      _buscarCuadrilla();
      claveController.clear();
      nombreController.clear();
      grupoController.clear();
      actividadSeleccionada = null;
    });
  }

  bool _validarCredencialesSupervisor(String usuario, String password) {
    return usuario == "supervisor" && password == "1234";
  }

  Future<void> _toggleHabilitado(int index) async {
    bool? result = await AuthDialog.show(
      context: context,
      title: 'Autenticación de Supervisor',
      onValidate: _validarCredencialesSupervisor,
    );
    if (result == true) {
      setState(() {
        String clave = cuadrillasFiltradas[index]['clave'];
        int originalIndex = cuadrillas.indexWhere((c) => c['clave'] == clave);
        if (originalIndex != -1) {
          cuadrillas[originalIndex]['habilitado'] =
              !cuadrillas[originalIndex]['habilitado'];
          final bool habilitado = cuadrillas[originalIndex]['habilitado'];
          CustomSnackBar.showSuccess(
            context,
            'Cuadrilla {habilitada" : "deshabilitada"} correctamente',
          );
          _buscarCuadrilla();
        }
      });
    }
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
                    Text(
                      'Gestión de Cuadrillas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 32),
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    CuadrillaSearchBar(
                      controller: searchController,
                      onSearchPressed: _buscarCuadrilla,
                    ),
                    const SizedBox(height: 24),
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
