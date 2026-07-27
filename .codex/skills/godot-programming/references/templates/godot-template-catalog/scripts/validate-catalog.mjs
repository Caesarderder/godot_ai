#!/usr/bin/env node

import { access, readFile, readdir } from "node:fs/promises";
import { basename, dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const skillRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const projectRoot = join(skillRoot, "assets", "catalog-project");
const recipeCatalogRoot = join(projectRoot, "recipes");
const projectSkillsRoot = resolve(skillRoot, "..");
const catalog = JSON.parse(await readFile(join(skillRoot, "catalog.json"), "utf8"));
const manifestSchema = JSON.parse(
  await readFile(join(skillRoot, "schemas", "recipe-manifest.schema.json"), "utf8"),
);
const routingText = (
  await Promise.all(
    (await readdir(join(skillRoot, "references")))
      .filter((name) => name.endsWith("-recipes.md"))
      .map((name) => readFile(join(skillRoot, "references", name), "utf8")),
  )
).join("\n");
const expectedTarget = {
  engine: "Godot 4.6.x",
  language: "GDScript",
  platform: "Web",
  renderer: "Compatibility",
  threading: "single",
};
const expectedOwners = new Set([
  "godot-project-setup",
  "godot-architecture",
  "resource-pattern",
  "save-load",
  "state-machine",
  "combat-system",
  "godot-ui",
  "responsive-ui",
  "godot-testing",
]);

assert(catalog.version === 1, "catalog version must be 1");
assert(JSON.stringify(catalog.target) === JSON.stringify(expectedTarget), "catalog target drifted");
assert(Array.isArray(catalog.recipes) && catalog.recipes.length === 12, "catalog must contain 12 recipes");
assert(new Set(catalog.recipes).size === catalog.recipes.length, "recipe paths must be unique");

const ids = new Set();
for (const recipePath of catalog.recipes) {
  const recipeRoot = resolveInside(recipeCatalogRoot, recipePath, "recipe path");
  const manifest = JSON.parse(await readFile(join(recipeRoot, "manifest.json"), "utf8"));
  validateSchema(manifest, manifestSchema, `${recipePath} manifest`);
  assert(!ids.has(manifest.id), `duplicate recipe id: ${manifest.id}`);
  ids.add(manifest.id);
  assert(
    manifest.id === `${manifest.category}.${basename(recipePath)}`,
    `${recipePath} id must match its catalog path`,
  );
  assert(manifest.category === recipePath.split("/", 1)[0], `${recipePath} category mismatch`);
  assert(expectedOwners.has(manifest.canonical_owner), `${recipePath} has an unknown canonical owner`);
  await assertExists(join(projectSkillsRoot, manifest.canonical_owner, "SKILL.md"));
  assert(JSON.stringify(manifest.target) === JSON.stringify(expectedTarget), `${recipePath} target drifted`);

  const readme = await readFile(join(recipeRoot, "README.md"), "utf8");
  assert(readme.startsWith("# "), `${recipePath} README must start with a title`);
  assert(
    routingText.includes(`recipes/${recipePath}/README.md`),
    `${recipePath} is missing from its progressive-disclosure recipe route`,
  );

  assert(new Set(manifest.files).size === manifest.files.length, `${recipePath} files contain duplicates`);
  const declaredFiles = [...new Set([...manifest.files, manifest.demo_scene, manifest.test_script])];
  for (const relativePath of declaredFiles) {
    await assertExists(resolveInside(recipeRoot, relativePath, `${recipePath} declared path`));
  }
  const actualFiles = (await listFiles(recipeRoot))
    .filter((path) => !["README.md", "manifest.json"].includes(path) && !path.endsWith(".uid"))
    .sort();
  assert(
    JSON.stringify(actualFiles) === JSON.stringify([...declaredFiles].sort()),
    `${recipePath} declared files do not close over its source artifacts`,
  );
}

console.log(`[OK] validated ${catalog.recipes.length} Godot micro-recipes`);

function resolveInside(root, value, label) {
  assert(typeof value === "string" && value.length > 0, `${label} must be non-empty text`);
  const normalized = value.replaceAll("\\", "/");
  assert(!normalized.startsWith("/") && !normalized.split("/").includes(".."), `${label} must stay relative`);
  const resolved = resolve(root, normalized);
  const child = resolved.slice(root.length);
  assert(child === "" || child.startsWith(sep), `${label} escapes its root`);
  return resolved;
}

async function listFiles(root, current = root) {
  const files = [];
  for (const entry of await readdir(current, { withFileTypes: true })) {
    const path = join(current, entry.name);
    if (entry.isDirectory()) files.push(...(await listFiles(root, path)));
    else if (entry.isFile()) files.push(relative(root, path).replaceAll("\\", "/"));
    else throw new Error(`${path} must be a regular file`);
  }
  return files;
}

function validateSchema(value, schema, label) {
  if (Object.hasOwn(schema, "const")) {
    assert(Object.is(value, schema.const), `${label} must equal ${JSON.stringify(schema.const)}`);
  }
  if (schema.enum) assert(schema.enum.includes(value), `${label} is not an allowed value`);
  if (schema.type === "object") {
    assert(value !== null && typeof value === "object" && !Array.isArray(value), `${label} must be an object`);
    for (const required of schema.required ?? []) {
      assert(Object.hasOwn(value, required), `${label}.${required} is required`);
    }
    if (schema.additionalProperties === false) {
      for (const key of Object.keys(value)) {
        assert(Object.hasOwn(schema.properties ?? {}, key), `${label}.${key} is not allowed`);
      }
    }
    for (const [key, propertySchema] of Object.entries(schema.properties ?? {})) {
      if (Object.hasOwn(value, key)) validateSchema(value[key], propertySchema, `${label}.${key}`);
    }
  } else if (schema.type === "array") {
    assert(Array.isArray(value), `${label} must be an array`);
    if (schema.minItems !== undefined) assert(value.length >= schema.minItems, `${label} is too short`);
    for (const [index, item] of value.entries()) {
      validateSchema(item, schema.items ?? {}, `${label}[${index}]`);
    }
  } else if (schema.type === "string") {
    assert(typeof value === "string", `${label} must be text`);
    if (schema.minLength !== undefined) assert(value.length >= schema.minLength, `${label} is too short`);
    if (schema.pattern) assert(new RegExp(schema.pattern).test(value), `${label} has an invalid format`);
  } else if (schema.type === "boolean") {
    assert(typeof value === "boolean", `${label} must be boolean`);
  }
}

async function assertExists(path) {
  await access(path);
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}
