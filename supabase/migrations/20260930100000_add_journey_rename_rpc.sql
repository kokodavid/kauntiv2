-- Lets a user rename their own Trip. journeys has no client update policy
-- (see 20260925130000): this security-definer RPC is the only write path,
-- mirroring upload_journey_to_place's owner check.
create function public.rename_journey(
  p_user_id uuid,
  p_journey_id uuid,
  p_title text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or auth.uid() <> p_user_id then
    raise exception 'Journey owner does not match the signed-in account'
      using errcode = '42501';
  end if;
  if p_title is null or length(btrim(p_title)) not between 1 and 120 then
    raise exception 'Journey title is not valid' using errcode = '22023';
  end if;

  update public.journeys
  set title = btrim(p_title)
  where id = p_journey_id and user_id = p_user_id;

  if not found then
    raise exception 'Journey not found for this account' using errcode = 'P0002';
  end if;
end;
$$;

revoke execute on function public.rename_journey(uuid, uuid, text) from public;
grant execute on function public.rename_journey(uuid, uuid, text) to authenticated;
