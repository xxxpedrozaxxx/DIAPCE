# Estado de la migración — 2026-09-21 (sesión 1, fin) — MIGRACIÓN COMPLETA

Migración: monolítico Flutter + SQLite → cliente-servidor Flutter + Flask + PostgreSQL.

## Completado
- Tarea 2+3+4 (backend completo) — `backend/` — verificar: `cd backend && DATABASE_URL=sqlite:///smoke.db .venv/Scripts/python seed.py --reset` y luego el smoke test del test_client (register → login → options → predict → POST /projects → mixtures → PUT → optimal-ranges → calibration → DELETE) devuelve 201/200/204. Todos los endpoints probados contra SQLite temporal; **falta probarlos contra PostgreSQL real** (sin credenciales aún).
  - `backend/app/models.py` — 10 tablas (9 originales + `tipos_estructura`), FKs con ON DELETE, índice `idx_busqueda_resistencia`, CHECK 24–57 en `resistance_target`.
  - `backend/app/schemas.py` — marshmallow; nombres de campo = `toMap()` de Dart.
  - `backend/app/analysis.py` — predicción (stats por edad + curva `a + b·ln(t)`), rangos óptimos, calibración (MAE/RMSE/R²). Con el CSV real: 91 combinaciones, MAE global 1.507 MPa, RMSE 1.925, R² promedio 0.9897.
  - `backend/app/mixtures_logic.py` — plantillas de mezcla elegidas por tipo de estructura + resistencia objetivo (ya no aleatorias).
  - `backend/app/resources/{auth,projects,mixtures,experiments,catalog}.py` — 20 rutas bajo `/api`, Swagger en `/api/docs`.
  - `backend/seed.py` — idempotente, `--reset` recrea; carga 1.872 filas del CSV.
  - `backend/Dockerfile`, `docker-compose.yml` (raíz), `backend/README.md`, `.env.example`, `requirements.txt`, venv en `backend/.venv` (gitignored).

## Completado (continuación)
- Tarea 5 (cliente Flutter) — `flutter analyze` limpio (solo el aviso de nombre de archivo preexistente de `ViewExistingProjectScreen.dart`).
  - `pubspec.yaml`: +`http`, +`flutter_secure_storage`; −`sqflite`, −`sqflite_common_ffi`, −`csv`, −`path`; asset CSV retirado.
  - `lib/core/api_client.dart` — singleton HTTP, JWT en secure storage, `ApiException`, base URL por `--dart-define=API_URL` (default localhost / 10.0.2.2 en Android).
  - `lib/services/auth_service.dart` (nuevo), `experiment_service.dart` (nuevo: opciones cascada, predict, optimalRanges), `project_service.dart` y `mixture_service.dart` reescritos sobre la API (+ `previewMixture`).
  - Vistas: `main.dart` (sin FFI ni DatabaseHelper), `main_login.dart`, `create_count.dart` (registra y entra directo al Hall), `hall.dart` (logout borra token), `create_proyect_screen.dart` (temperaturas desde API, aditivos tipados), `ViewExistingProjectScreen.dart` (preview de mezcla para proyecto nuevo; `createProject` al guardar).
  - Eliminados: `lib/core/database_helper.dart`, `lib/view/view__properties.dart`.
- Backend: endpoint extra `GET /api/mixtures/preview` (composición propuesta sin persistir) para que el detalle de un proyecto nuevo muestre la mezcla antes de guardar.

## Completado (Tarea 6 — prueba extremo a extremo)
- PostgreSQL local: usuario/BD `diapce`/`diapce` creados por el usuario. `backend/seed.py --reset` contra Postgres: 1.872 ensayos, 24 materiales, 3 tipos de estructura; `resistance_target` = double precision; `password_hash` bcrypt (`$2b$12$…`).
- API arrancada con `python run.py` y probada por HTTP real (curl): register, temperatures, POST /projects (predicción 35.01 / 45.62 / 56.44 MPa y mezcla "Concreto de Alta Resistencia" elegida por Puentes + 42 MPa), calibration.
- Cliente: `flutter build windows --debug` compila (`build/windows/x64/runner/Debug/diapce_aplicationn.exe`) y la app abre en la pantalla de login.
- `test/api_e2e_test.dart` — prueba de la capa de servicios Dart contra el backend real: registro, 409 duplicado, cascada de opciones, predict, optimal-ranges, preview de mezcla, create/list/delete de proyecto, 401 tras logout. **Pasa** (`flutter test test/api_e2e_test.dart`, se omite sola si el backend no está arriba).
- `backend/schema.sql` exportado con `pg_dump --schema-only` (10 tablas) para el documento de tesis.
- `docs/base_de_datos.md` actualizado a v5 (PostgreSQL, tipos_estructura, password_hash, migraciones).

## Completado (objetivo 3 — visualización, 2026-09-23)
- Backend: `GET /api/experiments/dispersion?variable=&edad_dias=&tipo_aditivo=` (ensayos individuales + tabla de dispersión: n, promedio, desviación, CV, min, max, rango; correlación de Pearson). `optimal-ranges` ahora devuelve la cantidad de aditivo (%) por tipo de aditivo (`aditivos`) en vez del rango de `aditivo_id`, y `mejores` incluye tipo y dosis. El control P0 (0 %) se reporta como "Sin aditivo".
- Cliente: `lib/view/analysis_screen.dart` (pestañas Dispersión y Rangos óptimos; acceso desde el ícono de Hall y el menú lateral). La curva del detalle de proyecto ya no usa porcentajes fijos: dibuja f(t) = a + b·ln(t) del servidor, los promedios reales y la línea de objetivo, y enlaza a los rangos óptimos del proyecto.
- Android: Gradle 9.3.1 + AGP 9.1.0 y `org.gradle.configuration-cache=false` (el único JDK instalado es Java 25).
- Base de datos: `backend/.env` apunta a PostgreSQL; `backend/setup_postgres.ps1` crea rol/BD `diapce`, escribe `.env` y corre `seed.py`. SQLite ya no se usa.

