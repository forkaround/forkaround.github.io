module Route exposing (Route(..), fromUrl, href)

import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, map, oneOf, s, top)


type Route
    = ChatRoute
    | SettingsRoute
    | NotFoundRoute


parser : Parser (Route -> a) a
parser =
    oneOf
        [ map ChatRoute top
        , map SettingsRoute <| s "settings"
        ]


fromUrl : Url -> Route
fromUrl url =
    url
        |> Parser.parse parser
        |> Maybe.withDefault NotFoundRoute


href : Route -> String
href route =
    case route of
        ChatRoute ->
            "/"

        SettingsRoute ->
            "/settings"

        NotFoundRoute ->
            "/404"
