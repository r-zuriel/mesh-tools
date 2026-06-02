#!/usr/bin/env node
/**
 * mesh-tools CLI
 *
 * Entrypoint for the mesh-tools toolkit. In this scaffold (F1) it exposes
 * --help / --version and an `init` stub. Component installers (hooks, mesh,
 * methods) are wired up in later versions.
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
  init        Scaffold hooks + mesh bus into ~/.claude (interactive, non-destructive)
  help        Show this help
  version     Show version

Options:
  -h, --help     Show this help
  -v, --version  Show version

Status: 0.x experimental. See https://github.com/r-zuriel/mesh-tools
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
        "init: not yet implemented in this version.\n" +
          "Component installers ship starting in v0.1.0 (visibility hooks).\n" +
          "Track progress: https://github.com/r-zuriel/mesh-tools\n"
      );
      return 0;
    default:
      process.stderr.write(`Unknown command: ${cmd}\n\n${HELP}`);
      return 1;
  }
}

process.exit(main(process.argv));
