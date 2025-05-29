import '../services/database_service.dart';

Future<void> registrarEmpleadoEnBD(Map<String, dynamic> datos) async {
  final db = DatabaseService();

  try {
    await db.connect();

    final result = await db.connection.query(
      '''
      INSERT INTO empleados (codigo, nombre, apellido_paterno, apellido_materno, curp, rfc, nss, estado_origen)
      VALUES (@codigo, @nombre, @apellidoPaterno, @apellidoMaterno, @curp, @rfc, @nss, @estado)
      RETURNING id_empleado;
    ''',
      substitutionValues: {
        'codigo': datos['codigo'],
        'nombre': datos['nombre'],
        'apellidoPaterno': datos['apellidoPaterno'],
        'apellidoMaterno': datos['apellidoMaterno'],
        'curp': datos['curp'],
        'rfc': datos['rfc'],
        'nss': datos['nss'],
        'estado': datos['estado'],
      },
    );

    final int idEmpleado = result.first[0];

    await db.connection.query(
      '''
      INSERT INTO datos_laborales (id_empleado, tipo, id_cuadrilla, fecha_ingreso, empresa, puesto, registro_patronal, inactivo, deshabilitado)
      VALUES (@idEmpleado, @tipo, @idCuadrilla, @fechaIngreso, @empresa, @puesto, @registroPatronal, false, false);
    ''',
      substitutionValues: {
        'idEmpleado': idEmpleado,
        'tipo': datos['tipo'],
        'idCuadrilla': datos['idCuadrilla'],
        'fechaIngreso': datos['fechaIngreso'],
        'empresa': datos['empresa'],
        'puesto': datos['puesto'],
        'registroPatronal': datos['registroPatronal'],
      },
    );

    await db.connection.query(
      '''
      INSERT INTO datos_nomina (id_empleado, sueldo, domingo_laboral, descuento_comedor, tipo_descuento_infonavit, descuento_infonavit)
      VALUES (@idEmpleado, @sueldo, @domingoLaboral, @descuentoComedor, @tipoDescuento, @descuentoInfonavit);
    ''',
      substitutionValues: {
        'idEmpleado': idEmpleado,
        'sueldo': datos['sueldo'],
        'domingoLaboral': datos['domingoLaboral'],
        'descuentoComedor': datos['descuentoComedor'],
        'tipoDescuento': datos['tipoDescuento'],
        'descuentoInfonavit': datos['descuentoInfonavit'],
      },
    );

    print('✅ Empleado registrado correctamente');
  } catch (e) {
    print('❌ Error al registrar empleado: $e');
  } finally {
    await db.close();
  }
}
