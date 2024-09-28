import {match} from 'ts-pattern'

import {Elm} from '@/Main.elm'

export const {
  ports: {
    interopToElm: {send},
    interopFromElm: {subscribe},
  },
} = Elm.Main.init({flags: null, node: document.getElementById('#app')})

subscribe(async msg =>
  match(msg)
    .with({tag: 'db/init'}, _ =>
      import('@/lib/db/pg')
        .then(() => send({tag: 'db/init/ready'}))
        .catch(() => send({tag: 'db/init/error'})),
    )

    .with({tag: 'chat/request'}, chat =>
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
            send({tag: 'chat/msg/chunk', data: chunk.message.content})
          }
          send({tag: 'chat/msg/done'})
        }),
    )

    .exhaustive(),
)
