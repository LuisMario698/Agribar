import 'package:flutter/material.dart';

/// Widget para encabezados de página
/// Proporciona un header consistente con título, breadcrumbs y acciones
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<String>? breadcrumbs;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? textColor;

  const PageHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.breadcrumbs,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ?? Colors.black87;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
            Wrap(
              children:
                  breadcrumbs!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final breadcrumb = entry.value;
                    final isLast = index == breadcrumbs!.length - 1;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          breadcrumb,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                isLast
                                    ? effectiveTextColor
                                    : effectiveTextColor.withOpacity(0.6),
                            fontWeight:
                                isLast ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        if (!isLast) ...[
                          SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: effectiveTextColor.withOpacity(0.6),
                          ),
                          SizedBox(width: 8),
                        ],
                      ],
                    );
                  }).toList(),
            ),
            SizedBox(height: 12),
          ],

          // Title row
          Row(
            children: [
              if (leading != null) ...[leading!, SizedBox(width: 16)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: effectiveTextColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 16,
                          color: effectiveTextColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...[
                SizedBox(width: 16),
                Row(mainAxisSize: MainAxisSize.min, children: actions!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
