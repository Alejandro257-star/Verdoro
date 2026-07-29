-- =========================================================
-- VERDORO — esquema de base de datos para Supabase
-- Cópialo entero y pégalo en: Supabase > SQL Editor > New query > Run
-- =========================================================

create extension if not exists pgcrypto;

create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);

create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category_id uuid references categories(id) on delete set null,
  price numeric not null default 0,
  stock integer not null default 0,
  description text default '',
  promo2x1 boolean default false,
  images text[] default '{}',
  sizes text[] default '{}',
  colors text[] default '{}',
  created_at timestamptz default now()
);

create table if not exists reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid references products(id) on delete cascade,
  user_name text not null,
  rating integer not null check (rating between 1 and 5),
  comment text default '',
  created_at timestamptz default now()
);

create table if not exists coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  type text not null check (type in ('percent','fixed')),
  value numeric not null,
  expiry date
);

create table if not exists banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  subtitle text default '',
  img text not null,
  sort_order integer default 0
);

create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  total numeric not null,
  method text not null,
  customer_name text,
  customer_email text,
  customer_address text,
  provider_ref text,
  created_at timestamptz default now()
);

create table if not exists order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders(id) on delete cascade,
  product_id uuid references products(id),
  qty integer not null,
  size text,
  color text,
  price numeric not null
);

-- =========================================================
-- Seguridad (Row Level Security)
-- Lectura pública del catálogo; escritura solo para un
-- administrador autenticado en Supabase Auth.
-- =========================================================
alter table categories enable row level security;
alter table products   enable row level security;
alter table reviews    enable row level security;
alter table coupons    enable row level security;
alter table banners    enable row level security;
alter table orders     enable row level security;
alter table order_items enable row level security;

create policy "public read categories" on categories for select using (true);
create policy "admin write categories" on categories for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "public read products" on products for select using (true);
create policy "admin write products" on products for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "public read reviews" on reviews for select using (true);
create policy "public insert reviews" on reviews for insert with check (true); -- cualquier cliente puede opinar
create policy "admin delete reviews" on reviews for delete using (auth.role() = 'authenticated');

create policy "public read coupons" on coupons for select using (true);
create policy "admin write coupons" on coupons for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "public read banners" on banners for select using (true);
create policy "admin write banners" on banners for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

create policy "public insert orders" on orders for insert with check (true); -- checkout sin necesidad de cuenta
create policy "admin read orders" on orders for select using (auth.role() = 'authenticated');
create policy "public insert order_items" on order_items for insert with check (true);
create policy "admin read order_items" on order_items for select using (auth.role() = 'authenticated');

-- =========================================================
-- Datos de ejemplo (puedes borrarlos luego desde el panel admin)
-- =========================================================
insert into categories (name) values
  ('Ropa'), ('Zapatillas'), ('Accesorios'), ('Accesorios Electrónicos'), ('Perfumes')
on conflict (name) do nothing;

insert into products (name, category_id, price, stock, promo2x1, images, sizes, colors, description)
select 'Camisa Oxford Verde', id, 39.90, 24, true,
  array['https://picsum.photos/seed/verdoro1/700/700','https://picsum.photos/seed/verdoro1b/700/700'],
  array['S','M','L','XL'], array['Verde','Blanco','Negro'],
  'Camisa de algodón premium, corte regular, ideal para entretiempo.'
from categories where name='Ropa';

insert into products (name, category_id, price, stock, promo2x1, images, sizes, colors, description)
select 'Zapatilla Runner Oro', id, 79.00, 15, false,
  array['https://picsum.photos/seed/verdoro2/700/700','https://picsum.photos/seed/verdoro2b/700/700'],
  array['38','39','40','41','42','43'], array['Blanco/Oro','Negro'],
  'Amortiguación ligera y suela de tracción para uso diario.'
from categories where name='Zapatillas';

insert into products (name, category_id, price, stock, promo2x1, images, sizes, colors, description)
select 'Cinturón Piel Verdoro', id, 24.50, 40, true,
  array['https://picsum.photos/seed/verdoro3/700/700'],
  array['Única'], array['Marrón','Negro'],
  'Piel genuina con hebilla dorada grabada.'
from categories where name='Accesorios';

insert into products (name, category_id, price, stock, promo2x1, images, sizes, colors, description)
select 'Auriculares BT Verdoro Air', id, 59.90, 30, false,
  array['https://picsum.photos/seed/verdoro4/700/700','https://picsum.photos/seed/verdoro4b/700/700'],
  array[]::text[], array['Blanco','Negro','Verde'],
  'Bluetooth 5.3, 24h de batería con estuche de carga.'
from categories where name='Accesorios Electrónicos';

insert into products (name, category_id, price, stock, promo2x1, images, sizes, colors, description)
select 'Eau de Parfum Dorado 90ml', id, 54.00, 20, false,
  array['https://picsum.photos/seed/verdoro5/700/700'],
  array['50ml','90ml'], array[]::text[],
  'Notas de bergamota, ámbar y madera de cedro.'
from categories where name='Perfumes';

insert into coupons (code, type, value, expiry) values
  ('BIENVENIDO10','percent',10,'2026-12-31'),
  ('VERDORO5','fixed',5,'2026-12-31')
on conflict (code) do nothing;

insert into banners (title, subtitle, img, sort_order) values
  ('Colección Verdoro','Estilo con acento dorado, para cada día.','https://picsum.photos/seed/verdorobanner1/700/560',0),
  ('2x1 en piezas seleccionadas','Encuentra el sello 2x1 en la ficha de producto.','https://picsum.photos/seed/verdorobanner2/700/560',1),
  ('Nuevo: Accesorios Electrónicos','Auriculares y gadgets con estética Verdoro.','https://picsum.photos/seed/verdorobanner3/700/560',2);
