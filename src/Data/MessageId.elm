module Data.MessageId exposing (Envelope, MessageId, decoder)

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


decoder : Decode.Decoder Envelope
decoder =
    DecodeP.decode Envelope
        |> DecodeP.required "messages" (Decode.list messageIdDecoder)
        |> DecodeP.required "nextPageToken" (Decode.nullable Decode.string)
        |> DecodeP.required "resultSizeEstimate" Decode.int


messageIdDecoder : Decode.Decoder MessageId
messageIdDecoder =
    DecodeP.decode MessageId
        |> DecodeP.required "id" Id.messageIdDecoder
        |> DecodeP.required "threadId" Id.threadIdDecoder
