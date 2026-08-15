import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

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
      version: 4, // Incrementado para nueva estructura de datos experimentales
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de usuarios (existente)
    await db.execute('''
  CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL
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

    // Tabla de proyectos (ahora con user_id y campos experimentales)
    await db.execute('''
      CREATE TABLE projects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        project_name TEXT NOT NULL,
        selected_date TEXT,
        selected_image_path TEXT,
        creator_name TEXT,
        work_type TEXT,
        resistance_target INTEGER NOT NULL,
        temperature INTEGER NOT NULL,
        humidity INTEGER NOT NULL,
        relacion_ac REAL NOT NULL,
        aditivo_id INTEGER,
        resistencia_predicha_7d REAL,
        resistencia_predicha_14d REAL,
        resistencia_predicha_28d REAL,
        mixture_id INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (aditivo_id) REFERENCES aditivos (id) ON DELETE SET NULL,
        FOREIGN KEY (mixture_id) REFERENCES mixtures (id) ON DELETE SET NULL
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
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE SET NULL
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

    // === NUEVAS TABLAS EXPERIMENTALES ===
    
    // Tabla de tipos de aditivo
    await db.execute('''
      CREATE TABLE tipos_aditivo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE
      )
    ''');

    // Tabla de productos comerciales
    await db.execute('''
      CREATE TABLE productos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_producto TEXT NOT NULL UNIQUE,
        marca TEXT
      )
    ''');

    // Tabla de aditivos
    await db.execute('''
      CREATE TABLE aditivos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        porcentaje_aplicado TEXT NOT NULL,
        tipo_aditivo_id INTEGER NOT NULL,
        producto_id INTEGER NOT NULL,
        FOREIGN KEY (tipo_aditivo_id) REFERENCES tipos_aditivo (id) ON DELETE CASCADE,
        FOREIGN KEY (producto_id) REFERENCES productos (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de resultados de concreto (datos experimentales)
    await db.execute('''
      CREATE TABLE resultados_concreto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        temperatura INTEGER NOT NULL,
        humedad INTEGER NOT NULL,
        relacion_ac REAL NOT NULL,
        edad_dias INTEGER NOT NULL,
        resistencia_mpa REAL NOT NULL,
        aditivo_id INTEGER NOT NULL,
        FOREIGN KEY (aditivo_id) REFERENCES aditivos (id) ON DELETE CASCADE
      )
    ''');

    // Crear índice para búsquedas rápidas de resistencia
    await db.execute('''
      CREATE INDEX idx_busqueda_resistencia 
      ON resultados_concreto (temperatura, humedad, relacion_ac, aditivo_id, edad_dias)
    ''');

    // Insertar datos semilla
    await _insertDefaultMaterials(db);
    await _insertExperimentalData(db);
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

      // Crear tabla de proyectos
      await db.execute('''
        CREATE TABLE projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          project_name TEXT NOT NULL,
          selected_date TEXT,
          selected_image_path TEXT,
          creator_name TEXT,
          resistance_level TEXT,
          temperature TEXT,
          humidity TEXT,
          work_type TEXT,
          mixture_id INTEGER,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (mixture_id) REFERENCES mixtures (id) ON DELETE SET NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE mixtures (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT,
          total_volume REAL,
          project_id INTEGER,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE SET NULL
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

    if (oldVersion < 3) {
      // Crear la tabla de proyectos
      await db.execute('''
        CREATE TABLE projects (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          project_name TEXT NOT NULL,
          selected_date TEXT,
          selected_image_path TEXT,
          creator_name TEXT,
          resistance_level TEXT,
          temperature TEXT,
          humidity TEXT,
          work_type TEXT,
          mixture_id INTEGER,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (mixture_id) REFERENCES mixtures (id) ON DELETE SET NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      // Migración a versión 4: Datos experimentales y reestructuración de projects
      
      // 1. Crear tablas experimentales
      await db.execute('''
        CREATE TABLE tipos_aditivo (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL UNIQUE
        )
      ''');

      await db.execute('''
        CREATE TABLE productos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre_producto TEXT NOT NULL UNIQUE,
          marca TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE aditivos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          codigo TEXT NOT NULL UNIQUE,
          porcentaje_aplicado TEXT NOT NULL,
          tipo_aditivo_id INTEGER NOT NULL,
          producto_id INTEGER NOT NULL,
          FOREIGN KEY (tipo_aditivo_id) REFERENCES tipos_aditivo (id) ON DELETE CASCADE,
          FOREIGN KEY (producto_id) REFERENCES productos (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE resultados_concreto (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          temperatura INTEGER NOT NULL,
          humedad INTEGER NOT NULL,
          relacion_ac REAL NOT NULL,
          edad_dias INTEGER NOT NULL,
          resistencia_mpa REAL NOT NULL,
          aditivo_id INTEGER NOT NULL,
          FOREIGN KEY (aditivo_id) REFERENCES aditivos (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_busqueda_resistencia 
        ON resultados_concreto (temperatura, humedad, relacion_ac, aditivo_id, edad_dias)
      ''');

      // 2. Reestructurar tabla projects (crear nueva, copiar datos, eliminar vieja)
      await db.execute('''
        CREATE TABLE projects_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          project_name TEXT NOT NULL,
          selected_date TEXT,
          selected_image_path TEXT,
          creator_name TEXT,
          work_type TEXT,
          resistance_target INTEGER NOT NULL DEFAULT 28,
          temperature INTEGER NOT NULL DEFAULT 25,
          humidity INTEGER NOT NULL DEFAULT 50,
          relacion_ac REAL NOT NULL DEFAULT 0.5,
          aditivo_id INTEGER,
          resistencia_predicha_7d REAL,
          resistencia_predicha_14d REAL,
          resistencia_predicha_28d REAL,
          mixture_id INTEGER,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (aditivo_id) REFERENCES aditivos (id) ON DELETE SET NULL,
          FOREIGN KEY (mixture_id) REFERENCES mixtures (id) ON DELETE SET NULL
        )
      ''');

      // Copiar datos antiguos (con valores por defecto para nuevos campos)
      await db.execute('''
        INSERT INTO projects_new 
        (id, user_id, project_name, selected_date, selected_image_path, 
         creator_name, work_type, mixture_id, created_at)
        SELECT 
          id, user_id, project_name, selected_date, selected_image_path,
          creator_name, work_type, mixture_id, created_at
        FROM projects
      ''');

      // Eliminar tabla vieja y renombrar
      await db.execute('DROP TABLE projects');
      await db.execute('ALTER TABLE projects_new RENAME TO projects');

      // 3. Insertar datos experimentales
      await _insertExperimentalData(db);
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

  Future<void> _insertExperimentalData(Database db) async {
    // 1. Insertar tipos de aditivo
    await db.insert('tipos_aditivo', {'id': 1, 'nombre': 'Impermeabilizante'});
    await db.insert('tipos_aditivo', {'id': 2, 'nombre': 'Plastificante'});

    // 2. Insertar productos
    await db.insert('productos', {'id': 1, 'nombre_producto': 'Control / Sin Aditivo', 'marca': 'N/A'});
    await db.insert('productos', {'id': 2, 'nombre_producto': 'Euco Vandex AM 10I', 'marca': 'Euco'});
    await db.insert('productos', {'id': 3, 'nombre_producto': 'Sika® Plastiment® AP', 'marca': 'Sika'});

    // 3. Insertar aditivos
    final aditivos = [
      {'id': 1, 'codigo': 'P0', 'porcentaje_aplicado': '0%', 'tipo_aditivo_id': 1, 'producto_id': 1},
      {'id': 2, 'codigo': 'P1', 'porcentaje_aplicado': '2%', 'tipo_aditivo_id': 1, 'producto_id': 2},
      {'id': 3, 'codigo': 'P2', 'porcentaje_aplicado': '3%', 'tipo_aditivo_id': 1, 'producto_id': 2},
      {'id': 4, 'codigo': 'P3', 'porcentaje_aplicado': '4%', 'tipo_aditivo_id': 1, 'producto_id': 2},
      {'id': 5, 'codigo': 'PP1', 'porcentaje_aplicado': '0.2%', 'tipo_aditivo_id': 2, 'producto_id': 3},
      {'id': 6, 'codigo': 'PP2', 'porcentaje_aplicado': '0.4%', 'tipo_aditivo_id': 2, 'producto_id': 3},
      {'id': 7, 'codigo': 'PP3', 'porcentaje_aplicado': '0.6%', 'tipo_aditivo_id': 2, 'producto_id': 3},
    ];

    for (var aditivo in aditivos) {
      await db.insert('aditivos', aditivo);
    }

    // 4. Cargar resultados experimentales desde CSV
    await _loadCSVData(db);
  }

  Future<void> _loadCSVData(Database db) async {
    try {
      // 1. Leer el archivo CSV desde assets
      final csvString = await rootBundle.loadString('lib/data/csv_datos_1.1.csv');
      
      // 2. Parsear el CSV
      final List<List<dynamic>> csvData = const CsvToListConverter(
        fieldDelimiter: ';',
        eol: '\n',
      ).convert(csvString);
      
      // 3. Saltar la primera fila (encabezados)
      final rows = csvData.skip(1);
      
      // 4. Insertar datos en lotes para mejor rendimiento
      final batch = db.batch();
      int count = 0;
      
      for (var row in rows) {
        if (row.length >= 7) {
          batch.insert('resultados_concreto', {
            'id': row[0],
            'temperatura': row[1],
            'humedad': row[2],
            'relacion_ac': row[3],
            'edad_dias': row[4],
            'resistencia_mpa': row[5],
            'aditivo_id': row[6],
          });
          count++;
        }
      }
      
      // 5. Ejecutar el batch
      await batch.commit(noResult: true);
      
      print('✓ Cargados $count registros experimentales desde CSV');
    } catch (e) {
      print('Error cargando datos del CSV: $e');
      // No lanzamos error para que la app pueda continuar
    }
  }

  // === MÉTODOS PARA USUARIOS (existentes) ===
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmailAndPassword(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first : null;
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

  // === MÉTODOS PARA PROYECTOS ===
  Future<int> insertProject(Map<String, dynamic> project) async {
    final db = await database;
    return await db.insert('projects', project);
  }

  Future<List<Map<String, dynamic>>> getProjects({int? userId}) async {
    final db = await database;
    if (userId != null) {
      return await db.query('projects', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
    } else {
      return await db.query('projects', orderBy: 'created_at DESC');
    }
  }

  Future<Map<String, dynamic>?> getProjectById(int id) async {
    final db = await database;
    final results = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateProject(int id, Map<String, dynamic> project) async {
    final db = await database;
    return await db.update('projects', project, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteProject(int id) async {
    final db = await database;
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
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

  // === MÉTODOS PARA DATOS EXPERIMENTALES ===

  // Tipos de Aditivo
  Future<List<Map<String, dynamic>>> getTiposAditivo() async {
    final db = await database;
    return await db.query('tipos_aditivo', orderBy: 'nombre ASC');
  }

  // Productos
  Future<List<Map<String, dynamic>>> getProductos() async {
    final db = await database;
    return await db.query('productos', orderBy: 'nombre_producto ASC');
  }

  // Aditivos
  Future<List<Map<String, dynamic>>> getAditivos() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT a.*, ta.nombre as tipo_nombre, p.nombre_producto, p.marca
      FROM aditivos a
      JOIN tipos_aditivo ta ON a.tipo_aditivo_id = ta.id
      JOIN productos p ON a.producto_id = p.id
      ORDER BY a.codigo ASC
    ''');
  }

  Future<Map<String, dynamic>?> getAditivoByCodigo(String codigo) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT a.*, ta.nombre as tipo_nombre, p.nombre_producto, p.marca
      FROM aditivos a
      JOIN tipos_aditivo ta ON a.tipo_aditivo_id = ta.id
      JOIN productos p ON a.producto_id = p.id
      WHERE a.codigo = ?
    ''', [codigo]);
    return results.isNotEmpty ? results.first : null;
  }

  // Resultados de Concreto
  Future<List<Map<String, dynamic>>> getResultadosConcreto({
    int? temperatura,
    int? humedad,
    double? relacionAc,
    int? aditivoId,
    int? edadDias,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (temperatura != null) {
      whereClause += 'temperatura = ?';
      whereArgs.add(temperatura);
    }
    if (humedad != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'humedad = ?';
      whereArgs.add(humedad);
    }
    if (relacionAc != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'relacion_ac = ?';
      whereArgs.add(relacionAc);
    }
    if (aditivoId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'aditivo_id = ?';
      whereArgs.add(aditivoId);
    }
    if (edadDias != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'edad_dias = ?';
      whereArgs.add(edadDias);
    }

    return await db.query(
      'resultados_concreto',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'edad_dias ASC, resistencia_mpa DESC',
    );
  }

  // Obtener resistencia promedio para condiciones específicas
  Future<Map<String, double?>> getResistenciaPromedio({
    required int temperatura,
    required int humedad,
    required double relacionAc,
    required int aditivoId,
  }) async {
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        edad_dias,
        ROUND(AVG(resistencia_mpa), 2) as resistencia_promedio,
        COUNT(*) as num_muestras
      FROM resultados_concreto
      WHERE temperatura = ? AND humedad = ? AND relacion_ac = ? AND aditivo_id = ?
      GROUP BY edad_dias
      ORDER BY edad_dias ASC
    ''', [temperatura, humedad, relacionAc, aditivoId]);

    Map<String, double?> resistencias = {
      'dias_7': null,
      'dias_14': null,
      'dias_28': null,
    };

    for (var row in result) {
      final edad = row['edad_dias'] as int;
      final promedio = row['resistencia_promedio'] as double?;
      
      if (edad == 7) resistencias['dias_7'] = promedio;
      if (edad == 14) resistencias['dias_14'] = promedio;
      if (edad == 28) resistencias['dias_28'] = promedio;
    }

    return resistencias;
  }

  // Método detallado con JOIN para obtener información completa
  Future<List<Map<String, dynamic>>> getPromediosResistenciaDetallados({
    required int temperatura,
    required int humedad,
    required double relacionAc,
    int? aditivoId,
  }) async {
    final db = await database;
    
    String whereClause = 'r.temperatura = ? AND r.humedad = ? AND r.relacion_ac = ?';
    List<dynamic> whereArgs = [temperatura, humedad, relacionAc];
    
    if (aditivoId != null) {
      whereClause += ' AND r.aditivo_id = ?';
      whereArgs.add(aditivoId);
    }
    
    final result = await db.rawQuery('''
      SELECT
        p.nombre_producto,
        a.codigo AS codigo_aditivo,
        r.edad_dias,
        r.temperatura,
        r.humedad,
        r.relacion_ac,
        ROUND(AVG(r.resistencia_mpa), 2) AS promedio_resistencia,
        COUNT(r.id) AS numero_de_muestras
      FROM
        resultados_concreto AS r
      JOIN
        aditivos AS a ON r.aditivo_id = a.id
      JOIN
        productos AS p ON a.producto_id = p.id
      WHERE $whereClause
      GROUP BY
        p.nombre_producto, a.codigo, r.edad_dias, 
        r.temperatura, r.humedad, r.relacion_ac
      ORDER BY
        a.codigo, r.edad_dias
    ''', whereArgs);

    return result;
  }

  // Obtener opciones válidas según el árbol de decisiones
  Future<List<int>> getOpcionesHumedad(int temperatura) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT DISTINCT humedad 
      FROM resultados_concreto 
      WHERE temperatura = ?
      ORDER BY humedad ASC
    ''', [temperatura]);
    return results.map((r) => r['humedad'] as int).toList();
  }

  Future<List<double>> getOpcionesRelacionAC(int temperatura, int humedad) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT DISTINCT relacion_ac 
      FROM resultados_concreto 
      WHERE temperatura = ? AND humedad = ?
      ORDER BY relacion_ac ASC
    ''', [temperatura, humedad]);
    return results.map((r) => r['relacion_ac'] as double).toList();
  }

  Future<List<int>> getOpcionesAditivos(int temperatura, int humedad, double relacionAc) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT DISTINCT aditivo_id 
      FROM resultados_concreto 
      WHERE temperatura = ? AND humedad = ? AND relacion_ac = ?
      ORDER BY aditivo_id ASC
    ''', [temperatura, humedad, relacionAc]);
    return results.map((r) => r['aditivo_id'] as int).toList();
  }

  // Método para obtener aditivos con sus códigos (P0-P3, PP1-PP3)
  Future<List<Map<String, dynamic>>> getAditivosConCodigos(int temperatura, int humedad, double relacionAc) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT DISTINCT a.id, a.codigo
      FROM resultados_concreto AS r
      JOIN aditivos AS a ON r.aditivo_id = a.id
      WHERE r.temperatura = ? AND r.humedad = ? AND r.relacion_ac = ?
      ORDER BY a.codigo ASC
    ''', [temperatura, humedad, relacionAc]);
    return results.map((r) => {'id': r['id'] as int, 'codigo': r['codigo'] as String}).toList();
  }
}

