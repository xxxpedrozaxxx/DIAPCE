# DIAPCE API (Flask + PostgreSQL)

Backend del sistema DIAPCE. Expone una API REST documentada con OpenAPI
(Swagger UI en `/api/docs`) y ejecuta los modelos matemáticos de análisis de
mezclas del lado del servidor.

## Opción A — Docker (un solo comando)

```bash
docker compose up --build
```

Levanta PostgreSQL 16 y la API en http://localhost:5000. El contenedor crea
el esquema y carga los datos de semilla (CSV incluido) automáticamente.

## Opción B — Local (PostgreSQL ya instalado)

En Windows, un solo script crea el rol y la base `diapce`, escribe `.env` y
carga los datos de semilla (pide la contraseña del usuario `postgres`):

```powershell
powershell -ExecutionPolicy Bypass -File backend\setup_postgres.ps1
cd backend; .venv\Scripts\python run.py
```

Pasos manuales equivalentes:

```bash
# 1. Crear usuario y base de datos (una vez, como superusuario postgres)
psql -U postgres -c "CREATE USER diapce WITH PASSWORD 'diapce';"
psql -U postgres -c "CREATE DATABASE diapce OWNER diapce;"

# 2. Entorno Python
cd backend
python -m venv .venv
.venv\Scripts\activate          # Windows   |   source .venv/bin/activate  (Linux/macOS)
pip install -r requirements.txt
copy .env.example .env          # ajustar DATABASE_URL si cambia la contraseña

# 3. Esquema + datos de semilla
python seed.py                  # --reset para recrear desde cero

# 4. Servidor
python run.py                   # http://localhost:5000/api/docs
```

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| POST | `/api/auth/register` | Registro → JWT |
| POST | `/api/auth/login` | Login → JWT |
| GET/POST | `/api/projects` | Listar / crear proyectos del usuario |
| GET/PUT/DELETE | `/api/projects/{id}` | Detalle / actualizar / eliminar |
| GET | `/api/mixtures/preview?work_type=&resistance_target=` | Composición propuesta sin guardar |
| GET | `/api/mixtures/{id}` | Mezcla con materiales |
| GET | `/api/mixtures/{id}/statistics` | Totales y costo |
| POST | `/api/mixtures/{id}/materials` | Agregar/actualizar material |
| DELETE | `/api/mixtures/{id}/materials/{material_id}` | Quitar material |
| GET | `/api/experiments/options/temperatures` | Temperaturas disponibles |
| GET | `/api/experiments/options/humidity?temperatura=` | Humedades disponibles |
| GET | `/api/experiments/options/relacion-ac?temperatura=&humedad=` | Relaciones a/c |
| GET | `/api/experiments/options/aditivos?temperatura=&humedad=&relacion_ac=` | Aditivos |
| GET | `/api/experiments/predict?temperatura=&humedad=&relacion_ac=&aditivo_id=` | Predicción 7/14/28 d + curva |
| GET | `/api/experiments/optimal-ranges?resistencia_objetivo=` | Rangos óptimos (incluye tipo y cantidad de aditivo) |
| GET | `/api/experiments/dispersion?variable=&edad_dias=&tipo_aditivo=` | Ensayos individuales + tabla de dispersión |
| GET | `/api/experiments/calibration` | MAE/RMSE/R² del modelo |
| GET | `/api/catalog/materials` · `/aditivos` · `/tipos-estructura` | Catálogos |
| GET | `/api/health` | Estado |

Todas las rutas salvo `auth/*` y `health` requieren `Authorization: Bearer <token>`.

## Modelo matemático (`app/analysis.py`)

- **Predicción**: promedio, desviación, mín y máx de `resistencia_mpa` por edad
  para la combinación exacta (temperatura, humedad, a/c, aditivo), más ajuste
  por mínimos cuadrados de `f(t) = a + b·ln(t)` para estimar cualquier edad.
- **Rangos óptimos**: combinaciones cuyo promedio a 28 días ≥ objetivo;
  devuelve min/max/valores de temperatura, humedad y a/c, la cantidad de
  aditivo (%) por tipo de aditivo y las 10 mejores combinaciones.
- **Dispersión**: ensayos individuales de resistencia contra una variable
  (temperatura, humedad, a/c o cantidad de aditivo) y, por cada valor, n,
  promedio, desviación estándar, coeficiente de variación, mínimo, máximo y
  rango; más la correlación de Pearson.
- **Calibración**: MAE, RMSE y R² del modelo contra cada ensayo real, por
  combinación y global.
