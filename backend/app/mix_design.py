"""Dosificación de mezclas por el método de volumen absoluto del ACI 211.1.

Reemplaza las plantillas fijas de ejemplo: la composición de 1 m³ se calcula a
partir de la relación agua/cemento y del aditivo que el usuario eligió (los
mismos de los ensayos de laboratorio), del tipo de estructura y de las
propiedades de los materiales del catálogo.

Pasos (ACI 211.1, concreto sin aire incorporado):
1. Asentamiento según el tipo de estructura (Tabla 6.3.1).
2. Agua de mezclado y aire atrapado según asentamiento y tamaño máximo
   nominal del agregado (Tabla 6.3.3).
3. Cemento = agua / (a/c).
4. Agregado grueso = volumen seco compactado por m³ (Tabla 6.3.6, según
   tamaño máximo y módulo de finura de la arena) × peso unitario compactado.
5. Arena = 1 m³ − volúmenes absolutos de agua, cemento, grava y aire.
6. Aditivo = dosis (% del peso del cemento) × cemento.

No se reduce el agua por el plastificante: la resistencia usada para elegir
la relación a/c ya incluye su efecto, y conservar el agua de la tabla es
conservador. Las propiedades supuestas se devuelven con el resultado para que
el laboratorio las ajuste a sus materiales.
"""
from __future__ import annotations

from dataclasses import asdict, dataclass

# Tabla 6.3.3 — agua (kg/m³) y aire atrapado (%) por rango de asentamiento y TMN (mm).
AGUA = {
    "25-50": {9.5: 207, 12.5: 199, 19: 190, 25: 179, 37.5: 166, 50: 154},
    "75-100": {9.5: 228, 12.5: 216, 19: 205, 25: 193, 37.5: 181, 50: 169},
    "150-175": {9.5: 243, 12.5: 228, 19: 216, 25: 202, 37.5: 190, 50: 178},
}
AIRE_ATRAPADO = {9.5: 3.0, 12.5: 2.5, 19: 2.0, 25: 1.5, 37.5: 1.0, 50: 0.5}

# Tabla 6.3.6 — volumen de agregado grueso seco compactado por m³ de concreto,
# por TMN (mm) y módulo de finura de la arena (2,40 / 2,60 / 2,80 / 3,00).
VOLUMEN_GRUESO = {
    9.5: (0.50, 0.48, 0.46, 0.44),
    12.5: (0.59, 0.57, 0.55, 0.53),
    19: (0.66, 0.64, 0.62, 0.60),
    25: (0.71, 0.69, 0.67, 0.65),
    37.5: (0.75, 0.73, 0.71, 0.69),
    50: (0.78, 0.76, 0.74, 0.72),
}
MODULOS_FINURA = (2.40, 2.60, 2.80, 3.00)

# Tabla 6.3.1 — asentamiento recomendado por tipo de estructura (mm) y fila de
# la Tabla 6.3.3 que le corresponde. Los túneles se vacían con bomba o como
# revestimiento, lo que exige mayor fluidez.
ASENTAMIENTO = {
    "Muros": ("25-75 mm (muros de contención reforzados)", "25-50"),
    "Puentes": ("75-100 mm (vigas, pilas y muros reforzados)", "75-100"),
    "Tuneles": ("150-175 mm (revestimiento bombeado)", "150-175"),
}


@dataclass
class Materiales:
    """Propiedades supuestas de los materiales (ajustables por el laboratorio)."""

    tamano_maximo_mm: float = 19
    modulo_finura_arena: float = 2.80
    densidad_cemento: float = 3.15
    densidad_arena: float = 2.65
    densidad_grava: float = 2.70
    peso_unitario_grava: float = 1600.0  # kg/m³, seco compactado


def _volumen_grueso(tmn: float, mf: float) -> float:
    """Interpola linealmente en el módulo de finura."""
    fila = VOLUMEN_GRUESO[tmn]
    mf = min(max(mf, MODULOS_FINURA[0]), MODULOS_FINURA[-1])
    for i in range(len(MODULOS_FINURA) - 1):
        a, b = MODULOS_FINURA[i], MODULOS_FINURA[i + 1]
        if a <= mf <= b:
            return fila[i] + (fila[i + 1] - fila[i]) * (mf - a) / (b - a)
    return fila[-1]


def disenar(
    relacion_ac: float,
    tipo_estructura: str | None,
    dosis_aditivo_pct: float = 0.0,
    tipo_aditivo: str | None = None,
    materiales: Materiales | None = None,
) -> dict:
    """Proporciones en kg por m³ de concreto y supuestos usados."""
    m = materiales or Materiales()
    asentamiento, fila = ASENTAMIENTO.get(tipo_estructura or "", ASENTAMIENTO["Puentes"])
    agua = AGUA[fila][m.tamano_maximo_mm]
    aire = AIRE_ATRAPADO[m.tamano_maximo_mm]
    cemento = agua / relacion_ac
    grava = _volumen_grueso(m.tamano_maximo_mm, m.modulo_finura_arena) * m.peso_unitario_grava
    vol_arena = 1 - (agua / 1000 + cemento / (m.densidad_cemento * 1000)
                     + grava / (m.densidad_grava * 1000) + aire / 100)
    arena = vol_arena * m.densidad_arena * 1000
    aditivo = cemento * dosis_aditivo_pct / 100 if tipo_aditivo else 0.0
    return {
        "agua": round(agua, 1),
        "cemento": round(cemento, 1),
        "arena": round(arena, 1),
        "grava": round(grava, 1),
        "aditivo": round(aditivo, 2),
        "tipo_aditivo": tipo_aditivo if aditivo else None,
        "supuestos": {
            **asdict(m),
            "metodo": "ACI 211.1, volumen absoluto, concreto sin aire incorporado",
            "asentamiento": asentamiento,
            "aire_atrapado_pct": aire,
            "relacion_ac": relacion_ac,
            "dosis_aditivo_pct": dosis_aditivo_pct if aditivo else 0.0,
        },
    }
