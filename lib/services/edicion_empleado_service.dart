// lib/services/edicion_empleado_service.dart
import 'database_service.dart';

class EdicionEmpleadoService {
  
  /// Helper para parsear valores double de manera segura
  static double _parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) {
      return value.isNaN || value.isInfinite ? 0.0 : value;
    }
    
    if (value is String) {
      final parsed = double.tryParse(value);
      return (parsed == null || parsed.isNaN || parsed.isInfinite) ? 0.0 : parsed;
    }
    
    if (value is int) {
      return value.toDouble();
    }
    
    return 0.0;
  }
  
  /// Verifica si un código de empleado ya existe (excluyendo el empleado actual)
  static Future<bool> verificarCodigoExistente(String codigo, int idEmpleadoActual) async {
    final db = DatabaseService();
    
    try {
      await db.connect();
      
      final resultado = await db.connection.query('''
        SELECT COUNT(*) FROM empleados 
        WHERE codigo = @codigo AND id_empleado != @idEmpleado;
      ''', substitutionValues: {
        'codigo': codigo,
        'idEmpleado': idEmpleadoActual,
      });
      
      await db.close();
      return (resultado.first[0] as int) > 0;
      
    } catch (e) {
      print('❌ Error al verificar código existente: $e');
      await db.close();
      return false;
    }
  }

  /// Obtiene los datos completos del empleado incluyendo información de nómina
  static Future<Map<String, dynamic>?> obtenerEmpleadoCompleto(int idEmpleado) async {
    final db = DatabaseService();
    
    try {
      await db.connect();
      
      final result = await db.connection.query('''
        SELECT 
          e.id_empleado, e.codigo, e.nombre, e.apellido_paterno, e.apellido_materno,
          e.curp, e.rfc, e.nss, e.estado_origen, e.habilitado,
          dn.sueldo, dn.descuento_infonavit, dn.domingo_laboral, dn.descuento_comedor
        FROM empleados e
        LEFT JOIN datos_nomina dn ON e.id_empleado = dn.id_empleado
        WHERE e.id_empleado = @idEmpleado;
      ''', substitutionValues: {'idEmpleado': idEmpleado});
      
      await db.close();
      
      if (result.isEmpty) return null;
      
      final row = result.first;
      return {
        'id_empleado': row[0],
        'codigo': row[1],
        'nombre': row[2],
        'apellido_paterno': row[3],
        'apellido_materno': row[4],
        'curp': row[5],
        'rfc': row[6],
        'nss': row[7],
        'estado_origen': row[8],
        'habilitado': row[9],
        'sueldo': _parseDoubleValue(row[10]),
        'descuento_infonavit': _parseDoubleValue(row[11]),
        'domingo_laboral': row[12],
        'descuento_comedor': _parseDoubleValue(row[13]),
      };
      
    } catch (e) {
      print('❌ Error al obtener empleado completo: $e');
      await db.close();
      return null;
    }
  }

  /// Actualiza los datos básicos del empleado
  static Future<bool> actualizarDatosBasicos(int idEmpleado, Map<String, dynamic> datos) async {
    final db = DatabaseService();
    
    try {
      await db.connect();
      
      // Verificar si el código ya existe en otro empleado
      final codigoExistente = await db.connection.query('''
        SELECT COUNT(*) FROM empleados 
        WHERE codigo = @codigo AND id_empleado != @idEmpleado;
      ''', substitutionValues: {
        'codigo': datos['codigo'],
        'idEmpleado': idEmpleado,
      });
      
      if ((codigoExistente.first[0] as int) > 0) {
        print('❌ Error: El código ${datos['codigo']} ya existe para otro empleado');
        await db.close();
        throw Exception('El código de empleado ${datos['codigo']} ya existe. Por favor, use un código diferente.');
      }
      
      await db.connection.query('''
        UPDATE empleados SET
          codigo = @codigo,
          nombre = @nombre,
          apellido_paterno = @apellidoPaterno,
          apellido_materno = @apellidoMaterno,
          curp = @curp,
          rfc = @rfc,
          nss = @nss,
          estado_origen = @estadoOrigen
        WHERE id_empleado = @idEmpleado;
      ''', substitutionValues: {
        'idEmpleado': idEmpleado,
        'codigo': datos['codigo'],
        'nombre': datos['nombre'],
        'apellidoPaterno': datos['apellido_paterno'],
        'apellidoMaterno': datos['apellido_materno'],
        'curp': datos['curp'],
        'rfc': datos['rfc'],
        'nss': datos['nss'],
        'estadoOrigen': datos['estado_origen'],
      });
      
      await db.close();
      print('✅ Datos básicos actualizados correctamente');
      return true;
      
    } catch (e) {
      print('❌ Error al actualizar datos básicos: $e');
      await db.close();
      rethrow; // Re-lanzar la excepción para que el diálogo pueda capturarla
    }
  }

  /// Actualiza solo los datos de nómina editables del empleado
  static Future<bool> actualizarDatosNomina(int idEmpleado, Map<String, dynamic> datos) async {
    final db = DatabaseService();
    
    try {
      await db.connect();
      
      // Validar límites de la base de datos antes de actualizar
      final sueldo = datos['sueldo'] as double;
      final descuentoInfonavit = datos['descuento_infonavit'] as double;
      
      if (sueldo > 999.99) {
        print('❌ Error: Sueldo excede el límite máximo de 999.99');
        await db.close();
        throw Exception('El sueldo no puede ser mayor a \$999.99');
      }
      
      if (descuentoInfonavit > 999.99) {
        print('❌ Error: Descuento INFONAVIT excede el límite máximo de 999.99');
        await db.close();
        throw Exception('El descuento INFONAVIT no puede ser mayor a \$999.99');
      }
      
      // Verificar si existen datos de nómina
      final existeQuery = await db.connection.query('''
        SELECT COUNT(*) FROM datos_nomina WHERE id_empleado = @idEmpleado;
      ''', substitutionValues: {'idEmpleado': idEmpleado});
      
      final existe = (existeQuery.first[0] as int) > 0;
      
      if (existe) {
        // Actualizar solo los campos editables
        await db.connection.query('''
          UPDATE datos_nomina SET
            sueldo = @sueldo,
            descuento_infonavit = @descuentoInfonavit
          WHERE id_empleado = @idEmpleado;
        ''', substitutionValues: {
          'idEmpleado': idEmpleado,
          'sueldo': datos['sueldo'],
          'descuentoInfonavit': datos['descuento_infonavit'],
        });
      } else {
        // Insertar nuevos datos con valores por defecto para campos no editables
        // Nota: domingo_laboral es de tipo numeric, por lo que usamos 0 para false y 1 para true
        await db.connection.query('''
          INSERT INTO datos_nomina (id_empleado, sueldo, domingo_laboral, descuento_comedor, descuento_infonavit)
          VALUES (@idEmpleado, @sueldo, 0, 0.0, @descuentoInfonavit);
        ''', substitutionValues: {
          'idEmpleado': idEmpleado,
          'sueldo': datos['sueldo'],
          'descuentoInfonavit': datos['descuento_infonavit'],
        });
      }
      
      await db.close();
      print('✅ Datos de nómina actualizados correctamente');
      return true;
      
    } catch (e) {
      print('❌ Error al actualizar datos de nómina: $e');
      await db.close();
      rethrow; // Re-lanzar la excepción para que el diálogo la maneje
    }
  }

  /// Actualiza solo el estado habilitado del empleado
  static Future<bool> actualizarEstadoHabilitado(int idEmpleado, bool habilitado) async {
    final db = DatabaseService();
    
    try {
      await db.connect();
      
      await db.connection.query('''
        UPDATE empleados SET
          habilitado = @habilitado
        WHERE id_empleado = @idEmpleado;
      ''', substitutionValues: {
        'idEmpleado': idEmpleado,
        'habilitado': habilitado,
      });
      
      await db.close();
      print('✅ Estado habilitado actualizado correctamente');
      return true;
      
    } catch (e) {
      print('❌ Error al actualizar estado habilitado: $e');
      await db.close();
      return false;
    }
  }

  /// Método simplificado para actualizar solo los datos editables del empleado
  static Future<bool> actualizarEmpleadoCompleto(int idEmpleado, Map<String, dynamic> datosCompletos) async {
    try {
      // Actualizar datos básicos (solo campos editables)
      final datosBasicos = {
        'codigo': datosCompletos['codigo'],
        'nombre': datosCompletos['nombre'],
        'apellido_paterno': datosCompletos['apellido_paterno'],
        'apellido_materno': datosCompletos['apellido_materno'],
        'curp': datosCompletos['curp'],
        'rfc': datosCompletos['rfc'],
        'nss': datosCompletos['nss'],
        'estado_origen': datosCompletos['estado_origen'],
      };
      
      // Esto puede lanzar una excepción si hay error de clave duplicada
      await actualizarDatosBasicos(idEmpleado, datosBasicos);
      
      // Actualizar solo los datos de nómina editables con valores seguros
      final datosNomina = {
        'sueldo': _parseDoubleValue(datosCompletos['sueldo']),
        'descuento_infonavit': _parseDoubleValue(datosCompletos['descuento_infonavit']),
      };
      
      // Esto puede lanzar una excepción si hay error de límites numéricos
      await actualizarDatosNomina(idEmpleado, datosNomina);
      
      return true;
      
    } catch (e) {
      print('❌ Error al actualizar empleado completo: $e');
      rethrow; // Re-lanzar la excepción para que el diálogo la maneje
    }
  }
}