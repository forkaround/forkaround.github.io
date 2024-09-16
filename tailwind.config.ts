import * as rdx from '@radix-ui/colors'
import typography from '@tailwindcss/typography'
import daisyui, {type Config as DaisyConfig} from 'daisyui'
import {type Config as TailwindConfig} from 'tailwindcss'

export default {
  content: ['index.html', 'src/**/*.{elm, css}'],
  plugins: [typography, daisyui],
  daisyui: {
    themes: [
      {
        light: {
          'color-scheme': 'light',
          'base-content': rdx.grayP3.gray12,
          'primary': rdx.grayP3.gray1,
          'primary-content': rdx.grayP3.gray12,
          'neutral': rdx.grayP3.gray5,
          'neutral-content': rdx.grayP3.gray10,
          'base-100': rdx.grayP3.gray1,
          'base-200': rdx.grayP3.gray2,
          'base-300': rdx.grayP3.gray3,
        },
        dark: {
          'color-scheme': 'dark',
          'base-content': rdx.grayDarkP3.gray12,
          'primary': rdx.grayDarkP3.gray1,
          'primary-content': rdx.grayDarkP3.gray12,
          'neutral': rdx.grayDarkP3.gray5,
          'neutral-content': rdx.grayDarkP3.gray10,
          'base-100': rdx.grayDarkP3.gray1,
          'base-200': rdx.grayDarkP3.gray2,
          'base-300': rdx.grayDarkP3.gray3,
        },
      },
    ],
    darkTheme: 'dark',
  } satisfies DaisyConfig,
} satisfies TailwindConfig
