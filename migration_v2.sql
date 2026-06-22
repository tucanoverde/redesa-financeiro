-- ============================================================
-- REDESA Financeiro — Migração v2
-- Execute no SQL Editor do Supabase (projeto qplvprpaldzoqiwbkzeg)
-- ============================================================

-- 1) Adicionar colunas REDESA à tabela municipios (que já existia do Eureka)
ALTER TABLE municipios ADD COLUMN IF NOT EXISTS nome         text;
ALTER TABLE municipios ADD COLUMN IF NOT EXISTS habitantes   bigint;
ALTER TABLE municipios ADD COLUMN IF NOT EXISTS qtd_alunos  integer;
ALTER TABLE municipios ADD COLUMN IF NOT EXISTS observacoes text;
ALTER TABLE municipios ADD COLUMN IF NOT EXISTS ativo       boolean default true;

-- 2) Município base "Corporativo" (despesas sem vínculo geográfico)
INSERT INTO municipios (nome, uf, ativo)
SELECT 'Corporativo', '--', true
WHERE NOT EXISTS (SELECT 1 FROM municipios WHERE nome = 'Corporativo');

-- 3) Adicionar coluna de comprovante em todas as tabelas de lançamento
ALTER TABLE receitas       ADD COLUMN IF NOT EXISTS comprovante_url text;
ALTER TABLE custos_diretos ADD COLUMN IF NOT EXISTS comprovante_url text;
ALTER TABLE despesas_admin ADD COLUMN IF NOT EXISTS comprovante_url text;
ALTER TABLE diretoria      ADD COLUMN IF NOT EXISTS comprovante_url text;
ALTER TABLE tributos       ADD COLUMN IF NOT EXISTS comprovante_url text;
