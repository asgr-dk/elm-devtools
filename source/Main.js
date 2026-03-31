import { Elm } from "../build/main.js";
import {
  buildElm,
  convertToESM,
  getModulePath,
  watchProject,
  watchSource,
} from "./Elm.js";

if (import.meta.main) await main();

async function main() {
  const project = await Deno.readTextFile("elm.json").catch((_) => null);
  const flags = { args: Deno.args, project };
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
  { module, output, optimize, format, project, watch },
) {
  const modulePath = await getModulePath(project, module);
  async function build() {
    await buildElm({ modulePath, output, optimize });
    if (format === "esm") await convertToESM(output, optimize);
  }
  if (watch) {
    const sourceWatch = watchSource(project, build);
    await watchProject();
    sourceWatch.close();
    await main();
  } else {
    await build();
  }
}

function toLogOutput(message) {
  return console.log(message);
}

function toErrorOutput(message) {
  console.error(message);
  Deno.exit(1);
}
