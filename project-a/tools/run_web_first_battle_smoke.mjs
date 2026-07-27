#!/usr/bin/env node

import { spawn } from "node:child_process";
import { createServer } from "node:http";
import { createReadStream } from "node:fs";
import { mkdir, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, extname, join, normalize, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { once } from "node:events";

const TOOLS_DIR = dirname(fileURLToPath(import.meta.url));
const PROJECT_DIR = resolve(TOOLS_DIR, "..");
const BUILD_DIR = resolve(PROJECT_DIR, "build/web");
const EVIDENCE_DIR = resolve(PROJECT_DIR, "artifacts");
const CHROME = process.env.GODOT_WEB_SMOKE_CHROME
	?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const VIEWPORT = { width: 844, height: 390 };
const MIME = {
	".html": "text/html; charset=utf-8",
	".js": "text/javascript; charset=utf-8",
	".json": "application/json; charset=utf-8",
	".wasm": "application/wasm",
	".pck": "application/octet-stream",
	".png": "image/png",
	".svg": "image/svg+xml",
};

class CdpSession {
	constructor(url) {
		this.socket = new WebSocket(url);
		this.serial = 0;
		this.pending = new Map();
		this.listeners = new Map();
		this.socket.addEventListener("message", (event) => {
			const message = JSON.parse(String(event.data));
			if (message.id && this.pending.has(message.id)) {
				const { accept, reject } = this.pending.get(message.id);
				this.pending.delete(message.id);
				if (message.error) reject(new Error(JSON.stringify(message.error)));
				else accept(message.result ?? {});
				return;
			}
			for (const listener of this.listeners.get(message.method) ?? []) {
				listener(message.params ?? {});
			}
		});
	}

	async open() {
		if (this.socket.readyState !== WebSocket.OPEN) await once(this.socket, "open");
	}

	on(method, listener) {
		const listeners = this.listeners.get(method) ?? [];
		listeners.push(listener);
		this.listeners.set(method, listeners);
	}

	send(method, params = {}) {
		const id = ++this.serial;
		return new Promise((accept, reject) => {
			this.pending.set(id, { accept, reject });
			this.socket.send(JSON.stringify({ id, method, params }));
		});
	}

	close() {
		this.socket.close();
	}
}

function contentPath(urlPath) {
	const decoded = decodeURIComponent(urlPath.split("?")[0]);
	const relative = decoded === "/" ? "index.html" : decoded.replace(/^\/+/, "");
	const candidate = resolve(BUILD_DIR, normalize(relative));
	if (!candidate.startsWith(`${BUILD_DIR}/`) && candidate !== BUILD_DIR) {
		throw new Error("path traversal rejected");
	}
	return candidate;
}

async function startServer() {
	const server = createServer(async (request, response) => {
		try {
			const path = contentPath(request.url ?? "/");
			const info = await stat(path);
			if (!info.isFile()) throw new Error("not a file");
			response.writeHead(200, {
				"Content-Type": MIME[extname(path)] ?? "application/octet-stream",
				"Content-Length": info.size,
				"Cache-Control": "no-store",
				"Cross-Origin-Resource-Policy": "same-origin",
			});
			createReadStream(path).pipe(response);
		} catch {
			response.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
			response.end("not found");
		}
	});
	server.listen(0, "127.0.0.1");
	await once(server, "listening");
	const address = server.address();
	if (!address || typeof address === "string") throw new Error("HTTP address unavailable");
	return { server, url: `http://127.0.0.1:${address.port}/index.html` };
}

async function freePort() {
	const server = createServer();
	server.listen(0, "127.0.0.1");
	await once(server, "listening");
	const address = server.address();
	if (!address || typeof address === "string") throw new Error("debug port unavailable");
	await new Promise((accept) => server.close(accept));
	return address.port;
}

async function waitFor(description, callback, timeoutMs = 30000, intervalMs = 100) {
	const deadline = Date.now() + timeoutMs;
	let lastError;
	while (Date.now() < deadline) {
		try {
			const value = await callback();
			if (value) return value;
		} catch (error) {
			lastError = error;
		}
		await new Promise((accept) => setTimeout(accept, intervalMs));
	}
	throw new Error(`${description} timed out${lastError ? `: ${lastError.message}` : ""}`);
}

async function evaluate(cdp, expression) {
	const result = await cdp.send("Runtime.evaluate", {
		expression,
		awaitPromise: true,
		returnByValue: true,
	});
	if (result.exceptionDetails) throw new Error(result.exceptionDetails.text ?? "evaluation failed");
	return result.result?.value;
}

async function touch(cdp, x, y) {
	await cdp.send("Input.dispatchTouchEvent", {
		type: "touchStart",
		touchPoints: [{ x, y, radiusX: 2, radiusY: 2, force: 1 }],
	});
	await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
}

async function screenshot(cdp, name) {
	const result = await cdp.send("Page.captureScreenshot", {
		format: "png",
		captureBeyondViewport: false,
	});
	await writeFile(join(EVIDENCE_DIR, name), Buffer.from(result.data, "base64"));
}

const READ_SAVE_EXPRESSION = `new Promise((resolve, reject) => {
	const openRequest = indexedDB.open("/userfs");
	openRequest.onerror = () => reject(openRequest.error);
	openRequest.onsuccess = () => {
		const database = openRequest.result;
		if (!database.objectStoreNames.contains("FILE_DATA")) {
			database.close();
			resolve(null);
			return;
		}
		const transaction = database.transaction(["FILE_DATA"], "readonly");
		const store = transaction.objectStore("FILE_DATA");
		const keysRequest = store.getAllKeys();
		keysRequest.onerror = () => reject(keysRequest.error);
		keysRequest.onsuccess = () => {
			const saveKey = keysRequest.result.find((key) => String(key).endsWith("/save_v1.json"));
			if (!saveKey) {
				database.close();
				resolve(null);
				return;
			}
			const valueRequest = store.get(saveKey);
			valueRequest.onerror = () => reject(valueRequest.error);
			valueRequest.onsuccess = () => {
				try {
					const value = valueRequest.result?.contents ?? valueRequest.result;
					let bytes;
					if (value instanceof ArrayBuffer) bytes = new Uint8Array(value);
					else if (ArrayBuffer.isView(value)) {
						bytes = new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
					} else if (typeof value === "string") bytes = new TextEncoder().encode(value);
					else throw new Error("unsupported IndexedDB save value");
					const parsed = JSON.parse(new TextDecoder().decode(bytes));
					database.close();
					resolve({
						key: String(saveKey),
						schemaVersion: parsed.schema_version,
						contentVersion: parsed.content_version,
						clearedStages: parsed.stage_progress?.cleared_stages,
						attempts: parsed.attempt_counters,
						onboardingActiveIndex: parsed.onboarding?.active_index,
					});
				} catch (error) {
					database.close();
					reject(error);
				}
			};
		};
	};
})`;

async function continueBattle(cdp, stageId, completion, evidenceName) {
	await touch(cdp, 650, 210);
	await new Promise((accept) => setTimeout(accept, 2200));
	let skillTouches = 0;
	const skillInput = setInterval(() => {
		skillTouches += 1;
		void touch(cdp, 420, 306);
	}, 900);
	try {
		const settledSave = await waitFor(`${stageId} settlement persisted to IndexedDB`, async () => {
			const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
			return save && completion(save) ? save : null;
		}, 90000, 400);
		await new Promise((accept) => setTimeout(accept, 700));
		await screenshot(cdp, evidenceName);
		return { save: settledSave, skillTouches };
	} finally {
		clearInterval(skillInput);
	}
}

async function main() {
	for (const file of ["index.html", "index.js", "index.wasm", "index.pck"]) {
		await readFile(join(BUILD_DIR, file));
	}
	await readFile(CHROME);
	await mkdir(EVIDENCE_DIR, { recursive: true });
	const candidate = JSON.parse(
		await readFile(join(BUILD_DIR, "release-candidate.json"), "utf8"),
	);
	if (candidate.project_dirty !== false || candidate.reproducible !== true) {
		throw new Error("first-battle smoke requires a clean reproducible candidate");
	}

	const profile = await mkdtemp(join(tmpdir(), "godot-first-battle-"));
	const { server, url } = await startServer();
	const debugPort = await freePort();
	const chrome = spawn(CHROME, [
		"--headless=new",
		"--no-first-run",
		"--no-default-browser-check",
		"--disable-background-networking",
		"--disable-background-timer-throttling",
		"--disable-backgrounding-occluded-windows",
		"--disable-renderer-backgrounding",
		"--autoplay-policy=no-user-gesture-required",
		`--remote-debugging-port=${debugPort}`,
		`--user-data-dir=${profile}`,
		`--window-size=${VIEWPORT.width},${VIEWPORT.height}`,
		"about:blank",
	], { stdio: ["ignore", "pipe", "pipe"] });
	let chromeStderr = "";
	chrome.stderr.on("data", (chunk) => { chromeStderr += String(chunk); });
	let cdp;
	try {
		const target = await waitFor("Chrome DevTools page", async () => {
			const response = await fetch(`http://127.0.0.1:${debugPort}/json/list`);
			if (!response.ok) return null;
			const values = await response.json();
			return values.find((value) => value.type === "page");
		});
		cdp = new CdpSession(target.webSocketDebuggerUrl);
		await cdp.open();

		const exceptions = [];
		const consoleErrors = [];
		const failedRequests = [];
		const requestUrls = new Map();
		cdp.on("Runtime.exceptionThrown", ({ exceptionDetails }) => {
			exceptions.push(exceptionDetails?.text ?? "uncaught exception");
		});
		cdp.on("Runtime.consoleAPICalled", ({ type, args }) => {
			if (type === "error") {
				consoleErrors.push(args.map((arg) => arg.value ?? arg.description).join(" "));
			}
		});
		cdp.on("Network.requestWillBeSent", ({ requestId, request }) => {
			requestUrls.set(requestId, request?.url ?? "");
		});
		cdp.on("Network.loadingFailed", ({ requestId, errorText, canceled }) => {
			if (!canceled) failedRequests.push({ url: requestUrls.get(requestId) ?? "", errorText });
		});
		await Promise.all([
			cdp.send("Runtime.enable"),
			cdp.send("Page.enable"),
			cdp.send("Network.enable"),
			cdp.send("Emulation.setDeviceMetricsOverride", {
				...VIEWPORT,
				deviceScaleFactor: 1,
				mobile: false,
			}),
			cdp.send("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 5 }),
		]);

		const startedAt = Date.now();
		await cdp.send("Page.navigate", { url });
		await waitFor("Godot WebGL2 canvas boot", async () => evaluate(cdp, `(() => {
			const canvas = document.querySelector("canvas");
			const text = document.body?.innerText ?? "";
			if (text.includes("WebGL2") && text.includes("missing")) throw new Error(text.trim());
			return document.readyState === "complete"
				&& !document.getElementById("status")
				&& canvas?.width === ${VIEWPORT.width}
				&& canvas?.height === ${VIEWPORT.height};
		})()`), 30000);
		await new Promise((accept) => setTimeout(accept, 1800));

		// Fresh profile: title -> factory -> the primary 1-1 attack CTA.
		await touch(cdp, 422, 276);
		await new Promise((accept) => setTimeout(accept, 1200));
		const freshSave = await evaluate(cdp, READ_SAVE_EXPRESSION);
		if (
			!freshSave
				|| freshSave.schemaVersion !== 8
				|| freshSave.contentVersion !== "toilet-factory-slg-v2"
				|| !Array.isArray(freshSave.clearedStages)
				|| freshSave.clearedStages.length !== 0
				|| typeof freshSave.attempts !== "object"
		) {
			throw new Error(`expected a fresh playable save: ${JSON.stringify(freshSave)}`);
		}
		await touch(cdp, 630, 323);
		await new Promise((accept) => setTimeout(accept, 2500));
		await screenshot(cdp, "browser-first-battle-844x390.png");

		// Exercise the real hero-card input throughout the useful battle window.
		// Repeated touches are intentional: the command is accepted only when energy is ready.
		let skillTouches = 0;
		const skillInput = setInterval(() => {
			skillTouches += 1;
			void touch(cdp, 420, 306);
		}, 900);
		const stopSkillInput = setTimeout(() => clearInterval(skillInput), 42000);

		const settledSave = await waitFor("stage 1-1 settlement persisted to IndexedDB", async () => {
			const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
			return save?.clearedStages?.includes("stage_1_1") ? save : null;
		}, 90000, 400);
		clearInterval(skillInput);
		clearTimeout(stopSkillInput);
		await new Promise((accept) => setTimeout(accept, 700));
		await screenshot(cdp, "browser-first-battle-result-844x390.png");

		const stage12 = await continueBattle(
			cdp,
			"stage_1_2",
			(save) => save.clearedStages?.includes("stage_1_2"),
			"browser-first-session-stage-1-2-result-844x390.png",
		);
		const stage13 = await continueBattle(
			cdp,
			"stage_1_3",
			(save) => save.clearedStages?.includes("stage_1_3"),
			"browser-first-session-stage-1-3-result-844x390.png",
		);
		const firstWall = await continueBattle(
			cdp,
			"stage_1_4",
			(save) => Number(save.attempts?.stage_1_4 ?? 0) === 1
				&& !save.clearedStages?.includes("stage_1_4")
				&& Number(save.onboardingActiveIndex ?? -1) >= 3,
			"browser-first-wall-defeat-844x390.png",
		);

		const knownTeardownLines = new Set([
			'ERROR: Condition "!is_inside_tree()" is true. Returning: false',
			"   at: can_process (scene/main/node.cpp:902)",
		]);
		const unexpectedConsoleErrors = consoleErrors.filter((line) => !knownTeardownLines.has(line));
		if (exceptions.length || unexpectedConsoleErrors.length || failedRequests.length) {
			throw new Error(`runtime errors: ${JSON.stringify({
				exceptions,
				consoleErrors: unexpectedConsoleErrors,
				failedRequests,
			})}`);
		}
		const browserVersion = await cdp.send("Browser.getVersion");
		console.log("WEB_FIRST_WALL_SMOKE_PASS");
		console.log(JSON.stringify({
			candidate: {
				revision: candidate.revision,
				version: candidate.version,
				godotVersion: candidate.godot_version,
			},
			browser: browserVersion.product,
			viewport: VIEWPORT,
			journey: "fresh profile through first stage_1_4 defeat",
			openingStageCleared: true,
			attempts: settledSave.attempts.stage_1_1,
			firstWallReached: true,
			firstWallOutcome: "defeat",
			firstWallAttempts: firstWall.save.attempts.stage_1_4,
			clearedStages: firstWall.save.clearedStages,
			skillCardTouchInputs: skillTouches
				+ stage12.skillTouches
				+ stage13.skillTouches
				+ firstWall.skillTouches,
			elapsedMs: Date.now() - startedAt,
			runtimeExceptions: exceptions.length,
			unexpectedConsoleErrors: unexpectedConsoleErrors.length,
			failedRequests: failedRequests.length,
			evidence: [
				"artifacts/browser-first-battle-844x390.png",
				"artifacts/browser-first-battle-result-844x390.png",
				"artifacts/browser-first-session-stage-1-2-result-844x390.png",
				"artifacts/browser-first-session-stage-1-3-result-844x390.png",
				"artifacts/browser-first-wall-defeat-844x390.png",
			],
		}, null, 2));
	} finally {
		cdp?.close();
		chrome.kill("SIGTERM");
		await Promise.race([
			once(chrome, "exit"),
			new Promise((accept) => setTimeout(accept, 3000)),
		]);
		await new Promise((accept) => server.close(accept));
		await rm(profile, { recursive: true, force: true });
		if (chrome.exitCode && chrome.exitCode !== 0 && !chrome.killed) {
			throw new Error(`Chrome exited ${chrome.exitCode}: ${chromeStderr}`);
		}
	}
}

main().catch((error) => {
	console.error("WEB_FIRST_WALL_SMOKE_FAIL");
	console.error(error?.stack ?? String(error));
	process.exitCode = 1;
});
