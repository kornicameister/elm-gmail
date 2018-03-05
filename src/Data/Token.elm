module Data.Token exposing (Token, decoder, withAuthorizationHeader)

import HttpBuilder as HttpB
import Json.Decode as Decode


type Token
    = Token String


decoder : Decode.Decoder Token
decoder =
    Decode.string
        |> Decode.map Token


withAuthorizationHeader : Maybe Token -> HttpB.RequestBuilder a -> HttpB.RequestBuilder a
withAuthorizationHeader maybeToken builder =
    case maybeToken of
        Just (Token token) ->
            builder
                |> HttpB.withHeader "Authorization" ("Bearer " ++ token)

        Nothing ->
            builder
