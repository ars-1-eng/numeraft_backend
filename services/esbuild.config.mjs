import { rm, writeFile, mkdir } from "node:fs/promises";
import { build } from "esbuild";
import { HANDLERS } from "./handlers.manifest.mjs";
await rm("dist", { recursive: true, force: true });
const results = await Promise.all(
HANDLERS.map(async (name) => {
const outdir = `dist/${name}`;
await mkdir(outdir, { recursive: true });
const result = await build({
entryPoints: [`src/handlers/${name}.ts`],
outfile: `${outdir}/index.mjs`,
bundle: true,
platform: "node",
target: "node24",
format: "esm",
// Bundle everything, including the AWS SDK. The SDK version shipped
// inside a managed runtime changes without your involvement, so
// relying on it means production runs a version you never tested.
external: [],
// Some dependencies still call require() internally. In ESM output
// that throws "require is not defined". This shim makes it work.
banner: {
js: [
"import { createRequire as __nodeCreateRequire } from 'node:module';",
"const require = __nodeCreateRequire(import.meta.url);",
].join(""),
},
minify: true,
sourcemap: true,
sourcesContent: false,
legalComments: "none",
treeShaking: true,
metafile: true,
logLevel: "warning",
});
// Explicit, not accidental. .mjs is already ESM, but stating it means
// nobody can break the module resolution by changing the extension.
await writeFile(
`${outdir}/package.json`,
`${JSON.stringify({ type: "module" }, null, 2)}\n`
);
const bytes = Object.values(result.metafile.outputs).reduce(
(total, output) => total + output.bytes,
0
);
return { name, kb: Math.round(bytes / 1024) };
})
);
console.log(`Built ${results.length} handler bundle(s):`);
for (const { name, kb } of results) {
console.log(`  ${name.padEnd(20)} ${String(kb).padStart(6)} KB`);
}