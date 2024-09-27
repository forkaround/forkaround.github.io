module InteropDefinitions exposing (Flags, FromElm(..), ToElm(..), interop)

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
    = MsgFromElm


type ToElm
    = MsgToElm


type alias Flags =
    {}


fromElm : Encoder FromElm
fromElm =
    TsEncode.union
        (\msgFromElm value ->
            case value of
                MsgFromElm ->
                    msgFromElm value
        )
        |> TsEncode.variantTagged "msgFromElm" TsEncode.null
        |> TsEncode.buildUnion


toElm : Decoder ToElm
toElm =
    TsDecode.discriminatedUnion "tag"
        [ ( "msgToElm", TsDecode.succeed MsgToElm ) ]


flags : Decoder Flags
flags =
    TsDecode.null {}
