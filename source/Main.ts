import { Error, toErrorMessage } from "./Error.ts";
import { build, toHelpMsgBuild } from "./Command/Build.ts";

if (import.meta.main) {
  await main(Deno.args).catch((error) => {
    console.error(toErrorMessage(error));
    Deno.exit(1);
  });
}

function toHelpMsgMain() {
  return `Tools for developing Elm programs!

Available commands are:

    elm-devtools.exe build
        Builds an Elm module.
    
    elm-devtools.exe --version
        Prints the version number associated
        with the build of elm-devtools you
        are currently running.

    elm-devtools.exe --help
        Prints this help message.
`;
}

async function main(args: Array<string>) {
  const version = args.at(0);
  switch (args.at(1)) {
    case "build":
      return args.includes("--help")
        ? console.log(toHelpMsgBuild())
        : await build(args);
    case "--version":
      return console.log(version);
    case "--help":
      return console.log(toHelpMsgMain());
    default:
      console.log(toHelpMsgMain());
      return Promise.reject(Error.INVALID_ARGS);
  }
}
