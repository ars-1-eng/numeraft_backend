import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here=dirname(fileURLToPath(import.meta.url))

export const HANDLERS=JSON.parse(
    await readFile(join(here,"handlers.json"),"utf8")

)
