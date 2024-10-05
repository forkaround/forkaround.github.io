module Stream exposing (Stream(..), streamCodec)

import TsJson.Codec as Codec exposing (Codec)


type Stream
    = Idle
    | Done
    | Loading
    | Errored String
    | Streaming String


streamCodec : Codec Stream
streamCodec =
    Codec.custom (Just "tag")
        (\vDone vIdle vLoading vStreaming vError value ->
            case value of
                Done ->
                    vDone

                Idle ->
                    vIdle

                Loading ->
                    vLoading

                Streaming text ->
                    vStreaming text

                Errored error ->
                    vError error
        )
        |> Codec.variant0 "done" Done
        |> Codec.variant0 "idle" Idle
        |> Codec.variant0 "loading" Loading
        |> Codec.namedVariant1 "error" Errored ( "error", Codec.string )
        |> Codec.namedVariant1 "streaming" Streaming ( "text", Codec.string )
        |> Codec.buildCustom
