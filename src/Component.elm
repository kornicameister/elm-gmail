module Component exposing (materialIcon)

import Html as H
import Html.Attributes as HA


materialIcon : String -> H.Html msg
materialIcon icon =
    H.i [ HA.class "material-icons" ] [ H.text icon ]
