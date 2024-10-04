module InteropDefinitions exposing (Flags, FromElm(..), ToElm(..), interop)

import Chat exposing (Chat, chatEncoder)
import TsJson.Decode as TsDecode exposing (Decoder)
import TsJson.Encode as TsEncode exposing (Encoder)


interop :
    { flags : Decoder Flags
    , toElm : Decoder ToElm
    , fromElm : Encoder FromElm
    }
interop =
    { flags = flags
    , toElm = toElm
    , fromElm = fromElm
    }


type FromElm
    = DbInit
    | ChatRequest Chat


type ToElm
    = DbInitReady
    | DbInitError
    | ChatMessageDone
    | ChatMessageChunk String


type alias Flags =
    {}


fromElm : Encoder FromElm
fromElm =
    TsEncode.union
        (\dbInit chatRequest value ->
            case value of
                DbInit ->
                    dbInit value

                ChatRequest chat ->
                    chatRequest chat
        )
        |> TsEncode.variantTagged "db/init" TsEncode.null
        |> TsEncode.variantTagged "chat/request" chatEncoder
        |> TsEncode.buildUnion


toElm : Decoder ToElm
toElm =
    TsDecode.discriminatedUnion "tag"
        [ ( "db/init/ready", TsDecode.succeed DbInitReady )
        , ( "db/init/error", TsDecode.succeed DbInitError )
        , ( "chat/msg/done", TsDecode.succeed ChatMessageDone )
        , ( "chat/msg/chunk", TsDecode.succeed (\chunk -> ChatMessageChunk chunk) |> TsDecode.andMap (TsDecode.field "data" TsDecode.string) )
        ]


flags : Decoder Flags
flags =
    TsDecode.null {}