## En curso
- Nada. Migración funcional completa.

## Pendiente (opcional / siguiente sesión)
- Recorrido manual de la UI en Windows con el backend arriba (registro → crear proyecto → guardar → ver detalle). No se pudo automatizar con SendKeys; la capa de servicios sí está probada extremo a extremo.
- Regenerar `docs/DIAPCE_Documentacion_Tecnica.docx` con la arquitectura cliente-servidor (hoy describe el monolito).
- Probar `docker compose up --build` en una máquina con Docker.
- Decidir si volver a `flutter_secure_storage` (requiere instalar "C++ ATL" en Visual Studio Installer); hoy el token va en `shared_preferences`.
- Endpoint para registrar nuevos ensayos de laboratorio (`POST /api/experiments/results`) si el documento exige "registro" de datos experimentales.

## Hallazgos de la validación (sección 1 y 2 del prompt vs código real)
- Vistas que llaman `DatabaseHelper()` directo: `main_login.dart`, `create_count.dart`, `create_proyect_screen.dart` (4 llamadas: 3 opciones en cascada + 1 predicción) **y también** `ViewExistingProjectScreen.dart:70` (createRandomExampleMixture). `view__properties.dart` es código legado sin uso y no compila contra `ProjectData` actual → se elimina.
- `work_type TEXT` ya existe en `projects` con valores `Puentes` / `Tuneles` / `Muros`. Se normaliza a FK `tipo_estructura_id → tipos_estructura`.
- **No existe modelo matemático en Dart.** La "predicción" actual es `SELECT edad_dias, ROUND(AVG(resistencia_mpa),2) ... GROUP BY edad_dias`. El módulo de análisis se construye desde cero en Python.
- Objetivo 3 (visualización): el cliente ya dibuja PieChart (composición) y LineChart (resistencia vs edad con 3 puntos); NO hay "rangos óptimos". Objetivo 4 (calibración): nada implementado.
- Esquema fuente: `docs/base_de_datos.md` (v4) coincide con `lib/core/database_helper.dart`.
- Dataset: `lib/data/csv_datos_1.1.csv`, 1.872 filas, delimitador `;`, columnas `ID;Temperatura;Humedad;Relacion_a_c;Edad;Resistencia;Aditivo_id`.

## Decisiones tomadas y por qué
- Flask + flask-smorest (OpenAPI/Swagger en `/api/docs`) porque el objetivo 2 nombra Flask; smorest da la documentación de la API sin FastAPI.
- SQLAlchemy (Flask-SQLAlchemy) para los modelos; DDL de referencia exportado a `backend/schema.sql` para el documento de tesis.
- Contraseñas con bcrypt; sesión con JWT (flask-jwt-extended). Proyectos siempre filtrados por el `user_id` del token.
- Tabla nueva `tipos_estructura` (Puentes, Tuneles, Muros) y `projects.tipo_estructura_id` FK — cumple "clasificado por tipo de estructura" del objetivo 1. La API sigue exponiendo `work_type` (código) para no romper `ProjectData` en Dart.
- `resistance_target` → `REAL`. Todas las FK con `ON DELETE` explícito (igual que docs/base_de_datos.md).
- Módulo matemático (`backend/app/analysis.py`): (a) promedio y desviación por edad para la combinación exacta; (b) ajuste por mínimos cuadrados de la curva de desarrollo de resistencia `f(t) = a + b·ln(t)` sobre los promedios 7/14/28 para estimar cualquier edad; (c) rangos óptimos: combinaciones cuyo promedio a 28 d ≥ resistencia objetivo, devolviendo min/max por variable; (d) calibración: error (MAE/RMSE) del modelo contra los ensayos reales.
- Postgres de desarrollo: instancia local PostgreSQL 16 (servicio `postgresql-x64-16`, puerto 5432). Docker Compose se entrega igual para el jurado.
- Cliente: paquete `http` (más simple que dio, sin necesidad de interceptores). Token en `shared_preferences`: `flutter_secure_storage` no compila en esta máquina (`error C1083: 'atlstr.h'`, falta el componente ATL de Visual Studio).
- `GET /api/mixtures/preview` añadido para que el detalle de un proyecto nuevo muestre la composición antes de guardar (antes el cliente creaba la mezcla en SQLite al abrir la pantalla).

## Riesgos/dudas abiertas
- Docker no instalado en la máquina de desarrollo → `docker-compose.yml` sin probar.
- Sin modo offline: la app requiere el backend corriendo (localhost en sustentación). Arranque: `cd backend && .venv\Scripts\python run.py`, luego el `.exe` o `flutter run -d windows`.
- `backend/.env` (gitignored) apunta a `postgresql+psycopg2://diapce:diapce@localhost:5432/diapce`.

## Cómo retomar
1. Leer este archivo completo.
2. Verificar: `cd backend && .venv\Scripts\python run.py` → `curl localhost:5000/api/health`; en otra terminal `flutter test test/api_e2e_test.dart` debe pasar.
3. Continuar en: lista "Pendiente (opcional)". Nada bloqueante.
