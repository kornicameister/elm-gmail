module Mailbox
    exposing
        ( Error(..)
        , Mailbox
        , init
        )

import Data.Label as Label
import Data.Token as Token
import Http
import Request.Label
import Task


--- MODEL


type alias Mailbox =
    { labels : List Label.Label
    }


type Error
    = Unkown String
    | DataError String Http.Error


init : Token.Token -> Task.Task Error Mailbox
init token =
    Request.Label.list token
        |> Http.toTask
        |> Task.mapError (DataError "Failed to load labels")
        |> Task.map
            (\labels ->
                { labels = labels
                }
            )
