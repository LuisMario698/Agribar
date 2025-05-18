import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import 'AppTheme.dart';
import 'package:agribar/main.dart';

class ConfiguracionContent extends StatefulWidget {
  final AppTheme appTheme;
  final void Function(AppTheme)? onThemeChanged;
  const ConfiguracionContent({
    Key? key,
    this.appTheme = AppTheme.light,
    this.onThemeChanged,
  }) : super(key: key);
  @override
  State<ConfiguracionContent> createState() => _ConfiguracionContentState();
}

class _ConfiguracionContentState extends State<ConfiguracionContent> {
  bool showTableModal = false;
  List<List<String>>? loadedData;
  String? modalTitle;
  late AppTheme appTheme;
  final GlobalKey<_UserListCardState> _userListCardKey =
      GlobalKey<_UserListCardState>();

  @override
  void initState() {
    super.initState();
    appTheme = widget.appTheme;
  }

  void _simulateFilePick(String section) {
    // Simula la selección de un archivo y carga datos de ejemplo según la sección
    List<List<String>> data;
    String title;
    switch (section) {
      case 'Cuadrillas':
        title = 'Cuadrillas cargadas';
        data = [
          ['ID', 'Nombre', 'Supervisor'],
          ['1', 'Cuadrilla Norte', 'Juan Pérez'],
          ['2', 'Cuadrilla Sur', 'Ana López'],
        ];
        break;
      case 'Actividades':
        title = 'Actividades cargadas';
        data = [
          ['ID', 'Actividad', 'Fecha'],
          ['1', 'Riego', '2024-06-01'],
          ['2', 'Cosecha', '2024-06-02'],
        ];
        break;
      case 'Empleados':
        title = 'Empleados cargados';
        data = [
          ['ID', 'Nombre', 'Rol'],
          ['1', 'Carlos Ruiz', 'Supervisor'],
          ['2', 'María Torres', 'Capturista'],
        ];
        break;
      default:
        title = 'Datos cargados';
        data = [
          ['ID', 'Nombre', 'Rol'],
          ['1', 'Juan Pérez', 'Admin'],
        ];
    }
    setState(() {
      loadedData = data;
      modalTitle = title;
      showTableModal = true;
    });
  }

  void _closeModal() {
    setState(() {
      showTableModal = false;
      loadedData = null;
      modalTitle = null;
    });
  }

