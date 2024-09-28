import pattycake from 'pattycake'
import {defineConfig} from 'vite'
import elmPlugin from 'vite-plugin-elm'

export default defineConfig({
  plugins: [elmPlugin(), pattycake.vite({disableOptionalChaining: true})],
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
