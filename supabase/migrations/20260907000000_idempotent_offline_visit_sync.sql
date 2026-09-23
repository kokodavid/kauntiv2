-- Event receipts are inserted in the same transaction as the progress update.
-- A lost HTTP response can therefore be retried without incrementing pass_count.
create table public.county_visit_receipts (
  user_id uuid not null references auth.users(id) on delete cascade,
  county_id smallint not null references public.counties(id),
  entered_at timestamptz not null,
  outcome text not null check (outcome in ('explored', 'passed_through')),
  primary key (user_id, county_id, entered_at, outcome)
);
alter table public.county_visit_receipts enable row level security;
create policy "Read own visit receipts" on public.county_visit_receipts
  for select to authenticated using (auth.uid() = user_id);
create policy "Insert own visit receipts" on public.county_visit_receipts
  for insert to authenticated with check (auth.uid() = user_id);
grant select, insert on public.county_visit_receipts to authenticated;

create function public.sync_county_visit(
  p_user_id uuid, p_county_id smallint, p_outcome text, p_entered_at timestamptz
) returns jsonb
language plpgsql
set search_path = public
as $$
declare
  v_inserted integer;
  v_visits jsonb;
begin
  if auth.uid() is null or auth.uid() <> p_user_id then
    raise exception 'Visit owner does not match authenticated account' using errcode = '42501';
  end if;
  -- Serialize all visits for an account, including first visits with no row yet.
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text, 0));
  insert into public.county_visit_receipts(user_id, county_id, entered_at, outcome)
    values (p_user_id, p_county_id, p_entered_at, p_outcome)
    on conflict do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted = 1 then
    perform public.record_county_visit(p_county_id, p_outcome, p_entered_at);
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('county_id', county_id, 'state', state)
      order by county_id), '[]'::jsonb) into v_visits
    from public.county_visits where user_id = p_user_id;
  return v_visits;
end;
$$;
revoke execute on function public.sync_county_visit(uuid, smallint, text, timestamptz) from public;
grant execute on function public.sync_county_visit(uuid, smallint, text, timestamptz) to authenticated;
