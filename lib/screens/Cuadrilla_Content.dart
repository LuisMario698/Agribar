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

  // Lista de cuadrillas (mock data)
  final List<Map<String, String>> cuadrillas = [
    {
      'nombre': 'Indirectos',
      'clave': '000001+390',
      'grupo': 'Grupo Baranzini',
      'actividad': 'Destajo',
    },
    {
      'nombre': 'Linea 1',
      'clave': '000002+390',
      'grupo': 'Grupo Baranzini',
      'actividad': 'Destajo',
    },
    {
      'nombre': 'Linea 3',
      'clave': '000003+390',
      'grupo': 'Grupo Baranzini',
      'actividad': 'Destajo',
    },
  ];

  // Lista filtrada para mostrar en la tabla
  List<Map<String, String>> cuadrillasFiltradas = [];

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
        cuadrillasFiltradas = cuadrillas.where((c) => c['nombre']!.toLowerCase().contains(query)).toList();
      }
    });
  }

  // Crea una nueva cuadrilla y la agrega a la lista
  void _crearCuadrilla() {
    if (claveController.text.isEmpty || nombreController.text.isEmpty || grupoController.text.isEmpty || actividadSeleccionada == null) {
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
      });
      _buscarCuadrilla();
      claveController.clear();
      nombreController.clear();
      grupoController.clear();
      actividadSeleccionada = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: const Color(0xFFF5F5F5), // Fondo gris claro
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Creacion de Cuadrillas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B7A2F),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                                        borderRadius: BorderRadius.circular(8),
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
                                        borderRadius: BorderRadius.circular(8),
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
                                        borderRadius: BorderRadius.circular(8),
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
                                    items: actividades
                                        .map((a) => DropdownMenuItem(
                                              value: a,
                                              child: Text(a),
                                            ))
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
                                        borderRadius: BorderRadius.circular(8),
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
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _crearCuadrilla,
                            child: const Text('Crear', style: TextStyle(fontSize: 18)),
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
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                bottomLeft: Radius.circular(24),
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
                            topRight: Radius.circular(24),
                            bottomRight: Radius.circular(24),
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
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                                headingRowColor: MaterialStateProperty.all(Color(0xFFE0E0E0)),
                                dataRowColor: MaterialStateProperty.all(Colors.white),
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
                                ],
                                rows: cuadrillasFiltradas.map((cuadrilla) {
                                  return DataRow(cells: [
                                    DataCell(Text(cuadrilla['nombre']!)),
                                    DataCell(Text(cuadrilla['clave']!)),
                                    DataCell(Text(cuadrilla['grupo']!)),
                                    DataCell(Text(cuadrilla['actividad']!)),
                                  ]);
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
          ),
        ),
      ),
    );
  }
}
