module Data.Message exposing (Message, decoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP
import Data.Id as Id


---- MODEL ----


type alias Message =
    { messageId : Id.MessageId
    , threadId : Id.ThreadId
    , historyId : Id.HistoryId
    , labelIds : List Id.LabelId
    , snippet : String
    , payload : Payload
    }


type alias Payload =
    { partId : String }



---- SERIALIZATION


decoder : Decode.Decoder Message
decoder =
    let
        payloadDecoder =
            DecodeP.decode Payload
                |> DecodeP.required "partId" Decode.string
    in
        DecodeP.decode Message
            |> DecodeP.required "id" Id.messageIdDecoder
            |> DecodeP.required "threadId" Id.threadIdDecoder
            |> DecodeP.required "historyId" Id.historyIdDecoder
            |> DecodeP.required "labelIds" (Decode.list Id.labelIdDecoder)
            |> DecodeP.required "snippet" Decode.string
            |> DecodeP.required "payload" payloadDecoder
