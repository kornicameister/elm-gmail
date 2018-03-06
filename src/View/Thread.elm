module View.Thread exposing (Model, init, view, Msg, update)

import Html as H
import Html.Attributes as HA
import Http
import Task
import Data.Id as Id
import Data.Token as Token
import Data.Message as Message
import Data.Thread as Thread
import Request.Thread


---- MODEL ----


type alias Model =
    { thread : Thread.Thread (List Message.Message)
    }


init : Token.Token -> Id.ThreadId -> Task.Task Http.Error ( Model, Cmd Msg )
init token threadId =
    Request.Thread.one token threadId
        |> Http.toTask
        |> Task.map
            (\thread ->
                ( { thread = thread }
                , Cmd.none
                )
            )



---- VIEW ----


view : Model -> H.Html Msg
view model =
    H.div []
        [ H.h3 [ HA.class "mdc-list-group__subheader" ] [ H.text model.thread.snippet ]
        , H.ul [ HA.class "mdc-list" ] [ H.ul [ HA.class "mdc-list" ] [] ]
        ]



---- UPDATE ----


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
