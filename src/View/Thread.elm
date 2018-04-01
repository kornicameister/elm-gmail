module View.Thread
    exposing
        ( Model
        , Msg
        , init
        , update
        , view
        )

import Component as C
import Data.Message as Message
import Data.Thread as Thread
import Data.Token as Token
import Data.User as User
import Html as H
import Html.Attributes as A
import Html.Events as E
import HtmlParser
import HtmlParser.Util
import Http
import RemoteData
import Request.Message
import Request.Thread


---- MODEL ----


type alias Model =
    { token : Token.Token
    , thread : Thread.Thread
    , messages : RemoteData.WebData (List Message.Message)
    , expanded : Bool
    }


init : User.User -> Thread.Thread -> Model
init user thread =
    { token = user.accessToken
    , thread = thread
    , messages = RemoteData.Loading
    , expanded = False
    }



---- VIEW ----


view : Model -> H.Html Msg
view model =
    H.div []
        [ H.section []
            [ H.h1 [ A.class "title is-6", E.onClick ToggleThread ] [ H.text model.thread.snippet ]
            ]
        , H.ul []
            (case ( model.messages, model.expanded ) of
                ( RemoteData.NotAsked, _ ) ->
                    [ C.empty ]

                ( RemoteData.Loading, True ) ->
                    [ H.div [ A.class "container" ] [ H.text "Loading" ] ]

                ( RemoteData.Loading, False ) ->
                    [ C.empty ]

                ( RemoteData.Failure err, True ) ->
                    [ H.p [] [ H.text "Failed to load messages for this topic" ] ]

                ( RemoteData.Failure err, False ) ->
                    [ C.empty ]

                ( RemoteData.Success messages, True ) ->
                    List.map messageView messages

                ( RemoteData.Success messages, False ) ->
                    [ C.empty ]
            )
        ]


messageView : Message.Message -> H.Html msg
messageView message =
    H.li []
        [ H.p [ A.class "subtitle is-7" ] [ H.text message.snippet ]
        , H.div []
            (case message.payload.parts of
                Message.NoParts ->
                    [ C.empty ]

                Message.Parts parts ->
                    List.map
                        (\{ body, mimeType } ->
                            case ( body, mimeType ) of
                                ( Message.Empty, _ ) ->
                                    [ C.empty ]

                                ( Message.WithData { data }, "text/html" ) ->
                                    HtmlParser.parse data
                                        |> HtmlParser.Util.filterElements (\tagName _ _ -> tagName |> String.toLower |> String.contains "DOCTYPE")
                                        |> HtmlParser.Util.toVirtualDom

                                ( Message.WithData { data }, _ ) ->
                                    [ H.text data ]

                                ( Message.WithAttachment _, _ ) ->
                                    [ C.empty ]
                        )
                        parts
                        |> List.concat
            )
        ]



---- UPDATE ----


type Msg
    = ToggleThread
    | ThreadWithMessagesLoaded (Result Http.Error Thread.WithMessages)
    | MessagesLoaded (Result Http.Error (List Message.Message))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleThread ->
            ( { model | expanded = not model.expanded }
            , case model.messages of
                RemoteData.NotAsked ->
                    Cmd.batch
                        [ Request.Thread.one model.token { id = model.thread.threadId, format = Request.Thread.Minimal }
                            |> Http.send ThreadWithMessagesLoaded
                        ]

                _ ->
                    Cmd.none
            )

        ThreadWithMessagesLoaded result ->
            case result of
                Ok { messages } ->
                    ( { model | messages = RemoteData.Loading }
                    , Request.Message.many model.token { ids = List.map .messageId messages, format = Request.Message.Full }
                        |> Http.send MessagesLoaded
                    )

                Err err ->
                    ( { model | messages = result |> Result.map (always []) |> RemoteData.fromResult }, Cmd.none )

        MessagesLoaded results ->
            case results of
                Ok messages ->
                    ( { model | messages = RemoteData.succeed messages }, Cmd.none )

                Err err ->
                    ( { model | messages = results |> Result.map (always []) |> RemoteData.fromResult }, Cmd.none )
