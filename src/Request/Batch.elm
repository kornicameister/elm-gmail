module Request.Batch exposing (batchGET)

import Config
import Data.Token as Token
import Http
import HttpBuilder as HttpB
import Json.Decode as Decode
import Regex


type alias BatchRequestConfig =
    { method : HttpMethod
    , url : String
    }


type HttpMethod
    = GET


methodAsString : HttpMethod -> String
methodAsString method =
    case method of
        GET ->
            "GET"


responseDecoder : Decode.Decoder (List a) -> Http.Response String -> Result String (List a)
responseDecoder decoder { body } =
    let
        maybeBoundary =
            List.head <| String.lines body

        chunks =
            case maybeBoundary of
                Just boundary ->
                    String.split boundary body
                        |> List.filter
                            (\x -> String.isEmpty x /= True || x == String.concat [ boundary, "--" ])
                        |> List.map
                            (\x -> Regex.find (Regex.AtMost 1) (Regex.regex "{(\n.+)+") x |> List.take 1 |> List.map .match |> String.concat)
                        |> List.filter
                            (\x -> String.isEmpty x /= True)

                Nothing ->
                    []

        arrayBody =
            String.concat [ "[", String.join "," chunks, "]" ]
    in
    Decode.decodeString decoder arrayBody


batchGET : Token.Token -> List String -> Decode.Decoder a -> Http.Request (List a)
batchGET token urls decoder =
    batch token (List.map (\url -> { url = url, method = GET }) urls) decoder


batch : Token.Token -> List BatchRequestConfig -> Decode.Decoder a -> Http.Request (List a)
batch token requestConfigs decoder =
    let
        url =
            Config.batchUrl

        boundary =
            "elm_gmail_part"

        finishBroundary =
            String.concat [ "--", boundary, "--" ]

        parts =
            List.indexedMap
                (\index req ->
                    [ String.concat [ "--", boundary, "" ]
                    , String.concat [ "Content-Type", ": ", "application/http" ]
                    , String.concat [ "Content-Transfer-Encoding", ": ", "binary" ]
                    , String.concat [ "Content-ID", ": ", toString index ]
                    , ""
                    , String.concat [ methodAsString req.method, " ", req.url ]
                    , ""
                    ]
                )
                requestConfigs
                |> List.map (String.join "\n")
                |> String.join "\n"

        body =
            Http.stringBody (String.concat [ "multipart/mixed; boundary=", boundary ]) (String.concat [ parts, finishBroundary ])
    in
    HttpB.post url
        |> Token.withAuthorizationHeader (Just token)
        |> HttpB.withBody body
        |> HttpB.withExpect (Http.expectStringResponse <| responseDecoder (Decode.list decoder))
        |> HttpB.toRequest
