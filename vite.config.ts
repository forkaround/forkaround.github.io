import {defineConfig} from 'vite'
import elmPlugin from 'vite-plugin-elm-watch'

export default defineConfig({
  plugins: [elmPlugin()],
  build: {
    target: 'esnext',
  },
})
