# App Version Management

## Release policy

The app compares stable `MAJOR.MINOR.PATCH` values. Flutter's `+build`
number may be stored separately when a platform store build needs to be
distinguished, but it is optional and is not used for update policy decisions.
The store URL is also optional during development and beta rollout. Add it when
the platform listing is available so the update prompt can open the correct
store destination.
Major releases are always required. Minor releases are required by default,
but an owner/admin can deliberately mark a minor release optional. Patch
releases are always optional. The first published release establishes the
required baseline. The database enforces this policy; the dashboard preview is
only explanatory.

Tracks are independent by platform (`android`, `ios`) and channel
(`development`, `beta`, `production`). Dev builds query `development`; prod
builds query `production`. Internal beta builds can use the beta channel only
by building with `--dart-define=APP_RELEASE_CHANNEL=beta`.

## Roles and data access

- Only active `owner` and `admin` memberships can open App versions in the
  dashboard or call release-list/create/publish RPCs.
- `editor`, `moderator`, and `viewer` have no release-management access.
- The release table has RLS enabled and no direct client grants. Dashboard
  writes and reads are security-definer RPCs that re-check
  `public.current_admin_role()`.
- The app's `get_app_update_policy` RPC is callable without a session, but
  returns only the latest public version, required floor, store URL, notes and
  comparison booleans. It exposes no user, admin, or draft data.

Release metadata remains immutable after publication, but an owner/admin can
deactivate a published release or reactivate it when no newer release is active
on the same platform/channel. Deactivating a release removes it from the
mobile policy lookup; it does not delete its history.

## Database change

Migrations: `supabase/migrations/20261023100000_app_version_management.sql`,
the follow-up `supabase/migrations/20261023110000_app_version_build_optional.sql`,
`supabase/migrations/20261023120000_app_version_store_url_optional.sql`, and
`supabase/migrations/20261023130000_app_version_status_controls.sql`.
Apply the complete files to **both** Supabase projects independently, dev first
and production only after dev verification. Do not run these against the
production project while the dashboard is still configured for dev.

The migration creates `public.app_version_releases` and these functions:

- `public.get_app_update_policy(text, text, text)` - public app check.
- `public.list_app_version_releases_dashboard()` - owner/admin release list.
- `public.create_app_version_release_dashboard(text, text, text, integer, text, text, boolean)` - validate and create a draft. The integer build and store URL arguments may be null.
- `public.publish_app_version_release_dashboard(uuid)` - activate an existing draft.
- `public.delete_app_version_release_draft_dashboard(uuid)` - remove a draft before publication.
- `public.set_app_version_release_status_dashboard(uuid, boolean)` - activate or deactivate a published release.

There are no Edge Functions, secrets, external cron jobs, or Storage changes
for this feature.

### Apply through Supabase SQL Editor

1. Select the **Kaunti 47 Dev** project and open SQL Editor.
2. Paste and run the full migration file. Do not run fragments separately.
3. Verify the table, RPCs, and RLS with the checks below.
4. Deploy the dashboard's dev branch against the dev project and create a
   non-production test release (use a test URL/channel; do not publish a
   real production version to the development channel).
5. Verify the app's development build receives the matching policy.
6. Repeat the same migration on the **production** project, then deploy the
   dashboard `main` build and configure the real store URLs/releases.

CLI alternative, from the app repository linked to the intended project:

```sh
supabase link --project-ref <DEV_PROJECT_REF>
supabase db push
```

Confirm the linked project reference before pushing. Repeat with the production
project only during the production rollout.

### Verification SQL

```sql
select to_regclass('public.app_version_releases') as release_table;

select p.proname, pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'get_app_update_policy',
    'list_app_version_releases_dashboard',
    'create_app_version_release_dashboard',
    'publish_app_version_release_dashboard',
    'delete_app_version_release_draft_dashboard',
    'set_app_version_release_status_dashboard'
  )
order by p.proname;

select relrowsecurity
from pg_class
where oid = 'public.app_version_releases'::regclass;

select *
from public.get_app_update_policy('android', 'development', '1.0.0');
```

Expect the table to resolve, five function rows, `relrowsecurity = true`, and
an empty policy (`available=false`, `required=false`) before the first release.
The last query is safe to run as an unauthenticated SQL-editor caller; its
result contains public release metadata only.

## Dashboard workflow

Open Operations → App versions. Select platform and channel, enter a strict
three-part version, optional build number, optional store URL and release notes.
The dashboard explains the required/optional rule. Save creates a draft; review
its metadata, make sure the store listing is available, then publish. Only
publishing changes the policy seen by app clients. Keep each environment's
dashboard connected to its matching Supabase project.

## App behavior and release order

The startup splash waits for the update check alongside session restoration,
so the wrong onboarding/shell screen is not briefly shown before a mandatory
gate. Required releases take precedence over sign-in/setup routes. Optional
releases show a `Later` action and do not block app usage. Release prompts are
deferred while a local Trip is active; startup restores a returning user's
Trip before checking policy so a mandatory gate cannot interrupt capture or
hide a recovered Trip. The app checks again when returning from background.
If the policy endpoint is unreachable, the
app fails open to avoid stranding a traveler; update enforcement therefore
requires an online check at launch/resume. This first version does not cache a
previous mandatory policy offline.

Recommended rollout for each environment:

1. Apply and verify the migration.
2. Deploy dashboard code compatible with the new RPCs.
3. Upload and release the mobile binary in the relevant store/test track.
4. Create the release draft using the exact store version and build.
5. Publish only after the store listing is installable.
6. Test old, current, optional, required, offline and resume paths on physical
   Android and iOS devices before enabling the production release policy.

The update CTA opens the platform's store listing; it does not install or
download an update in-app. Store availability and review timing remain owned
by Google Play and App Store Connect.
