// Archivo: ActividadContent.dart
// Pantalla para la gestión de actividades en el sistema Agribar
// Documentación y estructura profesionalizada
import 'package:flutter/material.dart';
import 'widgets/ActividadForm.dart';
import 'widgets/ActividadSearchBar.dart';
import 'widgets/ActividadDataTable.dart';
import '../../widgets/widgets.dart';

class ActividadContent extends StatefulWidget {
  const ActividadContent({Key? key}) : super(key: key);

  @override
  State<ActividadContent> createState() => _ActividadContentState();
}

class _ActividadContentState extends State<ActividadContent> {
  final TextEditingController claveController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController importeController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();
  String? cuadrillaSeleccionada;
  DateTime? fecha;

  final List<Map<String, String>> cuadrillas = [
    {'nombre': 'Indirectos', 'clave': '000001+390'},
    {'nombre': 'Linea 1', 'clave': '000002+390'},
    {'nombre': 'Linea 2', 'clave': '000003+390'},
    {'nombre': 'Linea 3', 'clave': '000004+390'},
    {'nombre': 'Linea 4', 'clave': '000005+390'},
    {'nombre': 'Linea 5', 'clave': '000006+390'},
    {'nombre': 'Linea 6', 'clave': '000007+390'},
    {'nombre': 'Linea 7', 'clave': '000008+390'},
    {'nombre': 'Linea 8', 'clave': '000009+390'},
    {'nombre': 'Linea 9', 'clave': '000010+390'},
    {'nombre': 'Linea 10', 'clave': '000011+390'},
    {'nombre': 'Linea 11', 'clave': '000012+390'},
    {'nombre': 'Linea 12', 'clave': '000013+390'},
    {'nombre': 'Linea 13', 'clave': '000014+390'},
    {'nombre': 'Linea 14', 'clave': '000015+390'},
    {'nombre': 'Linea 15', 'clave': '000016+390'},
    {'nombre': 'Linea 16', 'clave': '000017+390'},
  ];

  final List<String> actividadesOptions = [
    'Destajo',
    'Tapadora',
    'Limpieza',
    'Cosecha',
    'Riego',
    'Fertilización',
    'Poda',
    'Transplante',
    'Siembra',
    'Aplicación de Plaguicida',
    'Deshierbe',
    'Empaque',
    'Carga',
    'Selección',
    'Supervisión',
    'Mantenimiento',
  ];

  final TextEditingController searchController = TextEditingController();
  final ScrollController _tableScrollController = ScrollController();

  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  final List<Map<String, dynamic>> actividades = [
    {
      'clave': '1',
      'fecha': '25/04/2025',
      'importe': '\u024300',
      'actividad': 'Destajo',
      'cuadrilla': 'Indirectos',
      'habilitado': true,
    },
    {
      'clave': '1315',
      'fecha': '25/04/2025',
      'importe': '\u024300',
      'actividad': 'Tapadora',
      'cuadrilla': 'Linea 1',
      'habilitado': true,
    },
    {
      'clave': '1305',
      'fecha': '25/04/2025',
      'importe': '\u024200',
      'actividad': 'Limpieza',
      'cuadrilla': 'Linea 2',
      'habilitado': true,
    },
  ];

  List<Map<String, dynamic>> actividadesFiltradas = [];

  @override
  void initState() {
    super.initState();
    actividadesFiltradas = List.from(actividades);
  }

  void _buscarActividad() {
    String query = searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        actividadesFiltradas = List.from(actividades);
      } else {
        actividadesFiltradas =
            actividades
                .where(
                  (a) =>
                      a['actividad']!.toLowerCase().contains(query) ||
                      a['clave']!.toLowerCase().contains(query) ||
                      a['cuadrilla']!.toLowerCase().contains(query),
                )
                .toList();
      }
    });
  }

  void _crearActividad() {
    if (claveController.text.isEmpty ||
        nombreController.text.isEmpty ||
        importeController.text.isEmpty ||
        fechaController.text.isEmpty ||
        cuadrillaSeleccionada == null) {
      CustomSnackBar.showError(context, 'Por favor llena todos los campos.');
      return;
    }
    setState(() {
      actividades.add({
        'clave': claveController.text,
        'fecha': fechaController.text,
        'importe': importeController.text,
        'actividad': nombreController.text,
        'cuadrilla': cuadrillaSeleccionada!,
        'habilitado': true,
      });
      _buscarActividad();
      claveController.clear();
      nombreController.clear();
      importeController.clear();
      fechaController.clear();
      cuadrillaSeleccionada = null;
      fecha = null;
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
        String clave = actividadesFiltradas[index]['clave'];
        int originalIndex = actividades.indexWhere((a) => a['clave'] == clave);
        if (originalIndex != -1) {
          actividades[originalIndex]['habilitado'] =
              !actividades[originalIndex]['habilitado'];
          final bool habilitado = actividades[originalIndex]['habilitado'];
          CustomSnackBar.showSuccess(
            context,
            'Actividad ${habilitado ? "habilitada" : "deshabilitada"} correctamente',
          );
          _buscarActividad();
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
                      'Gestión de Actividades',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 32),
                    ActividadForm(
                      claveController: claveController,
                      nombreController: nombreController,
                      importeController: importeController,
                      fechaController: fechaController,
                      fecha: fecha,
                      actividadesOptions: actividadesOptions,
                      cuadrillas: cuadrillas,
                      cuadrillaSeleccionada: cuadrillaSeleccionada ?? '',
                      onDateSelected: (selectedDate) {
                        setState(() {
                          fecha = selectedDate;
                        });
                      },
                      onCuadrillaChanged: (value) {
                        setState(() {
                          cuadrillaSeleccionada = value;
                        });
                      },
                      onCrear: _crearActividad,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Catalogo de Actividades',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B7A2F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ActividadSearchBar(
                      controller: searchController,
                      onSearchPressed: _buscarActividad,
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
                                ActividadDataTable(
                                  actividades: actividadesFiltradas,
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
