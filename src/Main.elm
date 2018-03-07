module Main exposing (..)

import Http
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Decode
import Json.Encode as Encode
import RemoteData
import Component as C
import Ports
import Data.Id as Id
import Data.User as User
import Data.Thread as Thread
import Request.Thread
import View.Thread


---- MODEL ----


type alias Model =
    { state : PageState
    }


type PageState
    = NotAuthed
    | Authed AuthedPageState


type alias AuthedPageState =
    { user : User.User
    , threads : RemoteData.WebData (List View.Thread.Model)
    }


init : ( Model, Cmd Msg )
init =
    ( { state = NotAuthed }, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp
    | GoogleApiSignedStatusChanged (Maybe User.User)
    | GoogleApiSignIn
    | GoogleApiSignOut
    | ThreadsLoaded (Result Http.Error Thread.Envelope)
    | ThreadViewMsg Id.ThreadId View.Thread.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.state ) of
        ( NoOp, _ ) ->
            ( model, Cmd.none )

        ( GoogleApiSignedStatusChanged maybeUser, _ ) ->
            let
                ( state, nextCommand ) =
                    case maybeUser of
                        Nothing ->
                            ( NotAuthed, Cmd.none )

                        Just user ->
                            ( Authed
                                { user = user
                                , threads = RemoteData.Loading
                                }
                            , Cmd.batch
                                [ Request.Thread.list user.accessToken
                                    |> Http.send ThreadsLoaded
                                ]
                            )
            in
                ( { model | state = state }, nextCommand )

        ( GoogleApiSignIn, NotAuthed ) ->
            ( model, Ports.gApiSignIn () )

        ( GoogleApiSignIn, Authed _ ) ->
            ( model, Cmd.none )

        ( GoogleApiSignOut, Authed _ ) ->
            ( model, Ports.gApiSignOut () )

        ( GoogleApiSignOut, NotAuthed ) ->
            ( model, Cmd.none )

        ( ThreadsLoaded result, Authed state ) ->
            let
                newThreads =
                    RemoteData.fromResult result
                        |> RemoteData.map
                            (\{ threads } ->
                                List.map
                                    (\thread ->
                                        ({ token = state.user.accessToken
                                         , thread = thread
                                         , messages = RemoteData.NotAsked
                                         , expanded = False
                                         }
                                        )
                                    )
                                    threads
                            )
            in
                ( { model | state = Authed { state | threads = newThreads } }, Cmd.none )

        ( ThreadsLoaded result, NotAuthed ) ->
            ( model, Cmd.none )

        ( ThreadViewMsg threadId viewMsg, Authed state ) ->
            case state.threads of
                RemoteData.Success threadModels ->
                    let
                        ( newThreadModels, newThreadCmds ) =
                            List.map
                                (\t ->
                                    case t.thread.threadId == threadId of
                                        True ->
                                            View.Thread.update viewMsg t

                                        False ->
                                            ( t, Cmd.none )
                                )
                                threadModels
                                |> List.unzip

                        mappedCmds =
                            List.map (\cmd -> cmd |> Cmd.map (ThreadViewMsg threadId)) newThreadCmds
                                |> Cmd.batch
                    in
                        ( { model | state = Authed { state | threads = RemoteData.succeed newThreadModels } }, mappedCmds )

                _ ->
                    ( model, Cmd.none )

        ( ThreadViewMsg _ _, NotAuthed ) ->
            ( model, Cmd.none )



---- VIEW ----


view : Model -> H.Html Msg
view model =
    case model.state of
        Authed state ->
            mainScreen state

        NotAuthed ->
            loginScreen


loginScreen : H.Html Msg
loginScreen =
    H.main_ []
        [ H.div [ HA.class "mdc-layout-grid" ]
            [ H.div [ HA.class "mdc-layout-grid__inner" ]
                [ H.div [ HA.class "mdc-layout-grid__cell" ]
                    [ H.button [ HA.class "mdc-button", HE.onClick GoogleApiSignIn ] [ H.text "Sign In" ]
                    ]
                ]
            ]
        ]


mainScreen : AuthedPageState -> H.Html Msg
mainScreen state =
    let
        threadView thread =
            H.div []
                [ H.h3 [ HA.class "mdc-list-group__subheader" ] [ H.text thread.snippet ]
                , H.ul [ HA.class "mdc-list" ] [ H.ul [ HA.class "mdc-list" ] [] ]
                ]
    in
        H.div []
            [ mainScreenHeader state.user
            , H.main_ []
                [ C.progressBar state.threads
                , case state.threads of
                    RemoteData.Success threadModels ->
                        threadModels
                            |> List.map
                                (\threadModel ->
                                    View.Thread.view threadModel
                                        |> H.map
                                            (ThreadViewMsg threadModel.thread.threadId)
                                )
                            |> H.div [ HA.class "mdc-list-group" ]

                    _ ->
                        C.empty
                ]
            ]


mainScreenHeader : User.User -> H.Html Msg
mainScreenHeader user =
    H.header [ HA.class "mdc-toolbar" ]
        [ H.div [ HA.class "mdc-toolbar__row km-toolbar-image" ]
            [ H.section [ HA.class "mdc-toolbar__section mdc-toolbar__section--align-start" ]
                [ H.a [ HA.href "#", HA.class "mdc-toolbar__menu-icon" ] [ C.materialIcon "menu" ]
                , H.span [ HA.class "mdc-toolbar__title" ] [ H.text "ElmMail" ]
                ]
            , H.section [ HA.class "mdc-toolbar__section mdc-toolbar__section--align-end" ]
                [ H.a [ HA.class "mdc-toolbar__title", HA.title "Click to sign out", HE.onClick GoogleApiSignOut ] [ H.text user.name ]
                , H.img [ HA.src user.imageUrl, HA.class "km-avatar", HA.alt "user avatar" ] []
                ]
            ]
        , H.nav [ HA.class "mdc-toolbar__row" ]
            [ H.section [ HA.class "mdc-toolbar__section mdc-toolbar__section--align-end" ]
                [ H.a [ HA.href "#", HA.class "mdc-toolbar__icon material-icons" ] [ H.text "inbox" ]
                , H.a [ HA.href "#", HA.class "mdc-toolbar__icon material-icons" ] [ H.text "spam" ]
                , H.a [ HA.href "#", HA.class "mdc-toolbar__icon material-icons" ] [ H.text "add" ]
                ]
            ]
        ]



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.gApiIsSignedIn (decodeUser)


decodeUser : Encode.Value -> Msg
decodeUser x =
    Decode.decodeValue (Decode.nullable User.decoder) x
        |> Result.withDefault Nothing
        |> GoogleApiSignedStatusChanged



---- PROGRAM ----


main : Program Never Model Msg
main =
    H.program
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
