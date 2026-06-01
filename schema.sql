-- ============================================================
-- REDESA Financeiro Gerencial — Schema Supabase
-- BU: Educação / Eureka
-- ============================================================
-- Execute este SQL no SQL Editor do Supabase

-- Habilitar RLS
-- Cada tabela usa Row Level Security com política: usuários autenticados podem tudo

-- ─── MUNICIPIOS ────────────────────────────────────────────
create table if not exists municipios (
  id           bigserial primary key,
  nome         text not null,
  uf           text,
  habitantes   bigint,
  qtd_alunos   integer,
  observacoes  text,
  ativo        boolean default true,
  created_at   timestamptz default now()
);

-- Município especial "Corporativo" para despesas sem vínculo geográfico
insert into municipios (nome, uf, ativo) values ('Corporativo', '--', true)
  on conflict do nothing;

-- ─── APRESENTADORES ────────────────────────────────────────
create table if not exists apresentadores (
  id           bigserial primary key,
  nome         text not null,
  regiao       text,
  comissao_pct numeric(5,2) default 0,
  observacoes  text,
  ativo        boolean default true,
  created_at   timestamptz default now()
);

-- ─── RECEITAS ──────────────────────────────────────────────
create table if not exists receitas (
  id              bigserial primary key,
  data            date not null,
  municipio_id    bigint references municipios(id),
  municipio_nome  text,
  categoria       text not null,  -- '1000' ou '1010'
  valor           numeric(14,2) not null,
  observacao      text,
  bu              text default 'eureka',
  created_by      uuid references auth.users(id),
  created_at      timestamptz default now()
);

-- ─── CUSTOS DIRETOS ────────────────────────────────────────
create table if not exists custos_diretos (
  id               bigserial primary key,
  data             date not null,
  municipio_id     bigint references municipios(id),
  municipio_nome   text,
  categoria        text not null,  -- '2000','2100'
  subcategoria     text not null,  -- '2010','2110',...
  apresentador_id  bigint references apresentadores(id),
  apresentador_nome text,
  responsavel      text,
  valor            numeric(14,2) not null,
  observacao       text,
  bu               text default 'eureka',
  created_by       uuid references auth.users(id),
  created_at       timestamptz default now()
);

-- ─── DESPESAS ADMINISTRATIVAS ──────────────────────────────
create table if not exists despesas_admin (
  id            bigserial primary key,
  data          date not null,
  categoria     text not null,   -- '3000','3100','3200'
  subcategoria  text not null,   -- '3010','3020',...
  responsavel   text,
  valor         numeric(14,2) not null,
  observacao    text,
  bu            text default 'eureka',
  created_by    uuid references auth.users(id),
  created_at    timestamptz default now()
);

-- ─── DIRETORIA ─────────────────────────────────────────────
create table if not exists diretoria (
  id          bigserial primary key,
  data        date not null,
  responsavel text not null,  -- 'Mauricio' ou 'Francisco'
  subcategoria text not null, -- '4010','4110'
  valor       numeric(14,2) not null,
  observacao  text,
  bu          text default 'eureka',
  created_by  uuid references auth.users(id),
  created_at  timestamptz default now()
);

-- ─── TRIBUTOS ──────────────────────────────────────────────
create table if not exists tributos (
  id          bigserial primary key,
  data        date not null,
  categoria   text not null,   -- '5000','5100'
  subcategoria text not null,  -- '5010','5110','5120'
  valor       numeric(14,2) not null,
  observacao  text,
  bu          text default 'eureka',
  created_by  uuid references auth.users(id),
  created_at  timestamptz default now()
);

-- ─── PERFIS (usuários aprovados) ───────────────────────────
create table if not exists perfis (
  id         uuid primary key references auth.users(id),
  email      text,
  nome       text,
  papel      text default 'viewer',  -- 'admin' | 'editor' | 'viewer'
  aprovado   boolean default false,
  created_at timestamptz default now()
);

-- ─── RLS ───────────────────────────────────────────────────
alter table municipios      enable row level security;
alter table apresentadores  enable row level security;
alter table receitas        enable row level security;
alter table custos_diretos  enable row level security;
alter table despesas_admin  enable row level security;
alter table diretoria       enable row level security;
alter table tributos        enable row level security;
alter table perfis          enable row level security;

-- Política: usuários autenticados podem ler/escrever tudo
-- (controle de edição feito no frontend por papel)
create policy "auth_all" on municipios     for all using (auth.role() = 'authenticated');
create policy "auth_all" on apresentadores for all using (auth.role() = 'authenticated');
create policy "auth_all" on receitas       for all using (auth.role() = 'authenticated');
create policy "auth_all" on custos_diretos for all using (auth.role() = 'authenticated');
create policy "auth_all" on despesas_admin for all using (auth.role() = 'authenticated');
create policy "auth_all" on diretoria      for all using (auth.role() = 'authenticated');
create policy "auth_all" on tributos       for all using (auth.role() = 'authenticated');
create policy "auth_all" on perfis         for all using (auth.role() = 'authenticated');

-- ─── TRIGGER: criar perfil automaticamente no signup ───────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.perfis (id, email, nome, papel, aprovado)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'nome', split_part(new.email,'@',1)),
    case
      when new.email in ('cesaogolgpt@gmail.com','mauricio@redesa.co','francisco@redesa.co')
        then 'admin'
      when new.email like '%@redesa.co'
        then 'editor'
      else 'viewer'
    end,
    case
      when new.email in ('cesaogolgpt@gmail.com','mauricio@redesa.co','francisco@redesa.co')
        then true
      else false
    end
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
