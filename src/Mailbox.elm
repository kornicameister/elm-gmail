module Mailbox
    exposing
        ( Error(..)
        , Mailbox
        , init
        )

import Task


--- MODEL


type alias Mailbox =
    {}


type Error
    = Unkown String


init : Task.Task Error Mailbox
init =
    Task.fail (Unkown "Failed to init mailbox")
