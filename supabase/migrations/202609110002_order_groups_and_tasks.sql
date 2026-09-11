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

create index if not exists order_groups_booking_idx
  on public.order_groups (booking_id);
create index if not exists order_items_group_idx
  on public.order_items (order_group_id);
create index if not exists order_items_status_idx
  on public.order_items (status);

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
  create trigger order_groups_updated_at before update on public.order_groups
    for each row execute function public.set_updated_at();
  create trigger order_items_updated_at before update on public.order_items
    for each row execute function public.set_updated_at();
  create trigger tasks_updated_at before update on public.tasks
    for each row execute function public.set_updated_at();
exception
  when duplicate_object then null;
end;
$$;

alter table public.order_groups enable row level security;
alter table public.order_items enable row level security;
alter table public.tasks enable row level security;
