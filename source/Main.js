import { Elm } from "../build/main.js";
import { buildElm, convertToESM, getModulePath } from "./Elm.js";

if (import.meta.main) {
  const flags = {
    args: Deno.args,
    project: await Deno.readTextFile("elm.json").catch((_) => null),
  };
  Elm.Main.init({ flags }).ports.output.subscribe(toOutput);
}

async function toOutput({ cmd, args }) {
  switch (cmd) {
    case "build":
      return await toBuildOutput(args);
    case "log":
      return toLogOutput(args);
    case "error":
      return toErrorOutput(args);
    default:
      return toErrorOutput(
        `unrecognized command '${cmd}' with arguments '${
          JSON.stringify(args)
        }'`,
      );
  }
}

async function toBuildOutput(
  { module, output, optimize, format, project },
) {
  const modulePath = await getModulePath(project, module);
  await buildElm({ modulePath, output, optimize });
  if (format === "ESM") await convertToESM(output, optimize);
}

function toLogOutput(message) {
  return console.log(message);
}

function toErrorOutput(message) {
  console.error(message);
  Deno.exit(1);
}
