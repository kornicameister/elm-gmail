module Data.Thread
    exposing
        ( Id
        , Page
        , Thread
        , decoder
        , idAsString
        , idDecoder
        , pageDecoder
        )

import Data.History as History
import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP


---- MODEL ----


type Id
    = Id String


type alias Thread =
    { threadId : Id, historyId : History.Id, snippet : String }


type alias Page =
    { threads : List Thread
    , nextPageToken : Maybe String
    , resultSizeEstimate : Int
    }



---- HELPERS


idAsString : Id -> String
idAsString (Id str) =
    str



---- SERIALIZATION


decoder : Decode.Decoder Thread
decoder =
    DecodeP.decode Thread
        |> DecodeP.required "id" idDecoder
        |> DecodeP.required "historyId" History.idDecoder
        |> DecodeP.required "snippet" Decode.string


pageDecoder : Decode.Decoder Page
pageDecoder =
    DecodeP.decode Page
        |> DecodeP.required "threads" (Decode.list decoder)
        |> DecodeP.required "nextPageToken" (Decode.nullable Decode.string)
        |> DecodeP.required "resultSizeEstimate" Decode.int


idDecoder : Decode.Decoder Id
idDecoder =
    Decode.map Id Decode.string
