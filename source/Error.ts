export enum Error {
  NO_ELM_JSON = "no elm.json found",
  INVALID_ELM_JSON = "invalid elm.json",
  NO_SRC_MOD = "no source module",
  ELM_ERR = "elm make error",
  PKG_UNSUPPORTED = "packages are unsupported",
  INVALID_ARGS = "invalid arguments",
  BUNDLE_ERR = "deno bundle error",
}

export function toErrorMessage(error: Error): string {
  switch (error) {
    default:
      return `Something unexpected happened: ${error}`;
  }
}
