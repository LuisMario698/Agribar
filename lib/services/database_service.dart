// lib/services/database_service.dart
import 'package:postgres/postgres.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class DatabaseService {
  late PostgreSQLConnection _connection;

  /// Crea una nueva conexión segura con configuraciones para caracteres especiales
  static Future<PostgreSQLConnection> createSafeConnection() async {
    final connection = PostgreSQLConnection(
      'localhost',
      5432,
      'AGRIBAR',
      username: 'postgres',
      password: 'admin',
      useSSL: false,
      allowClearTextPassword: false,
      timeoutInSeconds: 30,
      queryTimeoutInSeconds: 30,
      timeZone: 'UTC',
    );
    
    await connection.open();
    
    // Configurar para manejo correcto de UTF-8 y caracteres especiales
    await connection.execute('SET client_encoding TO UTF8;');
    await connection.execute('SET client_min_messages TO WARNING;');
    await connection.execute('SET standard_conforming_strings = on;');
    
    return connection;
  }

  Future<void> connect() async {
    try {
      print('🔌 Intentando conectar a PostgreSQL...');
      _connection = PostgreSQLConnection(
        'localhost',  // Host
        5432,
        'AGRIBAR',
        username: 'postgres',
        password: 'admin',
      );
      await _connection.open();
      print('✅ Conexión a PostgreSQL establecida exitosamente');
    } catch (e) {
      print('❌ Error al conectar con PostgreSQL: $e');
      print('🔍 Detalles del error: ${e.runtimeType}');
      rethrow;
    }
  }

  PostgreSQLConnection get connection => _connection;

  Future<void> close() async {
    try {
      if (_connection.isClosed) {
        return;
      }
      await _connection.close();
    } catch (e) {
      print('❌ Error al cerrar conexión: $e');
    }
  }
}

Future<List<Map<String, dynamic>>> obtenerCuadrillasHabilitadas() async {
  final db = DatabaseService();
  await db.connect();

  final results = await db.connection.query('''
    SELECT id_cuadrilla, clave, nombre
    FROM cuadrillas
    WHERE estado = true
    ORDER BY nombre;
  ''');

  await db.close();

  return results
      .map((row) => {
        'id': row[0], 
        'clave': row[1], 
        'nombre': row[2], 
        'empleados': []
      })
      .toList();
}

Future<List<Map<String, dynamic>>> obtenerEmpleadosHabilitados() async {
  final db = DatabaseService();

  try {
    await db.connect();

    final results = await db.connection.query('''
      SELECT 
        e.id_empleado,
        e.nombre ||' '|| e.apellido_paterno ||' '|| e.apellido_materno as nombre,
        e.curp,
        e.rfc,
        e.nss,
        e.estado_origen,
        e.codigo
      FROM empleados e
    ''');
    
    await db.close();

    final empleadosList = results
        .map(
          (row) => {
            'id': row[0].toString(),
            'nombre': row[1],
            'curp': row[2],
            'rfc': row[3],
            'nss': row[4],
            'lugarProcedencia': row[5],
            'codigo': row[6], 
            'seleccionado': false,
          },
        )
        .toList();
        
    return empleadosList;
  } catch (e) {
    print('❌ Error al obtener empleados habilitados: $e');
    await db.close();
    return [];
  }
}

/// Obtiene las semanas cerradas para mostrar en el historial
Future<List<Map<String, dynamic>>> obtenerSemanasCerradas() async {
  final db = DatabaseService();
  
  try {
    await db.connect();

    final results = await db.connection.query('''
      SELECT 
        s.id_semana,
        s.fecha_inicio,
        s.fecha_fin,
        s.creado_en
      FROM semanas_nomina s
      WHERE s.esta_cerrada = true
      ORDER BY s.fecha_inicio DESC;
    ''');

    print('🔍 [DEBUG] Encontradas ${results.length} semanas cerradas en BD');

    List<Map<String, dynamic>> semanasCerradas = [];

    for (var row in results) {
      final semanaId = row[0];
      final fechaInicio = row[1];
      final fechaFin = row[2];
      
      print('🔍 [DEBUG] Procesando semana ID: $semanaId, fechas: $fechaInicio - $fechaFin');
      
      // Obtener todas las cuadrillas con datos de esta semana
      final cuadrillasInfo = await obtenerCuadrillasDatosCompletos(semanaId);
      
      print('🔍 [DEBUG] Cuadrillas obtenidas para semana $semanaId: ${cuadrillasInfo.length}');
      
      // Calcular total de la semana
      final totalSemana = cuadrillasInfo.fold<double>(
        0.0,
        (sum, cuadrilla) => sum + (cuadrilla['total'] as double),
      );
      
      print('🔍 [DEBUG] Total calculado para semana $semanaId: \$${totalSemana}');

      semanasCerradas.add({
        'id': semanaId,
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
        'cuadrillas': cuadrillasInfo,
        'totalSemana': totalSemana,
        'cuadrillaSeleccionada': 0,
      });
    }

    await db.close();
    print('🔍 [DEBUG] Procesamiento completado, retornando ${semanasCerradas.length} semanas');
    return semanasCerradas;
  } catch (e) {
    print('❌ Error al obtener semanas cerradas: $e');
    print('Stack trace: ${StackTrace.current}');
    await db.close();
    return [];
  }
}

