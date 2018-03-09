module Data.User exposing (User, decoder)

import Data.Token as Token
import Json.Decode as Decode
import Json.Decode.Pipeline as DecodeP


---- MODEL ----


type alias User =
    { name : String
    , email : String
    , imageUrl : String
    , accessToken : Token.Token
    }



---- SERIALIZATION


decoder : Decode.Decoder User
decoder =
    DecodeP.decode User
        |> DecodeP.required "name" Decode.string
        |> DecodeP.required "email" Decode.string
        |> DecodeP.required "imageUrl" Decode.string
        |> DecodeP.required "accessToken" Token.decoder
