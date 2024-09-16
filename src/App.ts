import './Highlighter'
import {Elm} from './Main.elm'

if (process.env.NODE_ENV === 'development') {
  // @ts-expect-error
  const ElmDebugTransform = await import('elm-debug-transformer')

  ElmDebugTransform.register({
    simple_mode: true,
  })
}

export const node = document.getElementById('#app')
export const app = Elm.Main.init({node, flags: null})

app.ports.interopFromElm.subscribe(value =>
  app.ports.interopToElm.send({
    tag: 'authenticatedUser',
    username: value.data.message,
  }),
)
