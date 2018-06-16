module Data.Label
    exposing
        ( DefinedBy(..)
        , Id
        , Kind(..)
        , Label
        , LabelColor
        , VisibilityInLabelsList(..)
        , decoder
        , idDecoder
        )

import Color
import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP
import ParseInt
import Regex


type Id
    = Id String


type alias Label =
    { id : Id
    , name : String
    , definedBy : DefinedBy
    , visibility : Visibility
    , kind : Kind
    , color : Maybe LabelColor
    }


type alias LabelColor =
    { background : Color.Color
    , text : Color.Color
    }


type DefinedBy
    = SystemDefined
    | UserDefined


type Kind
    = Inbox
    | Filter
    | Category


type alias Visibility =
    { inLabelList : VisibilityInLabelsList
    , inMessageList : Bool
    }


type VisibilityInLabelsList
    = Visible
    | VisibleIfUnread
    | Hidden


decoder : Decode.Decoder Label
decoder =
    let
        kindDecoder =
            Decode.string
                |> Decode.andThen
                    (\kind ->
                        case kind of
                            "user" ->
                                Decode.succeed UserDefined

                            "system" ->
                                Decode.succeed SystemDefined

                            _ ->
                                Decode.fail <| "Unknown kind: " ++ kind
                    )

        labelsListVisibility =
            Decode.string
                |> Decode.andThen
                    (\x ->
                        case x of
                            "labelHide" ->
                                Decode.succeed Hidden

                            "labelShow" ->
                                Decode.succeed Visible

                            "labelShowIfUnread" ->
                                Decode.succeed VisibleIfUnread

                            _ ->
                                Decode.fail <| "Unkown labelListVisibility: " ++ x
                    )

        messageListVisibility =
            Decode.string
                |> Decode.andThen
                    (\x ->
                        case x of
                            "show" ->
                                Decode.succeed True

                            "hide" ->
                                Decode.succeed False

                            _ ->
                                Decode.fail <| "Uknown messageListVisibility: " ++ x
                    )

        colorDecoder =
            DecodeP.decode LabelColor
                |> DecodeP.required "backgroundColor" hexToRgaColorDecoder
                |> DecodeP.required "textColor" hexToRgaColorDecoder

        hexToRgaColorDecoder =
            Decode.string
                |> Decode.andThen
                    (\hexColor ->
                        case hexToColor hexColor of
                            Err err ->
                                Decode.fail <| ("Failed to convert " ++ hexColor ++ " to color")

                            Ok color ->
                                Decode.succeed color
                    )

        hexToColor =
            let
                extend token =
                    case String.toList token of
                        [ token ] ->
                            String.fromList [ token, token ]

                        _ ->
                            token

                pattern =
                    ""
                        ++ "^"
                        ++ "#?"
                        ++ "(?:"
                        ++ "(?:([a-f\\d]{2})([a-f\\d]{2})([a-f\\d]{2}))"
                        ++ "|"
                        ++ "(?:([a-f\\d])([a-f\\d])([a-f\\d]))"
                        ++ ")"
                        ++ "$"
            in
            String.toLower
                >> Regex.find (Regex.AtMost 1) (Regex.regex pattern)
                >> List.head
                >> Maybe.map .submatches
                >> Maybe.map (List.filterMap identity)
                >> Result.fromMaybe "Parsing hex regex failed"
                >> Result.andThen
                    (\colors ->
                        case List.map (extend >> ParseInt.parseIntHex) colors of
                            [ Ok r, Ok g, Ok b ] ->
                                Ok <| Color.rgb r g b

                            _ ->
                                -- there could be more descriptive error cases per channel
                                Err "Parsing ints from hex failed"
                    )
    in
    DecodeP.decode Label
        |> DecodeP.required "id" idDecoder
        |> DecodeP.required "name" Decode.string
        |> DecodeP.required "type" kindDecoder
        |> DecodeP.custom
            (Decode.map2
                (\maybeLabelsVisibility maybeMessageVisibility ->
                    { inLabelList = Maybe.withDefault Visible maybeLabelsVisibility
                    , inMessageList = Maybe.withDefault True maybeMessageVisibility
                    }
                )
                (Decode.maybe (Decode.field "labelsListVisibility" labelsListVisibility))
                (Decode.maybe (Decode.field "messageListVisibility" messageListVisibility))
            )
        |> DecodeP.custom
            (Decode.field "id" Decode.string
                |> Decode.andThen
                    (\id ->
                        case
                            [ List.member id [ "INBOX", "SENT", "UNREAD", "DRAFT", "SPAM", "THRASH" ]
                            , String.startsWith "CATEGORY_" id
                            ]
                        of
                            [ True, False ] ->
                                Decode.succeed Inbox

                            [ False, True ] ->
                                Decode.succeed Category

                            [ False, False ] ->
                                Decode.succeed Filter

                            _ ->
                                Decode.fail <| "Failed to deduce label kind from id: " ++ id
                    )
            )
        |> DecodeP.optional "color" (Decode.nullable colorDecoder) Nothing


idDecoder : Decode.Decoder Id
idDecoder =
    Decode.map Id Decode.string
