/// Módulo de gestión de empleados del sistema Agribar.
/// Permite visualizar, agregar, editar y eliminar información de empleados,
/// así como gestionar sus datos personales y laborales.

import 'package:flutter/material.dart';
import 'empleados/EmpleadosGeneralTab.dart';
import 'empleados/RegistroEmpleadoWizard.dart';
import '../../widgets/common/auth_dialog.dart';

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
  List<Map<String, dynamic>> empleadosData = [
    {
      'clave': '*390',
      'nombre': 'Juan Carlos',
      'apellidoPaterno': 'Rodríguez',
      'apellidoMaterno': 'Fierro',
      'cuadrilla': 'JOSE FRANCISCO GONZALES REA',
      'sueldo': '241.00',
      'tipo': 'Fijo',
      'habilitado': true,
    },
    {
      'clave': '000001*390',
      'nombre': 'Celestino',
      'apellidoPaterno': 'Hernandez',
      'apellidoMaterno': 'Martinez',
      'cuadrilla': 'Indirectos',
      'sueldo': '2375.00',
      'tipo': 'Fijo',
      'habilitado': true,
    },
    {
      'clave': '000002*390',
      'nombre': 'Ines',
      'apellidoPaterno': 'Cruz',
      'apellidoMaterno': 'Quiroz',
      'cuadrilla': 'Indirectos',
      'sueldo': '2375.00',
      'tipo': 'Fijo',
      'habilitado': true,
    },
    {
      'clave': '000003*390',
      'nombre': 'Feliciano',
      'apellidoPaterno': 'Cruz',
      'apellidoMaterno': 'Quiroz',
      'cuadrilla': 'Indirectos',
      'sueldo': '2375.00',
      'tipo': 'Fijo',
      'habilitado': true,
    },
    {
      'clave': '000003*390',
      'nombre': 'Refugio Socorro',
      'apellidoPaterno': 'Ramirez',
      'apellidoMaterno': 'Carre--o',
      'cuadrilla': 'Indirectos',
      'sueldo': '2375.00',
      'tipo': 'Fijo',
      'habilitado': true,
    },
    {
      'clave': '000004*390',
      'nombre': 'Adela',
      'apellidoPaterno': 'Rodriguez',
      'apellidoMaterno': 'Ramirez',
      'cuadrilla': 'Indirectos',
      'sueldo': '2375.00',
      'tipo': 'Fijo',
      'habilitado': true,
    },
  ];

  final List<String> empleadosHeaders = [
    'Clave',
    'Nombre',
    'Apellido Paterno',
    'Apellido Materno',
    'Cuadrilla',
    'Sueldo',
    'Tipo',
    'Estado',
  ];

  final List<String> tabTitles = ['General', 'Registro'];

  // Keys para medir cada tab
  final List<GlobalKey> _tabKeys = List.generate(4, (_) => GlobalKey());

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
      box.localToGlobal(Offset.zero, ancestor: parentBox);
      setState(() {});
    }
  }

  void agregarEmpleado(List<String> nuevoEmpleado) {
    setState(() {
      empleadosData.add({
        'clave': nuevoEmpleado[0],
        'nombre': nuevoEmpleado[1],
        'apellidoPaterno': nuevoEmpleado[2],
        'apellidoMaterno': nuevoEmpleado[3],
        'cuadrilla': nuevoEmpleado[4],
        'sueldo': nuevoEmpleado[5],
        'tipo': nuevoEmpleado[6],
        'habilitado': true, // Por defecto, nuevo empleado está habilitado
      });
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
    bool? result = await AuthDialog.show(
      context: context,
      title: 'Autenticación de Supervisor',
      message: 'Ingrese sus credenciales para continuar',
      usernameLabel: 'Usuario',
      passwordLabel: 'Contraseña',
      onValidate: _validarCredencialesSupervisor,
    );
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
    } else if (result == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Credenciales inválidas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth =
              (constraints.maxWidth < 800 ? constraints.maxWidth * 0.9 : 1400)
                  .toDouble();

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
        return EmpleadosGeneralTab(
          empleadosData: empleadosData,
          empleadosHeaders: empleadosHeaders,
          toggleHabilitado: _toggleHabilitado,
        );
      case 1:
        return _buildRegistroTab();
      default:
        return EmpleadosGeneralTab(
          empleadosData: empleadosData,
          empleadosHeaders: empleadosHeaders,
          toggleHabilitado: _toggleHabilitado,
        );
    }
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
