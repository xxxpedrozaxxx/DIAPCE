import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'my_database.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de usuarios (existente)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL
      )
    ''');

    // Tabla de materiales
    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        unit TEXT NOT NULL,
        density REAL,
        cost_per_unit REAL,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de mezclas
    await db.execute('''
      CREATE TABLE mixtures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        total_volume REAL,
        project_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de relación materiales-mezclas (many-to-many)
    await db.execute('''
      CREATE TABLE mixture_materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mixture_id INTEGER NOT NULL,
        material_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        percentage REAL,
        FOREIGN KEY (mixture_id) REFERENCES mixtures (id) ON DELETE CASCADE,
        FOREIGN KEY (material_id) REFERENCES materials (id) ON DELETE CASCADE,
        UNIQUE(mixture_id, material_id)
      )
    ''');

    // Insertar algunos materiales de ejemplo
    await _insertDefaultMaterials(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Crear las nuevas tablas para materiales y mezclas
      await db.execute('''
        CREATE TABLE materials (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          unit TEXT NOT NULL,
          density REAL,
          cost_per_unit REAL,
          description TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE mixtures (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          total_volume REAL,
          project_id INTEGER,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE mixture_materials (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mixture_id INTEGER NOT NULL,
          material_id INTEGER NOT NULL,
          quantity REAL NOT NULL,
          percentage REAL,
          FOREIGN KEY (mixture_id) REFERENCES mixtures (id) ON DELETE CASCADE,
          FOREIGN KEY (material_id) REFERENCES materials (id) ON DELETE CASCADE,
          UNIQUE(mixture_id, material_id)
        )
      ''');

      await _insertDefaultMaterials(db);
    }
  }

  Future<void> _insertDefaultMaterials(Database db) async {
    final defaultMaterials = [
      // Cementos
      {'name': 'Cemento Portland', 'unit': 'kg', 'density': 3.15, 'cost_per_unit': 8.50, 'description': 'Cemento Portland tipo I'},
      {'name': 'Cemento Portland Tipo II', 'unit': 'kg', 'density': 3.15, 'cost_per_unit': 9.00, 'description': 'Cemento Portland tipo II resistente a sulfatos'},
      {'name': 'Cemento de Alta Resistencia', 'unit': 'kg', 'density': 3.20, 'cost_per_unit': 12.00, 'description': 'Cemento para concretos de alta resistencia'},
      
      // Agregados
      {'name': 'Agua', 'unit': 'L', 'density': 1.0, 'cost_per_unit': 0.002, 'description': 'Agua potable para mezcla'},
      {'name': 'Arena', 'unit': 'kg', 'density': 2.65, 'cost_per_unit': 0.25, 'description': 'Arena fina para construcción'},
      {'name': 'Arena Gruesa', 'unit': 'kg', 'density': 2.70, 'cost_per_unit': 0.28, 'description': 'Arena gruesa para concreto'},
      {'name': 'Grava', 'unit': 'kg', 'density': 2.70, 'cost_per_unit': 0.20, 'description': 'Grava triturada 19mm'},
      {'name': 'Grava Fina', 'unit': 'kg', 'density': 2.68, 'cost_per_unit': 0.22, 'description': 'Grava triturada 12mm'},
      {'name': 'Piedra Pómez', 'unit': 'kg', 'density': 1.20, 'cost_per_unit': 0.35, 'description': 'Agregado ligero volcánico'},
      
      // Aditivos
      {'name': 'Aditivo Plastificante', 'unit': 'L', 'density': 1.05, 'cost_per_unit': 15.00, 'description': 'Aditivo reductor de agua'},
      {'name': 'Aditivo Superplastificante', 'unit': 'L', 'density': 1.08, 'cost_per_unit': 25.00, 'description': 'Aditivo de alto rango reductor de agua'},
      {'name': 'Aditivo Acelerante', 'unit': 'L', 'density': 1.12, 'cost_per_unit': 18.00, 'description': 'Acelera el fraguado del concreto'},
      {'name': 'Aditivo Retardante', 'unit': 'L', 'density': 1.06, 'cost_per_unit': 16.00, 'description': 'Retarda el fraguado del concreto'},
      {'name': 'Aditivo Incorporador de Aire', 'unit': 'L', 'density': 1.02, 'cost_per_unit': 20.00, 'description': 'Incorpora burbujas de aire microscópicas'},
      
      // Fibras y Refuerzos
      {'name': 'Fibra de Acero', 'unit': 'kg', 'density': 7.85, 'cost_per_unit': 25.00, 'description': 'Fibras de acero para refuerzo'},
      {'name': 'Fibra de Polipropileno', 'unit': 'kg', 'density': 0.91, 'cost_per_unit': 35.00, 'description': 'Fibras sintéticas para control de fisuras'},
      {'name': 'Fibra de Vidrio', 'unit': 'kg', 'density': 2.50, 'cost_per_unit': 45.00, 'description': 'Fibras de vidrio resistentes a álcalis'},
      {'name': 'Fibra de Carbono', 'unit': 'kg', 'density': 1.60, 'cost_per_unit': 120.00, 'description': 'Fibras de carbono de alta resistencia'},
      
      // Puzolanas y Adiciones
      {'name': 'Ceniza Volante', 'unit': 'kg', 'density': 2.30, 'cost_per_unit': 3.50, 'description': 'Puzolana artificial de centrales térmicas'},
      {'name': 'Microsílice', 'unit': 'kg', 'density': 2.20, 'cost_per_unit': 15.00, 'description': 'Puzolana de alta reactividad'},
      {'name': 'Escoria de Alto Horno', 'unit': 'kg', 'density': 2.85, 'cost_per_unit': 5.00, 'description': 'Adición mineral siderúrgica'},
      
      // Materiales Especiales
      {'name': 'Látex Estireno-Butadieno', 'unit': 'L', 'density': 1.01, 'cost_per_unit': 28.00, 'description': 'Modificador polimérico'},
      {'name': 'Resina Epoxi', 'unit': 'kg', 'density': 1.15, 'cost_per_unit': 85.00, 'description': 'Resina para reparaciones estructurales'},
      {'name': 'Expansor No Metálico', 'unit': 'kg', 'density': 1.50, 'cost_per_unit': 22.00, 'description': 'Agente expansor compensador de retracción'},
    ];

    for (var material in defaultMaterials) {
      await db.insert('materials', material, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // === MÉTODOS PARA USUARIOS (existentes) ===
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  // === MÉTODOS PARA MATERIALES ===
  Future<int> insertMaterial(Map<String, dynamic> material) async {
    final db = await database;
    return await db.insert('materials', material);
  }

  Future<List<Map<String, dynamic>>> getMaterials() async {
    final db = await database;
    return await db.query('materials', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getMaterialById(int id) async {
    final db = await database;
    final results = await db.query('materials', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateMaterial(int id, Map<String, dynamic> material) async {
    final db = await database;
    return await db.update('materials', material, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMaterial(int id) async {
    final db = await database;
    return await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }

  // === MÉTODOS PARA MEZCLAS ===
  Future<int> insertMixture(Map<String, dynamic> mixture) async {
    final db = await database;
    return await db.insert('mixtures', mixture);
  }

  Future<List<Map<String, dynamic>>> getMixtures() async {
    final db = await database;
    return await db.query('mixtures', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getMixturesByProject(int projectId) async {
    final db = await database;
    return await db.query('mixtures', where: 'project_id = ?', whereArgs: [projectId], orderBy: 'created_at DESC');
  }

  Future<Map<String, dynamic>?> getMixtureById(int id) async {
    final db = await database;
    final results = await db.query('mixtures', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateMixture(int id, Map<String, dynamic> mixture) async {
    final db = await database;
    return await db.update('mixtures', mixture, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMixture(int id) async {
    final db = await database;
    return await db.delete('mixtures', where: 'id = ?', whereArgs: [id]);
  }

  // === MÉTODOS PARA RELACIÓN MATERIALES-MEZCLAS ===
  Future<int> addMaterialToMixture(int mixtureId, int materialId, double quantity, {double? percentage}) async {
    final db = await database;
    return await db.insert('mixture_materials', {
      'mixture_id': mixtureId,
      'material_id': materialId,
      'quantity': quantity,
      'percentage': percentage,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMaterialsInMixture(int mixtureId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        m.id,
        m.name,
        m.unit,
        m.density,
        m.cost_per_unit,
        m.description,
        mm.quantity,
        mm.percentage
      FROM materials m
      INNER JOIN mixture_materials mm ON m.id = mm.material_id
      WHERE mm.mixture_id = ?
      ORDER BY mm.percentage DESC, m.name ASC
    ''', [mixtureId]);
  }

  Future<List<Map<String, dynamic>>> getMixturesWithMaterial(int materialId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        mix.id,
        mix.name,
        mix.description,
        mix.total_volume,
        mix.project_id,
        mm.quantity,
        mm.percentage
      FROM mixtures mix
      INNER JOIN mixture_materials mm ON mix.id = mm.mixture_id
      WHERE mm.material_id = ?
      ORDER BY mix.created_at DESC
    ''', [materialId]);
  }

  Future<int> removeMaterialFromMixture(int mixtureId, int materialId) async {
    final db = await database;
    return await db.delete('mixture_materials', 
      where: 'mixture_id = ? AND material_id = ?', 
      whereArgs: [mixtureId, materialId]);
  }

  Future<int> updateMaterialInMixture(int mixtureId, int materialId, double quantity, {double? percentage}) async {
    final db = await database;
    return await db.update('mixture_materials', {
      'quantity': quantity,
      'percentage': percentage,
    }, where: 'mixture_id = ? AND material_id = ?', whereArgs: [mixtureId, materialId]);
  }

  // === MÉTODOS PARA CALCULAR PORCENTAJES ===
  Future<void> calculateAndUpdatePercentages(int mixtureId) async {
    final materials = await getMaterialsInMixture(mixtureId);
    
    double totalQuantity = 0;
    for (var material in materials) {
      totalQuantity += material['quantity'] as double;
    }
    
    if (totalQuantity > 0) {
      final db = await database;
      for (var material in materials) {
        final percentage = (material['quantity'] as double) / totalQuantity * 100;
        await db.update('mixture_materials', 
          {'percentage': percentage},
          where: 'mixture_id = ? AND material_id = ?',
          whereArgs: [mixtureId, material['id']]
        );
      }
    }
  }

  // === MÉTODO PARA CREAR MEZCLAS DE EJEMPLO ===
  Future<int> createRandomExampleMixture(String projectName) async {
    final db = await database;
    
    // Lista de diferentes tipos de mezclas con sus composiciones
    final mixtureTypes = [
      {
        'name': 'Concreto Estándar',
        'description': 'Mezcla estándar para construcción general',
        'materials': {
          'Cemento Portland': 350.0,
          'Agua': 175.0,
          'Arena': 700.0,
          'Grava': 1100.0,
          'Aditivo Plastificante': 1.2,
        }
      },
      {
        'name': 'Concreto de Alta Resistencia',
        'description': 'Mezcla para estructuras que requieren alta resistencia',
        'materials': {
          'Cemento Portland': 450.0,
          'Agua': 160.0,
          'Arena': 650.0,
          'Grava': 1050.0,
          'Aditivo Plastificante': 2.0,
          'Fibra de Acero': 25.0,
        }
      },
      {
        'name': 'Concreto Fluido',
        'description': 'Mezcla de alta trabajabilidad para elementos complejos',
        'materials': {
          'Cemento Portland': 380.0,
          'Agua': 190.0,
          'Arena': 750.0,
          'Grava': 1000.0,
          'Aditivo Plastificante': 3.5,
        }
      },
      {
        'name': 'Concreto Ligero',
        'description': 'Mezcla con agregados ligeros para reducir peso',
        'materials': {
          'Cemento Portland': 320.0,
          'Agua': 180.0,
          'Arena': 600.0,
          'Grava': 800.0,
          'Aditivo Plastificante': 1.5,
        }
      },
      {
        'name': 'Concreto para Pavimentos',
        'description': 'Mezcla especializada para pavimentación',
        'materials': {
          'Cemento Portland': 400.0,
          'Agua': 165.0,
          'Arena': 680.0,
          'Grava': 1150.0,
          'Aditivo Plastificante': 1.8,
          'Fibra de Acero': 15.0,
        }
      },
      {
        'name': 'Concreto Premezclado',
        'description': 'Mezcla estándar para concreto premezclado',
        'materials': {
          'Cemento Portland': 330.0,
          'Agua': 185.0,
          'Arena': 720.0,
          'Grava': 1080.0,
          'Aditivo Plastificante': 1.0,
        }
      },
      {
        'name': 'Concreto Autocompactante',
        'description': 'Mezcla que se compacta por gravedad',
        'materials': {
          'Cemento Portland': 420.0,
          'Agua': 170.0,
          'Arena': 800.0,
          'Grava': 950.0,
          'Aditivo Plastificante': 4.2,
        }
      },
      {
        'name': 'Concreto Reforzado con Fibras',
        'description': 'Mezcla con alto contenido de fibras de refuerzo',
        'materials': {
          'Cemento Portland': 380.0,
          'Agua': 175.0,
          'Arena': 690.0,
          'Grava': 1020.0,
          'Aditivo Plastificante': 2.5,
          'Fibra de Acero': 40.0,
        }
      },
    ];

    // Seleccionar una mezcla al azar
    final random = DateTime.now().millisecondsSinceEpoch;
    final selectedMixture = mixtureTypes[random % mixtureTypes.length];
    
    // Crear la mezcla
    final mixtureId = await db.insert('mixtures', {
      'name': '${selectedMixture['name']} - $projectName',
      'description': selectedMixture['description'],
      'total_volume': 1.0, // 1 m³
    });

    // Obtener materiales por nombre
    final materials = await db.query('materials');
    final materialMap = {for (var m in materials) m['name']: m['id']};

    // Agregar materiales con cantidades específicas para la mezcla seleccionada
    final materialQuantities = selectedMixture['materials'] as Map<String, double>;
    
    for (var entry in materialQuantities.entries) {
      final materialId = materialMap[entry.key];
      if (materialId != null) {
        await addMaterialToMixture(mixtureId, materialId as int, entry.value);
      }
    }

    // Calcular porcentajes
    await calculateAndUpdatePercentages(mixtureId);
    
    return mixtureId;
  }

  // Mantener el método original para compatibilidad, pero que use el nuevo método
  Future<int> createExampleMixture(String projectName) async {
    return await createRandomExampleMixture(projectName);
  }

  // Método para obtener información completa de una mezcla (útil para debugging)
  Future<Map<String, dynamic>?> getMixtureWithDetails(int mixtureId) async {
    final db = await database;
  
    final mixtureQuery = await db.query('mixtures', where: 'id = ?', whereArgs: [mixtureId]);
    if (mixtureQuery.isEmpty) return null;
  
    final mixture = mixtureQuery.first;
    final materialsQuery = await db.rawQuery('''
      SELECT m.name, m.unit, mm.quantity, mm.percentage
      FROM mixture_materials mm
      JOIN materials m ON mm.material_id = m.id
      WHERE mm.mixture_id = ?
      ORDER BY mm.percentage DESC
    ''', [mixtureId]);
  
    return {
      'mixture': mixture,
      'materials': materialsQuery,
    };
  }
}