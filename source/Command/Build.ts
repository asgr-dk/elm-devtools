import { buildAppModule, getElmJson } from "../Elm.ts";
import { parseFlag } from "../Help.ts";
import { Error } from "../Error.ts";

export function toHelpMsgBuild() {
  return `Builds an Elm module.

Available flags are:

    --module=<string>
        Defaults to "Main". Use this to name
        the Elm module you want to build.
    
    --optimize=<bool>
        Defaults to true. Use this to compress
        the built Elm code using ESBuild.

    --esm=<bool>
        Defaults to false. The Elm compiler emits
        "immediately invoked function expressions"
        or "iife". Use this flag to emit ecmascript
        modules instead.
`;
}

export async function build(args: Array<string>) {
  const elmJson = await getElmJson();
  if (elmJson.type === "package") {
    return Promise.reject(Error.PKG_UNSUPPORTED);
  }
  const moduleName = parseFlag(args, "module") || "Main";
  const optimize = parseFlag(args, "optimize") === "true";
  const esm = parseFlag(args, "esm") === "true";
  await buildAppModule(elmJson, moduleName, optimize, esm);
}
