module Request.Thread exposing (list, one)

import Http
import HttpBuilder as HttpB
import Config
import Data.Id as Id
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
            |> HttpB.withExpect (Http.expectJson <| Thread.envelopeDecoder)
            |> HttpB.toRequest


one : Token.Token -> Id.ThreadId -> Http.Request Thread.ThreadWithMessages
one token id =
    let
        url =
            String.join "/" [ Config.threadsUrl, Id.threadIdAsString id ]
    in
        HttpB.get url
            |> Token.withAuthorizationHeader (Just token)
            |> HttpB.withExpect (Http.expectJson <| Thread.decoderWithMessages)
            |> HttpB.toRequest
