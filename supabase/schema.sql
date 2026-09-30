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
  adults integer not null default 1 check (adults > 0),
  children integer not null default 0 check (children >= 0),
  has_dog boolean not null default false,
  has_electricity boolean not null default false,
  late_checkout boolean not null default false,
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

create table if not exists public.pricing (
  id integer primary key default 1 check (id = 1),
  site_per_night numeric(10, 2) not null default 21
    check (site_per_night >= 0),
  adult_per_stay numeric(10, 2) not null default 8
    check (adult_per_stay >= 0),
  child_per_stay numeric(10, 2) not null default 0
    check (child_per_stay >= 0),
  updated_at timestamptz not null default now()
);

insert into public.pricing (id) values (1) on conflict (id) do nothing;

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
  monthly_week integer check (monthly_week in (-1, 1, 2, 3, 4, 5)),
  monthly_weekday integer check (monthly_weekday between 1 and 7),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (recurrence = 'monthly' and monthly_week is not null
      and monthly_weekday is not null)
    or (recurrence <> 'monthly' and monthly_week is null
      and monthly_weekday is null)
  )
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete restrict,
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
  booking_id uuid not null references public.bookings(id) on delete cascade,
  site_id uuid not null references public.camp_sites(id),
  service_date date not null,
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
  status text not null default 'open'
    check (status in ('open', 'completed', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists order_groups_booking_idx on public.order_groups (booking_id);
create index if not exists order_items_group_idx on public.order_items (order_group_id);
create index if not exists order_items_status_idx on public.order_items (status);
create index if not exists tasks_status_idx on public.tasks (status);

create or replace function public.sync_product_task(p_product_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_product public.order_products%rowtype;
  v_quantity bigint;
begin
  if p_product_id is null then
    return;
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_product_id::text, 0)
  );
  select * into v_product from public.order_products
  where id = p_product_id;
  select coalesce(sum(quantity), 0) into v_quantity
  from public.order_items
  where product_id = p_product_id and status = 'open';

  if v_quantity = 0 then
    delete from public.tasks where task_key = 'order:' || p_product_id;
  else
    insert into public.tasks (task_key, title, quantity_text, category)
    values (
      'order:' || p_product_id,
      v_product.name,
      v_quantity::text,
      case when v_product.category = 'bakery' then 'bakery' else 'kiosk' end
    )
    on conflict (task_key) do update
    set title = excluded.title,
        quantity_text = excluded.quantity_text,
        category = excluded.category,
        status = 'open';
  end if;
end;
$$;

create or replace function public.on_order_item_change()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    perform public.sync_product_task(old.product_id);
    return old;
  end if;
  if tg_op = 'UPDATE' and old.product_id is distinct from new.product_id then
    perform public.sync_product_task(old.product_id);
  end if;
  perform public.sync_product_task(new.product_id);
  return new;
end;
$$;

create trigger order_items_sync_tasks
after insert or update or delete on public.order_items
for each row execute function public.on_order_item_change();

create or replace function public.complete_task(p_task_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_key text;
  v_product_id uuid;
begin
  select task_key into v_key from public.tasks where id = p_task_id;
  if v_key is null then
    raise exception 'Task not found.';
  end if;
  if v_key like 'order:%' then
    v_product_id := substring(v_key from 7)::uuid;
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(v_product_id::text, 0)
    );
    update public.order_items set status = 'completed'
    where product_id = v_product_id and status = 'open';
  end if;
  delete from public.tasks where id = p_task_id;
end;
$$;

revoke all on function public.sync_product_task(uuid) from public, anon;
revoke all on function public.complete_task(uuid) from public, anon;
grant execute on function public.sync_product_task(uuid) to authenticated;
grant execute on function public.complete_task(uuid) to authenticated;

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
  create trigger pricing_updated_at before update on public.pricing for each row execute function public.set_updated_at();
  create trigger order_products_updated_at before update on public.order_products for each row execute function public.set_updated_at();
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

create or replace function public.validate_booking_site()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_type text;
  v_status text;
begin
  select site_type, status into v_type, v_status
  from public.camp_sites where id = new.site_id for share;
  if v_type is null then
    raise exception 'Stellplatz nicht gefunden.';
  end if;
  if new.vehicle_type <> 'other' and new.vehicle_type <> v_type then
    raise exception 'Fahrzeugart passt nicht zum Stellplatz.';
  end if;
  if v_status = 'blocked' and new.status <> 'cancelled' then
    if tg_op = 'INSERT' then
      raise exception 'Dieser Stellplatz ist gesperrt.';
    end if;
    if new.site_id is distinct from old.site_id then
      raise exception 'Dieser Stellplatz ist gesperrt.';
    end if;
  end if;
  if v_status = 'occupied' and new.status <> 'cancelled'
      and new.arrival_date <= (now() at time zone 'Europe/Vienna')::date
      and new.departure_date > (now() at time zone 'Europe/Vienna')::date then
    if tg_op = 'INSERT' then
      raise exception 'Dieser Stellplatz ist heute belegt.';
    end if;
    if new.site_id is distinct from old.site_id then
      raise exception 'Dieser Stellplatz ist heute belegt.';
    end if;
  end if;
  return new;
end;
$$;

create trigger bookings_validate_site
before insert or update on public.bookings
for each row execute function public.validate_booking_site();

create or replace function public.save_invoice_snapshot(
  p_booking_id uuid,
  p_lines jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_invoice_id uuid;
  v_line jsonb;
begin
  if p_lines is null or jsonb_typeof(p_lines) <> 'array'
      or jsonb_array_length(p_lines) = 0 then
    raise exception 'Rechnungspositionen fehlen.';
  end if;
  insert into public.invoices (booking_id, guest_name, site_number)
  select b.id, b.guest_name, s.site_number
  from public.bookings b
  join public.camp_sites s on s.id = b.site_id
  where b.id = p_booking_id
  on conflict (booking_id) do nothing
  returning id into v_invoice_id;

  if v_invoice_id is null then
    select id into v_invoice_id from public.invoices
    where booking_id = p_booking_id;
    if v_invoice_id is null then
      raise exception 'Buchung nicht gefunden.';
    end if;
    return v_invoice_id;
  end if;

  for v_line in select value from jsonb_array_elements(p_lines) loop
    insert into public.invoice_lines (
      invoice_id, label, quantity, unit_price
    ) values (
      v_invoice_id,
      v_line ->> 'label',
      (v_line ->> 'quantity')::integer,
      (v_line ->> 'unit_price')::numeric
    );
  end loop;
  return v_invoice_id;
end;
$$;

revoke all on function public.save_invoice_snapshot(uuid, jsonb)
  from public, anon;
grant execute on function public.save_invoice_snapshot(uuid, jsonb)
  to authenticated;

create or replace function public.create_order_batch(
  p_booking_id uuid,
  p_site_number integer,
  p_service_date date,
  p_items jsonb
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_site_id uuid;
  v_group_id uuid;
  v_item jsonb;
  v_product_id uuid;
  v_quantity integer;
  v_seen uuid[] := '{}';
  v_product public.order_products%rowtype;
  v_stored public.order_items%rowtype;
  v_result jsonb := '[]'::jsonb;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array'
      or jsonb_array_length(p_items) = 0 then
    raise exception 'A batch requires at least one product.';
  end if;

  select b.site_id into v_site_id
  from public.bookings b
  join public.camp_sites s on s.id = b.site_id
  where b.id = p_booking_id
    and s.site_number = p_site_number
    and b.status <> 'cancelled'
    and p_service_date between b.arrival_date and b.departure_date
  for share of b, s;

  if v_site_id is null then
    raise exception 'Booking, site or service date is invalid.';
  end if;

  insert into public.order_groups (booking_id, site_id, service_date)
  values (p_booking_id, v_site_id, p_service_date)
  returning id into v_group_id;

  for v_item in select value from jsonb_array_elements(p_items) loop
    v_product_id := (v_item ->> 'product_id')::uuid;
    v_quantity := (v_item ->> 'quantity')::integer;
    if v_product_id is null or v_quantity is null or v_quantity < 1
        or v_product_id = any(v_seen) then
      raise exception 'Invalid or duplicate product in batch.';
    end if;
    v_seen := array_append(v_seen, v_product_id);

    select * into v_product
    from public.order_products
    where id = v_product_id and is_active = true;
    if not found then
      raise exception 'Product not found or inactive.';
    end if;

    insert into public.order_items (
      order_group_id, product_id, description, quantity,
      unit_price, category
    ) values (
      v_group_id, v_product_id, v_product.name, v_quantity,
      v_product.unit_price, v_product.category
    ) returning * into v_stored;
    v_result := v_result || jsonb_build_array(to_jsonb(v_stored));
  end loop;

  return v_result;
end;
$$;

revoke all on function public.create_order_batch(uuid, integer, date, jsonb)
  from public, anon;
grant execute on function public.create_order_batch(uuid, integer, date, jsonb)
  to authenticated;

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
alter table public.pricing enable row level security;
alter table public.order_products enable row level security;
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
create policy "authenticated read pricing" on public.pricing for select to authenticated using (true);
create policy "authenticated update pricing" on public.pricing for update to authenticated using (true) with check (true);
create policy "authenticated read products" on public.order_products for select to authenticated using (true);
create policy "authenticated manage products" on public.order_products for all to authenticated using (true) with check (true);
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