/// Obtiene datos completos de cuadrillas para una semana cerrada
Future<List<Map<String, dynamic>>> obtenerCuadrillasDatosCompletos(int semanaId) async {
  final db = DatabaseService();
  
  try {
    await db.connect();
    
    print('🔍🔍🔍 [HISTORIAL DEBUG] INICIANDO obtenerCuadrillasDatosCompletos para semana ID: $semanaId');

    // PRIMERO: Verificar si hay datos de nómina para esta semana
    final verificarNomina = await db.connection.query('''
      SELECT COUNT(*) as total_registros
      FROM nomina_empleados_semanal
      WHERE id_semana = @semanaId;
    ''', substitutionValues: {'semanaId': semanaId});
    
    final totalRegistros = verificarNomina.isNotEmpty ? verificarNomina.first[0] : 0;
    print('🔍🔍🔍 [HISTORIAL DEBUG] Total registros en nomina_empleados_semanal para semana $semanaId: $totalRegistros');
    
    if (totalRegistros == 0) {
      print('❌❌❌ [HISTORIAL DEBUG] No hay datos de nómina para semana $semanaId - RETORNANDO LISTA VACÍA');
      await db.close();
      return [];
    }

    // Mostrar algunos registros para debug
    final ejemploRegistros = await db.connection.query('''
      SELECT id_nomina, id_empleado, id_cuadrilla, total, total_neto
      FROM nomina_empleados_semanal
      WHERE id_semana = @semanaId
      LIMIT 3;
    ''', substitutionValues: {'semanaId': semanaId});
    
    print('🔍🔍🔍 [HISTORIAL DEBUG] Ejemplo de registros encontrados:');
    for (var reg in ejemploRegistros) {
      print('   - ID Nómina: ${reg[0]}, Empleado: ${reg[1]}, Cuadrilla: ${reg[2]}, Total: ${reg[3]}, Neto: ${reg[4]}');
    }

    // Obtener cuadrillas que tienen empleados en esta semana
    final cuadrillasResult = await db.connection.query('''
      SELECT DISTINCT c.id_cuadrilla, c.nombre
      FROM cuadrillas c
      JOIN nomina_empleados_semanal nes ON c.id_cuadrilla = nes.id_cuadrilla
      WHERE nes.id_semana = @semanaId
      ORDER BY c.nombre;
    ''', substitutionValues: {'semanaId': semanaId});
    
    print('🔍🔍🔍 [HISTORIAL DEBUG] Encontradas ${cuadrillasResult.length} cuadrillas con empleados para semana $semanaId');

    List<Map<String, dynamic>> cuadrillasInfo = [];

    for (var cuadrillaRow in cuadrillasResult) {
      final cuadrillaId = cuadrillaRow[0];
      final cuadrillaNombre = cuadrillaRow[1];
      
      print('🔍 [DEBUG] Procesando cuadrilla: $cuadrillaNombre (ID: $cuadrillaId)');

      // Obtener empleados de esta cuadrilla
      final empleadosResult = await db.connection.query('''
        SELECT 
          e.codigo,                                                     -- [0]
          CONCAT(e.nombre, ' ', e.apellido_paterno, ' ', e.apellido_materno) AS nombre_completo, -- [1]
          e.id_empleado,                                               -- [2]
          n.dia_1, n.dia_2, n.dia_3, n.dia_4, n.dia_5, n.dia_6, n.dia_7, -- [3-9]
          n.total, n.debe, n.subtotal, n.comedor, n.total_neto        -- [10-14]
        FROM nomina_empleados_semanal n
        JOIN empleados e ON e.id_empleado = n.id_empleado
        WHERE n.id_semana = @semanaId AND n.id_cuadrilla = @cuadrillaId;
      ''', substitutionValues: {
        'semanaId': semanaId,
        'cuadrillaId': cuadrillaId,
      });
      
      print('🔍 [DEBUG] Encontrados ${empleadosResult.length} empleados en cuadrilla $cuadrillaNombre');

      List<Map<String, dynamic>> empleadosConTablas = [];
      double totalCuadrilla = 0.0;

      for (var empRow in empleadosResult) {
        // Conversiones seguras de todos los valores
        final totalNeto = _parseDouble(empRow[14]); // total_neto
        final total = _parseDouble(empRow[10]); // total
        final debe = _parseDouble(empRow[11]); // debe
        final subtotal = _parseDouble(empRow[12]); // subtotal
        final comedor = empRow[13]; // comedor (puede ser boolean o número)
        
        print('🔍 [DEBUG] Empleado ${empRow[1]}: total_neto=$totalNeto, total=$total, debe=$debe');
        print('🔍 [DEBUG] Días individuales: D1=${_parseDouble(empRow[3])}, D2=${_parseDouble(empRow[4])}, D3=${_parseDouble(empRow[5])}, D4=${_parseDouble(empRow[6])}, D5=${_parseDouble(empRow[7])}, D6=${_parseDouble(empRow[8])}, D7=${_parseDouble(empRow[9])}');
        
        final empleadoData = {
          'codigo': empRow[0],
          'nombre': empRow[1],
          'id': empRow[2],
          // Formatear los días como espera el widget: dia_X_s para salarios
          'dia_0_s': _parseDouble(empRow[3]),  // dia_1
          'dia_1_s': _parseDouble(empRow[4]),  // dia_2
          'dia_2_s': _parseDouble(empRow[5]),  // dia_3
          'dia_3_s': _parseDouble(empRow[6]),  // dia_4
          'dia_4_s': _parseDouble(empRow[7]),  // dia_5
          'dia_5_s': _parseDouble(empRow[8]),  // dia_6
          'dia_6_s': _parseDouble(empRow[9]),  // dia_7
          'total': total,
          'debe': debe,
          'subtotal': subtotal,
          'comedor': comedor,
          'tabla_principal': {
            'dias': [
              _parseDouble(empRow[3]), // dia_1
              _parseDouble(empRow[4]), // dia_2
              _parseDouble(empRow[5]), // dia_3
              _parseDouble(empRow[6]), // dia_4
              _parseDouble(empRow[7]), // dia_5
              _parseDouble(empRow[8]), // dia_6
              _parseDouble(empRow[9])  // dia_7
            ],
            'total': total,
            'debe': debe,
            'comedor': _parseDouble(comedor), // Convertir comedor a double
            'neto': totalNeto,
          },
        };

        empleadosConTablas.add(empleadoData);
        totalCuadrilla += totalNeto;
      }
      
      print('🔍 [DEBUG] Total cuadrilla $cuadrillaNombre: \$${totalCuadrilla}');

      cuadrillasInfo.add({
        'nombre': cuadrillaNombre,
        'empleados': empleadosConTablas,
        'total': totalCuadrilla,
      });
    }

    await db.close();
    print('🔍 [DEBUG] Retornando ${cuadrillasInfo.length} cuadrillas con datos completos');
    return cuadrillasInfo;
  } catch (e) {
    print('❌ Error al obtener datos completos de cuadrillas: $e');
    print('Stack trace: ${StackTrace.current}');
    await db.close();
    return [];
  }
}

