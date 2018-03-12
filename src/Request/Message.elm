module Request.Message exposing (Format(..), listIds, many)

import Config
import Data.Id as Id
import Data.Message as Message
import Data.Token as Token
import Http
import HttpBuilder as HttpB
import Request.Batch


listIds : Token.Token -> Http.Request Message.Page
listIds token =
    let
        url =
            Config.messagesUrl
    in
    HttpB.get url
        |> Token.withAuthorizationHeader (Just token)
        |> HttpB.withExpect (Http.expectJson <| Message.pageDecoder)
        |> HttpB.toRequest


type Format
    = Minimal
    | Metadata
    | Full
    | Raw


many : Token.Token -> { ids : List Id.MessageId, format : Format } -> Http.Request (List Message.Message)
many token { ids, format } =
    let
        formatAsString format =
            case format of
                Minimal ->
                    "minimal"

                Metadata ->
                    "metadata"

                Full ->
                    "full"

                Raw ->
                    "raw"

        configs =
            List.map
                (\id ->
                    { url = String.concat [ Config.messagesUrl, "/", Id.messageIdAsString id ]
                    , method = Request.Batch.GET
                    , params = [ ( "format", formatAsString format ) ]
                    , headers = [ ( "Content-Type", "application/json" ) ]
                    }
                )
                ids
    in
    Request.Batch.batch token configs Message.decoder
