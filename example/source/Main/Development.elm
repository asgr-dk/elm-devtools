port module Main.Development exposing (main)

import Json.Decode
import Json.Encode
import Main exposing (..)
import MsgReplay


port saveMsgs : String -> Cmd msg


encodeMsg : Msg -> Json.Encode.Value
encodeMsg msg =
    Json.Encode.list Json.Encode.string
        (case msg of
            InputName name ->
                [ "InputName", name ]

            InputPass pass ->
                [ "InputPass", pass ]

            LogIn ->
                [ "LogIn" ]

            LogOut ->
                [ "LogOut" ]
        )


msgDecoder : Json.Decode.Decoder Msg
msgDecoder =
    Json.Decode.andThen
        (\strings ->
            case strings of
                [ "InputName", name ] ->
                    Json.Decode.succeed (InputName name)

                [ "InputPass", pass ] ->
                    Json.Decode.succeed (InputPass pass)

                [ "LogIn" ] ->
                    Json.Decode.succeed LogIn

                [ "LogOut" ] ->
                    Json.Decode.succeed LogOut

                _ ->
                    Json.Decode.fail
                        ("unrecognized message ["
                            ++ String.join ", " strings
                            ++ "]"
                        )
        )
        (Json.Decode.list Json.Decode.string)


main : MsgReplay.Program Flags Model Msg
main =
    MsgReplay.document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , encodeMsg = encodeMsg
        , msgDecoder = msgDecoder
        , saveMsgs = saveMsgs
        , initMsgs = .msgs
        }
