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
      _connection = PostgreSQLConnection(
        'localhost',  // Host
        5432,
        'AGRIBAR',
        username: 'postgres',
        password: 'admin',
      );
      await _connection.open();
    } catch (e) {
      print('❌ Error al conectar con PostgreSQL: $e');
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
        SELECT DISTINCT e.id_empleado, e.nombre, e.apellido_paterno, e.apellido_materno, e.codigo_empleado,
               nes.id as nomina_id
        FROM empleados e
        INNER JOIN nomina_empleados_semanal nes ON e.id_empleado = nes.id_empleado
        WHERE nes.id_cuadrilla = @cuadrillaId AND nes.id_semana = @semanaId AND e.activo = true
        ORDER BY e.nombre, e.apellido_paterno
      ''', substitutionValues: {'cuadrillaId': cuadrillaId, 'semanaId': semanaId});
    } else {
      // Si no hay semana específica, obtener todos los empleados activos
      results = await db.connection.query('''
        SELECT id_empleado, nombre, apellido_paterno, apellido_materno, codigo_empleado
        FROM empleados 
        WHERE activo = true
        ORDER BY nombre, apellido_paterno
      ''');
    }
    
    await db.close();
    
    final empleadosList = results
        .map((row) => {
              'id': row[0],
              'nombres': row[1],
              'apellidos': '${row[2] ?? ''} ${row[3] ?? ''}'.trim(),
              'codigo': row[4],
              'nomina_id': row.length > 5 ? row[5] : null,
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
