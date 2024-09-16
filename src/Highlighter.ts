import debounce from 'debounce'
import hljs from 'highlight.js/lib/core'

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
