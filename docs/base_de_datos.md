# Base de datos de DIAPCE

Última actualización: 2026-09-21
Versión de esquema: 5
Motor: PostgreSQL 16 (servida por el backend Flask en `backend/`; modelos en `backend/app/models.py`, DDL exportado en `backend/schema.sql`)

> Histórico: hasta la v4 la base de datos era SQLite embebida en la app Flutter (`sqflite`). En la v5 se migró a arquitectura cliente-servidor: la app consume la API REST y ya no abre ninguna base de datos local.

## Objetivo
La base de datos almacena usuarios, proyectos y un repositorio de resultados experimentales de concreto. Permite consultar promedios de resistencia (7, 14 y 28 días) en función de condiciones controladas (temperatura, humedad, relación a/c y aditivo) y asociarlos a proyectos por usuario.

## Visión general de entidades
- users: credenciales de usuario (contraseña con hash bcrypt).
- tipos_estructura: clasificación de proyectos por tipo de estructura (Puentes, Túneles, Muros de contención).
- projects: proyectos creados por cada usuario (incluye condiciones seleccionadas y predicciones).
- materials, mixtures, mixture_materials: catálogo y composición de mezclas (funcionalidad existente).
- tipos_aditivo, productos, aditivos: catálogo de aditivos (tipología, producto comercial y código).
- resultados_concreto: datos experimentales importados desde CSV (1874 filas aprox.).

## Diagrama ER (simplificado)

```
users 1 ──< projects >── 1 mixtures  (relación opcional)
                 |              \
                 |               >── mixture_materials >── materials
                 |
                 └──(opcional) aditivos ──< resultados_concreto >── productos
                                 ^
                                 |
                           tipos_aditivo
```

Leyenda: `A >── B` = A 1─N B;  `(opcional)` = FK puede ser NULL

## Tablas y columnas

### users
- id SERIAL PK
- email VARCHAR(255) NOT NULL UNIQUE
- password_hash VARCHAR(255) NOT NULL  (bcrypt; nunca texto plano)
- created_at TIMESTAMP NOT NULL

### tipos_estructura
- id SERIAL PK
- codigo VARCHAR(32) NOT NULL UNIQUE  (Puentes, Tuneles, Muros)
- nombre VARCHAR(64) NOT NULL

### materials
- id INTEGER PK AUTOINCREMENT
- name TEXT NOT NULL UNIQUE
- unit TEXT NOT NULL
- density REAL
- cost_per_unit REAL
- description TEXT
- created_at TEXT DEFAULT CURRENT_TIMESTAMP

### projects
- id INTEGER PK AUTOINCREMENT
- user_id INTEGER NOT NULL → users.id ON DELETE CASCADE
- project_name TEXT NOT NULL
- selected_date TEXT
- selected_image_path TEXT
- creator_name TEXT
- tipo_estructura_id INTEGER NOT NULL → tipos_estructura.id ON DELETE RESTRICT  (la API lo expone como `work_type`)
- resistance_target REAL NOT NULL  CHECK (24 ≤ valor ≤ 57)
- temperature INTEGER NOT NULL
- humidity INTEGER NOT NULL
- relacion_ac REAL NOT NULL
- aditivo_id INTEGER → aditivos.id ON DELETE SET NULL
- resistencia_predicha_7d REAL
- resistencia_predicha_14d REAL
- resistencia_predicha_28d REAL
- mixture_id INTEGER → mixtures.id ON DELETE SET NULL
- created_at TEXT DEFAULT CURRENT_TIMESTAMP

Nota técnica: en v5 `resistance_target` ya es REAL (double precision) y `work_type` pasó de texto libre a FK sobre `tipos_estructura`.

### mixtures
- id INTEGER PK AUTOINCREMENT
- name TEXT NOT NULL
- description TEXT
- total_volume REAL
- project_id INTEGER → projects.id ON DELETE SET NULL
- created_at TEXT DEFAULT CURRENT_TIMESTAMP

### mixture_materials
- id INTEGER PK AUTOINCREMENT
- mixture_id INTEGER NOT NULL → mixtures.id ON DELETE CASCADE
- material_id INTEGER NOT NULL → materials.id ON DELETE CASCADE
- quantity REAL NOT NULL
- percentage REAL
- UNIQUE(mixture_id, material_id)

### tipos_aditivo
- id INTEGER PK AUTOINCREMENT
- nombre TEXT NOT NULL UNIQUE  (ej. "Impermeabilizante", "Plastificante")

### productos
- id INTEGER PK AUTOINCREMENT
- nombre_producto TEXT NOT NULL UNIQUE (ej. "Euco Vandex AM 10I", "Sika® Plastiment® AP")
- marca TEXT

### aditivos
- id INTEGER PK AUTOINCREMENT
- codigo TEXT NOT NULL UNIQUE  (P0, P1, P2, P3, PP1, PP2, PP3)
- porcentaje_aplicado TEXT NOT NULL ("2%", "0.4%", etc.)
- tipo_aditivo_id INTEGER NOT NULL → tipos_aditivo.id ON DELETE CASCADE
- producto_id INTEGER NOT NULL → productos.id ON DELETE CASCADE

