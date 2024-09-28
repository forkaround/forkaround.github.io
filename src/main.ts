import {match} from 'ts-pattern'

import {Elm} from './Main.elm'

export const {
  ports: {
    interopToElm: {send},
    interopFromElm: {subscribe},
  },
} = Elm.Main.init({flags: null, node: document.getElementById('#app')})

subscribe(async msg =>
  match(msg)
    .with({tag: 'initDb'}, _ =>
      import('./lib/db')
        .then(() => send({tag: 'dbReady'}))
        .catch(() => send({tag: 'dbInitError'})),
    )

    .with({tag: 'chatRequest'}, chat =>
      import('ollama/browser')
        .then(({default: llm}) => llm)
        .then(llm =>
          llm.chat({
            ...chat.data,
            stream: true,
            tools: [], // FIXME: typings for tools don't work
          }),
        )
        .then(async stream => {
          for await (const chunk of stream) {
            console.log(chunk)
            send({tag: 'chatMessageChunk', data: chunk.message.content})
          }
          send({tag: 'chatMessageDone'})
        }),
    )

    .exhaustive(),
)
