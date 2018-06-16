module Data.Label
    exposing
        ( DefinedBy(..)
        , Id
        , Kind(..)
        , Label
        , VisibilityInLabelsList(..)
        , decoder
        , idDecoder
        )

import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP


type Id
    = Id String


type alias Label =
    { id : Id
    , name : String
    , definedBy : DefinedBy
    , visibility : Visibility
    , kind : Kind
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


idDecoder : Decode.Decoder Id
idDecoder =
    Decode.map Id Decode.string
