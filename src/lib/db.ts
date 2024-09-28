import {vector} from '@electric-sql/pglite/vector'
import {PGliteWorker} from '@electric-sql/pglite/worker'

export default new PGliteWorker(
  new Worker(new URL('./db.worker.ts', import.meta.url), {
    type: 'module',
  }),
  {
    extensions: {
      vector,
    },
  },
)
