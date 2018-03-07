module Component exposing (empty, materialIcon, progressBar)

import Html as H
import Html.Attributes as HA
import RemoteData


empty : H.Html msg
empty =
    H.text ""


materialIcon : String -> H.Html msg
materialIcon icon =
    H.i [ HA.class "material-icons" ] [ H.text icon ]


progressBar : RemoteData.RemoteData e a -> H.Html msg
progressBar remoteData =
    case remoteData of
        RemoteData.Loading ->
            H.div [ HA.class "mdc-linear-progress mdc-linear-progress--indeterminate", HA.attribute "role" "progressbar" ]
                [ H.div [ HA.class "mdc-linear-progress__buffering-dots" ] []
                , H.div [ HA.class "mdc-linear-progress__buffer" ] []
                , H.div [ HA.class "mdc-linear-progress__bar mdc-linear-progress__primary-bar" ]
                    [ H.span [ HA.class "mdc-linear-progress__bar-inner" ] [] ]
                , H.div [ HA.class "mdc-linear-progress__bar mdc-linear-progress__secondary-bar" ]
                    [ H.span [ HA.class "mdc-linear-progress__bar-inner" ] [] ]
                ]

        _ ->
            empty
