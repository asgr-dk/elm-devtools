module Extension.String exposing (capitalize)


capitalize : String -> String
capitalize text =
    String.toUpper (String.left 1 text)
        ++ String.dropLeft 1 text
