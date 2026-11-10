import { readFile } from 'node:fs/promises';
const { PGlite } = await import(process.env.PGLITE_MODULE || '@electric-sql/pglite');
const root = new URL('../supabase/', import.meta.url);
const db = new PGlite();
try {
  await db.exec('begin');
  for (const file of ['tests/dashboard_growth_stats.sql', 'migrations/20261107140000_dashboard_growth_stats.sql', 'migrations/20261108100000_leaderboard_min_counties.sql', 'tests/dashboard_growth_stats_assertions.sql']) {
    await db.exec(await readFile(new URL(file, root), 'utf8'));
  }
  console.log('PASS: dashboard growth statistics SQL regression checks');
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally {
  await db.close();
}
