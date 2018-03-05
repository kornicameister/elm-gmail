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
import Data.User as User
import Data.MessageId as MessageId
import Data.Thread as Thread
import Request.Message
import Request.Thread


---- MODEL ----


type alias Model =
    { state : PageState
    }


type PageState
    = NotAuthed
    | Authed AuthedPageState


type alias AuthedPageState =
    { user : User.User
    , messageIds : RemoteData.WebData MessageId.Envelope
    , threads : RemoteData.WebData Thread.Envelope
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
    | MessageIdsLoaded (Result Http.Error MessageId.Envelope)
    | ThreadsLoaded (Result Http.Error Thread.Envelope)


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
                                , messageIds = RemoteData.Loading
                                , threads = RemoteData.Loading
                                }
                            , Cmd.batch
                                [ Request.Message.listIds user.accessToken
                                    |> Http.send MessageIdsLoaded
                                , Request.Thread.list user.accessToken
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

        ( MessageIdsLoaded result, Authed state ) ->
            ( { model
                | state = Authed { state | messageIds = RemoteData.fromResult result }
              }
            , Cmd.none
            )

        ( MessageIdsLoaded result, NotAuthed ) ->
            ( model, Cmd.none )

        ( ThreadsLoaded result, Authed state ) ->
            ( { model
                | state = Authed { state | threads = RemoteData.fromResult result }
              }
            , Cmd.none
            )

        ( ThreadsLoaded result, NotAuthed ) ->
            ( model, Cmd.none )



---- VIEW ----


view : Model -> H.Html Msg
view model =
    case model.state of
        Authed { user } ->
            mainScreen user

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


mainScreen : User.User -> H.Html Msg
mainScreen user =
    H.div []
        [ mainScreenHeader user
        , H.main_ []
            [ H.div [ HA.class "mdc-layout-grid" ]
                [ H.div [ HA.class "mdc-layout-grid__inner" ]
                    [ H.div [ HA.class "mdc-layout-grid__cell" ] []
                    ]
                ]
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
    let
        result =
            Decode.decodeValue (Decode.nullable User.decoder) x
    in
        case result of
            Ok maybeUser ->
                GoogleApiSignedStatusChanged maybeUser

            Err _ ->
                GoogleApiSignedStatusChanged Nothing



---- PROGRAM ----


main : Program Never Model Msg
main =
    H.program
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
