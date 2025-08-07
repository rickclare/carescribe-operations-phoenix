/* global Bun */
import { parseArgs } from "util";

const DEFAULT_THEME = "carescribe";
const OTHER_THEMES = ["captioned", "talktype"];

const { values } = parseArgs({
  args: Bun.argv,
  options: {
    input: { type: "string" },
    output: { type: "string" },
  },
  strict: false,
});

const nameComparator = (a, b) => a.name.localeCompare(b.name);

const data = await Bun.file(values.input).text();
const collections = JSON.parse(data).collections;

const core = collections.find(({ name }) => name === "Core").modes[0];
const themes = collections.find(({ name }) => name === "Theme").modes;

const output = Bun.file(values.output);

if (await output.exists()) {
  await output.delete();
}

const writer = output.writer();

const writeLightTheme = (name) => writeTheme(`${name}/light`);

const writeDarkTheme = (name) => {
  writer.write("\n    @media (prefers-color-scheme: dark) {\n");
  writeTheme(`${name}/dark`, 3);
  writer.write("    }\n");
};

const writeTheme = (themeName, indent = 2) => {
  writer.write(`${"  ".repeat(indent)}/* theme: ${themeName} */\n`);

  themes
    .find(({ name }) => name === themeName)
    .variables.filter(({ type }) => type === "color")
    .sort(nameComparator)
    .forEach(({ name, value }) => {
      name = name.replaceAll("/", "-").replaceAll("*", "-").replaceAll("(!)", "");

      const color =
        typeof value === "object" ? `var(--${value.name.replaceAll("/", "-")})` : value;

      writer.write(`${"  ".repeat(indent)}--theme-${name}: ${color};\n`);
      writer.flush();
    });
};

writer.write(`\
/*
  This file is auto-generated from a Figma JSON export.
  Instead of editing this file, please execute \`bun build:figma_themes\`
*/

/* see https://tailwindcss.com/docs/theme#referencing-other-variables */
@theme inline {
`);

themes
  .find(({ name }) => name === `${DEFAULT_THEME}/light`)
  .variables.filter((el) => el.type === "color")
  .sort(nameComparator)
  .forEach(({ name }) => {
    name = name.replaceAll("/", "-").replaceAll("*", "-").replaceAll("(!)", "");
    writer.write(`  --color-${name}: var(--theme-${name});\n`);
  });

writer.flush();
writer.write("}\n"); // end `@theme inline`

writer.write(`
@layer theme {
  :root {
    /* core: colours */
`);

core.variables
  .filter(({ type }) => type === "color")
  .sort(nameComparator)
  .forEach(({ name, value }) => {
    writer.write(
      `    --${name.replaceAll("/", "-").replaceAll("*", "-")}: ${value.toLowerCase()};\n`,
    );
  });

writer.write("  }\n"); // end `:root`
writer.flush();

writer.write(`
  :root,
  [data-theme="${DEFAULT_THEME}"] {
`);

writeLightTheme(DEFAULT_THEME);
writeDarkTheme(DEFAULT_THEME);
writer.write("  }\n"); // end `:root, [data-theme="carescribe"]`

OTHER_THEMES.forEach((name) => {
  writer.write(`\n  [data-theme="${name}"] {\n`);
  writeLightTheme(name);
  writeDarkTheme(name);
  writer.write("  }\n");
});

writer.write("}\n\n"); // end `@layer theme`

writer.end();
