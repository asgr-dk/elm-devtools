module Extension.Result exposing (recover)


recover : (error -> ok) -> Result error ok -> ok
recover fromError result =
    case result of
        Ok value ->
            value

        Err error ->
            fromError error