/// Obtiene los empleados asignados a una cuadrilla específica
Future<List<Map<String, dynamic>>> obtenerEmpleadosAsignadosCuadrilla(
  int cuadrillaId, 
  int? semanaId
) async {
  final db = DatabaseService();
  
  try {
    await db.connect();

    // Query para obtener empleados que tienen registros en nómina para esta cuadrilla
    List<List<dynamic>> results;
    
    if (semanaId != null) {
      results = await db.connection.query('''
        SELECT DISTINCT e.id_empleado, e.nombre, e.apellido_paterno, e.apellido_materno,
               nes.id_nomina as nomina_id
        FROM empleados e
        INNER JOIN nomina_empleados_semanal nes ON e.id_empleado = nes.id_empleado
        WHERE nes.id_cuadrilla = @cuadrillaId AND nes.id_semana = @semanaId
        ORDER BY e.nombre, e.apellido_paterno
      ''', substitutionValues: {'cuadrillaId': cuadrillaId, 'semanaId': semanaId});
    } else {
      // Si no hay semana específica, obtener todos los empleados
      results = await db.connection.query('''
        SELECT id_empleado, nombre, apellido_paterno, apellido_materno
        FROM empleados 
        ORDER BY nombre, apellido_paterno
      ''');
    }
    
    await db.close();
    
    final empleadosList = results
        .map((row) => {
              'id': row[0],
              'nombres': row[1],
              'apellidos': '${row[2] ?? ''} ${row[3] ?? ''}'.trim(),
              'codigo': row[0].toString(), // Usar ID como código temporal
              'nomina_id': semanaId != null && row.length > 4 ? row[4] : null,
            })
        .toList();
        
    return empleadosList;
  } catch (e) {
    print('❌ Error al obtener empleados asignados a cuadrilla $cuadrillaId: $e');
    await db.close();
    return [];
  }
}

