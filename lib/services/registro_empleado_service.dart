import 'package:postgres/postgres.dart';
import '../services/database_service.dart';

/// Inserta un nuevo empleado en la base de datos PostgreSQL con sus tres secciones:
/// - empleados
/// - datos_laborales
/// - datos_nomina
Future<void> registrarEmpleadoEnDB({
  required String codigo,
  required String nombre,
  required String apellidoPaterno,
  required String apellidoMaterno,
  required String curp,
  required String rfc,
  required String nss,
  required String estadoOrigen,
  required String tipo,
  required String cuadrilla,
  required DateTime fechaIngreso,
  required String empresa,
  required String puesto,
  required String registroPatronal,
  required bool inactivo,
  required bool deshabilitado,
  required double sueldo,
  required double domingoLaboral,
  required double descuentoComedor,
  required String tipoDescuentoInfonavit,
  required double descuentoInfonavit,
}) async {
  final db = DatabaseService();
  await db.connect();

  try {
    await db.connection.transaction((ctx) async {
      // Insertar en empleados
      final empleadoId = await ctx.query(
        '''
        INSERT INTO empleados (codigo, nombre, apellido_paterno, apellido_materno, curp, rfc, nss, estado_origen)
        VALUES (@codigo, @nombre, @paterno, @materno, @curp, @rfc, @nss, @estado)
        RETURNING id_empleado
        ''',
        substitutionValues: {
          'codigo': codigo,
          'nombre': nombre,
          'paterno': apellidoPaterno,
          'materno': apellidoMaterno,
          'curp': curp,
          'rfc': rfc,
          'nss': nss,
          'estado': estadoOrigen,
        },
      );

      final int idEmpleado = empleadoId.first[0];

      // Insertar en datos_laborales
      await ctx.query(
        '''
        INSERT INTO datos_laborales (id_empleado, tipo, id_cuadrilla, fecha_ingreso, empresa, puesto, registro_patronal, inactivo, deshabilitado)
        VALUES (@id, @tipo, NULL, @fecha, @empresa, @puesto, @registro, @inactivo, @deshabilitado)
        ''',
        substitutionValues: {
          'id': idEmpleado,
          'tipo': tipo,
          'fecha': fechaIngreso.toIso8601String(),
          'empresa': empresa,
          'puesto': puesto,
          'registro': registroPatronal,
          'inactivo': inactivo,
          'deshabilitado': deshabilitado,
        },
      );

      // Insertar en datos_nomina
      await ctx.query(
        '''
        INSERT INTO datos_nomina (id_empleado, sueldo, domingo_laboral, descuento_comedor, tipo_descuento_infonavit, descuento_infonavit)
        VALUES (@id, @sueldo, @domingo, @comedor, @tipo_inf, @desc_inf)
        ''',
        substitutionValues: {
          'id': idEmpleado,
          'sueldo': sueldo,
          'domingo': domingoLaboral,
          'comedor': descuentoComedor,
          'tipo_inf': tipoDescuentoInfonavit,
          'desc_inf': descuentoInfonavit,
        },
      );
    });

    print('✅ Empleado registrado correctamente');
  } catch (e) {
    print('❌ Error al registrar empleado: \$e');
    rethrow;
  } finally {
    await db.close();
  }
}
