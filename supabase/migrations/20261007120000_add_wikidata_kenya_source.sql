-- First structured source for the Dev-only collector. It remains disabled so
-- only an explicit manual run may use it until the output has been reviewed.

insert into public.scrape_sources (
  slug,
  name,
  kind,
  enabled,
  config,
  licence_policy,
  max_items_per_run
)
values (
  'wikidata-ke',
  'Wikidata Kenya places',
  'wikidata',
  false,
  '{"country_qid":"Q114","images":false}'::jsonb,
  'Wikidata structured data is CC0. This collector does not import images.',
  25
)
on conflict (slug) do update
set
  name = excluded.name,
  kind = excluded.kind,
  config = excluded.config,
  licence_policy = excluded.licence_policy,
  max_items_per_run = excluded.max_items_per_run;