/// Crea un backup completo de los datos de una semana específica
Future<Map<String, dynamic>> crearBackupSemana(int semanaId, String supervisorUsuario) async {
  try {
    final connection = await DatabaseService.createSafeConnection();
    
    try {
      // Generar timestamp único para el backup
      final now = DateTime.now();
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      
      print('🔄 Iniciando backup para semana $semanaId con timestamp: $timestamp');
      
      // 1. Crear tabla de control de backups si no existe
      await connection.execute('''
        CREATE TABLE IF NOT EXISTS backup_control (
          id SERIAL PRIMARY KEY,
          semana_id INTEGER,
          timestamp VARCHAR(20),
          supervisor_usuario VARCHAR(100),
          fecha_backup TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          estado VARCHAR(20) DEFAULT 'COMPLETADO',
          archivo_backup VARCHAR(255),
          ruta_archivo TEXT,
          tamano_archivo BIGINT
        );
      ''');
      
      // 1.1. Verificar y agregar columnas faltantes si la tabla ya existía
      try {
        // Verificar si existe la columna archivo_backup
        final columnCheck = await connection.query('''
          SELECT column_name 
          FROM information_schema.columns 
          WHERE table_name = 'backup_control' 
          AND column_name = 'archivo_backup'
        ''');
        
        if (columnCheck.isEmpty) {
          print('🔧 Agregando columna archivo_backup a tabla backup_control');
          await connection.execute('ALTER TABLE backup_control ADD COLUMN archivo_backup VARCHAR(255)');
        }
        
        // Verificar si existe la columna ruta_archivo
        final rutaColumnCheck = await connection.query('''
          SELECT column_name 
          FROM information_schema.columns 
          WHERE table_name = 'backup_control' 
          AND column_name = 'ruta_archivo'
        ''');
        
        if (rutaColumnCheck.isEmpty) {
          print('🔧 Agregando columna ruta_archivo a tabla backup_control');
          await connection.execute('ALTER TABLE backup_control ADD COLUMN ruta_archivo TEXT');
        }
        
        // Verificar si existe la columna tamano_archivo
        final tamanoColumnCheck = await connection.query('''
          SELECT column_name 
          FROM information_schema.columns 
          WHERE table_name = 'backup_control' 
          AND column_name = 'tamano_archivo'
        ''');
        
        if (tamanoColumnCheck.isEmpty) {
          print('🔧 Agregando columna tamano_archivo a tabla backup_control');
          await connection.execute('ALTER TABLE backup_control ADD COLUMN tamano_archivo BIGINT');
        }
        
      } catch (alterError) {
        print('⚠️ Error al verificar/agregar columnas: $alterError');
      }
      
      // 2. Crear directorio de backups si no existe
      final backupDir = Directory('backups');
      if (!backupDir.existsSync()) {
        backupDir.createSync();
      }
      
      // 3. Nombre del archivo de backup
      final nombreArchivo = 'backup_semana_${semanaId}_${timestamp}.sql';
      final rutaArchivo = '${backupDir.path}/$nombreArchivo';
      
      // 4. Obtener todos los datos de la semana específica
      print('🔄 Obteniendo datos de la semana $semanaId...');
      final result = await connection.query('''
        SELECT * FROM nomina_empleados_semanal 
        WHERE id_semana = @semanaId
        ORDER BY id_empleado
      ''', substitutionValues: {'semanaId': semanaId});
      
      if (result.isEmpty) {
        print('⚠️ No se encontraron datos para la semana $semanaId');
        return {
          'success': false,
          'error': 'No se encontraron datos para la semana $semanaId',
        };
      }
      
      // 5. Generar el archivo SQL
      final buffer = StringBuffer();
      
      // Header del archivo
      buffer.writeln('-- ====================================================================');
      buffer.writeln('-- BACKUP SISTEMA AGRIBAR');
      buffer.writeln('-- ====================================================================');
      buffer.writeln('-- Semana ID: $semanaId');
      buffer.writeln('-- Timestamp: $timestamp');
      buffer.writeln('-- Supervisor: $supervisorUsuario');
      buffer.writeln('-- Fecha: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}');
      buffer.writeln('-- Registros: ${result.length}');
      buffer.writeln('-- Generado por: Sistema de Nóminas Agribar');
      buffer.writeln('-- ====================================================================');
      buffer.writeln('');
      
      // Limpiar datos existentes de la semana
      buffer.writeln('-- Limpiar datos existentes de la semana $semanaId');
      buffer.writeln('DELETE FROM nomina_empleados_semanal WHERE id_semana = $semanaId;');
      buffer.writeln('');
      
      // Generar INSERTs para cada registro
      buffer.writeln('-- Datos de nómina de la semana $semanaId');
      for (final row in result) {
        final values = row.map((value) {
          if (value == null) return 'NULL';
          if (value is String) return "'${value.replaceAll("'", "''")}'";
          return value.toString();
        }).join(', ');
        
        buffer.writeln('INSERT INTO nomina_empleados_semanal VALUES ($values);');
      }
      
      buffer.writeln('');
      buffer.writeln('-- Fin del backup');
      
      // 6. Escribir archivo
      final archivo = File(rutaArchivo);
      archivo.writeAsStringSync(buffer.toString());
      
      final tamanioArchivo = archivo.lengthSync();
      
      // 7. Registrar en tabla de control
      await connection.execute('''
        INSERT INTO backup_control (
          semana_id, 
          timestamp, 
          supervisor_usuario, 
          archivo_backup,
          ruta_archivo,
          tamano_archivo
        ) VALUES (
          @semanaId,
          @timestamp,
          @supervisorUsuario,
          @nombreArchivo,
          @rutaArchivo,
          @tamanioArchivo
        );
      ''', substitutionValues: {
        'semanaId': semanaId,
        'timestamp': timestamp,
        'supervisorUsuario': supervisorUsuario,
        'nombreArchivo': nombreArchivo,
        'rutaArchivo': rutaArchivo,
        'tamanioArchivo': tamanioArchivo,
      });
      
      print('✅ Backup completado exitosamente:');
      print('  - Archivo: $nombreArchivo');
      print('  - Registros: ${result.length}');
      print('  - Tamaño: ${(tamanioArchivo / 1024).toStringAsFixed(1)} KB');
      print('  - Ubicación: $rutaArchivo');
      
      return {
        'success': true,
        'timestamp': timestamp,
        'archivo': nombreArchivo,
        'ruta': rutaArchivo,
        'tamanio': tamanioArchivo,
        'registros': result.length,
      };
      
    } finally {
      await connection.close();
    }
    
  } catch (e) {
    print('❌ Error al crear backup de semana $semanaId: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// Obtiene el historial de backups realizados
Future<List<Map<String, dynamic>>> obtenerHistorialBackups() async {
  try {
    final connection = await DatabaseService.createSafeConnection();
    
    try {
      // Verificar que la tabla de control existe
      final tablaExiste = await connection.query('''
        SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_schema = 'public' 
          AND table_name = 'backup_control'
        );
      ''');
      
      if (tablaExiste.isEmpty || !tablaExiste.first[0]) {
        print('ℹ️ Tabla backup_control no existe. Retornando lista vacía.');
        return [];
      }
      
      final result = await connection.query('''
        SELECT 
          id,
          semana_id,
          timestamp,
          supervisor_usuario,
          fecha_backup,
          estado,
          archivo_backup,
          ruta_archivo,
          tamano_archivo
        FROM backup_control
        ORDER BY fecha_backup DESC
        LIMIT 50;
      ''');
      
      return result.map((row) {
        return {
          'id': row[0],
          'semana_id': row[1],
          'timestamp': row[2],
          'supervisor_usuario': row[3],
          'fecha_backup': row[4],
          'estado': row[5],
          'archivo_backup': row[6],
          'ruta_archivo': row[7],
          'tamano_archivo': row[8],
        };
      }).toList();
      
    } finally {
      await connection.close();
    }
    
  } catch (e) {
    print('❌ Error al obtener historial de backups: $e');
    return [];
  }
}

/// Descarga un archivo de backup permitiendo al usuario elegir ubicación y nombre
Future<Map<String, dynamic>> descargarBackup(String rutaArchivo, String nombreArchivo) async {
  try {
    // Convertir ruta relativa a absoluta si es necesario
    File archivoOrigen;
    if (rutaArchivo.startsWith('backups/') || rutaArchivo.startsWith('backups\\')) {
      // Es una ruta relativa, convertir a absoluta
      final directorioTrabajo = Directory.current.path;
      final rutaAbsoluta = '$directorioTrabajo\\$rutaArchivo'.replaceAll('/', '\\');
      archivoOrigen = File(rutaAbsoluta);
      print('🔍 Ruta convertida: $rutaArchivo -> $rutaAbsoluta');
    } else {
      // Ya es una ruta absoluta
      archivoOrigen = File(rutaArchivo);
    }
    
    print('🔍 Buscando archivo en: ${archivoOrigen.path}');
    
    if (!archivoOrigen.existsSync()) {
      return {
        'success': false,
        'error': 'El archivo de backup no existe: ${archivoOrigen.path}',
      };
    }
    
    // Abrir diálogo para que el usuario elija dónde guardar
    String? rutaDestino = await FilePicker.platform.saveFile(
      dialogTitle: 'Guardar backup SQL',
      fileName: nombreArchivo,
      type: FileType.custom,
      allowedExtensions: ['sql'],
    );

    if (rutaDestino == null) {
      // Usuario canceló
      return {
        'success': false,
        'error': 'Operación cancelada por el usuario',
        'cancelled': true,
      };
    }

    final archivoDestino = File(rutaDestino);
    
    // Copiar el archivo a la ubicación elegida
    await archivoOrigen.copy(archivoDestino.path);
    
    print('✅ Archivo guardado en: ${archivoDestino.path}');
    
    return {
      'success': true,
      'ruta_descarga': archivoDestino.path,
      'tamano': archivoDestino.lengthSync(),
    };
    
  } catch (e) {
    print('❌ Error en descargarBackup: $e');
    return {
      'success': false,
      'error': 'Error al descargar archivo: $e',
    };
  }
}

/// Marca una semana como cerrada en la base de datos y guarda los datos en historial
Future<bool> cerrarSemanaEnBD(int idSemana, {String? autorizadoPor, List<Map<String, dynamic>>? datosNomina, bool mantenerCuadrillas = true}) async {
  print('🔥🔥🔥 [CERRAR SEMANA] ¡¡¡FUNCIÓN CERRAR SEMANA INICIADA!!! 🔥🔥🔥');
  print('📋 [CERRAR SEMANA] Parámetro recibido - idSemana: $idSemana (tipo: ${idSemana.runtimeType})');
  print('👤 [CERRAR SEMANA] Usuario autorizado: ${autorizadoPor ?? 'NO PROPORCIONADO - ERROR'}');
  
  final db = DatabaseService();
  
  try {
    print('🚀 [CERRAR SEMANA] Iniciando cierre de semana $idSemana...');
    
    print('🔌 [CERRAR SEMANA] Conectando a la base de datos...');
    await db.connect();
    print('✅ [CERRAR SEMANA] Conexión establecida exitosamente');

    print('🔄 Iniciando proceso de cierre para semana $idSemana');

    // 1. VERIFICAR si ya está cerrada
    print('🔍 [CERRAR SEMANA] Verificando si la semana ya está cerrada...');
    final verificarCerrada = await db.connection.query('''
      SELECT esta_cerrada FROM semanas_nomina WHERE id_semana = @idSemana;
    ''', substitutionValues: {'idSemana': idSemana});
    print('🔍 [CERRAR SEMANA] Query ejecutada, resultados: ${verificarCerrada.length}');

    if (verificarCerrada.isNotEmpty && verificarCerrada.first[0] == true) {
      print('⚠️ La semana $idSemana ya está cerrada');
      await db.close();
      return true;
    }
    print('✅ [CERRAR SEMANA] La semana $idSemana está abierta, continuando...');

    // 2. VERIFICAR QUE HAY DATOS DE NÓMINA para preservar
    print('🔍 [CERRAR SEMANA] Verificando datos de nómina existentes...');
    final verificarDatos = await db.connection.query('''
      SELECT COUNT(*) as total_registros,
             COUNT(DISTINCT id_cuadrilla) as total_cuadrillas,
             SUM(total_neto) as total_dinero
      FROM nomina_empleados_semanal
      WHERE id_semana = @idSemana;
    ''', substitutionValues: {'idSemana': idSemana});
    print('🔍 [CERRAR SEMANA] Query de datos ejecutada, resultados: ${verificarDatos.length}');

    if (verificarDatos.isEmpty || _parseInt(verificarDatos.first[0]) == 0) {
      print('⚠️ No hay datos de nómina para preservar en semana $idSemana');
      // Aun así, marcamos la semana como cerrada
    } else {
      final totalRegistros = _parseInt(verificarDatos.first[0]);
      final totalCuadrillas = _parseInt(verificarDatos.first[1]);
      final totalDinero = _parseDouble(verificarDatos.first[2]);
      
      print('📊 Datos a preservar para semana $idSemana:');
      print('   • Registros de empleados: $totalRegistros');
      print('   • Cuadrillas: $totalCuadrillas');
      print('   • Total en dinero: \$${totalDinero}');
    }

    // 3. MARCAR LA SEMANA COMO CERRADA
    print('🔄 [CERRAR SEMANA] Ejecutando UPDATE para cerrar semana...');
    
    // Iniciar transacción explícita
    print('🔄 [CERRAR SEMANA] Iniciando transacción...');
    await db.connection.execute('BEGIN;');
    
    try {
      // Validar que SIEMPRE se proporcione un usuario autorizado
      if (autorizadoPor == null || autorizadoPor.trim().isEmpty) {
        throw Exception('ERROR: Se requiere un usuario autorizado válido para cerrar la semana. No se puede usar "sistema" por defecto.');
      }
      
      final usuarioFinal = autorizadoPor.trim();
      
      print('🔄 [CERRAR SEMANA] Ejecutando UPDATE con parámetros:');
      print('   - idSemana: $idSemana (tipo: ${idSemana.runtimeType})');
      print('   - autorizadoPor: $usuarioFinal');
      
      final updateResult = await db.connection.execute('''
        UPDATE semanas_nomina
        SET esta_cerrada = true,
            fecha_autorizacion = CURRENT_TIMESTAMP,
            autorizado_por = @autorizadoPor
        WHERE id_semana = @idSemana;
      ''', substitutionValues: {
        'idSemana': idSemana,
        'autorizadoPor': usuarioFinal,
      });
      
      print('✅ [CERRAR SEMANA] UPDATE ejecutado exitosamente, filas afectadas: $updateResult');
      
      // Verificar inmediatamente después del UPDATE
      final verificarInmediato = await db.connection.query('''
        SELECT esta_cerrada, fecha_autorizacion, autorizado_por FROM semanas_nomina WHERE id_semana = @idSemana;
      ''', substitutionValues: {'idSemana': idSemana});
      
      if (verificarInmediato.isNotEmpty) {
        final estaCerrada = verificarInmediato.first[0];
        final fechaAuth = verificarInmediato.first[1];
        final autorizado = verificarInmediato.first[2];
        print('🔍 [CERRAR SEMANA] Verificación INMEDIATA después del UPDATE:');
        print('   - esta_cerrada: $estaCerrada');
        print('   - fecha_autorizacion: $fechaAuth');  
        print('   - autorizado_por: $autorizado');
      }
      
      // Confirmar transacción
      await db.connection.execute('COMMIT;');
      print('✅ [CERRAR SEMANA] Transacción confirmada con COMMIT');
      
    } catch (updateError) {
      print('❌ [CERRAR SEMANA] Error en UPDATE: $updateError');
      print('❌ [CERRAR SEMANA] Tipo de error: ${updateError.runtimeType}');
      await db.connection.execute('ROLLBACK;');
      print('🔄 [CERRAR SEMANA] ROLLBACK completado debido al error');
      rethrow;
    }

    // 4. VERIFICAR que se marcó correctamente
    print('🔍 [CERRAR SEMANA] Verificando que el UPDATE fue exitoso...');
    final verificarResultado = await db.connection.query('''
      SELECT esta_cerrada, fecha_autorizacion, autorizado_por FROM semanas_nomina WHERE id_semana = @idSemana;
    ''', substitutionValues: {'idSemana': idSemana});
    print('🔍 [CERRAR SEMANA] Query de verificación ejecutada, resultados: ${verificarResultado.length}');
    
    if (verificarResultado.isNotEmpty) {
      final estaCerradaValor = verificarResultado.first[0];
      final fechaAutorizacion = verificarResultado.first[1];
      final autorizadoPor = verificarResultado.first[2];
      print('🔍 [CERRAR SEMANA] Valores obtenidos después del UPDATE:');
      print('   - esta_cerrada: $estaCerradaValor (tipo: ${estaCerradaValor.runtimeType})');
      print('   - fecha_autorizacion: $fechaAutorizacion');
      print('   - autorizado_por: $autorizadoPor');
      
      // Verificar cada campo individualmente
      if (estaCerradaValor != true) {
        print('❌ [CERRAR SEMANA] FALLA: esta_cerrada no es true, es: $estaCerradaValor');
      }
      if (fechaAutorizacion == null) {
        print('❌ [CERRAR SEMANA] FALLA: fecha_autorizacion es null');
      }
      if (autorizadoPor == null) {
        print('❌ [CERRAR SEMANA] FALLA: autorizado_por es null');
      } else {
        print('✅ [CERRAR SEMANA] Usuario autorizado correcto: $autorizadoPor');
      }
    } else {
      print('❌ [CERRAR SEMANA] No se encontraron resultados en la verificación');
    }

    final exitoso = verificarResultado.isNotEmpty && verificarResultado.first[0] == true;

    if (exitoso) {
      print('✅ Semana $idSemana cerrada exitosamente en semanas_nomina');
      
      // 5. COPIAR DATOS DE SEMANAL A HISTORIAL
      print('� [CERRAR SEMANA] Copiando datos de nomina_empleados_semanal a nomina_empleados_historial...');
      
      try {
        if (datosNomina != null && datosNomina.isNotEmpty) {
          // PASO 1: Eliminar datos existentes
          print('🔄 [HISTORIAL] Eliminando registros existentes para semana $idSemana...');
          await db.connection.execute('''
            DELETE FROM nomina_empleados_historial WHERE id_semana = $idSemana;
          ''');
          
          // PASO 2: Insertar los datos de nómina directamente
          print('🔄 [HISTORIAL] Insertando ${datosNomina.length} registros en historial...');
          print('🔍 [HISTORIAL DEBUG] Primer registro a insertar: ${datosNomina.first}');
          
          int registrosInsertados = 0;
          for (var registro in datosNomina) {
            try {
              await db.connection.execute('''
                INSERT INTO nomina_empleados_historial (
                  id_empleado, id_semana, id_cuadrilla, 
                  dia_1, dia_2, dia_3, dia_4, dia_5, dia_6, dia_7,
                  act_1, act_2, act_3, act_4, act_5, act_6, act_7,
                  campo_1, campo_2, campo_3, campo_4, campo_5, campo_6, campo_7,
                  total, debe, subtotal, comedor, fecha_cierre, usuario_cierre
                ) VALUES (
                  @idEmpleado, @idSemana, @idCuadrilla,
                  @dia1, @dia2, @dia3, @dia4, @dia5, @dia6, @dia7,
                  @act1, @act2, @act3, @act4, @act5, @act6, @act7,
                  @campo1, @campo2, @campo3, @campo4, @campo5, @campo6, @campo7,
                  @total, @debe, @subtotal, @comedor, CURRENT_TIMESTAMP, @usuarioCierre
                );
              ''', substitutionValues: {
                'idEmpleado': registro['id_empleado'],
                'idSemana': idSemana,
                'idCuadrilla': registro['id_cuadrilla'],
                // Días (convertir null a 0)
                'dia1': _parseDouble(registro['dia_1']).round(),
                'dia2': _parseDouble(registro['dia_2']).round(),
                'dia3': _parseDouble(registro['dia_3']).round(),
                'dia4': _parseDouble(registro['dia_4']).round(),
                'dia5': _parseDouble(registro['dia_5']).round(),
                'dia6': _parseDouble(registro['dia_6']).round(),
                'dia7': _parseDouble(registro['dia_7']).round(),  // ¡AGREGADO DIA_7!
                // Actividades (convertir null a 0)
                'act1': _parseInt(registro['act_1'] ?? 0),
                'act2': _parseInt(registro['act_2'] ?? 0),
                'act3': _parseInt(registro['act_3'] ?? 0),
                'act4': _parseInt(registro['act_4'] ?? 0),
                'act5': _parseInt(registro['act_5'] ?? 0),
                'act6': _parseInt(registro['act_6'] ?? 0),
                'act7': _parseInt(registro['act_7'] ?? 0),  // ¡AGREGADO ACT_7!
                // Campos (convertir null a "0")
                'campo1': registro['campo_1']?.toString() ?? "0",
                'campo2': registro['campo_2']?.toString() ?? "0",
                'campo3': registro['campo_3']?.toString() ?? "0",
                'campo4': registro['campo_4']?.toString() ?? "0",
                'campo5': registro['campo_5']?.toString() ?? "0",
                'campo6': registro['campo_6']?.toString() ?? "0",
                'campo7': registro['campo_7']?.toString() ?? "0",  // ¡AGREGADO CAMPO_7!
                // Totales
                'total': _parseDouble(registro['total']).round(),
                'debe': _parseDouble(registro['debe']).round(),
                'subtotal': _parseDouble(registro['subtotal']).round(),
                'comedor': _parseDouble(registro['comedor']).round(),
                'usuarioCierre': autorizadoPor,
              });
              registrosInsertados++;
            } catch (insertError) {
              print('❌ [HISTORIAL] Error al insertar registro ${registro['id_empleado']}: $insertError');
              print('❌ [HISTORIAL] Registro problemático: $registro');
            }
          }
          
          // VERIFICAR que los datos se insertaron
          final verificacion = await db.connection.query('''
            SELECT COUNT(*) FROM nomina_empleados_historial WHERE id_semana = $idSemana;
          ''');
          print('✅ [HISTORIAL] ¡DATOS GUARDADOS! $registrosInsertados/${datosNomina.length} registros insertados');
          print('✅ [HISTORIAL] VERIFICACIÓN: ${verificacion.first[0]} registros en historial para semana $idSemana');
        } else {
          print('⚠️ [HISTORIAL] No se proporcionaron datos de nómina para guardar en historial');
        }
        print('📋 Los datos de la semana $idSemana ya están disponibles para reportes');
        
        // 6. LIMPIAR O MANTENER CUADRILLAS SEGÚN ELECCIÓN
        if (!mantenerCuadrillas) {
          print('🔄 [LIMPIAR] Eliminando datos de nomina_empleados_semanal para la siguiente semana...');
          try {
            await db.connection.execute('''
              DELETE FROM nomina_empleados_semanal WHERE id_semana = $idSemana;
            ''');
            print('✅ [LIMPIAR] Datos eliminados, cuadrillas reseteadas para la siguiente semana');
          } catch (limpiarError) {
            print('❌ [LIMPIAR] Error al limpiar datos: $limpiarError');
          }
        } else {
          print('📋 [MANTENER] Manteniendo cuadrillas actuales para la siguiente semana');
        }
        
      } catch (historialError) {
        print('❌❌❌ [HISTORIAL] ERROR CRÍTICO al copiar a historial: $historialError');
        print('❌ [HISTORIAL] Tipo de error: ${historialError.runtimeType}');
        print('❌ [HISTORIAL] Stack trace: ${StackTrace.current}');
        // No cancelar el cierre, solo reportar el error
      }
      
    } else {
      print('❌ Error al marcar semana $idSemana como cerrada');
      print('❌ [DEBUG] Valor de esta_cerrada después del UPDATE: ${verificarResultado.isNotEmpty ? verificarResultado.first[0] : 'SIN RESULTADOS'}');
    }

    print('🔄 [CERRAR SEMANA] Cerrando conexión a BD...');
    await db.close();
    print('✅ [CERRAR SEMANA] Proceso completado, retornando: $exitoso');
    return exitoso;

  } catch (e) {
    print('❌ [CERRAR SEMANA] ERROR CRÍTICO al cerrar semana en BD: $e');
    print('❌ [CERRAR SEMANA] Tipo de error: ${e.runtimeType}');
    print('❌ [CERRAR SEMANA] Stack trace: ${StackTrace.current}');
    try {
      await db.close();
      print('🔄 [CERRAR SEMANA] Conexión cerrada después del error');
    } catch (closeError) {
      print('❌ [CERRAR SEMANA] Error adicional al cerrar conexión: $closeError');
    }
    return false;
  }
}

/// Helper function para convertir de manera segura cualquier tipo a double
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed ?? 0.0;
  }
  if (value is bool) return value ? 1.0 : 0.0;
  return 0.0;
}

/// Helper function para convertir de manera segura cualquier tipo a int
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed ?? 0;
  }
  if (value is bool) return value ? 1 : 0;
  return 0;
}
