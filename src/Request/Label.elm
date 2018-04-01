module Request.Label exposing (list)

import Config
import Data.Label as Label
import Data.Token as Token
import Http
import HttpBuilder as HttpB
import Json.Decode as Decode


list : Token.Token -> Http.Request (List Label.Label)
list token =
    let
        nestedLabelsDecoder =
            Decode.field "labels" (Decode.list Label.decoder)
    in
    HttpB.get Config.labelsUrl
        |> Token.withAuthorizationHeader (Just token)
        |> HttpB.withExpectJson nestedLabelsDecoder
        |> HttpB.toRequest
