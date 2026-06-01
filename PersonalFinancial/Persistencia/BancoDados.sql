PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS "stg_origens_importacao" (
    "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
    "codigo" varchar(50) NOT NULL UNIQUE,
    "nome" varchar(100) NOT NULL UNIQUE,
    "ativo" bool NOT NULL,
    "criado_em" datetime NOT NULL
);

CREATE TABLE IF NOT EXISTS "stg_importacoes_arquivo" (
    "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nome_arquivo" varchar(255) NOT NULL,
    "hash_arquivo" varchar(64) NOT NULL,
    "tipo_arquivo" varchar(10) NOT NULL,
    "tamanho_bytes" bigint unsigned NOT NULL CHECK ("tamanho_bytes" >= 0),
    "data_inicial" date NOT NULL,
    "data_final" date NOT NULL,
    "status" varchar(20) NOT NULL,
    "mensagem_erro" text NOT NULL,
    "importado_em" datetime NOT NULL,
    "atualizado_em" datetime NOT NULL,
    "origem_id" bigint NOT NULL REFERENCES "stg_origens_importacao" ("id") DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT "uq_stg_imp_arq_origem_hash" UNIQUE ("origem_id", "hash_arquivo"),
    CONSTRAINT "ck_stg_imp_arq_hash_preenchido" CHECK (NOT ("hash_arquivo" = '')),
    CONSTRAINT "ck_stg_imp_arq_tamanho_positivo" CHECK ("tamanho_bytes" > 0),
    CONSTRAINT "ck_stg_imp_arq_periodo_valido" CHECK ("data_final" >= ("data_inicial"))
);

CREATE INDEX IF NOT EXISTS "stg_importacoes_arquivo_origem_id_a6ec7597"
ON "stg_importacoes_arquivo" ("origem_id");

CREATE INDEX IF NOT EXISTS "idx_stg_imp_arq_orig_st"
ON "stg_importacoes_arquivo" ("origem_id", "status");

CREATE INDEX IF NOT EXISTS "idx_stg_imp_arq_hash"
ON "stg_importacoes_arquivo" ("hash_arquivo");

CREATE INDEX IF NOT EXISTS "idx_stg_imp_arq_importado"
ON "stg_importacoes_arquivo" ("importado_em");

CREATE INDEX IF NOT EXISTS "idx_stg_imp_arq_periodo"
ON "stg_importacoes_arquivo" ("data_inicial", "data_final");

CREATE TABLE IF NOT EXISTS "stg_registros_importados" (
    "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
    "numero_linha" integer unsigned NOT NULL CHECK ("numero_linha" >= 0),
    "numero_pagina" integer unsigned NOT NULL CHECK ("numero_pagina" >= 0),
    "secao" varchar(100) NOT NULL,
    "hash_registro" varchar(64) NOT NULL,
    "dados_brutos" text NOT NULL CHECK ((JSON_VALID("dados_brutos") OR "dados_brutos" IS NULL)),
    "criado_em" datetime NOT NULL,
    "importacao_id" bigint NOT NULL REFERENCES "stg_importacoes_arquivo" ("id") DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT "uq_stg_reg_imp_hash" UNIQUE ("importacao_id", "hash_registro"),
    CONSTRAINT "ck_stg_reg_hash_preenchido" CHECK (NOT ("hash_registro" = ''))
);

CREATE UNIQUE INDEX IF NOT EXISTS "uq_stg_reg_imp_linha"
ON "stg_registros_importados" ("importacao_id", "numero_linha")
WHERE "numero_linha" > 0;

CREATE INDEX IF NOT EXISTS "stg_registros_importados_importacao_id_e696548a"
ON "stg_registros_importados" ("importacao_id");

CREATE INDEX IF NOT EXISTS "idx_stg_reg_importacao"
ON "stg_registros_importados" ("importacao_id");

CREATE INDEX IF NOT EXISTS "idx_stg_reg_secao"
ON "stg_registros_importados" ("secao");

CREATE INDEX IF NOT EXISTS "idx_stg_reg_hash"
ON "stg_registros_importados" ("hash_registro");

CREATE TABLE IF NOT EXISTS "business_categorias" (
    "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
    "codigo" varchar(50) NOT NULL UNIQUE,
    "nome" varchar(100) NOT NULL UNIQUE,
    "ativo" bool NOT NULL,
    "criado_em" datetime NOT NULL
);

CREATE TABLE IF NOT EXISTS "business_tipos_movimento" (
    "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
    "codigo" varchar(50) NOT NULL UNIQUE,
    "nome" varchar(100) NOT NULL UNIQUE,
    "ativo" bool NOT NULL,
    "criado_em" datetime NOT NULL
);

