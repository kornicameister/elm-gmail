module Data.Message exposing (Message, decoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP
import Data.Id as Id


---- MODEL ----


type alias Message =
    { messageId : Id.MessageId
    , threadId : Id.ThreadId
    , labelIds : List Id.LabelId
    , historyId : Id.HistoryId
    , snippet : String
    }



---- SERIALIZATION


decoder : Decode.Decoder Message
decoder =
    DecodeP.decode Message
        |> DecodeP.required "messageId" Id.messageIdDecoder
        |> DecodeP.required "threadId" Id.threadIdDecoder
        |> DecodeP.required "labelIds" (Decode.list Id.labelIdDecoder)
        |> DecodeP.required "historyId" Id.historyIdDecoder
        |> DecodeP.required "snippet" Decode.string
