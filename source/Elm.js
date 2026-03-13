if (import.meta.main) {
  const optimize = Deno.args.some((arg) => arg === "optimize");
  const modulePath = "source/Main.elm";
  const output = "build/main.js";
  console.table({ optimize, modulePath, output });
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

export function watchSource(
  project,
  onEvent,
  timeoutMilliseconds = 100,
) {
  const sourceWatch = Deno.watchFs(project["source-directories"]);
  (async function () {
    let id = undefined;
    for await (const event of sourceWatch) {
      if (event.paths.some((path) => path.endsWith(".elm"))) {
        if (id) clearTimeout(id);
        id = setTimeout(
          async () => await onEvent(event).catch(() => {}),
          timeoutMilliseconds,
        );
      }
    }
  })();
  return sourceWatch;
}

export async function watchProject() {
  const projectWatch = Deno.watchFs("elm.json");
  for await (const _ of projectWatch) {
    projectWatch.close();
  }
}
