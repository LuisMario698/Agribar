import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget para una celda editable individual de la tabla de nómina
class EditableTableCell extends StatefulWidget {
  final String fieldKey;
  final String initialValue;
  final bool isReadOnly;
  final bool isExpanded;
  final Function(String) onChanged;
  final bool showCurrencyPrefix;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;
  final double? height;
  final double? fontSize;

  const EditableTableCell({
    Key? key,
    required this.fieldKey,
    required this.initialValue,
    required this.onChanged,
    this.isReadOnly = false,
    this.isExpanded = false,
    this.showCurrencyPrefix = false,
    this.borderRadius,
    this.margin,
    this.height,
    this.fontSize,
  }) : super(key: key);

  @override
  State<EditableTableCell> createState() => _EditableTableCellState();
}

class _EditableTableCellState extends State<EditableTableCell> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isActivelyEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isActivelyEditing = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus) {
      // Limpiar el "0" automáticamente al enfocar
      if (_controller.text == '0') {
        _controller.clear();
      }
    } else {
      // Si queda vacío al perder el foco, poner "0"
      if (_controller.text.isEmpty) {
        _controller.text = '0';
        widget.onChanged('0');
      }
    }
  }

  /// Limpia el valor numérico removiendo formatos y caracteres no válidos
  String _cleanNumericValue(String value) {
    if (value.isEmpty) return '';
    
    // Remover símbolos de moneda, espacios, puntos y cualquier carácter no numérico
    String cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si está vacío después de limpiar, retornar cadena vacía
    if (cleaned.isEmpty) return '';
    
    // Remover ceros a la izquierda, excepto si es solo "0"
    cleaned = cleaned.replaceFirst(RegExp(r'^0+'), '');
    if (cleaned.isEmpty) cleaned = '0';
    
    return cleaned;
  }

  String _formatCurrency(String value) {
    final numValue = int.tryParse(value) ?? 0;
    return '\$${numValue}';
  }

  @override
  void didUpdateWidget(EditableTableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // CORRECCIÓN: Siempre actualizar si el valor inicial cambió, sin importar si está editando
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
      // Si no está siendo editado activamente, notificar el cambio
      if (!_isActivelyEditing) {
        widget.onChanged(widget.initialValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isReadOnly) {
      return Container(
        height: widget.height ?? (widget.isExpanded ? 48 : 40),
        margin: widget.margin,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: widget.borderRadius ?? 
            BorderRadius.circular(widget.isExpanded ? 8 : 4),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          widget.showCurrencyPrefix 
            ? _formatCurrency(widget.initialValue)
            : widget.initialValue,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: widget.fontSize ?? (widget.isExpanded ? 14 : 11),
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
      );
    }

    return Container(
      height: widget.height ?? (widget.isExpanded ? 48 : 40),
      margin: widget.margin,
      child: TextFormField(
        key: ValueKey(widget.fieldKey),
        controller: _controller,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        style: TextStyle(
          fontSize: widget.fontSize ?? (widget.isExpanded ? 14 : 11),
          fontWeight: FontWeight.w500,
          color: const Color(0xFF374151),
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? 8 : 4,
            vertical: widget.isExpanded ? 12 : 8,
          ),
          border: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? 
              BorderRadius.circular(widget.isExpanded ? 8 : 4),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? 
              BorderRadius.circular(widget.isExpanded ? 8 : 4),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: widget.borderRadius ?? 
              BorderRadius.circular(widget.isExpanded ? 8 : 4),
            borderSide: const BorderSide(
              color: Color(0xFF7BAE2F),
              width: 2,
            ),
          ),
          hintText: '0',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: widget.fontSize ?? (widget.isExpanded ? 14 : 11),
          ),
          prefixText: widget.showCurrencyPrefix ? '\$' : null,
          prefixStyle: widget.showCurrencyPrefix ? TextStyle(
            fontSize: widget.fontSize ?? (widget.isExpanded ? 14 : 11),
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ) : null,
        ),
        onChanged: (value) {
          final cleanedValue = _cleanNumericValue(value);
          widget.onChanged(cleanedValue.isEmpty ? '0' : cleanedValue);
        },
      ),
    );
  }
}
