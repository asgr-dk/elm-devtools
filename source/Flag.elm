module Flag exposing (parse, parseToggle)

import Parser exposing ((|.), (|=), Parser)


parse : String -> Parser value -> Parser value
parse key valueParser =
    Parser.succeed identity
        |. Parser.symbol ("--" ++ key ++ "=")
        |= valueParser


parseToggle : String -> Parser Bool
parseToggle key =
    Parser.succeed True |. Parser.symbol ("--" ++ key)
