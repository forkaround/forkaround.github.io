module Route exposing (Route(..), fromUrl, href)

import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, map, oneOf, s, top)


type Route
    = ChatRoute
    | SettingsRoute


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map ChatRoute top
        , map SettingsRoute <| s "settings"
        ]


fromUrl : Url -> Maybe Route
fromUrl url =
    url |> Parser.parse parser


href : Route -> String
href route =
    case route of
        ChatRoute ->
            "/"

        SettingsRoute ->
            "/settings"
