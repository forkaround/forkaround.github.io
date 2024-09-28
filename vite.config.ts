import patty from 'pattycake'
import {defineConfig} from 'vite'
import elm from 'vite-plugin-elm'
import tspaths from 'vite-tsconfig-paths'

export default defineConfig({
  plugins: [elm(), tspaths(), patty.vite({disableOptionalChaining: true})],
  optimizeDeps: {
    exclude: ['@electric-sql/pglite'],
  },
  build: {
    target: 'esnext',
  },
  worker: {
    format: 'es',
  },
})
