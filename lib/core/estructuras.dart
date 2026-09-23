// Tipos de estructura (tabla tipos_estructura): código de la API y etiqueta.

const estructuras = [
  ('Puentes', 'Puentes'),
  ('Tuneles', 'Túneles'),
  ('Muros', 'Muros de contención'),
];

/// Valor del filtro de análisis para los ensayos históricos sin estructura.
const sinClasificar = 'sin_clasificar';

/// Opciones del filtro por estructura: null = todas.
const filtrosEstructura = <String?>[
  null,
  'Puentes',
  'Tuneles',
  'Muros',
  sinClasificar,
];

String estructuraLabel(String? codigo) =>
    codigo == null
        ? 'Sin clasificar'
        : estructuras
            .firstWhere((e) => e.$1 == codigo, orElse: () => (codigo, codigo))
            .$2;

String filtroEstructuraLabel(String? filtro) => switch (filtro) {
  null => 'Todas',
  sinClasificar => 'Históricos',
  _ => estructuraLabel(filtro),
};
