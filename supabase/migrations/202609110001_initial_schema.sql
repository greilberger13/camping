create extension if not exists pgcrypto;

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

create index if not exists orders_booking_idx on public.orders (booking_id);
create index if not exists orders_status_idx on public.orders (status);

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
  create trigger camp_sites_updated_at before update on public.camp_sites
    for each row execute function public.set_updated_at();
  create trigger bookings_updated_at before update on public.bookings
    for each row execute function public.set_updated_at();
  create trigger order_products_updated_at before update on public.order_products
    for each row execute function public.set_updated_at();
  create trigger orders_updated_at before update on public.orders
    for each row execute function public.set_updated_at();
  create trigger stay_notes_updated_at before update on public.stay_notes
    for each row execute function public.set_updated_at();
  create trigger calendar_events_updated_at before update on public.calendar_events
    for each row execute function public.set_updated_at();
  create trigger invoices_updated_at before update on public.invoices
    for each row execute function public.set_updated_at();
exception
  when duplicate_object then null;
end;
$$;

alter table public.camp_sites enable row level security;
alter table public.bookings enable row level security;
alter table public.order_products enable row level security;
alter table public.orders enable row level security;
alter table public.stay_notes enable row level security;
alter table public.calendar_events enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_lines enable row level security;

insert into public.camp_sites (site_number, site_type, default_color)
values
  (1, 'motorhome', '#A9ED21'),
  (2, 'motorhome', '#A9ED21'),
  (3, 'motorhome', '#A9ED21'),
  (4, 'motorhome', '#A9ED21'),
  (5, 'motorhome', '#A9ED21'),
  (6, 'car_van', '#22D9ED'),
  (7, 'car_van', '#22D9ED'),
  (8, 'tent', '#FFBD21'),
  (9, 'motorhome', '#A9ED21'),
  (10, 'motorhome', '#A9ED21'),
  (11, 'motorhome', '#A9ED21'),
  (12, 'motorhome', '#A9ED21'),
  (13, 'motorhome', '#A9ED21'),
  (14, 'motorhome', '#A9ED21'),
  (15, 'motorhome', '#A9ED21'),
  (16, 'motorhome', '#A9ED21'),
  (17, 'tent', '#FFBD21'),
  (18, 'car_with_trailer', '#FF6BA8'),
  (19, 'car_with_trailer', '#FF6BA8'),
  (20, 'car_with_trailer', '#FF6BA8'),
  (21, 'car_with_trailer', '#FF6BA8'),
  (22, 'car_with_trailer', '#FF6BA8'),
  (23, 'car_with_trailer', '#FF6BA8'),
  (24, 'motorhome', '#A9ED21'),
  (25, 'motorhome', '#A9ED21'),
  (26, 'motorhome', '#A9ED21')
on conflict (site_number) do nothing;
