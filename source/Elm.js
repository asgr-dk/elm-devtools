if (import.meta.main) {
  const optimize = Deno.args.some((arg) => arg === "optimize");
  const modulePath = "source/Main.elm";
  const output = "build/main.js";
  console.log({ optimize, modulePath, output });
  await buildElm({ modulePath, output, optimize });
  await convertToESM({ output, optimize });
}

export async function buildElm({ modulePath, output, optimize }) {
  const args = ["make", `--output=${output}`, modulePath];
  if (optimize) args.push("--optimize");
  await new Deno.Command("elm", { args }).spawn().status
    .then(({ success }) => success ? Promise.resolve() : Promise.reject());
}

export async function convertToESM({ output, optimize }) {
  const buildFile = await Deno.open(output, { write: true });
  const constOrLet = optimize ? "const" : "let";
  await buildFile.seek(-8, Deno.SeekMode.End);
  await buildFile.write(
    new TextEncoder().encode(
      `(globalThis));export ${constOrLet} Elm = globalThis.Elm;`,
    ),
  );
}

export async function getModulePath(project, module) {
  const namePath = module.replace(".", "/");
  if (project.type === "package") return `src/${namePath}.elm`;
  return await Promise.any(
    project["source-directories"]
      .map((dir) => `${dir}/${namePath}.elm`)
      .map((path) => Deno.lstat(path).then((_) => path)),
  );
}