  void _setTheme(AppTheme theme) {
    setState(() {
      appTheme = theme;
    });
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(theme);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definición manual de colores para cada tema
    final isDark = appTheme == AppTheme.dark;
    final bgColor = isDark ? Color(0xFF232323) : Color(0xFFF3E9D2);
    final cardColor = isDark ? Color(0xFF2D2D2D) : Colors.white;
    final cardShadow = isDark ? Colors.black54 : Colors.black12;
    final textColor = isDark ? Color(0xFFEFEFEF) : Colors.black;
    final subTextColor = isDark ? Color(0xFFB0B0B0) : Colors.black87;
    final iconGreen = Color(0xFF5BA829);
    final iconBrown = Color(0xFF7B6A3A);
    final highlight = isDark ? Color(0xFF3A4D2C) : Color(0xFFDAF2C7);
    final buttonBg = isDark ? Color(0xFF5BA829) : Color(0xFF5BA829);
    final buttonFg = Colors.white;
    final uploadRowBg = isDark ? Color(0xFF353535) : Color(0xFFE0DED7);
    final uploadRowActive = isDark ? Color(0xFF3A4D2C) : Color(0xFFDAF2C7);
    final modalBg = isDark ? Color(0xFF232323) : Colors.white;
    final modalText = isDark ? Color(0xFFEFEFEF) : Colors.black;

    final screenSize = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double maxW =
                        constraints.maxWidth > 1100
                            ? 1100
                            : constraints.maxWidth;
                    double col1W = maxW * 0.43;
                    double col2W = maxW * 0.57 - 32;
                    return Container(
                      width: maxW,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Resolución actual: ${screenSize.width.toInt()} x ${screenSize.height.toInt()}',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 24),
                          Center(
                            child: Container(
                              width: maxW,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Columna 1: Cargar desde excel y Temas
                                  Container(
                                    width: col1W,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _ConfigCard(
                                          color: cardColor,
                                          shadow: cardShadow,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.add_box_rounded,
                                                    color: iconBrown,
                                                    size: 36,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Cargar desde excel',
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 18),
                                              Column(
                                                children: [
                                                  _UploadRow(
                                                    label: 'Cuadrillas',
                                                    iconColor: iconGreen,
                                                    onUpload:
                                                        () => _simulateFilePick(
                                                          'Cuadrillas',
                                                        ),
                                                    bgColor: uploadRowBg,
                                                    activeColor:
                                                        uploadRowActive,
                                                    textColor: textColor,
                                                  ),
                                                  SizedBox(height: 10),
                                                  _UploadRow(
                                                    label: 'Actividades',
                                                    iconColor: iconGreen,
                                                    onUpload:
                                                        () => _simulateFilePick(
                                                          'Actividades',
                                                        ),
                                                    bgColor: uploadRowBg,
                                                    activeColor:
                                                        uploadRowActive,
                                                    textColor: textColor,
                                                  ),
                                                  SizedBox(height: 10),
                                                  _UploadRow(
                                                    label: 'Empleados',
                                                    iconColor: iconGreen,
                                                    onUpload:
                                                        () => _simulateFilePick(
                                                          'Empleados',
                                                        ),
                                                    bgColor: uploadRowBg,
                                                    activeColor:
                                                        uploadRowActive,
                                                    textColor: textColor,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 32),
                                        _ConfigCard(
                                          color: cardColor,
                                          shadow: cardShadow,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.change_history,
                                                    color: iconBrown,
                                                    size: 32,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Temas',
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 18),
                                              _ThemeButtonList(
                                                currentTheme: appTheme,
                                                onThemeSelected: _setTheme,
                                                highlight: highlight,
                                                textColor: textColor,
                                                iconGreen: iconGreen,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 32),
                                  // Columna 2: Administrar Usuarios (ocupa el mismo alto que la columna 1)
                                  Container(
                                    width: col2W,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        _ConfigCard(
                                          color: cardColor,
                                          shadow: cardShadow,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minHeight: 440,
                                              maxHeight: 600,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.person,
                                                      color: iconBrown,
                                                      size: 36,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Administrar Usuarios',
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                    Spacer(),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.add,
                                                        color: iconGreen,
                                                        size: 28,
                                                      ),
                                                      tooltip:
                                                          'Agregar usuario',
                                                      onPressed: () {
                                                        _userListCardKey
                                                            .currentState
                                                            ?.showAddUserDialog(
                                                              isDark:
                                                                  textColor ==
                                                                  Colors.white,
                                                            );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 18),
                                                Expanded(
                                                  child: _UserListCard(
                                                    key: _userListCardKey,
                                                    textColor: textColor,
                                                    subTextColor: subTextColor,
                                                    cardColor: cardColor,
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
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (showTableModal && loadedData != null)
            Positioned.fill(
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(color: Colors.black.withOpacity(0)),
                  ),
                  Center(
                    child: Container(
                      width: 600,
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: modalBg,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            modalTitle ?? 'Datos cargados',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: modalText,
                            ),
                          ),
                          SizedBox(height: 24),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns:
                                  loadedData![0]
                                      .map(
                                        (h) => DataColumn(
                                          label: Text(
                                            h,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: modalText,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              rows:
                                  loadedData!
                                      .skip(1)
                                      .map(
                                        (row) => DataRow(
                                          cells:
                                              row
                                                  .map(
                                                    (cell) => DataCell(
                                                      Text(
                                                        cell,
                                                        style: TextStyle(
                                                          color: modalText,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                          SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _closeModal,
                            child: Text('Cerrar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonBg,
                              foregroundColor: buttonFg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
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
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color shadow;
  const _ConfigCard({
    required this.child,
    required this.color,
    required this.shadow,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: child,
    );
  }
}

class _ThemeButtonList extends StatelessWidget {
  final AppTheme currentTheme;
  final void Function(AppTheme) onThemeSelected;
  final Color highlight;
  final Color textColor;
  final Color iconGreen;
  const _ThemeButtonList({
    required this.currentTheme,
    required this.onThemeSelected,
    required this.highlight,
    required this.textColor,
    required this.iconGreen,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ThemeButton(
          label: 'Modo Claro',
          icon: Icons.wb_sunny_rounded,
          selected: currentTheme == AppTheme.light,
          onTap: () => onThemeSelected(AppTheme.light),
          highlight: highlight,
          textColor: textColor,
          iconColor: iconGreen,
        ),
        SizedBox(height: 10),
        _ThemeButton(
          label: 'Modo Oscuro',
          icon: Icons.nightlight_round,
          selected: currentTheme == AppTheme.dark,
          onTap: () => onThemeSelected(AppTheme.dark),
          highlight: highlight,
          textColor: textColor,
          iconColor: iconGreen,
        ),
      ],
    );
  }
}

class _ThemeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color highlight;
  final Color textColor;
  final Color iconColor;
  const _ThemeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.highlight,
    required this.textColor,
    required this.iconColor,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? highlight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: iconColor, width: 2) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadRow extends StatelessWidget {
  final String label;
  final Color iconColor;
  final VoidCallback onUpload;
  final Color bgColor;
  final Color activeColor;
  final Color textColor;
  const _UploadRow({
    required this.label,
    required this.iconColor,
    required this.onUpload,
    required this.bgColor,
    required this.activeColor,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: textColor,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.upload_file, color: iconColor, size: 28),
          onPressed: onUpload,
          tooltip: 'Subir archivo',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        dense: true,
      ),
    );
  }
}

class BlurredDialog extends StatelessWidget {
  final Widget child;
  const BlurredDialog({required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(color: Colors.black.withOpacity(0.08)),
          ),
        ),
        Center(child: child),
      ],
    );
  }
}

class _UserListCard extends StatefulWidget {
  final Color textColor;
  final Color subTextColor;
  final Color cardColor;
  const _UserListCard({
    Key? key,
    required this.textColor,
    required this.subTextColor,
    required this.cardColor,
  }) : super(key: key);
  @override
  State<_UserListCard> createState() => _UserListCardState();
}

class _UserListCardState extends State<_UserListCard> {
  List<_UserData> users = [
    _UserData('José Luis Perez Lopez', 'Admin', Color(0xFF7BAE2F)),
    _UserData('Jesus Quintero Cazares', 'Capturista', Color(0xFF2B8DDB)),
    _UserData('Adalberto Sainz Gomez', 'Supervisor', Color(0xFF7B6A3A)),
  ];
  int? editingIndex;

  void _showEditUserDialog(int index) async {
    final user = users[index];
    final nameController = TextEditingController(text: user.name);
    final passController = TextEditingController();
    String tipo = user.role;
    Color tipoColor = user.roleColor;
    final tipos = [
      {'label': 'Admin', 'color': Color(0xFF7BAE2F)},
      {'label': 'Capturista', 'color': Color(0xFF2B8DDB)},
      {'label': 'Supervisor', 'color': Color(0xFF7B6A3A)},
    ];
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return BlurredDialog(
          child: Dialog(
            backgroundColor: widget.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Editar usuario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: widget.subTextColor),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: widget.textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      labelStyle: TextStyle(
                        color: widget.subTextColor,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: widget.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    style: TextStyle(color: widget.textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: TextStyle(
                        color: widget.subTextColor,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: widget.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: tipo,
                    items:
                        tipos
                            .map(
                              (t) => DropdownMenuItem(
                                value: t['label'] as String,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: t['color'] as Color,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      t['label'] as String,
                                      style: TextStyle(
                                        color: widget.textColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      setState(() {
                        tipo = v!;
                        tipoColor =
                            tipos.firstWhere((t) => t['label'] == v)['color']
                                as Color;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      labelStyle: TextStyle(
                        color: widget.subTextColor,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: widget.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (index !=
                          null) // Solo mostrar el botón de eliminar en modo edición
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              users.removeAt(index!);
                            });
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red[700],
                            size: 18,
                          ),
                          label: Text(
                            'Eliminar',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          setState(() {
                            if (index != null) {
                              users[index!] = _UserData(
                                nameController.text,
                                tipo,
                                tipoColor,
                              );
                            } else {
                              users.add(
                                _UserData(nameController.text, tipo, tipoColor),
                              );
                            }
                          });
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          index != null ? Icons.save : Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          index != null ? 'Guardar' : 'Crear',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5BA829),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showAddUserDialog({required bool isDark}) async {
    final nameController = TextEditingController();
    final passController = TextEditingController();
    String tipo = 'Admin';
    Color tipoColor = Color(0xFF7BAE2F);
    final tipos = [
      {'label': 'Admin', 'color': Color(0xFF7BAE2F)},
      {'label': 'Capturista', 'color': Color(0xFF2B8DDB)},
      {'label': 'Supervisor', 'color': Color(0xFF7B6A3A)},
    ];
    final modalBg = isDark ? Color(0xFF232323) : Colors.white;
    final textColor = isDark ? Color(0xFFEFEFEF) : Colors.black;
    final fieldBg = isDark ? Color(0xFF353535) : Color(0xFFF3F3F3);
    final iconColor = isDark ? Color(0xFFB0B0B0) : Colors.grey[700]!;
    final addBtn = Color(0xFF5BA829);
    final cancelBtn = isDark ? Color(0xFFB71C1C) : Color(0xFFB71C1C);
    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return BlurredDialog(
          child: Dialog(
            backgroundColor: modalBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: 420,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'AÑADIR NUEVO USUARIO',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 18),
                  Icon(
                    Icons.account_circle,
                    size: 64,
                    color: isDark ? Color(0xFF8AB531) : Color(0xFF1976D2),
                  ),
                  SizedBox(height: 24),
                  // Campo usuario
                  _InputWithIcon(
                    icon: Icons.person,
                    hint: 'Usuario',
                    controller: nameController,
                    obscure: false,
                    fieldBg: fieldBg,
                    iconColor: iconColor,
                    textColor: textColor,
                  ),
                  SizedBox(height: 18),
                  // Campo contraseña
                  _InputWithIcon(
                    icon: Icons.lock,
                    hint: 'Contraseña',
                    controller: passController,
                    obscure: true,
                    fieldBg: fieldBg,
                    iconColor: iconColor,
                    textColor: textColor,
                  ),
                  SizedBox(height: 18),
                  // Campo rol
                  _DropdownWithIcon(
                    icon: Icons.emoji_events,
                    value: tipo,
                    items: tipos.map((t) => t['label'] as String).toList(),
                    onChanged: (v) {
                      setState(() {
                        tipo = v!;
                        tipoColor =
                            tipos.firstWhere((t) => t['label'] == v)['color']
                                as Color;
                      });
                    },
                    fieldBg: fieldBg,
                    iconColor: iconColor,
                    textColor: textColor,
                  ),
                  SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (nameController.text.trim().isEmpty) return;
                            setState(() {
                              users.add(
                                _UserData(nameController.text, tipo, tipoColor),
                              );
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: addBtn,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 18),
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text('Añadir'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cancelBtn,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 18),
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text('Cancelar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: users.length,
          separatorBuilder:
              (_, __) => Divider(height: 1, color: Colors.black12),
          itemBuilder: (context, i) {
            final u = users[i];
            return ListTile(
              onTap: () => _showEditUserDialog(i),
              title: Text(
                u.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: widget.textColor,
                ),
              ),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: u.roleColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  u.role,
                  style: TextStyle(
                    color: u.roleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UserData {
  final String name;
  final String role;
  final Color roleColor;
  _UserData(this.name, this.role, this.roleColor);
}

class _InputWithIcon extends StatelessWidget {
  final IconData icon;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final Color fieldBg;
  final Color iconColor;
  final Color textColor;
  const _InputWithIcon({
    required this.icon,
    required this.hint,
    required this.controller,
    this.obscure = false,
    required this.fieldBg,
    required this.iconColor,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(fontSize: 16, color: textColor),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        hintText: hint,
        hintStyle: TextStyle(color: iconColor),
        filled: true,
        fillColor: fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
    );
  }
}

class _DropdownWithIcon extends StatelessWidget {
  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final Color fieldBg;
  final Color iconColor;
  final Color textColor;
  const _DropdownWithIcon({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.fieldBg,
    required this.iconColor,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items:
            items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e, style: TextStyle(color: textColor)),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: iconColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
        style: TextStyle(fontSize: 16, color: textColor),
        dropdownColor: fieldBg,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}