CREATE TABLE IF NOT EXISTS "business_regras_categoria_manual" (
    "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
    "descricao_normalizada" text NOT NULL UNIQUE,
    "descricao_exibicao" text NOT NULL,
    "ativo" bool NOT NULL,
    "criado_em" datetime NOT NULL,
    "atualizado_em" datetime NOT NULL,
    "categoria_id" bigint NOT NULL REFERENCES "business_categorias" ("id") DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT "ck_bus_reg_cat_desc_norm_preenchida" CHECK (NOT ("descricao_normalizada" = '')),
    CONSTRAINT "ck_bus_reg_cat_desc_exib_preenchida" CHECK (NOT ("descricao_exibicao" = ''))
);

CREATE INDEX IF NOT EXISTS "business_regras_categoria_manual_categoria_id_761a2fcc"
ON "business_regras_categoria_manual" ("categoria_id");

CREATE INDEX IF NOT EXISTS "idx_bus_reg_cat_ativo_cat"
ON "business_regras_categoria_manual" ("ativo", "categoria_id");

CREATE INDEX IF NOT EXISTS "idx_bus_reg_cat_criado"
ON "business_regras_categoria_manual" ("criado_em");

CREATE TABLE IF NOT EXISTS "business_transacoes" (
    "id" integer NOT NULL PRIMARY KEY AUTOINCREMENT,
    "nome_conta" varchar(150) NOT NULL,
    "data_transacao" date NOT NULL,
    "descricao_original" text NOT NULL,
    "descricao_normalizada" text NOT NULL,
    "valor" decimal NOT NULL,
    "moeda" varchar(3) NOT NULL,
    "saldo" decimal NOT NULL,
    "hash_transacao" varchar(64) NOT NULL,
    "dados_interpretacao" text NOT NULL CHECK ((JSON_VALID("dados_interpretacao") OR "dados_interpretacao" IS NULL)),
    "criado_em" datetime NOT NULL,
    "atualizado_em" datetime NOT NULL,
    "categoria_id" bigint NOT NULL REFERENCES "business_categorias" ("id") DEFERRABLE INITIALLY DEFERRED,
    "importacao_id" bigint NOT NULL REFERENCES "stg_importacoes_arquivo" ("id") DEFERRABLE INITIALLY DEFERRED,
    "registro_importado_id" bigint NOT NULL UNIQUE REFERENCES "stg_registros_importados" ("id") DEFERRABLE INITIALLY DEFERRED,
    "tipo_movimento_id" bigint NOT NULL REFERENCES "business_tipos_movimento" ("id") DEFERRABLE INITIALLY DEFERRED,
    "hash_canonico" varchar(64) NOT NULL,
    CONSTRAINT "uq_bus_trans_imp_hash" UNIQUE ("importacao_id", "hash_transacao"),
    CONSTRAINT "ck_bus_trans_moeda_preenchida" CHECK (NOT ("moeda" = '')),
    CONSTRAINT "ck_bus_trans_hash_preenchido" CHECK (NOT ("hash_transacao" = '')),
    CONSTRAINT "ck_bus_trans_hash_canon_preenchido" CHECK (NOT ("hash_canonico" = '')),
    CONSTRAINT "uq_bus_trans_hash_canonico" UNIQUE ("hash_canonico")
);

CREATE INDEX IF NOT EXISTS "business_transacoes_categoria_id_63421ada"
ON "business_transacoes" ("categoria_id");

CREATE INDEX IF NOT EXISTS "business_transacoes_importacao_id_3d6e7a45"
ON "business_transacoes" ("importacao_id");

CREATE INDEX IF NOT EXISTS "business_transacoes_tipo_movimento_id_dee4cbf9"
ON "business_transacoes" ("tipo_movimento_id");

CREATE INDEX IF NOT EXISTS "idx_bus_trans_data"
ON "business_transacoes" ("data_transacao");

CREATE INDEX IF NOT EXISTS "idx_bus_trans_cat_data"
ON "business_transacoes" ("categoria_id", "data_transacao");

CREATE INDEX IF NOT EXISTS "idx_bus_trans_tipo_data"
ON "business_transacoes" ("tipo_movimento_id", "data_transacao");

CREATE INDEX IF NOT EXISTS "idx_bus_trans_conta_data"
ON "business_transacoes" ("nome_conta", "data_transacao");

CREATE INDEX IF NOT EXISTS "idx_bus_trans_hash"
ON "business_transacoes" ("hash_transacao");

CREATE INDEX IF NOT EXISTS "idx_bus_trans_hash_canon"
ON "business_transacoes" ("hash_canonico");
