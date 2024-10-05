module InteropDefinitions exposing (Flags, FromElm(..), ToElm(..), interop)

import Chat exposing (Chat, chatCodec)
import Stream exposing (Stream, streamCodec)
import TsJson.Codec as Codec exposing (Codec)
import TsJson.Decode as TsDecode exposing (Decoder)
import TsJson.Encode exposing (Encoder)


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
    | DbInitError String
    | Stream Stream


type alias Flags =
    {}


fromElm : Encoder FromElm
fromElm =
    Codec.encoder fromElmCodec


fromElmCodec : Codec FromElm
fromElmCodec =
    Codec.custom (Just "tag")
        (\vDbInit vChatRequest value ->
            case value of
                DbInit ->
                    vDbInit

                ChatRequest chat ->
                    vChatRequest chat
        )
        |> Codec.variant0 "@db.init" DbInit
        |> Codec.namedVariant1 "@chat.request" ChatRequest ( "chat", chatCodec )
        |> Codec.buildCustom


toElm : Decoder ToElm
toElm =
    Codec.decoder toElmCodec


toElmCodec : Codec ToElm
toElmCodec =
    Codec.custom (Just "tag")
        (\vDbInitReady vDbInitError vStreamUpdates value ->
            case value of
                DbInitReady ->
                    vDbInitReady

                DbInitError err ->
                    vDbInitError err

                Stream stream ->
                    vStreamUpdates stream
        )
        |> Codec.variant0 "@db.ready" DbInitReady
        |> Codec.namedVariant1 "@db.error" DbInitError ( "error", Codec.string )
        |> Codec.namedVariant1 "@stream" Stream ( "data", streamCodec )
        |> Codec.buildCustom


flags : Decoder Flags
flags =
    TsDecode.null {}
