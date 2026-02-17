module Main exposing
    ( Flags
    , Model
    , Msg(..)
    , init
    , main
    , subscriptions
    , update
    , view
    )

import Browser
import Browser.Navigation
import Html exposing (button, input, text)
import Html.Attributes exposing (type_, value)
import Html.Events exposing (onClick, onInput)


type alias Flags =
    { msgs : Maybe String }


type alias Model =
    { name : String
    , pass : String
    , isLoggedIn : Bool
    }


type Msg
    = InputName String
    | InputPass String
    | LogIn
    | LogOut


init : Flags -> ( Model, Cmd Msg )
init _ =
    ( { name = "", pass = "", isLoggedIn = False }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InputName name ->
            ( { model | name = name }, Cmd.none )

        InputPass pass ->
            ( { model | pass = pass }, Cmd.none )

        LogIn ->
            ( { model | isLoggedIn = True }, Cmd.none )

        LogOut ->
            ( { model | isLoggedIn = False }, Cmd.none )


view : Model -> Browser.Document Msg
view { isLoggedIn, name, pass } =
    { title = "Example"
    , body =
        if isLoggedIn then
            [ text ("hi " ++ name)
            , button [ onClick LogOut ] [ text "Log Out" ]
            ]

        else
            [ input [ onInput InputName, value name ] []
            , input [ onInput InputPass, value pass, type_ "password" ] []
            , button [ onClick LogIn ] [ text "Log In" ]
            ]
    }


subscriptions : Model -> Sub msg
subscriptions model =
    Sub.none


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
