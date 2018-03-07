module Data.Thread exposing (Thread(..), SlimThread, FullThread, PageThread, decoder, slimThreadDecoder, fullThreadDecoder, pageThreadDecoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP
import Data.Id as Id
import Data.Message as Message


---- MODEL ----


type Thread
    = Slim SlimThread
    | Full FullThread
    | Page PageThread


type alias SlimThread =
    { threadId : Id.ThreadId, historyId : Id.HistoryId, snippet : String }


type alias FullThread =
    { threadId : Id.ThreadId, historyId : Id.HistoryId, messages : List Message.Message }


type alias PageThread =
    { threads : List SlimThread
    , nextPageToken : Maybe String
    , resultSizeEstimate : Int
    }



---- SERIALIZATION


decoder : Decode.Decoder Thread
decoder =
    Decode.oneOf
        [ slimThreadDecoder |> Decode.map Slim
        , fullThreadDecoder |> Decode.map Full
        , pageThreadDecoder |> Decode.map Page
        ]


slimThreadDecoder : Decode.Decoder SlimThread
slimThreadDecoder =
    DecodeP.decode SlimThread
        |> DecodeP.required "id" Id.threadIdDecoder
        |> DecodeP.required "historyId" Id.historyIdDecoder
        |> DecodeP.required "snippet" Decode.string


fullThreadDecoder : Decode.Decoder FullThread
fullThreadDecoder =
    DecodeP.decode FullThread
        |> DecodeP.required "id" Id.threadIdDecoder
        |> DecodeP.required "historyId" Id.historyIdDecoder
        |> DecodeP.required "messages" (Decode.list Message.decoder)


pageThreadDecoder : Decode.Decoder PageThread
pageThreadDecoder =
    DecodeP.decode PageThread
        |> DecodeP.required "threads" (Decode.list slimThreadDecoder)
        |> DecodeP.required "nextPageToken" (Decode.nullable Decode.string)
        |> DecodeP.required "resultSizeEstimate" Decode.int
