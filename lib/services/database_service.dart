// lib/services/database_service.dart
import 'package:postgres/postgres.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  late PostgreSQLConnection _connection;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<void> connect() async {
    _connection = PostgreSQLConnection(
      'localhost', // IP del servidor PostgreSQL
      5432,
      'Agribar', // Nombre de tu base de datos
      username: 'postgres',
      password: 'admin',
    );
    await _connection.open();
    print('✅ Conexión establecida con PostgreSQL');
  }

  PostgreSQLConnection get connection => _connection;

  Future<void> close() async {
    await _connection.close();
    print('❌ Conexión cerrada');
  }
}
