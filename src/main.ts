import {Elm} from './Main.elm'

export const {
  ports: {
    interopToElm: {send},
    interopFromElm: {subscribe},
  },
} = Elm.Main.init({flags: null, node: document.getElementById('#app')})

subscribe(value => {
  switch (value.tag) {
    case 'msgFromElm':
      alert('from elm!')
      return send({tag: 'msgToElm'})
  }
})
