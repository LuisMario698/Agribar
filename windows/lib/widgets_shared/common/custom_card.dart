import 'package:flutter/material.dart';

/// Widget personalizado para cards/tarjetas
/// Proporciona un estilo consistente para contenedores
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;

  const CustomCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.width,
    this.height,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (elevation != null) {
      return Card(
        elevation: elevation!,
        color: backgroundColor ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(16),
        ),
        margin: margin ?? EdgeInsets.all(8),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? EdgeInsets.all(16),
          child: child,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin ?? EdgeInsets.all(8),
      padding: padding ?? EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
      ),
      child: child,
    );
  }
}
