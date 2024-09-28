module Main exposing (Model, Msg(..), Page(..), main)

import Browser exposing (UrlRequest)
import Browser.Navigation as Nav exposing (Key)
import Chat exposing (Chat, ChatMessage, Role(..), appendChatMessage)
import Html exposing (Attribute, Html, a, button, div, h1, h2, h3, input, li, nav, span, text, time, ul)
import Html.Attributes exposing (autofocus, class, disabled, href, id, placeholder, value)
import Html.Events exposing (keyCode, on, onClick, onInput)
import InteropDefinitions exposing (FromElm(..), ToElm(..))
import InteropPorts as Port
import Json.Decode as Json
import Markdown
import Minidenticons exposing (identicon)
import Route exposing (Route(..))
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



-- SUBS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Port.toElm
        |> Sub.map
            (\result ->
                case result of
                    Ok data ->
                        case data of
                            ChatMessageDone ->
                                GotMessageDone

                            ChatMessageChunk chunk ->
                                GotMessageChunk chunk

                            DbReady ->
                                NoOp

                            DbInitError ->
                                NoOp

                            MsgToElm ->
                                NoOp

                    Err _ ->
                        NoOp
            )



-- MODEL


type alias Model =
    { key : Key
    , page : Page
    , url : Url
    , prompt : String
    , chats : List Chat
    , currentChat : Chat
    , messageStream : String
    }


type Page
    = ChatPage
    | SettingsPage
    | NotFoundPage



-- MSG


type Msg
    = NoOp
    | UrlChanged Url
    | UrlRequested UrlRequest
    | PromptSubmitted
    | PromptChanged String
    | SendChatRequest
    | GotMessageDone
    | GotMessageChunk String



-- INIT


init : Json.Value -> Url -> Key -> ( Model, Cmd Msg )
init raw url key =
    let
        model : Model
        model =
            { key = key
            , url = url
            , page = pageFromRoute (Route.fromUrl url)
            , prompt = ""
            , messageStream = ""
            , chats = []
            , currentChat =
                { title = "Friendly hello"
                , description = "New chat"
                , model = "llama3.1"
                , tools = []
                , messages = []
                }
            }
    in
    case raw |> Port.decodeFlags of
        Ok _ ->
            ( model
            , Port.fromElm InitDb
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
                    ( modelFromUrl model url, Nav.pushUrl model.key (Url.toString url) )

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
                            , currentChat = appendChatMessage model.currentChat (ChatMessage User model.prompt "11:22")
                        }

        SendChatRequest ->
            ( model
            , Port.fromElm (ChatRequest model.currentChat)
            )

        GotMessageChunk chunk ->
            ( { model | messageStream = model.messageStream ++ chunk }, Cmd.none )

        GotMessageDone ->
            ( { model | messageStream = "", currentChat = appendChatMessage model.currentChat (ChatMessage Assistant model.messageStream "1122") }, Cmd.none )



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "ai.hike"
    , body =
        [ div [ id "app", class "flex flex-col lg:flex-row h-dvh" ]
            [ div [ class "min-w-48 p-3" ] (mainMenu model)
            , div [ class "grow flex flex-col md:flex-row border-t lg:border-l lg:border-t-0" ]
                (case model.page of
                    ChatPage ->
                        twoColumnLayout (chatMenu model) (chatContent model)

                    SettingsPage ->
                        twoColumnLayout (chatMenu model) (settingsView model)

                    NotFoundPage ->
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
                    [ a [ class "font-mono", href (Route.href ChatRoute) ]
                        [ text "ai.hike"
                        ]
                    ]
                ]
            , li [] [ a [ href (Route.href ChatRoute), active ChatPage model.page ] [ text "Chat" ] ]
            , li [] [ a [ href (Route.href ChatRoute), active NotFoundPage model.page ] [ text "Assistants" ] ]
            , li [] [ a [ href (Route.href SettingsRoute), active NotFoundPage model.page ] [ text "Tools" ] ]
            , li [] [ a [ href (Route.href SettingsRoute), active SettingsPage model.page ] [ text "Settings" ] ]
            ]
        ]
    ]


chatMenu : Model -> List (Html msg)
chatMenu model =
    [ nav []
        [ ul [ class "divide-y divide-neutral flex md:flex-col md:whitespace-normal md:border-b overflow-scroll" ]
            (List.map
                (\chat ->
                    li [ class "p-4" ]
                        [ h2 [ class "text-ellipsis overflow-hidden max-w-64 text-nowrap font-semibold" ] [ text chat.title ]
                        , h3 [ class "text-neutral-content text-ellipsis overflow-hidden max-w-64 text-nowrap" ] [ text chat.description ]
                        ]
                )
                model.chats
            )
        ]
    ]


chatContent : Model -> List (Html Msg)
chatContent model =
    [ div [ class "p-4" ]
        [ h2 [ class "font-semibold" ] [ text model.currentChat.title ]
        , h3 [ class "text-neutral-content" ] [ text model.currentChat.description ]
        ]
    , div [ class "grow basis-0 overflow-scroll p-3 border-t" ] <|
        List.append (List.map viewChatMessage model.currentChat.messages)
            (case model.messageStream of
                "" ->
                    []

                str ->
                    [ viewChatMessage { role = Assistant, content = str, time = "23" } ]
            )
    , div [ class "shrink-0 p-3 flex gap-3" ]
        [ input
            [ class "input w-full"
            , placeholder "What's on your mind?"
            , onInput PromptChanged
            , autofocus True
            , onEnter PromptSubmitted
            , value model.prompt
            ]
            []
        , button
            [ class "btn btn-primary touch-manipulation"
            , onClick PromptSubmitted
            , disabled (String.length model.prompt < 1)
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


roleToString : Role -> String
roleToString role =
    case role of
        User ->
            "User"

        Assistant ->
            "Assistant"


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
            , time
                [ class "opacity-50"
                ]
                [ text message.time ]
            ]
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
            { model | page = ChatPage }

        Just SettingsRoute ->
            { model | page = SettingsPage }

        Nothing ->
            { model | page = NotFoundPage }


pageFromRoute : Maybe Route -> Page
pageFromRoute route =
    case route of
        Just ChatRoute ->
            ChatPage

        Just SettingsRoute ->
            SettingsPage

        Nothing ->
            NotFoundPage
