import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";

const root = resolve(new URL("..", import.meta.url).pathname);
const sourcePath = resolve(root, "apps/api/.env");
const targetPath = resolve(root, "apps/mobile/.env");
const keys = ["SUPABASE_URL", "SUPABASE_ANON_KEY", "API_BASE_URL"];
const defaults = {
  API_BASE_URL: "https://swarnalekh-erp-api.vercel.app/api/v1",
};

if (!existsSync(sourcePath)) {
  throw new Error("apps/api/.env was not found");
}

const values = parseEnv(readFileSync(sourcePath, "utf8"));
const output = keys
  .map((key) => `${key}=${values[key] ?? defaults[key] ?? ""}`)
  .join("\n");

writeFileSync(targetPath, `${output}\n`);
console.log("Wrote apps/mobile/.env");

function parseEnv(contents) {
  const result = {};
  for (const rawLine of contents.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#") || !line.includes("=")) continue;
    const key = line.slice(0, line.indexOf("=")).trim();
    const value = line.slice(line.indexOf("=") + 1).trim();
    result[key] = unquote(value);
  }
  return result;
}

function unquote(value) {
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    return value.slice(1, -1);
  }
  return value;
}
