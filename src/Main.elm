module Main exposing (..)

import Component as C
import Data.Id as Id
import Data.Thread as Thread
import Data.User as User
import Html as H
import Html.Attributes as A
import Html.Events as HE
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Ports
import RemoteData
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
    | ThreadsLoaded (Result Http.Error Thread.Page)
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
                                        { token = state.user.accessToken
                                        , thread = thread
                                        , messages = RemoteData.NotAsked
                                        , expanded = False
                                        }
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
    H.main_ [ A.class "container" ]
        [ case model.state of
            Authed state ->
                mainScreen state

            NotAuthed ->
                loginScreen
        ]


loginScreen : H.Html Msg
loginScreen =
    H.div [ A.class "container" ]
        [ H.div [ A.class "buttons is-centered" ]
            [ H.button [ A.class "button is-primary", HE.onClick GoogleApiSignIn ] [ H.text "Sign In" ]
            ]
        ]


mainScreen : AuthedPageState -> H.Html Msg
mainScreen state =
    H.div [ A.class "content" ]
        [ mainScreenHeader state.user
        , H.section [ A.class "section" ]
            [ case state.threads of
                RemoteData.Loading ->
                    H.div [ A.class "container" ] [ H.text "Loading..." ]

                RemoteData.Success threadModels ->
                    threadModels
                        |> List.map
                            (\threadModel ->
                                View.Thread.view threadModel
                                    |> H.map
                                        (ThreadViewMsg threadModel.thread.threadId)
                            )
                        |> H.section [ A.class "section" ]

                _ ->
                    C.empty
            ]
        ]


mainScreenHeader : User.User -> H.Html Msg
mainScreenHeader user =
    H.nav
        [ A.class "navbar is-fixed-top is-dark"
        , A.attribute "role" "navigation"
        , A.attribute "aria-label" "main-navigation"
        ]
        [ H.div [ A.class "container" ]
            [ H.div [ A.class "navbar-brand" ]
                [ H.a [ A.href "#", A.class "navbar-item material-icons" ] [ H.text "menu" ]
                , H.div [ A.class "navbar-burger" ]
                    [ H.figure [ A.class "image is-24x24" ]
                        [ H.img [ A.src user.imageUrl, A.class "km-avatar", A.alt "user avatar" ] []
                        ]
                    ]
                ]
            , H.div [ A.class "navbar-menu" ]
                [ H.div [ A.class "navbar-start" ]
                    [ H.a [ A.href "#", A.class "navbar-item material-icons" ] [ H.text "inbox" ]
                    , H.a [ A.href "#", A.class "navbar-item material-icons" ] [ H.text "spam" ]
                    , H.a [ A.href "#", A.class "navbar-item material-icons" ] [ H.text "add" ]
                    ]
                , H.div [ A.class "navbar-end" ]
                    [ H.div [ A.class "navbar-item" ]
                        [ H.figure [ A.class "image is-24x24" ]
                            [ H.img [ A.src user.imageUrl, A.class "km-avatar", A.alt "user avatar" ] []
                            ]
                        ]
                    , H.a [ A.class "navbar-item", A.title "Click to sign out", HE.onClick GoogleApiSignOut ] [ H.text user.name ]
                    ]
                ]
            ]
        ]



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Ports.gApiIsSignedIn decodeUser


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
