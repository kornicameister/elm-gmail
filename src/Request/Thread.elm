module Request.Thread exposing (list)

import Http
import HttpBuilder as HttpB
import Config
import Data.Thread as Thread
import Data.Token as Token


list : Token.Token -> Http.Request Thread.Envelope
list token =
    let
        url =
            Config.threadsUrl
    in
        HttpB.get url
            |> Token.withAuthorizationHeader (Just token)
            |> HttpB.withExpect (Http.expectJson <| Thread.decoder)
            |> HttpB.toRequest
