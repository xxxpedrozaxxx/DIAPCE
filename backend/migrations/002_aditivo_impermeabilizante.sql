-- 002 — Material para dosificar el impermeabilizante en el diseño ACI 211.1.
-- Sin precio de catálogo: el laboratorio debe registrarlo.
INSERT INTO materials (name, unit, density, cost_per_unit, description, created_at)
SELECT 'Aditivo Impermeabilizante', 'kg', NULL, NULL,
       'Impermeabilizante integral (Euco Vandex AM 10I)', now()
WHERE NOT EXISTS (SELECT 1 FROM materials WHERE name = 'Aditivo Impermeabilizante');
