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
      version: 2, // Updated for new columns and ingredients_cache
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
        await _seedInitialData(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add user_id, name, mapped_name, synced to groceries
          await db.execute('''
            CREATE TABLE groceries_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id TEXT NOT NULL,
              name TEXT NOT NULL,
              mapped_name TEXT NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0,
              ingredient_id INTEGER,
              FOREIGN KEY (ingredient_id) REFERENCES ingredients(id)
            )
          ''');
          await db.execute('''
            INSERT INTO groceries_new (id, user_id, name, mapped_name, ingredient_id)
            SELECT id, '123', i.name, i.name, ingredient_id
            FROM groceries g
            JOIN ingredients i ON g.ingredient_id = i.id
          ''');
          await db.execute('DROP TABLE groceries');
          await db.execute('ALTER TABLE groceries_new RENAME TO groceries');
          await db.execute('''
            CREATE TABLE ingredients_cache (
              ingredient_id TEXT PRIMARY KEY,
              name TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> _seedInitialData(Database db) async {
    // Insert canonical ingredients
    await db.insert('ingredients', {'name': 'tomato'});
    await db.insert('ingredients', {'name': 'chicken'});
    await db.insert('ingredients', {'name': 'pasta'});
    await db.insert('ingredients', {'name': 'basil'});
    await db.insert('ingredients', {'name': 'rice'});
    await db.insert('ingredients', {'name': 'potato'});

    // Insert synonyms
    await db.insert('synonyms', {'synonym': 'tomatoes', 'ingredient_id': 1});
    await db.insert('synonyms', {
      'synonym': 'chicken breast',
      'ingredient_id': 2,
    });
    await db.insert('synonyms', {'synonym': 'spaghetti', 'ingredient_id': 3});
    await db.insert('synonyms', {'synonym': 'potatoes', 'ingredient_id': 6});
    await db.insert('synonyms', {'synonym': 'taters', 'ingredient_id': 6});

    // Insert sample recipes
    await db.insert('recipes', {
      'name': 'Tomato Basil Pasta',
      'instructions': 'Cook pasta, add tomato sauce and basil.',
    });
    await db.insert('recipes', {
      'name': 'Chicken Stir Fry',
      'instructions': 'Stir fry chicken with rice.',
    });

    // Insert recipe ingredients
    await db.insert('recipe_ingredients', {
      'recipe_id': 1,
      'ingredient_id': 1,
    }); // Tomato
    await db.insert('recipe_ingredients', {
      'recipe_id': 1,
      'ingredient_id': 3,
    }); // Pasta
    await db.insert('recipe_ingredients', {
      'recipe_id': 1,
      'ingredient_id': 4,
    }); // Basil
    await db.insert('recipe_ingredients', {
      'recipe_id': 2,
      'ingredient_id': 2,
    }); // Chicken
    await db.insert('recipe_ingredients', {
      'recipe_id': 2,
      'ingredient_id': 5,
    }); // Rice
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
