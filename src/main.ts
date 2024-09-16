// @ts-expect-error
import Elm from './Main.elm'
import hljs from 'highlight.js/lib/core'
import debounce from 'debounce'

if (process.env.NODE_ENV === 'development') {
  const ElmDebugTransform = await import('elm-debug-transformer')

  ElmDebugTransform.register({
    simple_mode: true,
  })
}

export const node = document.querySelector('#app')
export const app = Elm.init({node})

app.ports.fromElm.subscribe(ask)

async function ask(prompt: string) {
  const ollama = await import('ollama/browser')
  const stream = await ollama.default.generate({
    prompt,
    stream: true,
    model: 'llama3.1',
  })

  for await (const chunk of stream) {
    app.ports.toElm.send(chunk.response)
  }
}

const highlight = debounce(hljs.highlightAll, 300)
// @ts-expect-error
window.hljs = {
  listLanguages() {
    return {
      indexOf() {
        return 0
      },
    }
  },
  highlight(lang: string, code: string) {
    importGrammar(lang)
      .then(grammar => hljs.registerLanguage(lang, grammar.default))
      .then(() => highlight())

    return {
      value: code,
    }
  },
}

async function importGrammar(lang: string) {
  switch (lang) {
    case 'elm':
      return import(`highlight.js/lib/languages/elm`)
    case 'python':
      return import(`highlight.js/lib/languages/python`)
    case 'javascript':
      return import(`highlight.js/lib/languages/javascript`)
    case 'go':
      return import(`highlight.js/lib/languages/go`)
    case 'rust':
      return import(`highlight.js/lib/languages/rust`)
    case 'java':
      return import(`highlight.js/lib/languages/java`)
    default:
      return import(`highlight.js/lib/languages/c`)
  }
}
