create policy "authenticated read camp sites"
  on public.camp_sites for select to authenticated using (true);
create policy "authenticated update camp sites"
  on public.camp_sites for update to authenticated using (true) with check (true);

create policy "authenticated read bookings"
  on public.bookings for select to authenticated using (true);
create policy "authenticated insert bookings"
  on public.bookings for insert to authenticated with check (true);
create policy "authenticated update bookings"
  on public.bookings for update to authenticated using (true) with check (true);
create policy "authenticated delete bookings"
  on public.bookings for delete to authenticated using (true);

create policy "authenticated read products"
  on public.order_products for select to authenticated using (true);
create policy "authenticated manage products"
  on public.order_products for all to authenticated using (true) with check (true);

create policy "authenticated read orders"
  on public.orders for select to authenticated using (true);
create policy "authenticated manage orders"
  on public.orders for all to authenticated using (true) with check (true);

create policy "authenticated read notes"
  on public.stay_notes for select to authenticated using (true);
create policy "authenticated manage notes"
  on public.stay_notes for all to authenticated using (true) with check (true);

create policy "authenticated read calendar"
  on public.calendar_events for select to authenticated using (true);
create policy "authenticated manage calendar"
  on public.calendar_events for all to authenticated using (true) with check (true);

create policy "authenticated read invoices"
  on public.invoices for select to authenticated using (true);
create policy "authenticated manage invoices"
  on public.invoices for all to authenticated using (true) with check (true);

create policy "authenticated read invoice lines"
  on public.invoice_lines for select to authenticated using (true);
create policy "authenticated manage invoice lines"
  on public.invoice_lines for all to authenticated using (true) with check (true);

create policy "authenticated read order groups"
  on public.order_groups for select to authenticated using (true);
create policy "authenticated manage order groups"
  on public.order_groups for all to authenticated using (true) with check (true);

create policy "authenticated read order items"
  on public.order_items for select to authenticated using (true);
create policy "authenticated manage order items"
  on public.order_items for all to authenticated using (true) with check (true);

create policy "authenticated read tasks"
  on public.tasks for select to authenticated using (true);
create policy "authenticated manage tasks"
  on public.tasks for all to authenticated using (true) with check (true);
