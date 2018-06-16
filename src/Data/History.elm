module Data.History
    exposing
        ( Id
        , idDecoder
        )

import Json.Decode as Decode


type Id
    = Id String


idDecoder : Decode.Decoder Id
idDecoder =
    Decode.map Id Decode.string
