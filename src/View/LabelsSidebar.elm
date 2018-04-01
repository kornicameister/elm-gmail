module View.LabelsSidebar
    exposing
        ( Model
        , Msg
        , init
        , view
        )

import Data.Label as Label
import Html as H
import Html.Attributes as A
import Html.Events as E


--- MODEL ---


type alias Model =
    { isVisible : Bool
    , labels : List Label.Label
    , selectedLabel : Maybe Label.Label
    }


init : List Label.Label -> Model
init labels =
    { isVisible = True
    , labels = labels
    , selectedLabel = labels |> List.head
    }



--- UPDATE ---


type Msg
    = ToggleVisibility
    | LabelSelected Label.Label



--- VIEW ---


view : Model -> H.Html Msg
view model =
    let
        ( systemLabels, userLabels ) =
            model.labels
                |> List.filter
                    (\label -> label.visibility.inLabelList == Label.Visible)
                |> List.sortBy .name
                |> List.partition
                    (\label -> label.definedBy == Label.SystemDefined)

        ( inboxLabels, filterLabels ) =
            systemLabels
                |> List.filter (\label -> label.kind /= Label.Category)
                |> List.partition (\label -> label.kind == Label.Inbox)

        inboxLabelLis =
            inboxLabels
                |> List.map (\label -> H.p [] [ H.a [] [ H.text label.name ] ])

        filterLabelLis =
            filterLabels
                |> List.map (\label -> H.p [] [ H.a [] [ H.text label.name ] ])

        userLabelLis =
            userLabels
                |> List.map (\label -> H.p [] [ H.a [] [ H.text label.name ] ])

        paddingEl =
            [ H.p [ A.style [ ( "padding", "2px" ) ] ] [] ]

        fullLiList =
            inboxLabelLis ++ paddingEl ++ filterLabelLis ++ paddingEl ++ userLabelLis
    in
    H.div [ A.class "column is-3" ] [ H.div [ A.class "container" ] [ H.section [ A.class "section" ] fullLiList ] ]
