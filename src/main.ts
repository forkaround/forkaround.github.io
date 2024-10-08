import {match} from 'ts-pattern'

import {Elm} from '@/Main.elm'

export const {
  ports: {
    interopToElm: {send},
    interopFromElm: {subscribe},
  },
} = Elm.Main.init({flags: null})

subscribe(async msg =>
  match(msg)
    .with({tag: '@db.init'}, _ =>
      import('@/lib/db/pg')
        .then(() => send({tag: '@db.ready'}))
        .catch(err => send({tag: '@db.error', error: String(err)})),
    )

    .with({tag: '@chat.request'}, data =>
      import('ollama/browser')
        .then(({default: llm}) => llm)

        .then(llm =>
          llm.chat({
            ...data.chat,
            stream: true,
            tools: [], // FIXME: typings for tools don't work
          }),
        )

        .then(async stream => {
          for await (const chunk of stream) {
            send({
              tag: '@stream',
              data: {stream: 'streaming', text: chunk.message.content},
            })
          }

          send({tag: '@stream', data: {stream: 'done'}})
        })

        .catch(err =>
          send({tag: '@stream', data: {stream: 'error', error: String(err)}}),
        ),
    )

    .exhaustive(),
)
