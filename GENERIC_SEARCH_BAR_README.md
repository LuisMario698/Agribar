# GenericSearchBar Widget

## Descripción
`GenericSearchBar` es un widget genérico y reutilizable para implementar barras de búsqueda en la aplicación Agribar. Proporciona funcionalidad completa de búsqueda con opciones de personalización y callbacks flexibles.

## Características

- ✅ **Búsqueda en tiempo real** con callback `onChanged`
- ✅ **Botón de limpiar** automático con funcionalidad de borrado
- ✅ **Botón de búsqueda** opcional para búsquedas manuales
- ✅ **Iconos personalizables** para búsqueda y limpieza
- ✅ **Estilos configurables** (colores, altura, radio de borde)
- ✅ **Tipo de teclado** personalizable
- ✅ **Integración completa** con el sistema de widgets genéricos

## Uso Básico

### 1. Búsqueda Simple

```dart
GenericSearchBar(
  controller: _searchController,
  hintText: 'Buscar empleados...',
  onChanged: (query) {
    // Lógica de búsqueda en tiempo real
    _performSearch(query);
  },
)
```

### 2. Con Botón de Búsqueda

```dart
GenericSearchBar(
  controller: _searchController,
  hintText: 'Buscar cuadrillas...',
  showSearchButton: true,
  onSearchPressed: () {
    // Búsqueda manual al presionar botón
    _executeSearch();
  },
  onClearPressed: () {
    // Lógica personalizada al limpiar
    _clearResults();
  },
)
```

### 3. Personalización Avanzada

```dart
GenericSearchBar(
  controller: _searchController,
  hintText: 'Buscar actividades...',
  searchIcon: Icons.assignment,
  clearIcon: Icons.close,
  fillColor: const Color(0xFFF3F1EA),
  borderRadius: 12.0,
  height: 50.0,
  keyboardType: TextInputType.text,
  onChanged: _handleSearch,
)
```

## Widget Simplificado: SimpleSearchBar

Para casos de uso básicos, puedes usar `SimpleSearchBar`:

```dart
SimpleSearchBar(
  controller: _controller,
  hintText: 'Buscar...',
  onChanged: _search,
  onClear: _clearSearch,
)
```

## Factory Methods con SearchBarBuilder

El widget incluye métodos factory para casos específicos:

### Para Empleados
```dart
SearchBarBuilder.forEmpleados(
  controller: _employeeController,
  onChanged: _searchEmployees,
)
```

### Para Cuadrillas
```dart
SearchBarBuilder.forCuadrillas(
  controller: _squadController,
  onChanged: _searchSquads,
)
```

### Para Actividades
```dart
SearchBarBuilder.forActividades(
  controller: _activityController,
  onChanged: _searchActivities,
)
```

### Con Botón de Búsqueda
```dart
SearchBarBuilder.withButton(
  controller: _controller,
  hintText: 'Buscar...',
  onSearchPressed: _search,
)
```

## Parámetros Disponibles

| Parámetro | Tipo | Descripción | Por Defecto |
|-----------|------|-------------|-------------|
| `controller` | `TextEditingController` | Controlador del campo de texto | Requerido |
| `hintText` | `String` | Texto de ayuda | `'Buscar...'` |
| `onChanged` | `ValueChanged<String>?` | Callback para cambios de texto | `null` |
| `onSearchPressed` | `VoidCallback?` | Callback para búsqueda manual | `null` |
| `onClearPressed` | `VoidCallback?` | Callback para limpiar | `null` |
| `searchIcon` | `IconData` | Icono de búsqueda | `Icons.search` |
| `clearIcon` | `IconData` | Icono de limpiar | `Icons.clear` |
| `fillColor` | `Color?` | Color de fondo | `Color.fromARGB(59, 139, 139, 139)` |
| `showClearButton` | `bool` | Mostrar botón limpiar | `true` |
| `showSearchButton` | `bool` | Mostrar botón búsqueda | `false` |
| `height` | `double?` | Altura del widget | `null` |
| `borderRadius` | `double` | Radio del borde | `8.0` |
| `keyboardType` | `TextInputType` | Tipo de teclado | `TextInputType.text` |

## Migración desde Widgets Existentes

### Antes (CuadrillaSearchBar original):
```dart
GenericCard(
  child: Row(
    children: [
      Expanded(
        child: GenericTextField(
          controller: controller,
          label: '',
          hintText: 'Buscar cuadrillas...',
          prefix: Icon(Icons.search, color: Colors.grey[700]),
          fillColor: Color.fromARGB(59, 139, 139, 139),
        ),
      ),
    ],
  ),
)
```

### Después (usando GenericSearchBar):
```dart
GenericSearchBar(
  controller: controller,
  hintText: 'Buscar cuadrillas...',
  fillColor: const Color.fromARGB(59, 139, 139, 139),
)
```

## Beneficios del Nuevo Widget

1. **Menos código**: Reduce significativamente la cantidad de código boilerplate
2. **Consistencia**: Mantiene un diseño uniforme en toda la aplicación
3. **Funcionalidad integrada**: Incluye botón de limpiar automático
4. **Flexibilidad**: Múltiples opciones de personalización
5. **Reutilización**: Un solo widget para todos los casos de búsqueda
6. **Mantenibilidad**: Cambios centralizados afectan toda la aplicación

## Compatibilidad

- ✅ Compatible con todos los widgets de Agribar
- ✅ Integrado con el sistema de temas
- ✅ Responsive design automático
- ✅ Accesibilidad incluida (tooltips, labels)

## Notas Técnicas

- El widget utiliza `GenericCard` y `GenericTextField` internamente
- Se eliminan automáticamente parámetros no compatibles con `GenericTextField`
- El botón de limpiar aparece solo cuando hay texto
- Los tooltips se incluyen automáticamente para mejor UX
