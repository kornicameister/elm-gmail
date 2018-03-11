module Data.Id
    exposing
        ( AttachmentId
        , HistoryId
        , LabelId
        , MessageId
        , ThreadId
        , attachmentIdDecoder
        , historyIdDecoder
        , labelIdDecoder
        , messageIdAsString
        , messageIdDecoder
        , threadIdAsString
        , threadIdDecoder
        )

import Json.Decode as Decode


type MessageId
    = MessageId String


type ThreadId
    = ThreadId String


type HistoryId
    = HistoryId String


type LabelId
    = LabelId String


type AttachmentId
    = AttachmentId String


messageIdDecoder : Decode.Decoder MessageId
messageIdDecoder =
    Decode.map MessageId Decode.string


messageIdAsString : MessageId -> String
messageIdAsString (MessageId str) =
    str


threadIdDecoder : Decode.Decoder ThreadId
threadIdDecoder =
    Decode.map ThreadId Decode.string


threadIdAsString : ThreadId -> String
threadIdAsString (ThreadId str) =
    str


historyIdDecoder : Decode.Decoder HistoryId
historyIdDecoder =
    Decode.map HistoryId Decode.string


labelIdDecoder : Decode.Decoder LabelId
labelIdDecoder =
    Decode.map LabelId Decode.string


attachmentIdDecoder : Decode.Decoder AttachmentId
attachmentIdDecoder =
    Decode.map AttachmentId Decode.string
