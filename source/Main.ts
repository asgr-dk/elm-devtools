import {yellow} from "./ANSI.ts"

switch(Deno.args.at(0)) {
    case "--help":
    default:
        console.log(toHelpMsg())
        Deno.exit(1)
}

function toHelpMsg() {
    return `
${yellow("elm-devtools")}
Tools for developing Elm programs!
`
}
