module Data.MessageId exposing (Envelope, MessageId, decoder, envelopeDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP
import Data.Id as Id


---- MODEL ----


type alias Envelope =
    { messages : List MessageId
    , nextPageToken : Maybe String
    , resultSizeEstimate : Int
    }


type alias MessageId =
    { messageId : Id.MessageId
    , threadId : Id.ThreadId
    }



---- SERIALIZATION


decoder : Decode.Decoder MessageId
decoder =
    DecodeP.decode MessageId
        |> DecodeP.required "id" Id.messageIdDecoder
        |> DecodeP.required "threadId" Id.threadIdDecoder


envelopeDecoder : Decode.Decoder Envelope
envelopeDecoder =
    DecodeP.decode Envelope
        |> DecodeP.required "messages" (Decode.list decoder)
        |> DecodeP.required "nextPageToken" (Decode.nullable Decode.string)
        |> DecodeP.required "resultSizeEstimate" Decode.int
