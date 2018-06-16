module Main exposing (..)

import Component as C
import Data.User as User
import Html as H
import Html.Attributes as A
import Html.Events as E
import Json.Decode as Decode
import Json.Encode as Encode
import Mailbox
import Ports
import Task


---- MODEL ----


type Model
    = NotAuthed
    | Initializing User.User
    | Initialized ( User.User, Mailbox.Mailbox )
    | Failed Mailbox.Error


init : ( Model, Cmd Msg )
init =
    ( NotAuthed, Cmd.none )



---- UPDATE ----


type Msg
    = GoogleApiSignedStatusChanged (Maybe User.User)
    | GoogleApiSignIn
    | GoogleApiSignOut
    | MailboxInitialized (Result Mailbox.Error Mailbox.Mailbox)


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
                                    ( Initializing user
                                    , Mailbox.init user.accessToken
                                        |> Task.attempt MailboxInitialized
                                    )
                    in
                    ( nextModel, nextCommand )

                _ ->
                    ( model, Cmd.none )

        Initializing user ->
            case msg of
                MailboxInitialized mailboxResult ->
                    case mailboxResult of
                        Ok mailbox ->
                            ( Initialized ( user, mailbox ), Cmd.none )

                        Err err ->
                            ( Failed err, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        Initialized _ ->
            case msg of
                GoogleApiSignOut ->
                    ( model, Ports.gApiSignOut () )

                _ ->
                    ( model, Cmd.none )

        Failed _ ->
            ( model, Cmd.none )



---- VIEW ----


view : Model -> H.Html Msg
view model =
    H.main_ [ A.class "container" ]
        [ case model of
            NotAuthed ->
                loginScreen

            Failed _ ->
                C.empty

            Initializing _ ->
                C.empty

            Initialized _ ->
                C.empty
        ]


loginScreen : H.Html Msg
loginScreen =
    H.div [ A.class "container" ]
        [ H.div [ A.class "buttons is-centered" ]
            [ H.button [ A.class "button is-primary", E.onClick GoogleApiSignIn ] [ H.text "Sign In" ]
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
