port module Ports exposing (..)

import Json.Encode as Encode


--- senders


port gApiSignIn : () -> Cmd msg


port gApiSignOut : () -> Cmd msg



--- receivers


port gApiIsSignedIn : (Encode.Value -> msg) -> Sub msg
