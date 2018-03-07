module View.Thread exposing (Model, view, Msg, update)

import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Http
import RemoteData
import Data.Token as Token
import Data.Message as Message
import Data.Thread as Thread
import Request.Thread
import Component as C


---- MODEL ----


type alias Model =
    { token : Token.Token
    , thread : Thread.SlimThread
    , messages : RemoteData.WebData (List Message.Message)
    , expanded : Bool
    }



---- VIEW ----


view : Model -> H.Html Msg
view model =
    H.div []
        [ H.h3 [ HA.class "mdc-list-group__subheader", HE.onClick ToggleThread ] [ H.text model.thread.snippet ]
        , H.ul [ HA.class "mdc-list" ]
            (case ( model.messages, model.expanded ) of
                ( RemoteData.NotAsked, _ ) ->
                    [ C.empty ]

                ( RemoteData.Loading, True ) ->
                    [ C.progressBar model.messages ]

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
    H.li [ HA.class "mdc-list-item" ] [ H.text message.snippet ]



---- UPDATE ----


type Msg
    = ToggleThread
    | ThreadMessagesLoaded (Result Http.Error Thread.FullThread)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleThread ->
            let
                ( newExpanded, cmd ) =
                    case model.expanded of
                        True ->
                            ( False, Cmd.none )

                        False ->
                            ( True
                            , (case model.messages of
                                RemoteData.NotAsked ->
                                    Cmd.batch
                                        [ Request.Thread.one model.token model.thread.threadId
                                            |> Http.send ThreadMessagesLoaded
                                        ]

                                _ ->
                                    Cmd.none
                              )
                            )
            in
                ( { model | expanded = newExpanded }, cmd )

        ThreadMessagesLoaded result ->
            case result of
                Ok { messages } ->
                    ( { model | messages = RemoteData.succeed messages }, Cmd.none )

                Err err ->
                    ( { model | messages = result |> Result.map (always []) |> RemoteData.fromResult }, Cmd.none )
