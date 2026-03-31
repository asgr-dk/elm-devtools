module Main exposing (main)

import Build
import Dict
import Elm.Project
import Extension.Parser as Parser
import Extension.Result as Result
import Json.Decode
import Json.Encode
import Output
import Parser exposing ((|.), (|=), Parser)
import Set


type alias Input =
    { args : List String
    , project : Maybe String
    }


run : Input -> Cmd msg
run { args, project } =
    let
        normalArgs =
            String.toLower (String.join " " (List.drop 1 args))
    in
    normalArgs
        |> Parser.run commandParser
        |> Result.recover ParseError
        |> commandToOutput normalArgs (decodeProject project)


main : Program Input () ()
main =
    Platform.worker
        { init = run >> Tuple.pair ()
        , update = always (always ( (), Cmd.none ))
        , subscriptions = always Sub.none
        }



-- Command


type Command
    = Build Build.Arguments
    | ParseError (List Parser.DeadEnd)


commandParser : Parser Command
commandParser =
    Parser.oneOf
        [ Parser.map Build Build.parser
        ]


commandToOutput : String -> Result ProjectError Elm.Project.Project -> Command -> Cmd msg
commandToOutput arg projectResult cmd =
    case cmd of
        Build buildArgs ->
            case projectResult of
                Ok project ->
                    Output.build project buildArgs

                Err projectError ->
                    Output.error (projectErrorToString projectError)

        ParseError deadEnds ->
            Output.error (Parser.deadEndsToString_ arg deadEnds)



-- ProjectError


type ProjectError
    = ProjectDecodeError Json.Decode.Error
    | NoProject


decodeProject : Maybe String -> Result ProjectError Elm.Project.Project
decodeProject =
    Maybe.map (Json.Decode.decodeString Elm.Project.decoder)
        >> Maybe.map (Result.mapError ProjectDecodeError)
        >> Maybe.withDefault (Result.Err NoProject)


projectErrorToString : ProjectError -> String
projectErrorToString error =
    case error of
        ProjectDecodeError decodeError ->
            Json.Decode.errorToString decodeError

        NoProject ->
            "No elm.json found in this directory"
