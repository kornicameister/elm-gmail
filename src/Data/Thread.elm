module Data.Thread exposing (Envelope, Thread, decoder, decoderWithMessages, envelopeDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP
import Data.Id as Id
import Data.Message as Message


---- MODEL ----


type alias Thread a =
    { threadId : Id.ThreadId
    , historyId : Id.HistoryId
    , snippet : String
    , messages : a
    }


type alias Envelope =
    { threads : List (Thread ())
    , nextPageToken : Maybe String
    , resultSizeEstimate : Int
    }



---- SERIALIZATION


decoder : Decode.Decoder (Thread ())
decoder =
    baseDecoder
        |> DecodeP.hardcoded ()


decoderWithMessages : Decode.Decoder (Thread (List Message.Message))
decoderWithMessages =
    baseDecoder
        |> DecodeP.required "messages" (Decode.list Message.decoder)


baseDecoder : Decode.Decoder (a -> Thread a)
baseDecoder =
    DecodeP.decode Thread
        |> DecodeP.required "id" Id.threadIdDecoder
        |> DecodeP.required "historyId" Id.historyIdDecoder
        |> DecodeP.required "snippet" Decode.string


envelopeDecoder : Decode.Decoder Envelope
envelopeDecoder =
    DecodeP.decode Envelope
        |> DecodeP.required "threads" (Decode.list decoder)
        |> DecodeP.required "nextPageToken" (Decode.nullable Decode.string)
        |> DecodeP.required "resultSizeEstimate" Decode.int
