import { EmptyObject } from "./Help.ts";
import { Error } from "./Error.ts";

export type ElmJson = ApplicationElmJson | PackageElmJson;

export type ApplicationElmJson = {
  "type": "application";
  "source-directories": Array<string>;
  "elm-version": string;
  "dependencies": ElmJsonDependencies;
  "test-dependencies": ElmJsonDependencies;
};

export type PackageElmJson = {
  "type": "package";
  "name": string;
  "summary": string;
  "license": string;
  "version": string;
  "exposed-modules": Array<string>;
  "elm-version": string;
  "dependencies": ElmJsonDependencies;
  "test-dependencies": ElmJsonDependencies;
};

export type ElmJsonDependencies = EmptyObject | {
  "direct": Record<string, string>;
  "indirect": Record<string, string>;
};

export async function getElmJson(): Promise<ElmJson> {
  const elmJson = await Deno.readTextFile("elm.json").catch((_) => undefined);
  if (elmJson === undefined) return Promise.reject(Error.NO_ELM_JSON);
  try {
    return JSON.parse(elmJson);
  } catch (_) {
    return Promise.reject(Error.INVALID_ELM_JSON);
  }
}

export async function getModulePath(elmJson: ElmJson, name: string) {
  const namePath = name.replace(".", "/");
  if (elmJson.type === "package") return `src/${namePath}.elm`;
  return await Promise.any(
    elmJson["source-directories"]
      .map((dir) => `${dir}/${namePath}.elm`)
      .map((path) =>
        Deno.lstat(path).then((_) => path).catch((_) =>
          Promise.reject(Error.NO_SRC_MOD)
        )
      ),
  );
}

export async function buildAppModule(
  elmJson: ApplicationElmJson,
  name: string,
  optimize: boolean,
  esm: boolean,
) {
  const modulePath = await getModulePath(elmJson, name);
  const buildPath = toBuildPath(name);
  const elmArgs = toElmArgs(modulePath, buildPath, optimize);
  const esbuildArgs = toESBuildArgs(buildPath);
  await new Deno.Command("elm", { args: elmArgs }).spawn().status
    .then(({ success }) => success || Promise.reject(Error.ELM_ERR));
  if (esm) await convertToESM(buildPath, optimize);
  if (optimize) {
    await new Deno.Command("esbuild", { args: esbuildArgs }).spawn().status
      .then(({ success }) => success || Promise.reject(Error.ESBUILD_ERR));
  }
}

export async function convertToESM(buildPath: string, optimize: boolean) {
  const buildFile = await Deno.open(buildPath, { write: true });
  const constOrLet = optimize ? "const" : "let"; // TODO - not sure if this helps with hot replacement after a rebuild.
  await buildFile.seek(-8, Deno.SeekMode.End);
  await buildFile.write(
    new TextEncoder().encode(
      `(globalThis));export ${constOrLet} Elm = globalThis.Elm;`,
    ),
  );
}

export function toBuildPath(name: string) {
  return `build/${name.toLowerCase()}.js`;
}

function toElmArgs(
  modulePath: string,
  buildPath: string,
  optimize: boolean,
) {
  const args = ["make", `--output=${buildPath}`, modulePath];
  if (optimize) args.push("--optimize");
  return args;
}

function toESBuildArgs(buildPath: string) {
  return [
    "--minify",
    "--allow-overwrite",
    `--outfile=${buildPath}`,
    "--pure:F",
    ...Array(8).keys().map((key) => `--pure:F${key + 2}`),
    ...Array(8).keys().map((key) => `--pure:A${key + 2}`),
    buildPath,
  ];
}
