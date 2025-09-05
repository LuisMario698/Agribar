import 'package:flutter/material.dart';
import '../../services/registrar_actividad.dart';

class SeleccionarActividadModal extends StatefulWidget {
  final String? actividadSeleccionada;

  const SeleccionarActividadModal({
    Key? key,
    this.actividadSeleccionada,
  }) : super(key: key);

  @override
  State<SeleccionarActividadModal> createState() => _SeleccionarActividadModalState();
}

class _SeleccionarActividadModalState extends State<SeleccionarActividadModal> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> actividades = [];
  List<Map<String, dynamic>> actividadesFiltradas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarActividades();
  }

  Future<void> cargarActividades() async {
    try {
      final actividadesBD = await obtenerActividadesDesdeBD();
      setState(() {
        actividades = actividadesBD;
        actividadesFiltradas = List.from(actividadesBD);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar actividades: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void filtrarActividades(String query) {
    setState(() {
      if (query.isEmpty) {
        actividadesFiltradas = List.from(actividades);
      } else {
        actividadesFiltradas = actividades.where((actividad) {
          final nombre = actividad['nombre'].toString().toLowerCase();
          final clave = actividad['clave'].toString().toLowerCase();
          final busqueda = query.toLowerCase();
          return nombre.contains(busqueda) || clave.contains(busqueda);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seleccionar Actividad',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B7A2F),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo de búsqueda
            TextField(
              controller: searchController,
              onChanged: filtrarActividades,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o clave...',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF0B7A2F),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de actividades
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0B7A2F),
                      ),
                    )
                  : actividadesFiltradas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No se encontraron actividades',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: actividadesFiltradas.length,
                          itemBuilder: (context, index) {
                            final actividad = actividadesFiltradas[index];
                            final isSelected = widget.actividadSeleccionada == actividad['nombre'];
                            
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: isSelected
                                    ? const BorderSide(
                                        color: Color(0xFF0B7A2F),
                                        width: 2,
                                      )
                                    : BorderSide.none,
                              ),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0B7A2F)
                                        : const Color(0xFFE8F5E8),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: Text(
                                      actividad['clave'].toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : const Color(0xFF0B7A2F),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  actividad['nombre'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelected ? const Color(0xFF0B7A2F) : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  'Clave: ${actividad['clave']}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF0B7A2F),
                                        size: 20,
                                      )
                                    : const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.grey,
                                        size: 12,
                                      ),
                                onTap: () {
                                  Navigator.of(context).pop(actividad['nombre']);
                                },
                              ),
                            );
                          },
                        ),
            ),

            const SizedBox(height: 16),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
