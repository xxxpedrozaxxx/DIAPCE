# Configura PostgreSQL local para DIAPCE (Windows).
#
#   powershell -ExecutionPolicy Bypass -File backend\setup_postgres.ps1
#
# 1. Crea el rol `diapce` y la base `diapce` (si no existen) usando el
#    superusuario `postgres`. Pide su contraseña, o la toma de $env:PGPASSWORD.
# 2. Escribe backend\.env apuntando a PostgreSQL.
# 3. Crea el esquema y carga los datos de semilla (seed.py).
param(
    [string]$DbPassword = "diapce",
    [string]$PgHost = "localhost",
    [int]$PgPort = 5432
)

$ErrorActionPreference = "Stop"
$backend = $PSScriptRoot

# psql de la versión de PostgreSQL más reciente instalada.
$psql = Get-ChildItem "C:\Program Files\PostgreSQL\*\bin\psql.exe" -ErrorAction SilentlyContinue |
    Sort-Object { [int]$_.Directory.Parent.Name } -Descending |
    Select-Object -First 1 -ExpandProperty FullName
if (-not $psql) { throw "No se encontró psql.exe en C:\Program Files\PostgreSQL\*\bin" }
Write-Host "psql: $psql"

if (-not $env:PGPASSWORD) {
    $secure = Read-Host "Contraseña del usuario postgres" -AsSecureString
    $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
}

function Invoke-Psql([string]$Sql, [string]$Db = "postgres") {
    $out = & $psql -U postgres -h $PgHost -p $PgPort -d $Db -v ON_ERROR_STOP=1 -tAc $Sql 2>&1
    if ($LASTEXITCODE -ne 0) { throw "psql falló: $out" }
    return $out
}

if ((Invoke-Psql "SELECT 1 FROM pg_roles WHERE rolname = 'diapce'") -ne "1") {
    Invoke-Psql "CREATE ROLE diapce LOGIN PASSWORD '$DbPassword'" | Out-Null
    Write-Host "[OK] Rol diapce creado"
} else {
    Invoke-Psql "ALTER ROLE diapce LOGIN PASSWORD '$DbPassword'" | Out-Null
    Write-Host "[OK] Rol diapce ya existía (contraseña actualizada)"
}

if ((Invoke-Psql "SELECT 1 FROM pg_database WHERE datname = 'diapce'") -ne "1") {
    Invoke-Psql "CREATE DATABASE diapce OWNER diapce ENCODING 'UTF8' TEMPLATE template0" | Out-Null
    Write-Host "[OK] Base de datos diapce creada"
} else {
    Write-Host "[OK] Base de datos diapce ya existía"
}
# PostgreSQL 15+ ya no da CREATE sobre public a todos: el dueño de la BD lo necesita.
Invoke-Psql "ALTER SCHEMA public OWNER TO diapce" "diapce" | Out-Null
Remove-Item Env:PGPASSWORD

# .env del backend apuntando a PostgreSQL.
$envFile = Join-Path $backend ".env"
$url = "postgresql+psycopg2://diapce:$DbPassword@${PgHost}:$PgPort/diapce"
if (-not (Test-Path $envFile)) { Copy-Item (Join-Path $backend ".env.example") $envFile }
$lines = Get-Content $envFile | Where-Object { $_ -notmatch '^\s*DATABASE_URL=' }
Set-Content $envFile (@("DATABASE_URL=$url") + $lines)
Write-Host "[OK] backend\.env -> $url"

# Esquema + datos de semilla.
$python = Join-Path $backend ".venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    python -m venv (Join-Path $backend ".venv")
    & $python -m pip install -q -r (Join-Path $backend "requirements.txt")
}
Push-Location $backend
try {
    & $python seed.py
    if ($LASTEXITCODE -ne 0) { throw "seed.py falló" }
} finally {
    Pop-Location
}
Write-Host "`nListo. Arranca la API con:  cd backend; .venv\Scripts\python run.py"
