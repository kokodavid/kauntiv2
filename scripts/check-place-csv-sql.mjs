import {readFile} from 'node:fs/promises';
const {PGlite}=await import(process.env.PGLITE_MODULE || '@electric-sql/pglite');
const root=new URL('../supabase/',import.meta.url),db=new PGlite();
try {
 await db.exec('begin');
 for(const file of ['tests/place_csv_import_fixture.sql','migrations/20261109120000_place_csv_import.sql','tests/place_csv_import_assertions.sql'])await db.exec(await readFile(new URL(file,root),'utf8'));
 console.log('PASS: CSV draft creation, retry/named duplicates, atomic rollback, validation, publishing rejection, existing records preserved, role restrictions');
} catch(error){console.error(error.message);process.exitCode=1;}finally{await db.close();}
