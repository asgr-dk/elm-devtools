port module Main exposing (main)

import Dict
import Elm.Project
import Json.Decode
import Json.Encode
import Parser exposing ((|.), (|=), Parser)
import Set


port output : Output -> Cmd msg


type alias Input =
    { args : List String
    , project : Maybe String
    }


run : Input -> Output
run { args, project } =
    args
        |> List.drop 1
        |> String.join " "
        |> Parser.run commandParser
        |> recoverWith ParseError
        |> commandToOutput (decodeProject project)


main : Program Input () ()
main =
    Platform.worker
        { init = run >> output >> Tuple.pair ()
        , update = always (always ( (), Cmd.none ))
        , subscriptions = always Sub.none
        }



-- Command


type Command
    = Build BuildArgs
    | ParseError (List Parser.DeadEnd)


commandParser : Parser Command
commandParser =
    Parser.oneOf
        [ buildParser
        ]


commandToOutput : Result ProjectError Elm.Project.Project -> Command -> Output
commandToOutput projectResult cmd =
    case cmd of
        Build buildArgs ->
            case projectResult of
                Ok project ->
                    toBuildOutput project buildArgs

                Err projectError ->
                    toErrorOutput (projectErrorToString projectError)

        ParseError deadEnds ->
            toErrorOutput (deadEndsToString deadEnds)


type ProjectError
    = ProjectDecodeError Json.Decode.Error
    | NoProject



-- Build Command


buildParser : Parser Command
buildParser =
    Parser.succeed Build
        |. Parser.keyword "build"
        |. Parser.spaces
        |= buildArgsParser
        |. Parser.end


buildArgsParser : Parser BuildArgs
buildArgsParser =
    Parser.loop initBuildArgs buildArgsParserLoop


buildArgsParserLoop : BuildArgs -> Parser (Parser.Step BuildArgs BuildArgs)
buildArgsParserLoop args =
    Parser.oneOf
        [ Parser.succeed (\o -> Parser.Loop { args | optimize = o })
            |= flagParser "optimize" boolParser
            |. Parser.spaces
        , Parser.succeed (\o -> Parser.Loop { args | optimize = o })
            |= toggleFlagParser "optimize"
            |. Parser.spaces
        , Parser.succeed (\m -> Parser.Loop { args | module_ = m })
            |. Parser.spaces
            |= flagParser "module" moduleParser
            |. Parser.spaces
        , Parser.succeed (\f -> Parser.Loop { args | format = f })
            |= flagParser "format" formatParser
            |. Parser.spaces
        , Parser.succeed (\o -> Parser.Loop { args | output_ = Just o })
            |= flagParser "output" outputParser
            |. Parser.spaces
        , Parser.succeed (\w -> Parser.Loop { args | watch = w })
            |= toggleFlagParser "watch"
            |. Parser.spaces
        , Parser.succeed (Parser.Done args)
        ]


type alias BuildArgs =
    { module_ : List String
    , optimize : Bool
    , format : Format
    , output_ : Maybe String
    , watch : Bool
    }


initBuildArgs : BuildArgs
initBuildArgs =
    { module_ = [ "Main" ]
    , optimize = False
    , format = IIFE
    , output_ = Nothing
    , watch = False
    }


outputParser : Parser String
outputParser =
    Parser.variable
        { start = always True
        , inner = always True
        , reserved = Set.empty
        }



-- Output


type alias Output =
    { cmd : String
    , args : Json.Encode.Value
    }


toBuildOutput : Elm.Project.Project -> BuildArgs -> Output
toBuildOutput project { module_, output_, optimize, format, watch } =
    { cmd = "build"
    , args =
        Json.Encode.object
            [ ( "module", Json.Encode.string (String.join "." module_) )
            , ( "output", Json.Encode.string (Maybe.withDefault (outputFromModule module_) output_) )
            , ( "optimize", Json.Encode.bool optimize )
            , ( "format", Json.Encode.string (formatToString format) )
            , ( "project", Elm.Project.encode project )
            , ( "watch", Json.Encode.bool watch )
            ]
    }


toLogOutput : String -> Output
toLogOutput message =
    { cmd = "log"
    , args = Json.Encode.string message
    }


toErrorOutput : String -> Output
toErrorOutput message =
    { cmd = "error"
    , args = Json.Encode.string message
    }



-- Module_


moduleParser : Parser (List String)
moduleParser =
    Parser.succeed (::)
        |= moduleSegmentParser
        |= Parser.loop [] moduleParserLoop


moduleParserLoop : List String -> Parser (Parser.Step (List String) (List String))
moduleParserLoop mods =
    Parser.oneOf
        [ Parser.succeed (\mod -> Parser.Loop (mods ++ [ mod ]))
            |. Parser.symbol "."
            |= moduleSegmentParser
        , Parser.succeed ()
            |> Parser.map (\_ -> Parser.Done mods)
        ]


moduleSegmentParser : Parser String
moduleSegmentParser =
    Parser.variable
        { start = \c -> Char.isAlpha c && Char.isUpper c
        , inner = \c -> Char.isAlpha c
        , reserved = Set.empty
        }


outputFromModule : List String -> String
outputFromModule module_ =
    String.join "/" (List.map String.toLower ("build" :: module_)) ++ ".js"



-- Format


type Format
    = ESM
    | IIFE


formatParser : Parser Format
formatParser =
    Parser.oneOf
        [ Parser.succeed ESM |. Parser.keyword "esm"
        , Parser.succeed IIFE |. Parser.keyword "iife"
        ]


formatToString : Format -> String
formatToString format =
    case format of
        ESM ->
            "ESM"

        IIFE ->
            "IIFE"



-- Project


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
            "TODO - no project here"



-- Result


recoverWith : (error -> ok) -> Result error ok -> ok
recoverWith recover result =
    case result of
        Ok value ->
            value

        Err error ->
            recover error



-- Parser


deadEndsToString : List Parser.DeadEnd -> String
deadEndsToString ends =
    Debug.toString ends


boolParser : Parser Bool
boolParser =
    Parser.oneOf
        [ Parser.succeed True |. Parser.keyword "true"
        , Parser.succeed False |. Parser.keyword "false"
        ]


flagParser : String -> Parser value -> Parser value
flagParser keyword valueParser =
    Parser.succeed identity
        |. Parser.symbol ("--" ++ keyword ++ "=")
        |= valueParser


toggleFlagParser : String -> Parser Bool
toggleFlagParser keyword =
    Parser.succeed True |. Parser.symbol ("--" ++ keyword)
