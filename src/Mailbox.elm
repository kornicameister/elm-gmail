module Mailbox
    exposing
        ( Error(..)
        , Mailbox
        , Msg
        , init
        , update
        )

import Data.Label as Label
import Data.Message as Message
import Data.Thread as Thread
import Data.Token as Token
import EveryDict
import Http
import Request.Label
import Request.Thread
import Task


--- MODEL


type alias Mailbox =
    Model


type Model
    = Loading LoadingModel
    | Loaded LoadedModel


type alias LoadingModel =
    { labels : List Label.Label
    , threadPage : Thread.Page
    }


type alias LoadedModel =
    { labels : EveryDict.EveryDict Label.Id Label.Label
    , threads : EveryDict.EveryDict Thread.Id ThreadWithMessages
    }


type alias ThreadWithMessages =
    { thread : Thread.Thread
    , messages : List Message.Message
    }


type Error
    = Unkown String
    | DataError String Http.Error



--- INIT


init : Token.Token -> Task.Task Error ( Model, Cmd Msg )
init token =
    let
        listLabelsTask =
            Request.Label.list token
                |> Http.toTask
                |> Task.mapError (DataError "Failed to load labels")

        listThreadsTask =
            Request.Thread.page token Request.Thread.FirstPage
                |> Http.toTask
                |> Task.mapError (DataError "Failed to load thraeds")
    in
    Task.map2
        (\labels threadPage ->
            ( Loading
                { labels = labels
                , threadPage = threadPage
                }
            , threadPage.threads
                |> List.map
                    (\{ threadId } ->
                        Request.Thread.messages token { id = threadId, format = Request.Thread.Full }
                            |> Http.send (ThreadMessagesLoaded threadId)
                    )
                |> Cmd.batch
            )
        )
        listLabelsTask
        listThreadsTask



--- UPDATE


type Msg
    = NoOp
    | ThreadMessagesLoaded Thread.Id (Result Http.Error (List Message.Message))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ThreadMessagesLoaded threadId result ->
            ( model, Cmd.none )
