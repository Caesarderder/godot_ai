#!/usr/bin/env node

import { lstat, readFile, readdir } from "node:fs/promises";
import { extname, join, resolve } from "node:path";
import process from "node:process";

const MAX_FILE_BYTES = 64 * 1024;
const MAX_ELEMENTS = 512;
const MAX_PATH_COMMANDS = 4096;
const MAX_VIEWBOX_EDGE = 4096;

const ALLOWED_ELEMENTS = new Set([
  "svg",
  "g",
  "path",
  "rect",
  "circle",
  "ellipse",
  "line",
  "polyline",
  "polygon",
  "defs",
  "linearGradient",
  "radialGradient",
  "stop",
  "clipPath",
  "mask",
]);

const DRAWABLE_ELEMENTS = new Set([
  "path",
  "rect",
  "circle",
  "ellipse",
  "line",
  "polyline",
  "polygon",
]);

const ALLOWED_ATTRIBUTES = new Set([
  "xmlns",
  "viewBox",
  "width",
  "height",
  "preserveAspectRatio",
  "id",
  "d",
  "x",
  "y",
  "x1",
  "y1",
  "x2",
  "y2",
  "cx",
  "cy",
  "r",
  "rx",
  "ry",
  "points",
  "fill",
  "fill-opacity",
  "fill-rule",
  "stroke",
  "stroke-width",
  "stroke-opacity",
  "stroke-linecap",
  "stroke-linejoin",
  "stroke-miterlimit",
  "stroke-dasharray",
  "stroke-dashoffset",
  "opacity",
  "transform",
  "vector-effect",
  "shape-rendering",
  "clip-rule",
  "clip-path",
  "mask",
  "offset",
  "stop-color",
  "stop-opacity",
  "gradientUnits",
  "gradientTransform",
  "spreadMethod",
  "fx",
  "fy",
]);

const FORBIDDEN_ELEMENT_PATTERN =
  /<\s*(?:script|foreignObject|image|text|use|style|animate|animateMotion|animateTransform|set|a|audio|video|iframe|object|embed|filter)\b/iu;
const EXTERNAL_REFERENCE_PATTERN = /(?:javascript|data|https?|file|ftp):/iu;
const XML_DECLARATION_PATTERN =
  /^<\?xml\s+version=(?:"1\.0"|'1\.0')(?:\s+encoding=(?:"UTF-8"|'UTF-8'))?\s*\?>/u;
const TAG_PATTERN = /<\s*(\/?)\s*([A-Za-z][A-Za-z0-9]*)\b([^<>]*?)(\/?)\s*>/gu;
const ATTRIBUTE_PATTERN = /([A-Za-z_:][A-Za-z0-9_.:-]*)\s*=\s*(?:"([^"]*)"|'([^']*)')/gu;

class SvgValidationError extends Error {}

async function main() {
  const inputs = process.argv.slice(2);
  if (inputs.length === 1 && inputs[0] === "--self-test") {
    runSelfTest();
    return;
  }
  if (inputs.length === 0) {
    process.stderr.write(
      "Usage: node validate-svg.mjs <svg-file-or-directory> [...more-paths]\n" +
        "       node validate-svg.mjs --self-test\n",
    );
    process.exitCode = 2;
    return;
  }

  const files = await collectSvgFiles(inputs);
  if (files.length === 0) throw new SvgValidationError("no SVG files found in the given paths");

  let failed = false;
  for (const file of files) {
    try {
      const source = await readFile(file);
      const result = validateSvg(source, file);
      process.stdout.write(
        `[OK] ${file} (${result.elements} elements, ${result.pathCommands} path commands, ${source.byteLength} bytes)\n`,
      );
    } catch (error) {
      failed = true;
      const message = error instanceof Error ? error.message : String(error);
      process.stderr.write(`[FAIL] ${file}: ${message}\n`);
    }
  }
  if (failed) process.exitCode = 1;
}

async function collectSvgFiles(inputs) {
  const files = [];
  for (const input of inputs) await collectPath(resolve(input), files);
  return [...new Set(files)].sort();
}

async function collectPath(path, files) {
  const info = await lstat(path);
  if (info.isSymbolicLink())
    throw new SvgValidationError(`symbolic links are not allowed: ${path}`);
  if (info.isFile()) {
    if (extname(path).toLowerCase() !== ".svg") {
      throw new SvgValidationError(`expected an .svg file: ${path}`);
    }
    files.push(path);
    return;
  }
  if (!info.isDirectory()) throw new SvgValidationError(`unsupported path type: ${path}`);
  const entries = await readdir(path, { withFileTypes: true });
  for (const entry of entries.sort((left, right) => left.name.localeCompare(right.name))) {
    const child = join(path, entry.name);
    if (entry.isSymbolicLink())
      throw new SvgValidationError(`symbolic links are not allowed: ${child}`);
    if (entry.isDirectory()) await collectPath(child, files);
    else if (entry.isFile() && extname(entry.name).toLowerCase() === ".svg") files.push(child);
  }
}

