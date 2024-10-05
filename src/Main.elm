module Main exposing (Model, Msg(..), main)

import Browser exposing (UrlRequest)
import Browser.Navigation as Nav exposing (Key)
import Chat exposing (Chat, ChatMessage, Role(..), appendChatMessage, fromAssistant, fromUser, roleToString)
import Html exposing (Html, a, button, div, form, h1, h2, h3, input, li, nav, p, span, text, ul)
import Html.Attributes exposing (autofocus, class, disabled, href, id, placeholder, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import InteropDefinitions as IO
import InteropPorts as IO
import Json.Decode as Json
import Markdown
import Minidenticons exposing (identicon)
import Route exposing (Route)
import Stream exposing (Stream)
import Url exposing (Url)


main : Program Json.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , onUrlChange = UrlChanged
        , onUrlRequest = UrlRequested
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { key : Key
    , url : Url
    , route : Route
    , prompt : String
    , chats : List Chat
    , chunks : String
    , stream : Stream
    , currentChat : Chat
    }



-- MSG


type Msg
    = NoOp
    | UrlChanged Url
    | UrlRequested UrlRequest
    | PromptSubmitted
    | PromptChanged String
    | SendChatRequest
    | StreamUpdated Stream



-- INIT


init : Json.Value -> Url -> Key -> ( Model, Cmd Msg )
init raw url key =
    let
        model : Model
        model =
            { key = key
            , url = url
            , route = Route.fromUrl url
            , prompt = ""
            , chunks = ""
            , stream = Stream.Idle
            , chats = []
            , currentChat =
                { title = "Friendly hello"
                , description = "New chat"
                , model = "llama3.2"
                , tools = []
                , messages = []
                }
            }
    in
    case raw |> IO.decodeFlags of
        Ok _ ->
            ( model
            , IO.fromElm IO.DbInit
            )

        Err _ ->
            ( model
            , Cmd.none
            )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UrlChanged url ->
            ( { model | url = url }, Cmd.none )

        UrlRequested request ->
            case request of
                Browser.Internal url ->
                    ( { model | route = Route.fromUrl url }, Nav.pushUrl model.key (Url.toString url) )

                Browser.External url ->
                    ( model, Nav.load url )

        PromptChanged prompt ->
            ( { model | prompt = prompt }, Cmd.none )

        PromptSubmitted ->
            case model.prompt of
                "" ->
                    ( model, Cmd.none )

                _ ->
                    update
                        SendChatRequest
                        { model
                            | prompt = ""
                            , currentChat = appendChatMessage model.currentChat (fromUser model.prompt)
                        }

        SendChatRequest ->
            ( { model | stream = Stream.Loading }
            , IO.fromElm (IO.ChatRequest model.currentChat)
            )

        StreamUpdated Stream.Done ->
            case model.stream of
                Stream.Streaming message ->
                    ( { model | stream = Stream.Done, currentChat = appendChatMessage model.currentChat (fromAssistant message) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        StreamUpdated stream ->
            ( { model | stream = stream }, Cmd.none )



-- SUBS


subscriptions : Model -> Sub Msg
subscriptions model =
    IO.toElm
        |> Sub.map
            (\result ->
                case result of
                    Ok data ->
                        case data of
                            IO.DbInitReady ->
                                NoOp

                            IO.DbInitError _ ->
                                NoOp

                            IO.Stream stream ->
                                StreamUpdated (Stream.append stream model.stream)

                    Err _ ->
                        NoOp
            )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "ai.hike"
    , body =
        [ div [ id "app", class "flex flex-col lg:flex-row h-dvh" ]
            [ div [ class "min-w-48 p-3" ] (mainMenu model)
            , div [ class "grow flex flex-col md:flex-row border-t lg:border-l lg:border-t-0" ]
                (case model.route of
                    Route.ChatRoute ->
                        twoColumnLayout (chatMenu model) (chatContent model)

                    Route.SettingsRoute ->
                        twoColumnLayout (chatMenu model) (settingsView model)

                    Route.NotFoundRoute ->
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
            [ li [ class "grow text-xl hidden sm:block lg:mb-2" ]
                [ h1 []
                    [ a [ class "font-mono", href (Route.href Route.ChatRoute) ]
                        [ text "ollamix"
                        ]
                    ]
                ]
            , li [] [ a [ href (Route.href Route.ChatRoute), active Route.ChatRoute model.route ] [ text "Chat" ] ]
            , li [] [ a [ href (Route.href Route.SettingsRoute), active Route.SettingsRoute model.route ] [ text "Settings" ] ]
            ]
        ]
    ]


chatMenu : Model -> List (Html msg)
chatMenu model =
    [ nav []
        [ ul [ class "divide-y divide-neutral flex md:flex-col md:whitespace-normal md:border-b overflow-scroll" ]
            (List.map chatMenuItem model.chats)
        ]
    ]


chatMenuItem : Chat -> Html msg
chatMenuItem { title, description } =
    li [ class "p-4" ]
        [ h2 [ class "text-ellipsis overflow-hidden max-w-64 text-nowrap font-semibold" ] [ text title ]
        , h3 [ class "text-neutral-content text-ellipsis overflow-hidden max-w-64 text-nowrap" ] [ text description ]
        ]


chatContent : Model -> List (Html Msg)
chatContent model =
    [ div [ class "p-4" ]
        [ h2 [ class "font-semibold" ] [ text model.currentChat.title ]
        , h3 [ class "text-neutral-content" ] [ text model.currentChat.description ]
        ]
    , div [ class "grow basis-0 overflow-scroll p-3 border-t" ] <|
        List.append (List.map viewChatMessage model.currentChat.messages)
            (case model.stream of
                Stream.Idle ->
                    []

                Stream.Done ->
                    []

                Stream.Errored _ ->
                    []

                Stream.Loading ->
                    [ viewChatMessageLoading ]

                Stream.Streaming message ->
                    [ viewChatMessage (fromAssistant message) ]
            )
    , form [ class "shrink-0 p-3 flex gap-3", onSubmit PromptSubmitted ]
        [ input
            [ class "input w-full"
            , placeholder "What's on your mind?"
            , onInput PromptChanged
            , autofocus True
            , value model.prompt
            ]
            []
        , button
            [ class "btn btn-primary touch-manipulation hidden sm:block"
            , type_ "submit"
            , onClick PromptSubmitted
            , disabled
                (case model.stream of
                    Stream.Done ->
                        False

                    Stream.Idle ->
                        False

                    _ ->
                        True
                )
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


active : Route -> Route -> Html.Attribute msg
active a b =
    if a == b then
        class "font-bold"

    else
        class "text-neutral-content"


viewChatMessage : ChatMessage -> Html Msg
viewChatMessage message =
    div
        [ class "chat"
        , class <|
            case message.role of
                User ->
                    "chat-end"

                Assistant ->
                    "chat-start"
        ]
        [ div
            [ class "chat-image avatar hidden sm:inline"
            ]
            [ div
                [ class "w-10 rounded-full"
                ]
                [ div [ class "rounded-xl bg-neutral p-1" ] [ identicon 50 50 (roleToString message.role) ]
                ]
            ]
        , div
            [ class "chat-bubble chat-bubble-primary"
            ]
            [ Markdown.toHtml [ class "prose py-3" ] message.content ]
        , div
            [ class "chat-footer text-neutral-content flex gap-2 items-baseline"
            ]
            [ text
                (roleToString message.role)
            ]
        ]


viewChatMessageLoading : Html Msg
viewChatMessageLoading =
    div
        [ class "chat chat-start" ]
        [ div
            [ class "chat-image avatar hidden sm:inline"
            ]
            [ div
                [ class "w-10 rounded-full"
                ]
                [ div [ class "rounded-xl bg-neutral p-1" ] [ identicon 50 50 (roleToString Assistant) ]
                ]
            ]
        , div
            [ class "chat-bubble chat-bubble-primary flex gap-2 flex-col p-2" ]
            [ p [ class "skeleton h-3 w-96" ] []
            , p [ class "skeleton h-3 w-72" ] []
            , p [ class "skeleton h-3 w-80" ] []
            ]
        , div
            [ class "chat-footer text-neutral-content flex gap-2 items-baseline"
            ]
            [ text
                (roleToString Assistant)
            ]
        ]
