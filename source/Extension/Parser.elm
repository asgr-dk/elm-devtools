module Extension.Parser exposing (bool, deadEndsToString_)

import Parser exposing ((|.), (|=), Parser)


bool : Parser Bool
bool =
    Parser.oneOf
        [ Parser.succeed True |. Parser.keyword "true"
        , Parser.succeed False |. Parser.keyword "false"
        ]


deadEndsToString_ : String -> List Parser.DeadEnd -> String
deadEndsToString_ string ends =
    "Problem with the given string:\n\n"
        ++ string
        ++ "\n\n"
        ++ String.join "\n" (List.map deadEndToString ends)


deadEndToString : Parser.DeadEnd -> String
deadEndToString { row, col, problem } =
    parserProblemToString problem
        ++ " (line "
        ++ String.fromInt row
        ++ " column "
        ++ String.fromInt col
        ++ ")"


parserProblemToString : Parser.Problem -> String
parserProblemToString problem =
    case problem of
        Parser.Expecting text ->
            "Expecting string \"" ++ text ++ "\""

        Parser.ExpectingInt ->
            "Expecting int"

        Parser.ExpectingHex ->
            "Expecting hex"

        Parser.ExpectingOctal ->
            "Expecting octal"

        Parser.ExpectingBinary ->
            "Expecting binary"

        Parser.ExpectingFloat ->
            "Expecting float"

        Parser.ExpectingNumber ->
            "Expecting number"

        Parser.ExpectingVariable ->
            "Expecting variable"

        Parser.ExpectingSymbol key ->
            "Expecting symbol \"" ++ key ++ "\""

        Parser.ExpectingKeyword key ->
            "Expecting keyword \"" ++ key ++ "\""

        Parser.ExpectingEnd ->
            "Expecting end of line"

        Parser.UnexpectedChar ->
            "Expecting character"

        Parser.Problem reason ->
            "Something went wrong: " ++ reason

        Parser.BadRepeat ->
            "Something shouldn't be repeated"