function validateSvg(buffer, label = "<svg>") {
  if (buffer.byteLength === 0) throw new SvgValidationError("file is empty");
  if (buffer.byteLength > MAX_FILE_BYTES) {
    throw new SvgValidationError(`file exceeds ${MAX_FILE_BYTES} bytes`);
  }
  if (buffer.includes(0)) throw new SvgValidationError("NUL bytes are not allowed");

  let source;
  try {
    source = new TextDecoder("utf-8", { fatal: true }).decode(buffer);
  } catch {
    throw new SvgValidationError("file must contain valid UTF-8");
  }
  source = source.replace(/^\uFEFF/u, "").trim();
  if (source.startsWith("<?xml")) {
    const declaration = source.match(XML_DECLARATION_PATTERN)?.[0];
    if (!declaration) throw new SvgValidationError("unsupported XML declaration");
    source = source.slice(declaration.length).trimStart();
  }
  reject(FORBIDDEN_ELEMENT_PATTERN.test(source), "contains a forbidden SVG element");
  reject(
    /<!DOCTYPE|<!ENTITY|<!--|<\?/iu.test(source),
    "DOCTYPE, entities, comments, and processing instructions are forbidden",
  );
  reject(containsForbiddenControlCharacter(source), "contains control characters");

  const stack = [];
  const ids = new Set();
  const localReferences = [];
  let rootSeen = false;
  let rootClosed = false;
  let elements = 0;
  let drawables = 0;
  let pathCommands = 0;
  let cursor = 0;
  TAG_PATTERN.lastIndex = 0;
  let match = TAG_PATTERN.exec(source);
  while (match !== null) {
    const between = source.slice(cursor, match.index);
    reject(between.trim().length > 0, "text nodes or malformed markup are not allowed");
    cursor = TAG_PATTERN.lastIndex;

    const closing = match[1] === "/";
    const name = match[2];
    const rawAttributes = match[3] ?? "";
    const selfClosing = match[4] === "/";
    reject(!ALLOWED_ELEMENTS.has(name), `element <${name}> is not allowed`);

    if (closing) {
      reject(selfClosing || rawAttributes.trim().length > 0, `closing tag </${name}> is malformed`);
      const expected = stack.pop();
      reject(expected !== name, `closing tag </${name}> does not match <${expected ?? "none"}>`);
      if (name === "svg") rootClosed = true;
      match = TAG_PATTERN.exec(source);
      continue;
    }

    reject(rootClosed, "content exists after the root </svg>");
    if (!rootSeen) {
      reject(name !== "svg", "the first element must be <svg>");
      rootSeen = true;
    } else {
      reject(name === "svg", "nested or multiple <svg> elements are not allowed");
    }

    elements += 1;
    reject(elements > MAX_ELEMENTS, `contains more than ${MAX_ELEMENTS} elements`);
    if (DRAWABLE_ELEMENTS.has(name)) drawables += 1;

    const attributes = parseAttributes(rawAttributes, name);
    if (name === "svg") validateRootAttributes(attributes);
    else {
      reject(attributes.has("xmlns"), "xmlns is only allowed on the root <svg>");
      reject(attributes.has("viewBox"), "viewBox is only allowed on the root <svg>");
      reject(
        attributes.has("preserveAspectRatio"),
        "preserveAspectRatio is only allowed on the root <svg>",
      );
    }
    for (const [attributeName, value] of attributes) {
      reject(/^on/iu.test(attributeName), `event attribute ${attributeName} is forbidden`);
      reject(
        !ALLOWED_ATTRIBUTES.has(attributeName),
        `attribute ${attributeName} is not allowed on <${name}>`,
      );
      reject(
        /[<>&]/u.test(value),
        `attribute ${attributeName} contains forbidden markup or entities`,
      );
      reject(
        attributeName !== "xmlns" && EXTERNAL_REFERENCE_PATTERN.test(value),
        `attribute ${attributeName} contains an external URI`,
      );
      reject(
        /url\s*\(/iu.test(value) && !/^url\(#[A-Za-z_][A-Za-z0-9_.-]*\)$/u.test(value),
        `attribute ${attributeName} contains a non-local url()`,
      );
      const reference = value.match(/^url\(#([A-Za-z_][A-Za-z0-9_.-]*)\)$/u)?.[1];
      if (reference) localReferences.push(reference);
    }

    const id = attributes.get("id");
    if (id) {
      reject(!/^[A-Za-z_][A-Za-z0-9_.-]*$/u.test(id), `invalid id: ${id}`);
      reject(ids.has(id), `duplicate id: ${id}`);
      ids.add(id);
    }
    if (name === "path") {
      const data = attributes.get("d");
      reject(!data, "<path> must contain a non-empty d attribute");
      const invalidPathData = data
        ?.replace(/[MmZzLlHhVvCcSsQqTtAa]/gu, "")
        .replace(/[0-9eE+.,\s-]/gu, "");
      reject((invalidPathData?.length ?? 0) > 0, "<path> d contains invalid characters");
      const commandCount = data?.match(/[MmZzLlHhVvCcSsQqTtAa]/gu)?.length ?? 0;
      reject(commandCount === 0, "<path> d must contain at least one path command");
      pathCommands += commandCount;
      reject(
        pathCommands > MAX_PATH_COMMANDS,
        `contains more than ${MAX_PATH_COMMANDS} path commands`,
      );
    }
    if (!selfClosing) stack.push(name);
    else if (name === "svg") rootClosed = true;
    match = TAG_PATTERN.exec(source);
  }

  reject(
    source.slice(cursor).trim().length > 0,
    "trailing text or malformed markup is not allowed",
  );
  reject(!rootSeen, "missing <svg> root element");
  reject(stack.length > 0, `unclosed element <${stack.at(-1)}>`);
  reject(!rootClosed, "the root <svg> must be explicitly closed");
  reject(drawables === 0, "SVG contains no drawable elements");
  for (const reference of localReferences)
    reject(!ids.has(reference), `local reference #${reference} does not exist`);

  return { label, elements, pathCommands };
}

function parseAttributes(source, elementName) {
  const attributes = new Map();
  let cursor = 0;
  ATTRIBUTE_PATTERN.lastIndex = 0;
  let match = ATTRIBUTE_PATTERN.exec(source);
  while (match !== null) {
    reject(
      source.slice(cursor, match.index).trim().length > 0,
      `malformed attributes on <${elementName}>`,
    );
    cursor = ATTRIBUTE_PATTERN.lastIndex;
    const name = match[1];
    const value = match[2] ?? match[3] ?? "";
    reject(attributes.has(name), `duplicate attribute ${name} on <${elementName}>`);
    reject(
      name === "href" || name === "xlink:href" || name === "style" || name === "class",
      `attribute ${name} is forbidden`,
    );
    attributes.set(name, value);
    match = ATTRIBUTE_PATTERN.exec(source);
  }
  reject(source.slice(cursor).trim().length > 0, `malformed attributes on <${elementName}>`);
  return attributes;
}

function validateRootAttributes(attributes) {
  reject(
    attributes.get("xmlns") !== "http://www.w3.org/2000/svg",
    "root <svg> must declare the standard xmlns",
  );
  const viewBox = attributes.get("viewBox");
  reject(!viewBox, "root <svg> must declare viewBox");
  const values =
    viewBox
      ?.trim()
      .split(/[\s,]+/u)
      .map(Number) ?? [];
  reject(
    values.length !== 4 || values.some((value) => !Number.isFinite(value)),
    "viewBox must contain four finite numbers",
  );
  const width = values[2] ?? 0;
  const height = values[3] ?? 0;
  reject(width <= 0 || height <= 0, "viewBox width and height must be positive");
  reject(
    width > MAX_VIEWBOX_EDGE || height > MAX_VIEWBOX_EDGE,
    `viewBox edges must not exceed ${MAX_VIEWBOX_EDGE}`,
  );
}

function reject(condition, message) {
  if (condition) throw new SvgValidationError(message);
}

function containsForbiddenControlCharacter(source) {
  for (const character of source) {
    const codePoint = character.codePointAt(0) ?? 0;
    if (
      codePoint === 0x7f ||
      (codePoint >= 0x00 && codePoint <= 0x08) ||
      codePoint === 0x0b ||
      codePoint === 0x0c ||
      (codePoint >= 0x0e && codePoint <= 0x1f)
    ) {
      return true;
    }
  }
  return false;
}

function runSelfTest() {
  const validSamples = [
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><circle cx="16" cy="16" r="12" fill="#4CC9C0"/><path d="M8 16h16" stroke="#2B2430" stroke-width="3"/></svg>',
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><defs><linearGradient id="glow"><stop offset="0" stop-color="#fff"/><stop offset="1" stop-color="#4cc9c0"/></linearGradient></defs><rect x="4" y="4" width="40" height="40" fill="url(#glow)"/></svg>',
  ];
  const invalidSamples = [
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><script>alert(1)</script><circle r="2"/></svg>',
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><image href="https://example.com/a.png"/></svg>',
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><text>Builda</text></svg>',
    '<!DOCTYPE svg><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><circle r="2"/></svg>',
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><!-- comment --><circle r="2"/></svg>',
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 0 32"><circle r="2"/></svg>',
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><circle fill="url(#missing)" r="2"/></svg>',
  ];
  for (const [index, sample] of validSamples.entries()) {
    validateSvg(Buffer.from(sample), `valid-${index}`);
  }
  for (const [index, sample] of invalidSamples.entries()) {
    let rejected = false;
    try {
      validateSvg(Buffer.from(sample), `invalid-${index}`);
    } catch (error) {
      if (error instanceof SvgValidationError) rejected = true;
      else throw error;
    }
    if (!rejected) throw new Error(`self-test invalid sample ${index} was accepted`);
  }
  process.stdout.write(
    `[OK] self-test passed (${validSamples.length} valid, ${invalidSamples.length} invalid)\n`,
  );
}

main().catch((error) => {
  const message = error instanceof Error ? error.message : String(error);
  process.stderr.write(`[FAIL] ${message}\n`);
  process.exitCode = 1;
});
