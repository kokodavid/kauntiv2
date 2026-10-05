# One-user Journey migration

`tools/migrate_user_journeys.py` moves one user's **private** Journey history
from Dev to Prod. It carries `journeys`, `journey_points`, `journey_counties`,
`journey_media`, and only Storage objects referenced by the copied media rows.
Public-trip publications and unreferenced Storage files are intentionally out
of scope.

## Required environment

Keep these values in the terminal environment, never in a committed file:

```bash
export KAUNTI_DEV_SUPABASE_URL='https://<dev-project-ref>.supabase.co'
export KAUNTI_DEV_SERVICE_ROLE_KEY='<dev-service-role-key>'
export KAUNTI_PROD_SUPABASE_URL='https://<prod-project-ref>.supabase.co'
export KAUNTI_PROD_SERVICE_ROLE_KEY='<prod-service-role-key>'
```

Run the dry-run first:

```bash
python3 tools/migrate_user_journeys.py \
  --dev-user-id '<dev-auth-user-id>' \
  --prod-user-id '<prod-auth-user-id>'
```

After its source inventory matches the reviewed audit, run the same command
with `--apply`.

The tool is resumable: database rows upsert by their primary keys and copied
media objects use Storage upsert. It rewrites the first folder segment of every
photo path from the Dev user UUID to the Prod user UUID, which keeps the
private bucket's owner-path RLS valid.

## Multiple selected users

For a reviewed cohort, create a local text file with one email address per
line. Each person must have signed in to the Prod build once so their Prod auth
account exists. Start from `tools/selected_users.example.txt`; do not commit
the real list.

```bash
python3 tools/migrate_selected_users.py \
  --emails-file /path/to/selected-users.txt
```

The inventory reports portable profile/county/wishlist data and invokes the
same Journey audit for each account. By default it carries one source event per
current visit, not all Dev history, to avoid migrating unreviewed testing
events into production leaderboards. After reviewing each line, repeat with
`--apply`. The batch tool deliberately excludes Dev testing entitlements,
free-tier counters, public-trip publications, and wishlist rows whose places do
not yet exist in Prod.
