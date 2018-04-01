module Main exposing (..)

import Component as C
import Data.Id as Id
import Data.Label as Label
import Data.Thread as Thread
import Data.User as User
import Html as H
import Html.Attributes as A
import Html.Events as E
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Ports
import RemoteData
import Request.Label
import Request.Thread
import View.LabelsSidebar
import View.Thread


---- MODEL ----


type Model
    = NotAuthed
    | Initializing InitializingPageState
    | Ready ReadyPageState


type alias InitializingPageState =
    { user : User.User
    , threads : RemoteData.WebData Thread.Page
    , labels : RemoteData.WebData (List Label.Label)
    }


type alias ReadyPageState =
    { user : User.User
    , threadList : List View.Thread.Model
    , labelSidebar : View.LabelsSidebar.Model
    }


init : ( Model, Cmd Msg )
init =
    ( NotAuthed, Cmd.none )



---- UPDATE ----


type Msg
    = GoogleApiSignedStatusChanged (Maybe User.User)
    | GoogleApiSignIn
    | GoogleApiSignOut
    | ThreadsLoaded (Result Http.Error Thread.Page)
    | LabelsLoaded (Result Http.Error (List Label.Label))
    | ThreadViewMsg Id.ThreadId View.Thread.Msg
    | LabelSidebarMsg View.LabelsSidebar.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        NotAuthed ->
            case msg of
                GoogleApiSignIn ->
                    ( model, Ports.gApiSignIn () )

                GoogleApiSignedStatusChanged maybeUser ->
                    let
                        ( nextModel, nextCommand ) =
                            case maybeUser of
                                Nothing ->
                                    ( NotAuthed, Cmd.none )

                                Just user ->
                                    ( Initializing
                                        { user = user
                                        , threads = RemoteData.Loading
                                        , labels = RemoteData.Loading
                                        }
                                    , Cmd.batch
                                        [ Request.Thread.list user.accessToken
                                            |> Http.send ThreadsLoaded
                                        , Request.Label.list user.accessToken
                                            |> Http.send LabelsLoaded
                                        ]
                                    )
                    in
                    ( nextModel, nextCommand )

        Initializing state ->
            case msg of
                ThreadsLoaded result ->
                    ( maybeGoToReady { state | threads = RemoteData.fromResult result }, Cmd.none )

                LabelsLoaded result ->
                    ( maybeGoToReady { state | labels = RemoteData.fromResult result }, Cmd.none )

        Ready state ->
            case msg of
                ThreadViewMsg threadId threadMsg ->
                    ( model, Cmd.none )

                LabelSidebarMsg sideberMsg ->
                    ( model, Cmd.none )


maybeGoToReady : InitializingPageState -> Model
maybeGoToReady state =
    let
        newRemoteData =
            RemoteData.map2 (,) state.threads state.labels

        nextModel =
            case newRemoteData of
                RemoteData.Success ( threadPage, labels ) ->
                    Ready
                        { user = state.user
                        , threadList = threadPage.threads |> List.map (View.Thread.init state.user)
                        , labelSidebar = View.LabelsSidebar.init labels
                        }

                _ ->
                    Initializing state
    in
    nextModel



---- VIEW ----


view : Model -> H.Html Msg
view model =
    H.main_ [ A.class "container" ]
        [ case model of
            NotAuthed ->
                loginScreen

            Initializing _ ->
                C.empty

            Ready state ->
                mainScreen state
        ]


loginScreen : H.Html Msg
loginScreen =
    H.div [ A.class "container" ]
        [ H.div [ A.class "buttons is-centered" ]
            [ H.button [ A.class "button is-primary", E.onClick GoogleApiSignIn ] [ H.text "Sign In" ]
            ]
        ]


mainScreen : ReadyPageState -> H.Html Msg
mainScreen state =
    H.div [ A.class "content" ]
        [ mainScreenHeader state.user
        , H.section [ A.class "section" ]
            [ H.div [ A.class "columns" ]
                [ View.LabelsSidebar.view state.labels
                    |> H.map LabelSidebarMsg
                , H.div [ A.class "column" ]
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
                [ H.a [ A.href "#", A.class "navbar-item material-icons", E.onClick ToogleLabelsColumn ] [ H.text "menu" ]
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
                    , H.a [ A.class "navbar-item", A.title "Click to sign out", E.onClick GoogleApiSignOut ] [ H.text user.name ]
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
