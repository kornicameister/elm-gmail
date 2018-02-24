module Main exposing (..)

import Html as H
import Html.Attributes as HA
import Component as C


---- MODEL ----


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----


view : Model -> H.Html Msg
view model =
    H.div [ HA.class "container root" ]
        [ H.nav [ HA.class "grey darken-1" ]
            -- a href="#!" class="brand-logo"><i class="material-icons">cloud</i>Logo</a>
            [ H.div [ HA.class "nav-wrapper" ]
                [ H.a [ HA.class "brand-logo", HA.href "#" ]
                    [ C.materialIcon "cloud"
                    , H.text "KGmail"
                    ]
                , H.ul [ HA.class "right hide-on-med-and-down" ]
                    [ H.li [] [ C.materialIcon "more_vert" ]
                    ]
                ]
            ]
        , H.div [ HA.class "row" ]
            [ H.div [ HA.class "col s12" ]
                []
            ]
        ]



---- PROGRAM ----


main : Program Never Model Msg
main =
    H.program
        { view = view
        , init = init
        , update = update
        , subscriptions = always Sub.none
        }
