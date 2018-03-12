module Request.Message exposing (listIds, many)

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


many : Token.Token -> List Id.MessageId -> Http.Request (List Message.Message)
many token ids =
    Request.Batch.batchGET token (List.map (\id -> String.concat [ Config.messagesUrl, "/", Id.messageIdAsString id ]) ids) Message.decoder
