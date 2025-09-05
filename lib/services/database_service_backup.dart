// lib/services/database_service.dart
import 'package:postgres/postgres.dart';
import 'dart:io';
import 'package:intl/intl.dart';

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
    await _connection.close();
  }

  /// Método auxiliar para obtener la instancia de conexión
  static Future<DatabaseService> getInstance() async {
    final db = DatabaseService();
    await db.connect();
    return db;
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
          tamaño_archivo BIGINT
        );
      ''');
      
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
          tamaño_archivo
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
          tamaño_archivo
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
          'tamaño_archivo': row[8],
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

/// Verifica si existe un archivo de backup
Future<Map<String, dynamic>> verificarArchivoBackup(String rutaArchivo) async {
  try {
    final archivo = File(rutaArchivo);
    
    if (archivo.existsSync()) {
      final tamano = archivo.lengthSync();
      final fechaModificacion = archivo.lastModifiedSync();
      
      return {
        'existe': true,
        'tamano': tamano,
        'fecha_modificacion': fechaModificacion.toIso8601String(),
        'ruta': rutaArchivo,
      };
    } else {
      return {
        'existe': false,
        'error': 'El archivo no existe en la ruta especificada',
        'ruta': rutaArchivo,
      };
    }
  } catch (e) {
    return {
      'existe': false,
      'error': e.toString(),
      'ruta': rutaArchivo,
    };
  }
}

/// Descarga un archivo de backup a la carpeta de descargas del usuario
Future<Map<String, dynamic>> descargarBackup(String rutaArchivo, String nombreArchivo) async {
  try {
    final archivoOrigen = File(rutaArchivo);
    
    if (!archivoOrigen.existsSync()) {
      return {
        'success': false,
        'error': 'El archivo de backup no existe: $rutaArchivo',
      };
    }
    
    // Obtener la carpeta de descargas del usuario
    final downloadsPath = Platform.environment['USERPROFILE'] != null 
        ? '${Platform.environment['USERPROFILE']}\\Downloads'
        : Directory.current.path;
    
    final archivoDestino = File('$downloadsPath\\$nombreArchivo');
    
    // Copiar el archivo
    await archivoOrigen.copy(archivoDestino.path);
    
    return {
      'success': true,
      'ruta_descarga': archivoDestino.path,
      'tamano': archivoDestino.lengthSync(),
    };
    
  } catch (e) {
    return {
      'success': false,
      'error': 'Error al descargar archivo: $e',
    };
  }
}

/// Obtiene el contenido de un archivo de backup para vista previa
Future<Map<String, dynamic>> obtenerContenidoBackup(String rutaArchivo) async {
  try {
    final archivo = File(rutaArchivo);
    
    if (!archivo.existsSync()) {
      return {
        'success': false,
        'error': 'El archivo no existe: $rutaArchivo',
      };
    }
    
    // Leer solo las primeras 50 líneas para vista previa
    final lines = archivo.readAsLinesSync();
    final preview = lines.take(50).join('\n');
    
    return {
      'success': true,
      'contenido': preview,
      'lineas_totales': lines.length,
      'tamano': archivo.lengthSync(),
    };
    
  } catch (e) {
    return {
      'success': false,
      'error': 'Error al leer archivo: $e',
    };
  }
}
