import {vector} from '@electric-sql/pglite/vector'
import {PGliteWorker} from '@electric-sql/pglite/worker'

import migrations from '@/lib/db/migrations.sql?raw'

export const pg = new PGliteWorker(
  new Worker(new URL('./worker.ts', import.meta.url), {
    type: 'module',
  }),
  {
    extensions: {
      vector,
    },
  },
)

await pg.exec(migrations)
