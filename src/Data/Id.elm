module Data.Id
    exposing
        ( MessageId
        , messageIdDecoder
        , ThreadId
        , threadIdDecoder
        , threadIdAsString
        , HistoryId
        , historyIdDecoder
        , LabelId
        , labelIdDecoder
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


messageIdDecoder : Decode.Decoder MessageId
messageIdDecoder =
    Decode.map MessageId Decode.string


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
