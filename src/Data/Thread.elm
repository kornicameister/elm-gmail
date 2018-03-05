module Data.Thread exposing (Envelope, Thread, decoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP
import Data.Id as Id


---- MODEL ----


type alias Envelope =
    { messages : List Thread
    , nextPageToken : Maybe String
    , resultSizeEstimate : Int
    }


type alias Thread =
    { threadId : Id.ThreadId
    , snippet : String
    , historyId : Id.HistoryId
    }



---- SERIALIZATION


decoder : Decode.Decoder Envelope
decoder =
    DecodeP.decode Envelope
        |> DecodeP.required "threads" (Decode.list threadDecoder)
        |> DecodeP.required "nextPageToken" (Decode.nullable Decode.string)
        |> DecodeP.required "resultSizeEstimate" Decode.int


threadDecoder : Decode.Decoder Thread
threadDecoder =
    DecodeP.decode Thread
        |> DecodeP.required "id" Id.threadIdDecoder
        |> DecodeP.required "snippet" Decode.string
        |> DecodeP.required "historyId" Id.historyIdDecoder
