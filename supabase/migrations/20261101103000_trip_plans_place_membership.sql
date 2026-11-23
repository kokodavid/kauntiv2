-- Which of my plans already hold a place, for "In 2 trips" on Place Detail.
-- Plans I'm a joined member of, not archived; a place counts when it is on
-- a day or on Places to visit.

create function public.trip_plans_with_place(p_place uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'title', p.title)
    order by p.updated_at desc), '[]'::jsonb)
  from public.trip_plans p
  where p.archived_at is null
    and trip_plan_private.is_member(p.id)
    and (
      exists (select 1 from public.trip_plan_stops s
        where s.plan_id = p.id and s.place_id = p_place)
      or exists (select 1 from public.trip_plan_places pp
        where pp.plan_id = p.id and pp.place_id = p_place)
    );
$$;

revoke execute on function public.trip_plans_with_place(uuid) from public;
grant execute on function public.trip_plans_with_place(uuid) to authenticated;
