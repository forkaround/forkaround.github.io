module Chat exposing (Chat, ChatMessage, Function, Parameter, Property, Role(..), Tool, appendChatMessage, chatEncoder)

import Dict exposing (Dict)
import TsJson.Codec as Codec exposing (Codec)
import TsJson.Encode exposing (Encoder)


type alias Chat =
    { title : String
    , description : String
    , model : String
    , messages : List ChatMessage
    , tools : List Tool
    }


chatEncoder : Encoder Chat
chatEncoder =
    Codec.encoder chatCodec


chatCodec : Codec Chat
chatCodec =
    Codec.object
        (\title description model messages tools ->
            { title = title
            , description = description
            , model = model
            , messages = messages
            , tools = tools
            }
        )
        |> Codec.field "title" .title Codec.string
        |> Codec.field "description" .description Codec.string
        |> Codec.field "model" .model Codec.string
        |> Codec.field "messages" .messages (Codec.list chatMessageCodec)
        |> Codec.field "tools" .tools (Codec.list toolCodec)
        |> Codec.buildObject


appendChatMessage : Chat -> ChatMessage -> Chat
appendChatMessage chat msg =
    { chat | messages = List.append chat.messages [ msg ] }


type alias ChatMessage =
    { role : Role
    , content : String
    , time : String
    }


chatMessageCodec : Codec ChatMessage
chatMessageCodec =
    Codec.object (\role content time -> { role = role, content = content, time = time })
        |> Codec.field "role" .role roleCodec
        |> Codec.field "content" .content Codec.string
        |> Codec.field "time" .time Codec.string
        |> Codec.buildObject


type Role
    = User
    | Assistant


roleCodec : Codec Role
roleCodec =
    Codec.stringUnion [ ( "User", User ), ( "Assistant", Assistant ) ]


type alias Tool =
    { kind : String
    , function : Function
    }


toolCodec : Codec Tool
toolCodec =
    Codec.object
        (\kind function -> { kind = kind, function = function })
        |> Codec.field "type" .kind Codec.string
        |> Codec.field "function" .function functionCodec
        |> Codec.buildObject


type alias Function =
    { name : String
    , description : String
    , parameters : List Parameter
    }


functionCodec : Codec Function
functionCodec =
    Codec.object
        (\name description parameters ->
            { name = name
            , description = description
            , parameters = parameters
            }
        )
        |> Codec.field "name" .name Codec.string
        |> Codec.field "description" .description Codec.string
        |> Codec.field "parameters" .parameters (Codec.list parameterCodec)
        |> Codec.buildObject


type alias Parameter =
    { kind : String
    , required : List String
    , properties : Dict String Property
    }


parameterCodec : Codec Parameter
parameterCodec =
    Codec.object (\kind required properties -> { kind = kind, required = required, properties = properties })
        |> Codec.field "type" .kind Codec.string
        |> Codec.field "required" .required (Codec.list Codec.string)
        |> Codec.field "properties" .properties (Codec.dict propertyCodec)
        |> Codec.buildObject


type alias Property =
    { kind : String
    , description : String
    , enum : Maybe (List String)
    }


propertyCodec : Codec Property
propertyCodec =
    Codec.object
        (\kind description enum ->
            { kind = kind
            , description = description
            , enum = enum
            }
        )
        |> Codec.field "type" .kind Codec.string
        |> Codec.field "description" .description Codec.string
        |> Codec.field "enum" .enum (Codec.maybe <| Codec.list Codec.string)
        |> Codec.buildObject
