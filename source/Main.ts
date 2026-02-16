import { yellow } from "./ANSI.ts";

if (import.meta.main) {
  switch (Deno.args.at(1)) {
    case "watch":
      await watch();
      break;
    case "--version":
      console.log(Deno.args.at(0));
      break;
    case "--help":
      console.log(toHelpMsg());
      break;
    default:
      console.log(toHelpMsg());
      Deno.exit(1);
  }
}

function toHelpMsg() {
  return `
${yellow("elm-devtools")}
Tools for developing Elm programs!
`;
}

async function watch() {
  throw "TODO";
}
