module Data.Thread exposing (Page, Thread, WithMessages, decoder, decoderWithMessages, pageDecoder)

import Data.Id as Id
import Data.Message as Message
import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP


---- MODEL ----


type alias Thread =
    { threadId : Id.ThreadId, historyId : Id.HistoryId, snippet : String }


type alias WithMessages =
    { threadId : Id.ThreadId, historyId : Id.HistoryId, messages : List Message.Key }


type alias Page =
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


decoderWithMessages : Decode.Decoder WithMessages
decoderWithMessages =
    DecodeP.decode WithMessages
        |> DecodeP.required "id" Id.threadIdDecoder
        |> DecodeP.required "historyId" Id.historyIdDecoder
        |> DecodeP.required "messages" (Decode.list Message.keyDecoder)


pageDecoder : Decode.Decoder Page
pageDecoder =
    DecodeP.decode Page
        |> DecodeP.required "threads" (Decode.list decoder)
        |> DecodeP.required "nextPageToken" (Decode.nullable Decode.string)
        |> DecodeP.required "resultSizeEstimate" Decode.int
