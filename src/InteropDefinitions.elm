module InteropDefinitions exposing (Flags, FromElm(..), ToElm(..), interop)

import Chat exposing (Chat, chatEncoder)
import TsJson.Decode as TsDecode exposing (Decoder)
import TsJson.Encode as TsEncode exposing (Encoder)


interop :
    { toElm : Decoder ToElm
    , fromElm : Encoder FromElm
    , flags : Decoder Flags
    }
interop =
    { toElm = toElm
    , fromElm = fromElm
    , flags = flags
    }


type FromElm
    = InitDb
    | ChatRequest Chat


type ToElm
    = MsgToElm
    | DbReady
    | DbInitError
    | ChatMessageDone
    | ChatMessageChunk String


type alias Flags =
    {}


fromElm : Encoder FromElm
fromElm =
    TsEncode.union
        (\initDb chatRequest value ->
            case value of
                InitDb ->
                    initDb value

                ChatRequest chat ->
                    chatRequest chat
        )
        |> TsEncode.variantTagged "initDb" TsEncode.null
        |> TsEncode.variantTagged "chatRequest" chatEncoder
        |> TsEncode.buildUnion


toElm : Decoder ToElm
toElm =
    TsDecode.discriminatedUnion "tag"
        [ ( "msgToElm", TsDecode.succeed MsgToElm )
        , ( "dbReady", TsDecode.succeed DbReady )
        , ( "dbInitError", TsDecode.succeed DbInitError )
        , ( "chatMessageDone", TsDecode.succeed ChatMessageDone )
        , ( "chatMessageChunk", TsDecode.succeed (\chunk -> ChatMessageChunk chunk) |> TsDecode.andMap (TsDecode.field "data" TsDecode.string) )
        ]


flags : Decoder Flags
flags =
    TsDecode.null {}
