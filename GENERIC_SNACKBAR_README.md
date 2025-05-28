# GenericSnackBar - Widget Genérico para Notificaciones

El `GenericSnackBar` es un widget genérico creado siguiendo las mejores prácticas de Flutter para mostrar notificaciones tipo SnackBar con estilos consistentes en toda la aplicación Agribar.

## Características

- ✅ Implementación modular y reutilizable
- ✅ Múltiples tipos de notificaciones (success, error, warning, info, custom)
- ✅ Parámetros personalizables
- ✅ Siguiendo el patrón de widgets genéricos establecido en el proyecto
- ✅ Compatibilidad total con el sistema existente

## Uso

### Importación
```dart
import '../../widgets_shared/index.dart';
```

### Métodos Disponibles

#### 1. Notificación de Éxito
```dart
GenericSnackBar.showSuccess(
  context, 
  'Operación completada exitosamente',
  duration: Duration(seconds: 3), // Opcional
  action: SnackBarAction(           // Opcional
    label: 'Deshacer',
    onPressed: () => {},
  ),
);
```

#### 2. Notificación de Error
```dart
GenericSnackBar.showError(
  context, 
  'Error al procesar la solicitud',
  duration: Duration(seconds: 4), // Por defecto 4 segundos para errores
);
```

#### 3. Notificación de Advertencia
```dart
GenericSnackBar.showWarning(
  context, 
  'Esta acción no se puede deshacer',
);
```

#### 4. Notificación de Información
```dart
GenericSnackBar.showInfo(
  context, 
  'Información importante para el usuario',
);
```

#### 5. Notificación Personalizada
```dart
GenericSnackBar.showCustom(
  context,
  message: 'Mensaje personalizado',
  backgroundColor: Colors.purple,
  textColor: Colors.white,
  icon: Icons.star,
  duration: Duration(seconds: 5),
);
```

## Componente Widget

También puedes usar el `GenericSnackBarWidget` como componente independiente:

```dart
GenericSnackBarWidget(
  message: 'Mensaje del snackbar',
  backgroundColor: Colors.blue,
  textColor: Colors.white,
  icon: Icons.info,
  onClose: () => print('SnackBar cerrado'),
)
```

## Migración desde CustomSnackBar

Para migrar código existente desde `CustomSnackBar`:

### Antes:
```dart
import '../../widgets/widgets.dart';

CustomSnackBar.showError(context, 'mensaje');
CustomSnackBar.showSuccess(context, 'mensaje');
```

### Después:
```dart
import '../../widgets_shared/index.dart';

GenericSnackBar.showError(context, 'mensaje');
GenericSnackBar.showSuccess(context, 'mensaje');
```

## Ejemplo de Implementación: Registro de Empleados

### Implementación Actual en `RegistroEmpleadoWizard.dart`:

```dart
import '../../widgets_shared/index.dart';

void _nextStep() {
  if (_currentStep < totalSteps - 1) {
    setState(() => _currentStep++);
  } else {
    // Validar campos obligatorios antes de finalizar
    if (_validarCamposObligatorios()) {
      // Al terminar, agrega el empleado
      widget.onEmpleadoRegistrado([...]);
      setState(() => _currentStep = 0);
      
      // ✅ Mensaje de éxito con GenericSnackBar
      GenericSnackBar.showSuccess(
        context, 
        'Empleado creado correctamente',
        duration: const Duration(seconds: 3),
      );
      _limpiarCampos();
    } else {
      // ✅ Mensaje de error con GenericSnackBar
      GenericSnackBar.showError(
        context,
        'Por favor completa todos los campos obligatorios',
        duration: const Duration(seconds: 4),
      );
    }
  }
}

bool _validarCamposObligatorios() {
  return codigoController.text.isNotEmpty &&
         nombreController.text.isNotEmpty &&
         apellidoPaternoController.text.isNotEmpty &&
         cuadrilla.isNotEmpty &&
         tipoEmpleado.isNotEmpty &&
         sueldoController.text.isNotEmpty;
}
```

### Características de la Implementación:
- ✅ Validación de campos obligatorios
- ✅ Mensaje de éxito al crear empleado correctamente
- ✅ Mensaje de error si faltan campos requeridos  
- ✅ Duración personalizada (3s para éxito, 4s para error)
- ✅ Integración perfecta con el flujo del wizard

## Estado Actual del Proyecto

- ✅ `GenericSnackBar` creado y exportado en `widgets_shared/index.dart`
- ✅ Funcionalidad completa implementada
- ✅ Proyecto compila sin errores
- ✅ **IMPLEMENTADO**: Registro de empleados usa `GenericSnackBar`
- ⚠️ Sistema híbrido: algunos archivos usan `GenericSnackBar`, otros mantienen `CustomSnackBar`

## Archivos Afectados

### Usando GenericSnackBar:
- ✅ `empleados/RegistroEmpleadoWizard.dart` - Mensajes de éxito y error en registro de empleados

### Usando CustomSnackBar (estado actual):
- `auth_dialog.dart`
- `Configuracion_content.dart`
- `Actividades_content.dart`
- `ActividadContent.dart`
- `CuadrillaContent.dart`
- `Cuadrilla_content.dart`

## Próximos Pasos

1. **Migrar archivos individuales** según necesidades del proyecto
2. **Mantener compatibilidad** con el sistema existente
3. **Usar GenericSnackBar** en nuevos desarrollos

---

**Nota**: El widget está listo para ser usado y sigue las mejores prácticas de Flutter establecidas en el proyecto Agribar.
