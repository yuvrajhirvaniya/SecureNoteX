import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/secure_entry.dart';
import 'encryption_service.dart';

/// Database service for handling SQLite operations with encrypted data
/// All sensitive data is encrypted before storage and decrypted on retrieval
class DatabaseService {
  static const String _databaseName = 'secure_app.db';
  static const int _databaseVersion = 1;
  static const String _tableSecureEntries = 'secure_entries';

  final EncryptionService _encryptionService;
  Database? _database;

  DatabaseService(this._encryptionService);

  /// Get database instance (singleton pattern)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the SQLite database
  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableSecureEntries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_secure_entries_type ON $_tableSecureEntries(type)
    ''');

    await db.execute('''
      CREATE INDEX idx_secure_entries_created_at ON $_tableSecureEntries(created_at)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema migrations here
    // For example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE $_tableSecureEntries ADD COLUMN new_field TEXT');
    // }
  }

  /// Insert a new secure entry into the database
  /// Content is encrypted before storage
  Future<int> insertSecureEntry(SecureEntry entry) async {
    try {
      final db = await database;
      
      // Encrypt the content before storing
      final encryptedContent = _encryptionService.encrypt(entry.content);
      
      // Create a copy with encrypted content
      final encryptedEntry = entry.copyWith(content: encryptedContent);
      
      final id = await db.insert(
        _tableSecureEntries,
        encryptedEntry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return id;
    } catch (e) {
      throw Exception('Failed to insert secure entry: $e');
    }
  }

  /// Get all secure entries from the database
  /// Content is decrypted after retrieval
  Future<List<SecureEntry>> getAllSecureEntries() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableSecureEntries,
        orderBy: 'updated_at DESC',
      );

      return maps.map((map) {
        // Create entry from map (with encrypted content)
        final entry = SecureEntry.fromMap(map);
        
        // Decrypt the content
        final decryptedContent = _encryptionService.decrypt(entry.content);
        
        // Return entry with decrypted content
        return entry.copyWith(content: decryptedContent);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get secure entries: $e');
    }
  }

  /// Get secure entries by type
  Future<List<SecureEntry>> getSecureEntriesByType(SecureEntryType type) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableSecureEntries,
        where: 'type = ?',
        whereArgs: [type.toString()],
        orderBy: 'updated_at DESC',
      );

      return maps.map((map) {
        final entry = SecureEntry.fromMap(map);
        final decryptedContent = _encryptionService.decrypt(entry.content);
        return entry.copyWith(content: decryptedContent);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get secure entries by type: $e');
    }
  }

  /// Get a specific secure entry by ID
  Future<SecureEntry?> getSecureEntryById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableSecureEntries,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final entry = SecureEntry.fromMap(maps.first);
        final decryptedContent = _encryptionService.decrypt(entry.content);
        return entry.copyWith(content: decryptedContent);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get secure entry by ID: $e');
    }
  }

  /// Update an existing secure entry
  Future<int> updateSecureEntry(SecureEntry entry) async {
    try {
      final db = await database;
      
      // Encrypt the content before updating
      final encryptedContent = _encryptionService.encrypt(entry.content);
      
      // Create updated entry with current timestamp and encrypted content
      final updatedEntry = entry.copyWith(
        content: encryptedContent,
        updatedAt: DateTime.now(),
      );
      
      final count = await db.update(
        _tableSecureEntries,
        updatedEntry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      
      return count;
    } catch (e) {
      throw Exception('Failed to update secure entry: $e');
    }
  }

  /// Delete a secure entry by ID
  Future<int> deleteSecureEntry(int id) async {
    try {
      final db = await database;
      final count = await db.delete(
        _tableSecureEntries,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return count;
    } catch (e) {
      throw Exception('Failed to delete secure entry: $e');
    }
  }

  /// Search secure entries by title (case-insensitive)
  /// Note: Content is not searchable as it's encrypted
  Future<List<SecureEntry>> searchSecureEntries(String query) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableSecureEntries,
        where: 'title LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: 'updated_at DESC',
      );

      return maps.map((map) {
        final entry = SecureEntry.fromMap(map);
        final decryptedContent = _encryptionService.decrypt(entry.content);
        return entry.copyWith(content: decryptedContent);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search secure entries: $e');
    }
  }

  /// Get count of entries by type
  Future<Map<SecureEntryType, int>> getEntriesCountByType() async {
    try {
      final db = await database;
      final result = <SecureEntryType, int>{};
      
      for (final type in SecureEntryType.values) {
        final count = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM $_tableSecureEntries WHERE type = ?',
          [type.toString()],
        )) ?? 0;
        result[type] = count;
      }
      
      return result;
    } catch (e) {
      throw Exception('Failed to get entries count by type: $e');
    }
  }

  /// Clear all data from the database
  Future<void> clearAllData() async {
    try {
      final db = await database;
      await db.delete(_tableSecureEntries);
    } catch (e) {
      throw Exception('Failed to clear all data: $e');
    }
  }

  /// Close the database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
