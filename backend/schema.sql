
\restrict yDShBPJbMAid8t2de51mPIcPai4Vb8Ye5y5LGtbcKX1xxBN0kc0aozRdER4wdYU

CREATE TABLE public.aditivos (
    id integer NOT NULL,
    codigo character varying(16) NOT NULL,
    porcentaje_aplicado character varying(16) NOT NULL,
    tipo_aditivo_id integer NOT NULL,
    producto_id integer NOT NULL
);

CREATE SEQUENCE public.aditivos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.aditivos_id_seq OWNED BY public.aditivos.id;

CREATE TABLE public.materials (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    unit character varying(16) NOT NULL,
    density double precision,
    cost_per_unit double precision,
    description text,
    created_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.materials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.materials_id_seq OWNED BY public.materials.id;

CREATE TABLE public.mixture_materials (
    id integer NOT NULL,
    mixture_id integer NOT NULL,
    material_id integer NOT NULL,
    quantity double precision NOT NULL,
    percentage double precision
);

CREATE SEQUENCE public.mixture_materials_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.mixture_materials_id_seq OWNED BY public.mixture_materials.id;

CREATE TABLE public.mixtures (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    description text,
    total_volume double precision,
    project_id integer,
    created_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.mixtures_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.mixtures_id_seq OWNED BY public.mixtures.id;

CREATE TABLE public.productos (
    id integer NOT NULL,
    nombre_producto character varying(128) NOT NULL,
    marca character varying(64)
);

CREATE SEQUENCE public.productos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.productos_id_seq OWNED BY public.productos.id;

CREATE TABLE public.projects (
    id integer NOT NULL,
    user_id integer NOT NULL,
    project_name character varying(128) NOT NULL,
    selected_date character varying(32),
    selected_image_path text,
    creator_name character varying(128),
    tipo_estructura_id integer NOT NULL,
    resistance_target double precision NOT NULL,
    temperature integer NOT NULL,
    humidity integer NOT NULL,
    relacion_ac double precision NOT NULL,
    aditivo_id integer,
    resistencia_predicha_7d double precision,
    resistencia_predicha_14d double precision,
    resistencia_predicha_28d double precision,
    mixture_id integer,
    created_at timestamp without time zone NOT NULL,
    CONSTRAINT ck_resistance_target CHECK (((resistance_target >= (24)::double precision) AND (resistance_target <= (57)::double precision)))
);

CREATE SEQUENCE public.projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;

CREATE TABLE public.resultados_concreto (
    id integer NOT NULL,
    temperatura integer NOT NULL,
    humedad integer NOT NULL,
    relacion_ac double precision NOT NULL,
    edad_dias integer NOT NULL,
    resistencia_mpa double precision NOT NULL,
    aditivo_id integer NOT NULL
);

CREATE SEQUENCE public.resultados_concreto_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.resultados_concreto_id_seq OWNED BY public.resultados_concreto.id;

CREATE TABLE public.tipos_aditivo (
    id integer NOT NULL,
    nombre character varying(64) NOT NULL
);

CREATE SEQUENCE public.tipos_aditivo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.tipos_aditivo_id_seq OWNED BY public.tipos_aditivo.id;

CREATE TABLE public.tipos_estructura (
    id integer NOT NULL,
    codigo character varying(32) NOT NULL,
    nombre character varying(64) NOT NULL
);

CREATE SEQUENCE public.tipos_estructura_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.tipos_estructura_id_seq OWNED BY public.tipos_estructura.id;

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL
);

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;

ALTER TABLE ONLY public.aditivos ALTER COLUMN id SET DEFAULT nextval('public.aditivos_id_seq'::regclass);

ALTER TABLE ONLY public.materials ALTER COLUMN id SET DEFAULT nextval('public.materials_id_seq'::regclass);

ALTER TABLE ONLY public.mixture_materials ALTER COLUMN id SET DEFAULT nextval('public.mixture_materials_id_seq'::regclass);

ALTER TABLE ONLY public.mixtures ALTER COLUMN id SET DEFAULT nextval('public.mixtures_id_seq'::regclass);

ALTER TABLE ONLY public.productos ALTER COLUMN id SET DEFAULT nextval('public.productos_id_seq'::regclass);

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);

ALTER TABLE ONLY public.resultados_concreto ALTER COLUMN id SET DEFAULT nextval('public.resultados_concreto_id_seq'::regclass);

ALTER TABLE ONLY public.tipos_aditivo ALTER COLUMN id SET DEFAULT nextval('public.tipos_aditivo_id_seq'::regclass);

ALTER TABLE ONLY public.tipos_estructura ALTER COLUMN id SET DEFAULT nextval('public.tipos_estructura_id_seq'::regclass);

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);

ALTER TABLE ONLY public.aditivos
    ADD CONSTRAINT aditivos_codigo_key UNIQUE (codigo);

ALTER TABLE ONLY public.aditivos
    ADD CONSTRAINT aditivos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_name_key UNIQUE (name);

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.mixture_materials
    ADD CONSTRAINT mixture_materials_mixture_id_material_id_key UNIQUE (mixture_id, material_id);

ALTER TABLE ONLY public.mixture_materials
    ADD CONSTRAINT mixture_materials_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.mixtures
    ADD CONSTRAINT mixtures_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_nombre_producto_key UNIQUE (nombre_producto);

ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.resultados_concreto
    ADD CONSTRAINT resultados_concreto_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.tipos_aditivo
    ADD CONSTRAINT tipos_aditivo_nombre_key UNIQUE (nombre);

ALTER TABLE ONLY public.tipos_aditivo
    ADD CONSTRAINT tipos_aditivo_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.tipos_estructura
    ADD CONSTRAINT tipos_estructura_codigo_key UNIQUE (codigo);

ALTER TABLE ONLY public.tipos_estructura
    ADD CONSTRAINT tipos_estructura_pkey PRIMARY KEY (id);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

CREATE INDEX idx_busqueda_resistencia ON public.resultados_concreto USING btree (temperatura, humedad, relacion_ac, aditivo_id, edad_dias);

ALTER TABLE ONLY public.aditivos
    ADD CONSTRAINT aditivos_producto_id_fkey FOREIGN KEY (producto_id) REFERENCES public.productos(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.aditivos
    ADD CONSTRAINT aditivos_tipo_aditivo_id_fkey FOREIGN KEY (tipo_aditivo_id) REFERENCES public.tipos_aditivo(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.mixtures
    ADD CONSTRAINT fk_mixtures_project FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.mixture_materials
    ADD CONSTRAINT mixture_materials_material_id_fkey FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.mixture_materials
    ADD CONSTRAINT mixture_materials_mixture_id_fkey FOREIGN KEY (mixture_id) REFERENCES public.mixtures(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_aditivo_id_fkey FOREIGN KEY (aditivo_id) REFERENCES public.aditivos(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_mixture_id_fkey FOREIGN KEY (mixture_id) REFERENCES public.mixtures(id) ON DELETE SET NULL;

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_tipo_estructura_id_fkey FOREIGN KEY (tipo_estructura_id) REFERENCES public.tipos_estructura(id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;

ALTER TABLE ONLY public.resultados_concreto
    ADD CONSTRAINT resultados_concreto_aditivo_id_fkey FOREIGN KEY (aditivo_id) REFERENCES public.aditivos(id) ON DELETE CASCADE;

\unrestrict yDShBPJbMAid8t2de51mPIcPai4Vb8Ye5y5LGtbcKX1xxBN0kc0aozRdER4wdYU

