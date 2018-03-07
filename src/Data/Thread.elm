module Data.Thread exposing (Envelope, Thread, ThreadWithMessages, decoder, decoderWithMessages, envelopeDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP
import Data.Id as Id
import Data.Message as Message


---- MODEL ----


type alias Thread =
    { threadId : Id.ThreadId
    , historyId : Id.HistoryId
    , snippet : String
    }


type alias ThreadWithMessages =
    { threadId : Id.ThreadId
    , historyId : Id.HistoryId
    , messages : List Message.Message
    }


type alias Envelope =
    { threads : List Thread
    , nextPageToken : Maybe String
    , resultSizeEstimate : Int
    }



---- SERIALIZATION


decoder : Decode.Decoder Thread
decoder =
    DecodeP.decode Thread
        |> DecodeP.required "id" Id.threadIdDecoder
        |> DecodeP.required "historyId" Id.historyIdDecoder
        |> DecodeP.required "snippet" Decode.string


decoderWithMessages : Decode.Decoder ThreadWithMessages
decoderWithMessages =
    DecodeP.decode ThreadWithMessages
        |> DecodeP.required "id" Id.threadIdDecoder
        |> DecodeP.required "historyId" Id.historyIdDecoder
        |> DecodeP.required "messages" (Decode.list Message.decoder)


envelopeDecoder : Decode.Decoder Envelope
envelopeDecoder =
    DecodeP.decode Envelope
        |> DecodeP.required "threads" (Decode.list decoder)
        |> DecodeP.required "nextPageToken" (Decode.nullable Decode.string)
        |> DecodeP.required "resultSizeEstimate" Decode.int
