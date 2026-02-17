import { buildAppModule, getElmJson, toBuildPath } from "../Elm.ts";
import { parseFlag, watchFiles } from "../Help.ts";
import { Error } from "../Error.ts";

export function toHelpMsgWatch() {
  return `
Rebuilds an Elm module on change.

Available flags are:

    --module=<string>
        Defaults to "Main". Use this to name
        the Elm module you want to build.

    --serve=<bool>
        Defaults to false. Use this to push
        code changes over websockets directly
        to the browser running the program.

    --port=<int>
        Defaults to 1337. Use this to set
        the port number of the server if
        --serve is set to true.
`;
}

export async function watch(args: Array<string>) {
  const elmJson = await getElmJson();
  if (elmJson.type === "package") {
    return Promise.reject(Error.PKG_UNSUPPORTED);
  }
  const moduleName = parseFlag(args, "module");
  const serveBuild = parseFlag(args, "serve") === "true";
  const servePort = serveBuild ? parseFlag(args, "port") : undefined;
  const buildPath = toBuildPath(name);
  await buildAppModule(elmJson, moduleName);
  const appBuildServer = serveBuild
    ? serveAppBuild(servePort ? parseInt(servePort) : undefined)
    : undefined;
  const srcDirWatch = watchFiles(
    elmJson["source-directories"],
    async (_) => {
      await buildAppModule(elmJson, moduleName);
      const codeBlob = await Deno.readFile(buildPath);
      if (appBuildServer) {
        appBuildServer.clients.forEach((client) =>
          client.readyState === client.OPEN && client.send(codeBlob)
        );
      }
    },
    (event) => event.paths.some((path) => path.endsWith(".elm")),
  );
  const elmJsonWatch = watchFiles(["elm.json"], (_) => {
    srcDirWatch.watcher.close();
    elmJsonWatch.watcher.close();
    if (appBuildServer) appBuildServer.server.shutdown();
  });
  const waitFor = [srcDirWatch.didExit, elmJsonWatch.didExit];
  if (appBuildServer) waitFor.push(appBuildServer.server.finished);
  await Promise.all(waitFor);
  return watch(args);
}

function serveAppBuild(
  port: number | undefined = 1337,
): { server: Deno.HttpServer<Deno.NetAddr>; clients: Map<string, WebSocket> } {
  const clients = new Map<string, WebSocket>();
  const clientScriptPath = `${import.meta.dirname}\\Client.js`;
  const server = Deno.serve({ port }, async (request: Request) => {
    if (request.headers.get("upgrade") !== "websocket") {
      return new Response((await Deno.open(clientScriptPath)).readable, {
        headers: { ["content-type"]: "application/javascript" },
      });
    }
    const { response, socket } = Deno.upgradeWebSocket(request);
    const id = crypto.randomUUID();
    socket.onopen = () => clients.set(id, socket);
    socket.onclose = () => clients.delete(id);
    socket.onerror = () => socket.close();
    return response;
  });
  return { server, clients };
}
