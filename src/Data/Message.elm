module Data.Message exposing (Message, decoder)

import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP
import Data.Id as Id


---- MODEL ----


type alias Message =
    { messageId : Id.MessageId
    , threadId : Id.ThreadId
    , historyId : Id.HistoryId
    , labelIds : List Id.LabelId
    , snippet : String
    , payload : Payload
    }


type alias Payload =
    { partId : Maybe String
    , mimeType : String
    , filename : Maybe String
    , headers : List ( String, String )
    , body : Body
    , parts : Parts
    }


type Parts
    = NoParts
    | Parts (List PayloadPart)


type alias PayloadPart =
    { partId : Int
    , mimeType : String
    , filename : Maybe String
    , headers : List ( String, String )
    , body : Body
    }


type Body
    = WithAttachment AttachedBody
    | WithData DataBody
    | Empty


type alias AttachedBody =
    { attachmentId : Id.AttachmentId }


type alias DataBody =
    { size : Int, data : String }



---- SERIALIZATION


decoder : Decode.Decoder Message
decoder =
    let
        emptyStringAsNothingDecoder =
            Decode.string
                |> Decode.andThen
                    (\val ->
                        case val of
                            "" ->
                                Decode.succeed Nothing

                            str ->
                                Decode.succeed (Just str)
                    )

        headersDecoder =
            DecodeP.decode (,)
                |> DecodeP.required "name" Decode.string
                |> DecodeP.required "value" Decode.string
                |> Decode.list

        bodyDecoder =
            Decode.oneOf
                [ DecodeP.decode AttachedBody
                    |> DecodeP.required "attachmentId" Id.attachmentIdDecoder
                    |> Decode.map WithAttachment
                , Decode.field "size" Decode.int
                    |> Decode.andThen
                        (\size ->
                            if size == 0 then
                                Decode.succeed Empty
                            else
                                Decode.field "data" Decode.string
                                    |> Decode.andThen
                                        (\data -> Decode.succeed { data = data, size = size })
                                    |> Decode.map WithData
                        )
                ]

        partDecoder =
            DecodeP.decode PayloadPart
                |> DecodeP.required "partId"
                    (Decode.string
                        |> Decode.andThen
                            (\str ->
                                case (String.toInt str) of
                                    Ok number ->
                                        Decode.succeed number

                                    Err err ->
                                        Decode.fail err
                            )
                    )
                |> DecodeP.required "mimeType" Decode.string
                |> DecodeP.required "filename" emptyStringAsNothingDecoder
                |> DecodeP.required "headers" headersDecoder
                |> DecodeP.required "body" bodyDecoder

        payloadDecoder =
            DecodeP.decode Payload
                |> DecodeP.required "partId" emptyStringAsNothingDecoder
                |> DecodeP.required "mimeType" Decode.string
                |> DecodeP.required "filename" emptyStringAsNothingDecoder
                |> DecodeP.required "headers" headersDecoder
                |> DecodeP.required "body" bodyDecoder
                |> DecodeP.optional "parts" ((Decode.list partDecoder) |> Decode.map Parts) NoParts
    in
        DecodeP.decode Message
            |> DecodeP.required "id" Id.messageIdDecoder
            |> DecodeP.required "threadId" Id.threadIdDecoder
            |> DecodeP.required "historyId" Id.historyIdDecoder
            |> DecodeP.required "labelIds" (Decode.list Id.labelIdDecoder)
            |> DecodeP.required "snippet" Decode.string
            |> DecodeP.required "payload" payloadDecoder
