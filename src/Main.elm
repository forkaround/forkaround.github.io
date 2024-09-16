port module Main exposing (main)

import Browser exposing (UrlRequest)
import Browser.Navigation as Nav exposing (Key)
import Html exposing (Attribute, Html, a, button, div, h1, h2, h3, input, li, nav, span, text, ul)
import Html.Attributes exposing (autofocus, class, href, id, placeholder, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import Json.Decode as Json
import Markdown
import Minidenticons exposing (identicon)
import Route exposing (Route(..))
import Url exposing (Url)


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , onUrlChange = UrlChanged
        , onUrlRequest = UrlRequested
        , subscriptions = subscriptions
        }



-- PORTS


port fromElm : String -> Cmd msg


port toElm : (String -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    toElm Received



-- MODEL


type alias Model =
    { key : Key
    , page : Page
    , url : Url
    , prompt : String
    , generation : String
    }


type Page
    = Chat
    | Settings
    | NotFound



-- MSG


type Msg
    = UrlChanged Url
    | UrlRequested UrlRequest
    | PromptSubmitted
    | PromptChanged String
    | Received String



-- INIT


generation : String
generation =
    """
Ask me anything!
```go
var a = 2 + 2;
```
"""


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ url key =
    let
        page : Page
        page =
            pageFromRoute (Route.fromUrl url)
    in
    ( { key = key, url = url, page = page, prompt = "", generation = generation }, Cmd.none )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PromptSubmitted ->
            ( { model | prompt = "", generation = "" }, fromElm model.prompt )

        UrlChanged url ->
            ( { model | url = url }, Cmd.none )

        UrlRequested request ->
            case request of
                Browser.Internal url ->
                    ( modelFromUrl model url, Nav.pushUrl model.key (Url.toString url) )

                Browser.External url ->
                    ( model, Nav.load url )

        PromptChanged prompt ->
            ( { model | prompt = prompt }, Cmd.none )

        Received chunk ->
            ( { model | generation = model.generation ++ chunk }, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Ollamix"
    , body =
        [ div [ id "app", class "flex flex-col lg:flex-row h-dvh" ]
            [ div [ class "min-w-48 p-3" ] (mainMenu model)
            , div [ class "grow flex flex-col md:flex-row border-t lg:border-l lg:border-t-0" ]
                (case model.page of
                    Chat ->
                        twoColumnLayout (chatMenu model) (chatContent model)

                    Settings ->
                        twoColumnLayout (chatMenu model) (settingsView model)

                    NotFound ->
                        notFoundView model
                )
            ]
        ]
    }


twoColumnLayout : List (Html Msg) -> List (Html Msg) -> List (Html Msg)
twoColumnLayout menu content =
    [ div [ class "bg-base-200 min-w-48" ]
        menu
    , div [ class "grow flex flex-col bg-base-300 border-t md:border-t-0 md:border-l" ]
        content
    ]


mainMenu : Model -> List (Html msg)
mainMenu model =
    [ nav []
        [ ul [ class "flex lg:flex-col gap-2 items-end sm:items-start" ]
            [ li [ class "font-bold grow text-xl hidden sm:block lg:mb-2" ] [ h1 [] [ a [ href (Route.href ChatRoute) ] [ text "Ollamix" ] ] ]
            , li [] [ a [ href (Route.href ChatRoute), active Chat model.page ] [ text "Chat" ] ]
            , li [] [ a [ href (Route.href ChatRoute), active NotFound model.page ] [ text "Assistants" ] ]
            , li [] [ a [ href (Route.href SettingsRoute), active NotFound model.page ] [ text "Tools" ] ]
            , li [] [ a [ href (Route.href SettingsRoute), active Settings model.page ] [ text "Settings" ] ]
            ]
        ]
    ]


chatMenu : a -> List (Html msg)
chatMenu _ =
    [ nav []
        [ ul [ class "divide-y divide-base-300 flex md:flex-col md:whitespace-normal border-b overflow-scroll" ]
            [ li [ class "p-4" ]
                [ h2 [ class "text-ellipsis overflow-hidden max-w-64 text-nowrap" ] [ text "Bed stories cara de nalga y salame la concha del mono" ]
                , h3 [ class "text-neutral-content text-ellipsis overflow-hidden max-w-64 text-nowrap" ] [ text "Tell me a bed story for kids when I'm home" ]
                ]
            , li [ class "p-4" ]
                [ h2 [ class "text-ellipsis overflow-hidden max-w-64 text-nowrap" ] [ text "Once upon a time in Hollywod!" ]
                , h3 [ class "text-neutral-content text-ellipsis overflow-hidden max-w-64 text-nowrap" ] [ text "The film directed by Quentin Tarantino won 3 oscars last night" ]
                ]
            ]
        ]
    ]


chatContent : Model -> List (Html Msg)
chatContent model =
    [ div [ class "p-3" ]
        [ h2 [] [ text "Bed time story" ]
        , h3 [ class "text-neutral-content" ] [ text "Bed time stories for kids" ]
        ]
    , div [ class "grow basis-0 overflow-scroll p-3 border-t" ]
        [ bubble model.generation
        ]
    , div [ class "shrink-0 p-3 flex gap-3" ]
        [ input
            [ class "input w-full"
            , placeholder "What's on your mind?"
            , value model.prompt
            , onInput PromptChanged
            , autofocus True
            , onEnter PromptSubmitted
            ]
            []
        , button
            [ class "btn btn-primary touch-manipulation"
            , onClick PromptSubmitted
            ]
            [ text "Send", span [ class "i-send" ] [] ]
        ]
    ]


settingsView : Model -> List (Html Msg)
settingsView _ =
    [ div [] [ text "Settings view" ] ]


notFoundView : Model -> List (Html Msg)
notFoundView _ =
    [ div [ class "bg-base-300 w-full flex items-center justify-center h-full" ] [ text "Not found " ] ]



-- UI


active : Page -> Page -> Html.Attribute msg
active a b =
    if a == b then
        class "font-bold"

    else
        class "text-neutral-content"


bubble : String -> Html Msg
bubble message =
    div
        [ class "chat chat-start"
        ]
        [ div
            [ class "chat-image avatar hidden sm:inline"
            ]
            [ div
                [ class "w-10 rounded-full"
                ]
                [ div [ class "rounded-xl bg-neutral p-1" ] [ identicon 50 50 "Assistant" ]
                ]
            ]
        , div
            [ class "chat-bubble chat-bubble-primary"
            ]
            [ Markdown.toHtml [ class "prose py-3" ] message ]
        ]


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter : number -> Json.Decoder Msg
        isEnter code =
            if code == 13 then
                Json.succeed msg

            else
                Json.fail "not ENTER"
    in
    on "keydown" (Json.andThen isEnter keyCode)



-- ROUTING HELPERS


modelFromUrl : Model -> Url -> Model
modelFromUrl model url =
    case Route.fromUrl url of
        Just ChatRoute ->
            { model | page = Chat }

        Just SettingsRoute ->
            { model | page = Settings }

        Nothing ->
            { model | page = NotFound }


pageFromRoute : Maybe Route -> Page
pageFromRoute route =
    case route of
        Just ChatRoute ->
            Chat

        Just SettingsRoute ->
            Settings

        Nothing ->
            NotFound
