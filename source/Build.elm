module Build exposing (Arguments, Format, formatToString, initArguments, parser)

import Extension.Parser as Parser
import Flag
import Parser exposing ((|.), (|=), Parser)
import Set


type alias Arguments =
    { module_ : List String
    , optimize : Bool
    , format : Format
    , output_ : String
    , watch : Bool
    }


initArguments : Arguments
initArguments =
    let
        module_ =
            [ "Main" ]
    in
    { module_ = module_
    , optimize = False
    , format = IIFE
    , output_ = String.join "/" (List.map String.toLower ("build" :: module_)) ++ ".js"
    , watch = False
    }


parser : Parser Arguments
parser =
    Parser.succeed identity
        |. Parser.keyword "build"
        |. Parser.spaces
        |= argumentsParser
        |. Parser.end


argumentsParser : Parser Arguments
argumentsParser =
    Parser.loop initArguments argumentsParserLoop


argumentsParserLoop : Arguments -> Parser (Parser.Step Arguments Arguments)
argumentsParserLoop args =
    Parser.oneOf
        [ Parser.succeed (\o -> Parser.Loop { args | optimize = o })
            |= Flag.parse "optimize" Parser.bool
            |. Parser.spaces
        , Parser.succeed (\o -> Parser.Loop { args | optimize = o })
            |= Flag.parseToggle "optimize"
            |. Parser.spaces
        , Parser.succeed (\m -> Parser.Loop { args | module_ = m })
            |. Parser.spaces
            |= Flag.parse "module" moduleParser
            |. Parser.spaces
        , Parser.succeed (\f -> Parser.Loop { args | format = f })
            |= Flag.parse "format" formatParser
            |. Parser.spaces
        , Parser.succeed (\o -> Parser.Loop { args | output_ = o })
            |= Flag.parse "output" outputParser
            |. Parser.spaces
        , Parser.succeed (\w -> Parser.Loop { args | watch = w })
            |= Flag.parseToggle "watch"
            |. Parser.spaces
        , Parser.succeed (Parser.Done args)
        ]


outputParser : Parser String
outputParser =
    Parser.variable
        { start = always True
        , inner = always True
        , reserved = Set.empty
        }



-- Format


type Format
    = ESM
    | IIFE


formatToString : Format -> String
formatToString format =
    case format of
        ESM ->
            "ESM"

        IIFE ->
            "IIFE"


formatParser : Parser Format
formatParser =
    Parser.oneOf
        [ Parser.succeed ESM |. Parser.keyword "esm"
        , Parser.succeed IIFE |. Parser.keyword "iife"
        ]



-- Module


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
