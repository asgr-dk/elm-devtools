port module Output exposing (build, error, log)

import Build
import Elm.Project
import Json.Encode


type alias Output =
    { cmd : String
    , args : Json.Encode.Value
    }


port output : Output -> Cmd msg


log : String -> Cmd msg
log message =
    output
        { cmd = "log"
        , args = Json.Encode.string message
        }


error : String -> Cmd msg
error message =
    output
        { cmd = "error"
        , args = Json.Encode.string message
        }


build : Elm.Project.Project -> Build.Arguments -> Cmd msg
build project { module_, output_, optimize, format, watch } =
    output
        { cmd = "build"
        , args =
            Json.Encode.object
                [ ( "module", Json.Encode.string (String.join "." module_) )
                , ( "output", Json.Encode.string (Maybe.withDefault (Build.toOutput module_) output_) )
                , ( "optimize", Json.Encode.bool optimize )
                , ( "format", Json.Encode.string (Build.formatToString format) )
                , ( "project", Elm.Project.encode project )
                , ( "watch", Json.Encode.bool watch )
                ]
        }
