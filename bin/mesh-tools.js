#!/usr/bin/env node
/**
 * mesh-tools CLI
 *
 * Entrypoint for the mesh-tools toolkit. It exposes --help / --version and an
 * `init` command that points to the per-component wiring guides; an automated
 * installer is planned but not promised.
 *
 * No runtime dependencies by design.
 */

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const pkg = JSON.parse(
  readFileSync(join(__dirname, "..", "package.json"), "utf8")
);

const HELP = `mesh-tools ${pkg.version} — ${pkg.description}

Usage:
  mesh-tools <command> [options]

Commands:
  init        Print the per-component wiring guides (automated setup is planned)
  help        Show this help
  version     Show version

Options:
  -h, --help     Show this help
  -v, --version  Show version

Docs & source: https://github.com/r-zuriel/mesh-tools
`;

function main(argv) {
  const args = argv.slice(2);
  const cmd = args[0];

  if (args.includes("-v") || args.includes("--version") || cmd === "version") {
    process.stdout.write(`${pkg.version}\n`);
    return 0;
  }

  if (!cmd || args.includes("-h") || args.includes("--help") || cmd === "help") {
    process.stdout.write(HELP);
    return 0;
  }

  switch (cmd) {
    case "init":
      process.stdout.write(
        "init: automated wiring is not implemented yet — setup is manual and documented.\n" +
          "\n" +
          "  1. Visibility hooks : src/hooks/README.md  (copy scripts + settings.json wiring)\n" +
          "  2. Mesh bus         : src/mesh/README.md   (PATH + mesh-init.sh init)\n" +
          "  3. Methods          : src/methods/README.md (read & copy templates)\n" +
          "\n" +
          "Full walkthrough: docs/INSTALL.md\n"
      );
      return 0;
    default:
      process.stderr.write(`Unknown command: ${cmd}\n\n${HELP}`);
      return 1;
  }
}

process.exit(main(process.argv));
