module Request.Thread exposing (list, one)

import Config
import Data.Id as Id
import Data.Thread as Thread
import Data.Token as Token
import Http
import HttpBuilder as HttpB


list : Token.Token -> Http.Request Thread.PageThread
list token =
    let
        url =
            Config.threadsUrl
    in
    HttpB.get url
        |> Token.withAuthorizationHeader (Just token)
        |> HttpB.withExpect (Http.expectJson <| Thread.pageThreadDecoder)
        |> HttpB.toRequest


one : Token.Token -> Id.ThreadId -> Http.Request Thread.FullThread
one token id =
    let
        url =
            String.join "/" [ Config.threadsUrl, Id.threadIdAsString id ]
    in
    HttpB.get url
        |> Token.withAuthorizationHeader (Just token)
        |> HttpB.withExpect (Http.expectJson <| Thread.fullThreadDecoder)
        |> HttpB.toRequest
