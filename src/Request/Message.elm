module Request.Message exposing (listIds)

import Config
import Data.MessageId as MessageId
import Data.Token as Token
import Http
import HttpBuilder as HttpB


listIds : Token.Token -> Http.Request MessageId.Envelope
listIds token =
    let
        url =
            Config.messagesUrl
    in
    HttpB.get url
        |> Token.withAuthorizationHeader (Just token)
        |> HttpB.withExpect (Http.expectJson <| MessageId.envelopeDecoder)
        |> HttpB.toRequest
