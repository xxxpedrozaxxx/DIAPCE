-- 001 — Registro y clasificación de ensayos + historial de calibración (esquema v6).
-- Idempotente: se puede ejecutar sobre una base creada con la v5.

ALTER TABLE resultados_concreto
    ADD COLUMN IF NOT EXISTS tipo_estructura_id integer
        REFERENCES tipos_estructura (id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS registrado_por integer
        REFERENCES users (id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS origen varchar(16) NOT NULL DEFAULT 'semilla',
    ADD COLUMN IF NOT EXISTS fecha_ensayo date,
    ADD COLUMN IF NOT EXISTS observaciones text,
    ADD COLUMN IF NOT EXISTS created_at timestamp without time zone NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_resultados_tipo_estructura
    ON resultados_concreto (tipo_estructura_id);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_resultados_resistencia') THEN
        ALTER TABLE resultados_concreto
            ADD CONSTRAINT ck_resultados_resistencia CHECK (resistencia_mpa > 0);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_resultados_edad') THEN
        ALTER TABLE resultados_concreto
            ADD CONSTRAINT ck_resultados_edad CHECK (edad_dias > 0);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'ck_resultados_humedad') THEN
        ALTER TABLE resultados_concreto
            ADD CONSTRAINT ck_resultados_humedad CHECK (humedad BETWEEN 0 AND 100);
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS calibraciones (
    id                serial PRIMARY KEY,
    created_at        timestamp without time zone NOT NULL,
    ejecutada_por     integer REFERENCES users (id) ON DELETE SET NULL,
    motivo            varchar(16) NOT NULL,
    num_ensayos       integer NOT NULL,
    num_combinaciones integer NOT NULL,
    mae_ajuste        double precision NOT NULL,
    rmse_ajuste       double precision NOT NULL,
    r2_promedio       double precision,
    mae_validacion    double precision,
    rmse_validacion   double precision,
    mape_validacion   double precision,
    detalle           json
);
