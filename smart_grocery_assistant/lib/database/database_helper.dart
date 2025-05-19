import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('grocery_assistant.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 3, // Updated for new columns and ingredients_cache
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ingredients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE
          )
        ''');
        await db.execute('''
          CREATE TABLE synonyms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            synonym TEXT NOT NULL,
            ingredient_id INTEGER,
            FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE groceries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            mapped_name TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            ingredient_id INTEGER,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
            category TEXT,
            FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
          )
        ''');
        await db.execute('''
          CREATE TABLE recipes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            instructions TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE recipe_ingredients (
            recipe_id INTEGER,
            ingredient_id INTEGER,
            FOREIGN KEY (recipe_id) REFERENCES recipes(id),
            FOREIGN KEY (ingredient_id) REFERENCES ingredients(id),
            PRIMARY KEY (recipe_id, ingredient_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE ingredients_cache (
            ingredient_id TEXT PRIMARY KEY,
            name TEXT NOT NULL
          )
        ''');
        await migrateNullTimestamps();
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          //no need to preserver existing data.
          await db.execute('DROP TABLE groceries');
          await db.execute('''
            CREATE TABLE groceries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id TEXT NOT NULL,
              name TEXT NOT NULL,
              mapped_name TEXT NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0,
              ingredient_id INTEGER,
              created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
              category TEXT,
              FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
            )
            ''');
        }
      },
    );
  }

  Future<int> _getOrCreateLocalIngredientId(String name) async {
    final db = await database;
    name = name.toLowerCase().trim();

    var result = await db.query(
      'ingredients',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) return result.first['id'] as int;

    result = await db.query(
      'synonyms',
      where: 'synonym = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) return result.first['ingredient_id'] as int;

    final id = await db.insert('ingredients', {'name': name});
    return id;
  }

  Future<String?> getMappedName(String name) async {
    final db = await database;
    name = name.toLowerCase().trim();

    var result = await db.query(
      'ingredients',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) return result.first['name'] as String;

    result = await db.query(
      'synonyms',
      where: 'synonym = ?',
      whereArgs: [name],
    );
    if (result.isNotEmpty) {
      final ingredientId = result.first['ingredient_id'] as int;
      result = await db.query(
        'ingredients',
        where: 'id = ?',
        whereArgs: [ingredientId],
      );
      return result.first['name'] as String;
    }
    return null;
  }

  Future<void> insertGrocery(
    String userId,
    String name,
    String mappedName,
  ) async {
    final db = await database;
    final ingredientId = await _getOrCreateLocalIngredientId(mappedName);
    await db.insert('groceries', {
      'user_id': userId,
      'name': name,
      'mapped_name': mappedName,
      'ingredient_id': ingredientId,
      'synced': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getGroceries(String userId) async {
    final db = await database;
    return await db.query(
      'groceries',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteGrocery(int id) async {
    final db = await database;
    await db.delete('groceries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> cacheIngredients(List<Map<String, dynamic>> ingredients) async {
    final db = await database;
    final batch = db.batch();
    for (var ingredient in ingredients) {
      batch.insert('ingredients_cache', {
        'ingredient_id': ingredient['ingredientId'],
        'name': ingredient['name'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getCachedIngredients() async {
    final db = await database;
    return await db.query('ingredients_cache');
  }

  Future<void> markAsSynced(List<int> ids) async {
    final db = await database;
    final batch = db.batch();
    for (var id in ids) {
      batch.update(
        'groceries',
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit();
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'grocery_assistant.db');
    await deleteDatabase(path);
  }

  // Add this to your database helper
  Future<void> migrateNullTimestamps() async {
    final db = await database;
    await db.execute(
      'UPDATE groceries SET created_at = strftime("%s","now") WHERE created_at IS NULL',
    );
  }

  Future<void> debugSchema() async {
    final db = await database;
    var tables = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type="table"',
    );
    print('Tables: $tables');
    for (var table in tables) {
      var columns = await db.rawQuery('PRAGMA table_info(${table['name']})');
      print('Columns in ${table['name']}: $columns');
    }
  }
}
