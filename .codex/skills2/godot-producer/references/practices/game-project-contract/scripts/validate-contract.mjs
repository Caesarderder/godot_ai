#!/usr/bin/env node

import { access, cp, mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, isAbsolute, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const OWNERS = new Set(["producer", "game-design", "programming", "art", "audio", "qa-release"]);
const STATUSES = new Set([
  "proposed",
  "accepted",
  "implemented",
  "verified",
  "deferred",
  "rejected",
  "drifted",
]);
const REQUIRED_FIELDS = [
  "owner",
  "status",
  "accepted_intent",
  "acceptance_criteria",
  "implementation_reference",
  "verification_evidence",
  "conflict_references",
  "handoffs",
  "handoff_from",
  "handoff_to",
  "handoff_request",
  "handoff_allowed_fields",
  "handoff_blocking",
  "deviation",
  "last_updated",
  "last_verified",
];
const EMPTY = new Set(["", "—", "-", "n/a", "none"]);

function fail(message) {
  throw new Error(message);
}

function present(value) {
  return !EMPTY.has(value.trim().toLowerCase());
}

async function exists(path) {
  try {
    await access(path);
    return true;
  } catch (error) {
    if (error?.code === "ENOENT") return false;
    throw error;
  }
}

function frontmatter(source, path) {
  const match = source.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/u);
  if (!match) fail(`${path}: missing YAML frontmatter`);
  const values = new Map();
  for (const line of match[1].split(/\r?\n/u)) {
    const field = line.match(/^([a-z_]+):\s*(.*?)\s*$/u);
    if (field) values.set(field[1], field[2].replace(/^['"]|['"]$/gu, ""));
  }
  return values;
}

function parseItems(source, path) {
  const headings = [...source.matchAll(/^##\s+(GC-\d{3,}):\s+(.+?)\s*$/gmu)];
  if (headings.length === 0) fail(`${path}: contract must contain at least one GC-NNN item`);
  const items = new Map();
  for (let index = 0; index < headings.length; index += 1) {
    const match = headings[index];
    const id = match[1];
    if (items.has(id)) fail(`${path}: duplicate contract item ID ${id}`);
    const start = (match.index ?? 0) + match[0].length;
    const end = headings[index + 1]?.index ?? source.length;
    const body = source.slice(start, end);
    const fields = new Map();
    for (const field of body.matchAll(/^-\s+([a-z_]+):\s*(.*?)\s*$/gmu)) {
      if (fields.has(field[1])) fail(`${path} ${id}: duplicate field ${field[1]}`);
      fields.set(field[1], field[2]);
    }
    for (const required of REQUIRED_FIELDS) {
      if (!fields.has(required)) fail(`${path} ${id}: missing field ${required}`);
    }
    items.set(id, { id, title: match[2], fields });
  }
  return items;
}

async function validateItem(item, allIds, path, projectRoot) {
  const value = (field) => item.fields.get(field) ?? "";
  const owner = value("owner");
  const status = value("status");
  if (!OWNERS.has(owner)) fail(`${path} ${item.id}: invalid owner ${owner}`);
  if (!STATUSES.has(status)) fail(`${path} ${item.id}: invalid status ${status}`);
  if (!/^\d{4}-\d{2}-\d{2}$/u.test(value("last_updated"))) {
    fail(`${path} ${item.id}: last_updated must use YYYY-MM-DD`);
  }
  if (["proposed", "accepted", "implemented", "verified", "drifted"].includes(status)) {
    if (!present(value("accepted_intent"))) {
      fail(`${path} ${item.id}: ${status} requires intent`);
    }
  }
  if (["accepted", "implemented", "verified", "drifted"].includes(status)) {
    if (!present(value("accepted_intent")) || !present(value("acceptance_criteria"))) {
      fail(`${path} ${item.id}: ${status} requires accepted intent and acceptance criteria`);
    }
  }
  if (["implemented", "verified"].includes(status)) {
    const reference = value("implementation_reference");
    if (!present(reference))
      fail(`${path} ${item.id}: ${status} requires implementation_reference`);
    if (/(^|[^0-9]):\d+(?:-\d+)?(?:$|[^0-9])/u.test(reference)) {
      fail(`${path} ${item.id}: implementation_reference must not use fixed line numbers`);
    }
    if (isAbsolute(reference)) {
      fail(`${path} ${item.id}: implementation_reference must be repository-relative`);
    }
    if (/^[a-z][a-z0-9+.-]*:/iu.test(reference)) {
      fail(`${path} ${item.id}: implementation_reference must not use a URL or URI`);
    }
    const referencePath = reference.split("#", 1)[0]?.trim() ?? "";
    const resolvedReference = resolve(projectRoot, referencePath);
    const relativeReference = relative(projectRoot, resolvedReference);
    if (
      referencePath.length === 0 ||
      relativeReference === ".." ||
      relativeReference.startsWith(`..${sep}`) ||
      isAbsolute(relativeReference)
    ) {
      fail(`${path} ${item.id}: implementation_reference escapes the project root`);
    }
    if (!(await exists(resolvedReference))) {
      fail(`${path} ${item.id}: implementation_reference does not exist`);
    }
  }
  if (status === "verified") {
    if (!present(value("verification_evidence"))) {
      fail(`${path} ${item.id}: verified requires verification_evidence`);
    }
    if (!/^\d{4}-\d{2}-\d{2}$/u.test(value("last_verified"))) {
      fail(`${path} ${item.id}: verified requires last_verified in YYYY-MM-DD`);
    }
  }
  if (["deferred", "rejected", "drifted"].includes(status) && !present(value("deviation"))) {
    fail(`${path} ${item.id}: ${status} requires a deviation note`);
  }
  const handoffFields = [
    "handoff_from",
    "handoff_to",
    "handoff_request",
    "handoff_allowed_fields",
    "handoff_blocking",
  ];
  const handoffPresent = handoffFields.filter((field) => present(value(field)));
  if (handoffPresent.length > 0 && handoffPresent.length !== handoffFields.length) {
    fail(`${path} ${item.id}: handoff fields must be recorded together`);
  }
  if (handoffPresent.length > 0) {
    if (!OWNERS.has(value("handoff_from")) || !OWNERS.has(value("handoff_to"))) {
      fail(`${path} ${item.id}: handoff source and target must be canonical roles`);
    }
    if (!["true", "false"].includes(value("handoff_blocking"))) {
      fail(`${path} ${item.id}: handoff_blocking must be true or false`);
    }
  }
  if (status === "drifted") {
    if (!present(value("conflict_references"))) {
      fail(`${path} ${item.id}: drifted requires both conflict references`);
    }
    if (handoffPresent.length !== handoffFields.length) {
      fail(`${path} ${item.id}: drifted requires a complete owner handoff`);
    }
  }
  if (present(value("handoffs"))) {
    for (const target of value("handoffs")
      .split(",")
      .map((entry) => entry.trim())) {
      if (!allIds.has(target)) fail(`${path} ${item.id}: unresolved handoff ${target}`);
    }
  }
}

async function validateProject(rawRoot) {
  const projectRoot = resolve(rawRoot);
  const indexPath = resolve(projectRoot, "docs/index.md");
  const contractPath = resolve(projectRoot, "docs/game-contract.md");
  if (!(await exists(indexPath))) fail(`${indexPath}: missing project documentation index`);
  if (!(await exists(contractPath))) fail(`${contractPath}: missing canonical contract`);
  const index = await readFile(indexPath, "utf8");
  const contract = await readFile(contractPath, "utf8");
  const contractLink = [...index.matchAll(/\]\(([^)#?]*game-contract\.md)\)/gu)].at(0)?.[1];
  if (!contractLink) fail(`${indexPath}: must link to the canonical game-contract.md`);
  if (resolve(dirname(indexPath), decodeURIComponent(contractLink)) !== contractPath) {
    fail(`${indexPath}: game contract link must resolve to docs/game-contract.md`);
  }
  const metadata = frontmatter(contract, contractPath);
  if (!/^[1-9]\d*$/u.test(metadata.get("contract_version") ?? "")) {
    fail(`${contractPath}: contract_version must be a positive integer`);
  }
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/u.test(metadata.get("project_id") ?? "")) {
    fail(`${contractPath}: project_id must use lowercase kebab-case`);
  }
  if (!/^\d{4}-\d{2}-\d{2}$/u.test(metadata.get("last_updated") ?? "")) {
    fail(`${contractPath}: last_updated must use YYYY-MM-DD`);
  }
  const items = parseItems(contract, contractPath);
  for (const item of items.values()) {
    await validateItem(item, new Set(items.keys()), contractPath, projectRoot);
  }
  return { projectRoot, items: items.size };
}

async function expectFailure(name, mutate) {
  const root = await mkdtemp(join(tmpdir(), "builda-contract-negative-"));
  try {
    await cp(
      resolve(dirname(fileURLToPath(import.meta.url)), "../templates/docs"),
      join(root, "docs"),
      {
        recursive: true,
      },
    );
    await mutate(root);
    try {
      await validateProject(root);
    } catch {
      return;
    }
    fail(`negative probe did not fail: ${name}`);
  } finally {
    await rm(root, { recursive: true, force: true });
  }
}

async function selfTest() {
  const templateRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../templates");
  await validateProject(templateRoot);
  const contract = (root) => join(root, "docs/game-contract.md");
  await expectFailure("duplicate ID", async (root) => {
    const source = await readFile(contract(root), "utf8");
    await writeFile(
      contract(root),
      `${source}\n## GC-001: Duplicate\n${source.split("## GC-001:")[1]}`,
    );
  });
  await expectFailure("accepted without criteria", async (root) => {
    const source = await readFile(contract(root), "utf8");
    await writeFile(
      contract(root),
      source
        .replace("status: proposed", "status: accepted")
        .replace(
          "acceptance_criteria: Replace with observable acceptance criteria.",
          "acceptance_criteria: —",
        ),
    );
  });
  await expectFailure("proposed without intent", async (root) => {
    const source = await readFile(contract(root), "utf8");
    await writeFile(
      contract(root),
      source.replace(
        "accepted_intent: Replace with the proposed player-facing promise.",
        "accepted_intent: —",
      ),
    );
  });
  await expectFailure("implemented without reference", async (root) => {
    const source = await readFile(contract(root), "utf8");
    await writeFile(contract(root), source.replace("status: proposed", "status: implemented"));
  });
  await expectFailure("verified without evidence", async (root) => {
    const source = await readFile(contract(root), "utf8");
    await mkdir(join(root, "scripts"), { recursive: true });
    await writeFile(join(root, "scripts/game.gd"), "extends Node\n");
    await writeFile(
      contract(root),
      source
        .replace("status: proposed", "status: verified")
        .replace("implementation_reference: —", "implementation_reference: scripts/game.gd#run"),
    );
  });
  await expectFailure("unresolved handoff", async (root) => {
    const source = await readFile(contract(root), "utf8");
    await writeFile(contract(root), source.replace("handoffs: —", "handoffs: GC-999"));
  });
  await expectFailure("drifted without conflict and handoff evidence", async (root) => {
    const source = await readFile(contract(root), "utf8");
    await writeFile(
      contract(root),
      source
        .replace("status: proposed", "status: drifted")
        .replace("deviation: —", "deviation: Runtime disagrees with the accepted rule."),
    );
  });
  await expectFailure("implementation path escape", async (root) => {
    const source = await readFile(contract(root), "utf8");
    await writeFile(
      contract(root),
      source
        .replace("status: proposed", "status: implemented")
        .replace("implementation_reference: —", "implementation_reference: ../../outside.gd"),
    );
  });
  await expectFailure("missing implementation path", async (root) => {
    const source = await readFile(contract(root), "utf8");
    await writeFile(
      contract(root),
      source
        .replace("status: proposed", "status: implemented")
        .replace("implementation_reference: —", "implementation_reference: scripts/missing.gd#run"),
    );
  });
  await expectFailure("implementation URL", async (root) => {
    const source = await readFile(contract(root), "utf8");
    await writeFile(
      contract(root),
      source
        .replace("status: proposed", "status: implemented")
        .replace(
          "implementation_reference: —",
          "implementation_reference: https://example.com/game.gd",
        ),
    );
  });
  await expectFailure("index does not reach contract", async (root) => {
    const path = join(root, "docs/index.md");
    const source = await readFile(path, "utf8");
    await writeFile(path, source.replace("(game-contract.md)", "(other.md)"));
  });
  console.log("game project contract validator self-test passed (11 negative probes)");
}

const selfTestMode = process.argv.includes("--self-test");
const root =
  process.argv.find(
    (argument) =>
      !argument.startsWith("--") && argument !== process.argv[0] && argument !== process.argv[1],
  ) ?? ".";
(selfTestMode ? selfTest() : validateProject(root))
  .then((result) => {
    if (!selfTestMode && result) {
      console.log(`game project contract passed: ${result.items} items in ${result.projectRoot}`);
    }
  })
  .catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