### resultados_concreto
- id INTEGER PK AUTOINCREMENT
- temperatura INTEGER NOT NULL   (10, 25, 32)
- humedad INTEGER NOT NULL       (20, 50, 70)
- relacion_ac REAL NOT NULL      (0.40, 0.45, 0.50)
- edad_dias INTEGER NOT NULL     (7, 14, 28)
- resistencia_mpa REAL NOT NULL  (MPa)
- aditivo_id INTEGER NOT NULL → aditivos.id ON DELETE CASCADE

### Índices
- `idx_busqueda_resistencia` sobre resultados_concreto(temperatura, humedad, relacion_ac, aditivo_id, edad_dias)
  - Acelera consultas por condiciones y edad.

## Datos de semilla
- tipos_aditivo: Impermeabilizante (1), Plastificante (2)
- productos: (1) Control / Sin Aditivo, (2) Euco Vandex AM 10I, (3) Sika® Plastiment® AP
- aditivos:
  - P0 (0%, producto 1)
  - P1 (2%), P2 (3%), P3 (4%) → producto 2
  - PP1 (0.2%), PP2 (0.4%), PP3 (0.6%) → producto 3
- resultados_concreto: importados desde `lib/data/csv_datos_1.1.csv` (delimitador `;`).

## Carga del CSV (resumen de proceso)
1) `backend/seed.py` lee `lib/data/csv_datos_1.1.csv` con el módulo `csv` de Python (delimitador `;`).
2) Se omite la primera fila (encabezados).
3) Se inserta en un solo `INSERT` multi-fila en `resultados_concreto` y se alinea la secuencia SERIAL.

## Consultas clave (usadas por la app)

Promedios por edad para condiciones y aditivo seleccionados (redondeo 2 decimales):

```sql
SELECT 
  edad_dias,
  ROUND(AVG(resistencia_mpa), 2) AS resistencia_promedio,
  COUNT(*) AS num_muestras
FROM resultados_concreto
WHERE temperatura = ? AND humedad = ? AND relacion_ac = ? AND aditivo_id = ?
GROUP BY edad_dias
ORDER BY edad_dias ASC;
```

Consulta detallada con JOIN (nombre de producto y código de aditivo):

```sql
SELECT
  p.nombre_producto,
  a.codigo AS codigo_aditivo,
  r.edad_dias,
  r.temperatura,
  r.humedad,
  r.relacion_ac,
  ROUND(AVG(r.resistencia_mpa), 2) AS promedio_resistencia,
  COUNT(r.id) AS numero_de_muestras
FROM resultados_concreto AS r
JOIN aditivos AS a ON r.aditivo_id = a.id
JOIN productos AS p ON a.producto_id = p.id
WHERE r.temperatura = ? AND r.humedad = ? AND r.relacion_ac = ?
-- opcional: AND r.aditivo_id = ?
GROUP BY p.nombre_producto, a.codigo, r.edad_dias, r.temperatura, r.humedad, r.relacion_ac
ORDER BY a.codigo, r.edad_dias;
```

Máximo y mínimo de promedios globales (útil para documentación/benchmark):

```sql
WITH CalculoPromedios AS (
  SELECT ROUND(AVG(resistencia_mpa), 2) AS promedio_resistencia
  FROM resultados_concreto
  GROUP BY temperatura, humedad, relacion_ac, edad_dias, aditivo_id
)
SELECT
  MAX(promedio_resistencia) AS maximo_promedio_general,
  MIN(promedio_resistencia) AS minimo_promedio_general
FROM CalculoPromedios;
```

## Reglas y consideraciones
- Aislamiento por usuario: `projects.user_id` con ON DELETE CASCADE.
- `projects.aditivo_id` es opcional (NULL) para permitir proyectos sin aditivo fijo.
- Validación en UI: resistencia objetivo (24.00–57.00, hasta 2 decimales).
- El índice `idx_busqueda_resistencia` es crítico para rendimiento en consultas por condiciones.

## Migraciones (histórico resumido)
- v2: incorporación de materials, mixtures, mixture_materials y primera versión de projects.
- v3: ajustes en projects (estructura textual inicial).
- v4: nuevas tablas experimentales (tipos_aditivo, productos, aditivos, resultados_concreto), creación de índice, reestructuración de projects a campos numéricos y campos de predicción, carga del CSV.
- v5: migración a PostgreSQL (cliente-servidor). Nueva tabla `tipos_estructura` y FK `projects.tipo_estructura_id`; `resistance_target` → REAL con CHECK; `users.password` → `password_hash` (bcrypt); FKs con ON DELETE aplicadas de forma nativa (ya no depende de `PRAGMA foreign_keys`). Esquema creado por SQLAlchemy (`backend/seed.py`).

## Extensiones futuras sugeridas
- Normalizar `selected_date` a tipo DATE.
- Guardar conteo de muestras usadas para cada predicción en projects (columna opcional).
- Endpoint para registrar nuevos ensayos de laboratorio en `resultados_concreto` (recalibración del modelo con datos nuevos).
- Migraciones versionadas con Alembic en lugar de `create_all`.

---
Documento generado para acompañar la app DIAPCE. Cualquier ajuste de esquema debe actualizarse aquí, en `backend/app/models.py` y regenerar `backend/schema.sql` (`pg_dump --schema-only`).
