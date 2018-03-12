module Request.Thread exposing (Format(..), list, one)

import Config
import Data.Id as Id
import Data.Thread as Thread
import Data.Token as Token
import Http
import HttpBuilder as HttpB


list : Token.Token -> Http.Request Thread.Page
list token =
    let
        url =
            Config.threadsUrl
    in
    HttpB.get url
        |> Token.withAuthorizationHeader (Just token)
        |> HttpB.withExpect (Http.expectJson <| Thread.pageDecoder)
        |> HttpB.toRequest


type Format
    = Minimal
    | Metadata
    | Full


one : Token.Token -> { id : Id.ThreadId, format : Format } -> Http.Request Thread.WithMessages
one token { id, format } =
    let
        formatAsString format =
            case format of
                Minimal ->
                    "minimal"

                Metadata ->
                    "metadata"

                Full ->
                    "full"

        url =
            String.join "/" [ Config.threadsUrl, Id.threadIdAsString id ]
    in
    HttpB.get url
        |> Token.withAuthorizationHeader (Just token)
        |> HttpB.withQueryParams [ ( "format", formatAsString format ) ]
        |> HttpB.withExpect (Http.expectJson <| Thread.decoderWithMessages)
        |> HttpB.toRequest
