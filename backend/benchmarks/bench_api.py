"""Mide los tiempos de respuesta de la API DIAPCE por HTTP.

    python benchmarks/bench_api.py --email demo@diapce.test --password ***
    python benchmarks/bench_api.py --url http://127.0.0.1:5000 -n 50 --csv ../docs/evidencias/rendimiento_api.csv

Hace `n` peticiones secuenciales a cada endpoint de lectura (después de 3 de
calentamiento) y reporta media, mediana, p95 y máximo en milisegundos, y el
tamaño de la respuesta. Solo usa la librería estándar.
"""
from __future__ import annotations

import argparse
import csv
import json
import statistics
import time
import urllib.request
from pathlib import Path

ENDPOINTS = [
    ("Salud del servicio", "/api/health"),
    ("Opciones: temperaturas", "/api/experiments/options/temperatures"),
    ("Predicción 7/14/28 d", "/api/experiments/predict?temperatura=25&humedad=70&relacion_ac=0.4&aditivo_id=7"),
    ("Rangos óptimos (45 MPa)", "/api/experiments/optimal-ranges?resistencia_objetivo=45"),
    ("Dispersión (a/c, 28 d)", "/api/experiments/dispersion?variable=relacion_ac&edad_dias=28"),
    ("Calibración + validación LOO", "/api/experiments/calibration"),
    ("Historial de calibración", "/api/experiments/calibration/history"),
    ("Listado de ensayos (50)", "/api/experiments/results?per_page=50"),
    ("Listado de proyectos", "/api/projects"),
]


def request(url: str, token: str | None = None, body: dict | None = None) -> tuple[float, bytes, int]:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method="POST" if body is not None else "GET")
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    start = time.perf_counter()
    with urllib.request.urlopen(req, timeout=30) as res:
        payload = res.read()
        status = res.status
    return (time.perf_counter() - start) * 1000, payload, status


def percentile(values: list[float], p: float) -> float:
    ordered = sorted(values)
    k = (len(ordered) - 1) * p
    lo, hi = int(k), min(int(k) + 1, len(ordered) - 1)
    return ordered[lo] + (ordered[hi] - ordered[lo]) * (k - lo)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--url", default="http://127.0.0.1:5000")
    parser.add_argument("--email", required=True)
    parser.add_argument("--password", required=True)
    parser.add_argument("-n", type=int, default=30, help="peticiones por endpoint")
    parser.add_argument("--csv", type=Path, help="guarda los resultados en CSV")
    args = parser.parse_args()

    _, payload, _ = request(f"{args.url}/api/auth/login", body={"email": args.email, "password": args.password})
    token = json.loads(payload)["access_token"]

    rows = []
    for nombre, path in ENDPOINTS:
        for _ in range(3):
            request(args.url + path, token)
        tiempos, size = [], 0
        for _ in range(args.n):
            ms, payload, status = request(args.url + path, token)
            assert status == 200, f"{path} → {status}"
            tiempos.append(ms)
            size = len(payload)
        rows.append({
            "endpoint": nombre,
            "ruta": path.split("?")[0],
            "n": args.n,
            "media_ms": round(statistics.fmean(tiempos), 1),
            "mediana_ms": round(statistics.median(tiempos), 1),
            "p95_ms": round(percentile(tiempos, 0.95), 1),
            "max_ms": round(max(tiempos), 1),
            "respuesta_kb": round(size / 1024, 1),
        })

    ancho = max(len(r["endpoint"]) for r in rows)
    print(f"{'Endpoint':<{ancho}}  {'media':>7}  {'mediana':>7}  {'p95':>7}  {'máx':>7}  {'KB':>6}")
    for r in rows:
        print(f"{r['endpoint']:<{ancho}}  {r['media_ms']:>7}  {r['mediana_ms']:>7}  "
              f"{r['p95_ms']:>7}  {r['max_ms']:>7}  {r['respuesta_kb']:>6}")

    if args.csv:
        args.csv.parent.mkdir(parents=True, exist_ok=True)
        with args.csv.open("w", newline="", encoding="utf-8") as fh:
            writer = csv.DictWriter(fh, fieldnames=list(rows[0]))
            writer.writeheader()
            writer.writerows(rows)
        print(f"\nCSV: {args.csv}")


if __name__ == "__main__":
    main()
