-- Peterbauer Camping: complete schema for a fresh Supabase project.
-- Run this file once in the Supabase SQL editor.

create extension if not exists pgcrypto;
create extension if not exists btree_gist;

create table if not exists public.camp_sites (
  id uuid primary key default gen_random_uuid(),
  site_number integer not null unique,
  site_type text not null,
  default_color text not null,
  plan_x numeric(8, 6),
  plan_y numeric(8, 6),
  plan_width numeric(8, 6),
  plan_height numeric(8, 6),
  status text not null default 'free'
    check (status in ('free', 'reserved', 'occupied', 'blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  guest_name text not null,
  address text,
  birth_date date,
  phone text,
  arrival_date date not null,
  departure_date date not null,
  guests integer not null default 1 check (guests > 0),
  has_dog boolean not null default false,
  vehicle_type text not null default 'motorhome'
    check (vehicle_type in ('motorhome', 'car_van', 'tent', 'car_with_trailer', 'other')),
  site_id uuid not null references public.camp_sites(id),
  status text not null default 'open'
    check (status in ('open', 'checked_in', 'checked_out', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (departure_date >= arrival_date)
);

create index if not exists bookings_site_dates_idx
  on public.bookings (site_id, arrival_date, departure_date);

create table if not exists public.order_products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null
    check (category in ('bakery', 'food_and_drinks', 'kiosk')),
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references public.bookings(id) on delete cascade,
  site_id uuid not null references public.camp_sites(id),
  product_id uuid references public.order_products(id) on delete set null,
  description text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  category text not null
    check (category in ('bakery', 'food_and_drinks', 'kiosk')),
  status text not null default 'open'
    check (status in ('open', 'completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.stay_notes (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references public.bookings(id) on delete cascade,
  site_id uuid not null references public.camp_sites(id),
  category text not null
    check (category in ('bakery', 'food_and_drinks', 'general')),
  note_text text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  event_date date not null,
  event_time time not null,
  category text not null
    check (category in ('waste_collection', 'delivery', 'event', 'private')),
  recurrence text not null default 'none'
    check (recurrence in ('none', 'weekly', 'monthly')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete restrict,
  guest_name text not null,
  site_number integer not null,
  status text not null default 'open'
    check (status in ('open', 'paid')),
  payment_method text
    check (payment_method in ('cash', 'card', 'bank_transfer')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.invoice_lines (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  label text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.order_groups (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid references public.bookings(id) on delete cascade,
  site_id uuid not null references public.camp_sites(id),
  status text not null default 'open'
    check (status in ('open', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_group_id uuid not null references public.order_groups(id) on delete cascade,
  product_id uuid references public.order_products(id) on delete set null,
  description text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(10, 2) not null check (unit_price >= 0),
  category text not null
    check (category in ('bakery', 'food_and_drinks', 'kiosk')),
  status text not null default 'open'
    check (status in ('open', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  task_key text not null unique,
  title text not null,
  quantity_text text not null default '',
  category text not null
    check (category in ('bakery', 'kiosk', 'camping')),
  source_order_item_id uuid references public.order_items(id) on delete set null,
  status text not null default 'open'
    check (status in ('open', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists orders_booking_idx on public.orders (booking_id);
create index if not exists orders_status_idx on public.orders (status);
create index if not exists order_groups_booking_idx on public.order_groups (booking_id);
create index if not exists order_items_group_idx on public.order_items (order_group_id);
create index if not exists order_items_status_idx on public.order_items (status);
create index if not exists tasks_status_idx on public.tasks (status);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
begin
  create trigger camp_sites_updated_at before update on public.camp_sites for each row execute function public.set_updated_at();
  create trigger bookings_updated_at before update on public.bookings for each row execute function public.set_updated_at();
  create trigger order_products_updated_at before update on public.order_products for each row execute function public.set_updated_at();
  create trigger orders_updated_at before update on public.orders for each row execute function public.set_updated_at();
  create trigger stay_notes_updated_at before update on public.stay_notes for each row execute function public.set_updated_at();
  create trigger calendar_events_updated_at before update on public.calendar_events for each row execute function public.set_updated_at();
  create trigger invoices_updated_at before update on public.invoices for each row execute function public.set_updated_at();
  create trigger order_groups_updated_at before update on public.order_groups for each row execute function public.set_updated_at();
  create trigger order_items_updated_at before update on public.order_items for each row execute function public.set_updated_at();
  create trigger tasks_updated_at before update on public.tasks for each row execute function public.set_updated_at();
exception
  when duplicate_object then null;
end;
$$;

alter table public.bookings
  add constraint bookings_no_active_site_overlap
  exclude using gist (
    site_id with =,
    daterange(arrival_date, departure_date, '[)') with &&
  )
  where (status <> 'cancelled');

insert into public.camp_sites (site_number, site_type, default_color)
values
  (1, 'motorhome', '#A9ED21'), (2, 'motorhome', '#A9ED21'),
  (3, 'motorhome', '#A9ED21'), (4, 'motorhome', '#A9ED21'),
  (5, 'motorhome', '#A9ED21'), (6, 'car_van', '#22D9ED'),
  (7, 'car_van', '#22D9ED'), (8, 'tent', '#FFBD21'),
  (9, 'motorhome', '#A9ED21'), (10, 'motorhome', '#A9ED21'),
  (11, 'motorhome', '#A9ED21'), (12, 'motorhome', '#A9ED21'),
  (13, 'motorhome', '#A9ED21'), (14, 'motorhome', '#A9ED21'),
  (15, 'motorhome', '#A9ED21'), (16, 'motorhome', '#A9ED21'),
  (17, 'tent', '#FFBD21'), (18, 'car_with_trailer', '#FF6BA8'),
  (19, 'car_with_trailer', '#FF6BA8'), (20, 'car_with_trailer', '#FF6BA8'),
  (21, 'car_with_trailer', '#FF6BA8'), (22, 'car_with_trailer', '#FF6BA8'),
  (23, 'car_with_trailer', '#FF6BA8'), (24, 'motorhome', '#A9ED21'),
  (25, 'motorhome', '#A9ED21'), (26, 'motorhome', '#A9ED21')
on conflict (site_number) do nothing;

alter table public.camp_sites enable row level security;
alter table public.bookings enable row level security;
alter table public.order_products enable row level security;
alter table public.orders enable row level security;
alter table public.stay_notes enable row level security;
alter table public.calendar_events enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_lines enable row level security;
alter table public.order_groups enable row level security;
alter table public.order_items enable row level security;
alter table public.tasks enable row level security;

create policy "authenticated read camp sites" on public.camp_sites for select to authenticated using (true);
create policy "authenticated update camp sites" on public.camp_sites for update to authenticated using (true) with check (true);
create policy "authenticated read bookings" on public.bookings for select to authenticated using (true);
create policy "authenticated insert bookings" on public.bookings for insert to authenticated with check (true);
create policy "authenticated update bookings" on public.bookings for update to authenticated using (true) with check (true);
create policy "authenticated delete bookings" on public.bookings for delete to authenticated using (true);
create policy "authenticated read products" on public.order_products for select to authenticated using (true);
create policy "authenticated manage products" on public.order_products for all to authenticated using (true) with check (true);
create policy "authenticated read orders" on public.orders for select to authenticated using (true);
create policy "authenticated manage orders" on public.orders for all to authenticated using (true) with check (true);
create policy "authenticated read notes" on public.stay_notes for select to authenticated using (true);
create policy "authenticated manage notes" on public.stay_notes for all to authenticated using (true) with check (true);
create policy "authenticated read calendar" on public.calendar_events for select to authenticated using (true);
create policy "authenticated manage calendar" on public.calendar_events for all to authenticated using (true) with check (true);
create policy "authenticated read invoices" on public.invoices for select to authenticated using (true);
create policy "authenticated manage invoices" on public.invoices for all to authenticated using (true) with check (true);
create policy "authenticated read invoice lines" on public.invoice_lines for select to authenticated using (true);
create policy "authenticated manage invoice lines" on public.invoice_lines for all to authenticated using (true) with check (true);
create policy "authenticated read order groups" on public.order_groups for select to authenticated using (true);
create policy "authenticated manage order groups" on public.order_groups for all to authenticated using (true) with check (true);
create policy "authenticated read order items" on public.order_items for select to authenticated using (true);
create policy "authenticated manage order items" on public.order_items for all to authenticated using (true) with check (true);
create policy "authenticated read tasks" on public.tasks for select to authenticated using (true);
create policy "authenticated manage tasks" on public.tasks for all to authenticated using (true) with check (true);
