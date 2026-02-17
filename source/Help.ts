export type EmptyObject = Record<PropertyKey, never>;

export function parseFlag(args: Array<string>, key: string) {
  const prefix = `--${key.toLowerCase()}=`;
  const flag = args.find((arg) => arg.startsWith(prefix));
  return flag ? flag.replace(prefix, "") : undefined;
}

export function watchFiles(
  paths: Array<string>,
  onEvent: (event: Deno.FsEvent) => void,
  isRelevant: (event: Deno.FsEvent) => boolean = (_) => true,
  timeoutMilliseconds = 100,
): { watcher: Deno.FsWatcher; didExit: Promise<void> } {
  const watcher = Deno.watchFs(paths);
  const didExit = new Promise<void>((resolve) =>
    (async function () {
      let id = undefined;
      for await (const event of watcher) {
        if (isRelevant(event)) {
          if (id) clearTimeout(id);
          id = setTimeout(() => onEvent(event), timeoutMilliseconds);
        }
      }
      resolve();
    })()
  );
  return { watcher, didExit };
}
