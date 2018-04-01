module Data.Label
    exposing
        ( Kind(..)
        , VisibilityInLabelsList(..)
        , Label
        , decoder
        )

import Data.Id as Id
import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP


type alias Label =
    { id : Id.LabelId
    , name : String
    , kind : Kind
    , visibility : Visibility
    }


type Kind
    = SystemDefined
    | UserDefined


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
        |> DecodeP.required "id" Id.labelIdDecoder
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
