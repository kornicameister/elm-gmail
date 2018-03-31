module Component exposing (empty, materialIcon, progressBar)

import Html as H
import Html.Attributes as A
import RemoteData


empty : H.Html msg
empty =
    H.text ""


materialIcon : String -> H.Html msg
materialIcon icon =
    H.i [ A.class "material-icons" ] [ H.text icon ]


progressBar : RemoteData.RemoteData e a -> H.Html msg
progressBar remoteData =
    case remoteData of
        RemoteData.Loading ->
            H.div [ A.class "mdc-linear-progress mdc-linear-progress--indeterminate", A.attribute "role" "progressbar" ]
                [ H.div [ A.class "mdc-linear-progress__buffering-dots" ] []
                , H.div [ A.class "mdc-linear-progress__buffer" ] []
                , H.div [ A.class "mdc-linear-progress__bar mdc-linear-progress__primary-bar" ]
                    [ H.span [ A.class "mdc-linear-progress__bar-inner" ] [] ]
                , H.div [ A.class "mdc-linear-progress__bar mdc-linear-progress__secondary-bar" ]
                    [ H.span [ A.class "mdc-linear-progress__bar-inner" ] [] ]
                ]

        _ ->
            empty
