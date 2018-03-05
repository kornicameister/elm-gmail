module Data.Id
    exposing
        ( MessageId
        , messageIdDecoder
        , ThreadId
        , threadIdDecoder
        , HistoryId
        , historyIdDecoder
        )

import Json.Decode as Decode


type MessageId
    = MessageId String


type ThreadId
    = ThreadId String


type HistoryId
    = HistoryId String


messageIdDecoder : Decode.Decoder MessageId
messageIdDecoder =
    Decode.map MessageId Decode.string


threadIdDecoder : Decode.Decoder ThreadId
threadIdDecoder =
    Decode.map ThreadId Decode.string


historyIdDecoder : Decode.Decoder HistoryId
historyIdDecoder =
    Decode.map HistoryId Decode.string
