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
      version: 1,
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
        await _seedInitialData(db);
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

    // Insert synonyms
    await db.insert('synonyms', {'synonym': 'tomatoes', 'ingredient_id': 1});
    await db.insert('synonyms', {
      'synonym': 'chicken breast',
      'ingredient_id': 2,
    });
    await db.insert('synonyms', {'synonym': 'spaghetti', 'ingredient_id': 3});

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

  Future<int> _getOrCreateIngredientId(String name) async {
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

  Future<void> insertGrocery(String name) async {
    final db = await database;
    final ingredientId = await _getOrCreateIngredientId(name);
    await db.insert('groceries', {'ingredient_id': ingredientId});
  }

  Future<List<Map<String, dynamic>>> getGroceries() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT g.id, i.name
      FROM groceries g
      JOIN ingredients i ON g.ingredient_id = i.id
    ''');
    return result;
  }

  Future<void> deleteGrocery(int id) async {
    final db = await database;
    await db.delete('groceries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getRecommendedRecipes() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT r.id, r.name, r.instructions,
             COUNT(CASE WHEN g.ingredient_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*) AS match_percentage
      FROM recipes r
      LEFT JOIN recipe_ingredients ri ON r.id = ri.recipe_id
      LEFT JOIN groceries g ON ri.ingredient_id = g.ingredient_id
      GROUP BY r.id, r.name, r.instructions
      HAVING match_percentage >= 70
      ORDER BY match_percentage DESC
    ''');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // This function is for testing purposes only
  // It deletes the database and all its contents
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
