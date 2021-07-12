module Request.Thread
    exposing
        ( Format(..)
        , PageToken(..)
        , messages
        , page
        )

import Config
import Data.Message as Message
import Data.Thread as Thread
import Data.Token as Token
import Http
import HttpBuilder as HttpB
import Json.Decode as Decode


type PageToken
    = FirstPage
    | NextPage String


page : Token.Token -> PageToken -> Http.Request Thread.Page
page token pageToken =
    let
        url =
            Config.threadsUrl

        params =
            case pageToken of
                FirstPage ->
                    []

                NextPage token ->
                    [ ( "pageToken", token ) ]
    in
    HttpB.get url
        |> Token.withAuthorizationHeader (Just token)
        |> HttpB.withExpect (Http.expectJson <| Thread.pageDecoder)
        |> HttpB.withQueryParams params
        |> HttpB.toRequest


type Format
    = Minimal
    | Metadata
    | Full


messages : Token.Token -> { id : Thread.Id, format : Format } -> Http.Request (List Message.Message)
messages token { id, format } =
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
            String.join "/" [ Config.threadsUrl, Thread.idAsString id ]
    in
    HttpB.get url
        |> Token.withAuthorizationHeader (Just token)
        |> HttpB.withQueryParams [ ( "format", formatAsString format ) ]
        |> HttpB.withExpect (Http.expectJson <| Decode.at [ "messages" ] (Decode.list Message.decoder))
        |> HttpB.toRequest
