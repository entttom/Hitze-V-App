// Copies the committed runtime assets into dist/assets. No network access.
const { cpSync, mkdirSync, rmSync } = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const target = path.join(root, "dist", "assets");
const files = ["push-copy.json", "municipalities.json", "map"];

rmSync(target, { recursive: true, force: true });
mkdirSync(target, { recursive: true });
for (const entry of files) {
  cpSync(path.join(root, "assets", entry), path.join(target, entry), { recursive: true });
}
console.log(`assets_copied ${files.join(", ")} -> dist/assets`);
