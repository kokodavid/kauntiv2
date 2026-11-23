insert into public.place_types (key, label, plural_label, icon, sort_order) values
  ('country_club', 'Country club', 'Country clubs', 'golf_course', 220)
on conflict (key) do nothing;

insert into public.place_type_aliases (alias, place_type) values
  ('country clubs', 'country_club')
on conflict (alias) do nothing;
