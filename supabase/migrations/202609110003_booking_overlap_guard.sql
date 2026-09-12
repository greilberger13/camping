create extension if not exists btree_gist;

alter table public.bookings
  add constraint bookings_no_active_site_overlap
  exclude using gist (
    site_id with =,
    daterange(arrival_date, departure_date, '[)') with &&
  )
  where (status <> 'cancelled');
