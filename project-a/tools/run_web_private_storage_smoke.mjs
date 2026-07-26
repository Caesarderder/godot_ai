#!/usr/bin/env node

import { spawn } from "node:child_process";
import { createServer } from "node:http";
import { createReadStream } from "node:fs";
import { mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, extname, join, normalize, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { once } from "node:events";

const TOOLS_DIR = dirname(fileURLToPath(import.meta.url));
const PROJECT_DIR = resolve(TOOLS_DIR, "..");
const ARTIFACT_DIR = resolve(PROJECT_DIR, "build/web");
const EVIDENCE_DIR = resolve(PROJECT_DIR, "artifacts");
const CHROME = process.env.GODOT_WEB_SMOKE_CHROME
	?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
const BLOCK_INDEXEDDB = process.env.GODOT_WEB_SMOKE_BLOCK_INDEXEDDB === "1";
const MIME = {
	".html": "text/html; charset=utf-8",
	".js": "text/javascript; charset=utf-8",
	".json": "application/json; charset=utf-8",
	".wasm": "application/wasm",
	".pck": "application/octet-stream",
	".png": "image/png",
};

class CdpSession {
	constructor(url) {
		this.socket = new WebSocket(url);
		this.serial = 0;
		this.pending = new Map();
		this.socket.addEventListener("message", (event) => {
			const message = JSON.parse(String(event.data));
			if (!message.id || !this.pending.has(message.id)) return;
			const { accept, reject } = this.pending.get(message.id);
			this.pending.delete(message.id);
			if (message.error) reject(new Error(JSON.stringify(message.error)));
			else accept(message.result ?? {});
		});
	}

	async open() {
		if (this.socket.readyState !== WebSocket.OPEN) await once(this.socket, "open");
	}

	send(method, params = {}, sessionId = undefined) {
		const id = ++this.serial;
		return new Promise((accept, reject) => {
			this.pending.set(id, { accept, reject });
			this.socket.send(JSON.stringify({
				id,
				method,
				params,
				...(sessionId ? { sessionId } : {}),
			}));
		});
	}

	close() {
		this.socket.close();
	}
}

class TargetSession {
	constructor(browser, sessionId) {
		this.browser = browser;
		this.sessionId = sessionId;
	}

	send(method, params = {}) {
		return this.browser.send(method, params, this.sessionId);
	}
}

function contentPath(urlPath) {
	const decoded = decodeURIComponent(urlPath.split("?")[0]);
	const relative = decoded === "/" ? "index.html" : decoded.replace(/^\/+/, "");
	const candidate = resolve(ARTIFACT_DIR, normalize(relative));
	if (!candidate.startsWith(`${ARTIFACT_DIR}/`) && candidate !== ARTIFACT_DIR) {
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

async function waitFor(description, callback, timeoutMs = 30000) {
	const deadline = Date.now() + timeoutMs;
	let lastError;
	while (Date.now() < deadline) {
		try {
			const value = await callback();
			if (value) return value;
		} catch (error) {
			lastError = error;
		}
		await new Promise((accept) => setTimeout(accept, 100));
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

const STORAGE_EXPRESSION = `new Promise((resolve, reject) => {
	const request = indexedDB.open("/userfs");
	request.onerror = () => reject(request.error);
	request.onsuccess = () => {
		const database = request.result;
		const stores = Array.from(database.objectStoreNames);
		if (stores.length === 0) {
			database.close();
			resolve({ stores: [], keys: [] });
			return;
		}
		const transaction = database.transaction(stores, "readonly");
		const keys = [];
		let pending = stores.length;
		for (const store of stores) {
			const keyRequest = transaction.objectStore(store).getAllKeys();
			keyRequest.onerror = () => reject(keyRequest.error);
			keyRequest.onsuccess = () => {
				for (const key of keyRequest.result) keys.push(String(key));
				pending -= 1;
				if (pending === 0) {
					database.close();
					resolve({ stores, keys: keys.sort() });
				}
			};
		}
	};
})`;

async function saveFingerprint(cdp, saveKey) {
	return evaluate(cdp, `new Promise((resolve, reject) => {
		const request = indexedDB.open("/userfs");
		request.onerror = () => reject(request.error);
		request.onsuccess = () => {
			const database = request.result;
			const transaction = database.transaction(["FILE_DATA"], "readonly");
			const valueRequest = transaction.objectStore("FILE_DATA").get(${JSON.stringify(saveKey)});
			valueRequest.onerror = () => reject(valueRequest.error);
			valueRequest.onsuccess = async () => {
				try {
					const value = valueRequest.result?.contents ?? valueRequest.result;
					let bytes;
					if (value instanceof ArrayBuffer) bytes = new Uint8Array(value);
					else if (ArrayBuffer.isView(value)) {
						bytes = new Uint8Array(value.buffer, value.byteOffset, value.byteLength);
					} else if (typeof value === "string") bytes = new TextEncoder().encode(value);
					else throw new Error("unsupported IndexedDB save value");
					const digest = await crypto.subtle.digest("SHA-256", bytes);
					database.close();
					resolve(Array.from(new Uint8Array(digest))
						.map((byte) => byte.toString(16).padStart(2, "0")).join(""));
				} catch (error) {
					database.close();
					reject(error);
				}
			};
		};
	})`);
}

async function launchChrome(profile) {
	const debugPort = await freePort();
	const chrome = spawn(CHROME, [
		"--headless=new",
		"--no-first-run",
		"--no-default-browser-check",
		"--disable-background-networking",
		"--autoplay-policy=no-user-gesture-required",
		`--remote-debugging-port=${debugPort}`,
		`--user-data-dir=${profile}`,
		"--window-size=844,390",
		"about:blank",
	], { stdio: ["ignore", "pipe", "pipe"] });
	let stderr = "";
	chrome.stderr.on("data", (chunk) => { stderr += String(chunk); });
	const target = await waitFor("Chrome browser DevTools target", async () => {
		const response = await fetch(`http://127.0.0.1:${debugPort}/json/version`);
		if (!response.ok) return null;
		return response.json();
	});
	const cdp = new CdpSession(target.webSocketDebuggerUrl);
	await cdp.open();
	return { chrome, cdp, stderr: () => stderr };
}

async function createPrivatePage(browser, url, blockIndexedDb = false) {
	const context = await browser.cdp.send("Target.createBrowserContext", {
		disposeOnDetach: false,
	});
	const created = await browser.cdp.send("Target.createTarget", {
		url: "about:blank",
		browserContextId: context.browserContextId,
	});
	const attached = await browser.cdp.send("Target.attachToTarget", {
		targetId: created.targetId,
		flatten: true,
	});
	const cdp = new TargetSession(browser.cdp, attached.sessionId);
	await Promise.all([
		cdp.send("Runtime.enable"),
		cdp.send("Page.enable"),
		cdp.send("Emulation.setDeviceMetricsOverride", {
			width: 844,
			height: 390,
			deviceScaleFactor: 1,
			mobile: false,
		}),
		cdp.send("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 5 }),
	]);
	if (blockIndexedDb) {
		await cdp.send("Page.addScriptToEvaluateOnNewDocument", {
			source: `Object.defineProperty(globalThis, "indexedDB", {
				configurable: false,
				get() {
					throw new DOMException("IndexedDB blocked by release smoke", "SecurityError");
				},
			});`,
		});
	}
	await cdp.send("Page.navigate", { url });
	if (blockIndexedDb) {
		await waitFor("blocked-storage document load", async () => evaluate(cdp,
			`document.readyState === "complete"`));
		await new Promise((accept) => setTimeout(accept, 3000));
		return { cdp, contextId: context.browserContextId };
	}
	await waitFor("incognito Godot boot", async () => evaluate(cdp, `(() => {
		const canvas = document.querySelector("canvas");
		return !document.getElementById("status")
			&& document.readyState === "complete"
			&& canvas?.width === 844
			&& canvas?.height === 390;
	})()`));
	await new Promise((accept) => setTimeout(accept, 1800));
	return { cdp, contextId: context.browserContextId };
}

async function disposePrivatePage(browser, page) {
	await browser.cdp.send("Target.disposeBrowserContext", {
		browserContextId: page.contextId,
	});
}

async function closeChrome(browser) {
	browser.cdp.close();
	browser.chrome.kill("SIGTERM");
	const exited = await Promise.race([
		once(browser.chrome, "exit").then(() => true),
		new Promise((accept) => setTimeout(() => accept(false), 5000)),
	]);
	if (!exited && browser.chrome.exitCode === null) {
		browser.chrome.kill("SIGKILL");
		await Promise.race([
			once(browser.chrome, "exit"),
			new Promise((_, reject) => setTimeout(
				() => reject(new Error("Chrome did not terminate after SIGKILL")),
				5000,
			)),
		]);
	}
	await new Promise((accept) => setTimeout(accept, 300));
}

async function main() {
	for (const file of ["index.html", "index.js", "index.wasm", "index.pck"]) {
		await readFile(join(ARTIFACT_DIR, file));
	}
	await readFile(CHROME);
	const candidate = JSON.parse(
		await readFile(join(ARTIFACT_DIR, "release-candidate.json"), "utf8"),
	);
	if (candidate.project_dirty !== false || candidate.reproducible !== true) {
		throw new Error("private-storage smoke requires a clean reproducible candidate");
	}
	const profile = await mkdtemp(join(tmpdir(), "godot-private-storage-"));
	const { server, url } = await startServer();
	let browser;
	let first;
	let second;
	try {
		browser = await launchChrome(profile);
		if (BLOCK_INDEXEDDB) {
			first = await createPrivatePage(browser, url, true);
			const state = await evaluate(first.cdp, `(() => {
				const status = document.getElementById("status");
				const canvas = document.querySelector("canvas");
				let indexedDbError = "";
				try {
					void indexedDB;
				} catch (error) {
					indexedDbError = String(error?.name || error);
				}
				return {
					document_ready: document.readyState,
					status_present: Boolean(status),
					status_text: status?.textContent?.trim() ?? "",
					canvas_width: canvas?.width ?? 0,
					canvas_height: canvas?.height ?? 0,
					canvas_visible: Boolean(canvas && getComputedStyle(canvas).display !== "none"),
					indexeddb_error: indexedDbError,
				};
			})()`);
			await screenshot(first.cdp, "browser-blocked-storage-844x390.png");
			console.log("WEB_BLOCKED_STORAGE_PROBE_PASS");
			console.log(JSON.stringify({
				candidate: candidate.revision,
				browser: (await browser.cdp.send("Browser.getVersion")).product,
				state,
				evidence: ["artifacts/browser-blocked-storage-844x390.png"],
			}, null, 2));
			return;
		}
		first = await createPrivatePage(browser, url);
		const persisted = await evaluate(first.cdp,
			`navigator.storage?.persisted ? navigator.storage.persisted() : Promise.resolve(false)`);
		if (persisted !== false) throw new Error("incognito storage unexpectedly reported durable");
		await touch(first.cdp, 422, 276);
		await new Promise((accept) => setTimeout(accept, 1200));
		const created = await evaluate(first.cdp, STORAGE_EXPRESSION);
		const saveKey = created.keys.find((key) => key.endsWith("/save_v1.json"));
		if (!saveKey) throw new Error("incognito session created no playable save");
		const firstFingerprint = await saveFingerprint(first.cdp, saveKey);
		await first.cdp.send("Page.reload", { ignoreCache: false });
		await waitFor("incognito reload", async () => evaluate(first.cdp, `(() => {
			const canvas = document.querySelector("canvas");
			return !document.getElementById("status") && document.readyState === "complete"
				&& canvas?.width === 844 && canvas?.height === 390;
		})()`));
		await new Promise((accept) => setTimeout(accept, 1200));
		const reloaded = await evaluate(first.cdp, STORAGE_EXPRESSION);
		if (!reloaded.keys.includes(saveKey)) {
			throw new Error("incognito save did not survive a same-session reload");
		}
		const reloadedFingerprint = await saveFingerprint(first.cdp, saveKey);
		if (reloadedFingerprint !== firstFingerprint) {
			throw new Error("incognito save identity changed across a same-session reload");
		}
		await touch(first.cdp, 422, 276);
		await new Promise((accept) => setTimeout(accept, 700));
		await touch(first.cdp, 797, 38);
		await new Promise((accept) => setTimeout(accept, 700));
		await screenshot(first.cdp, "browser-private-storage-warning-844x390.png");
		await disposePrivatePage(browser, first);
		first = null;

		second = await createPrivatePage(browser, url);
		const reopened = await evaluate(second.cdp, STORAGE_EXPRESSION);
		const reopenedSaveKey = reopened.keys.find((key) => key.endsWith("/save_v1.json"));
		if (!reopenedSaveKey) throw new Error("new incognito context created no playable fresh save");
		const reopenedFingerprint = await saveFingerprint(second.cdp, reopenedSaveKey);
		if (reopenedFingerprint === firstFingerprint) {
			throw new Error("new incognito context reused the prior private save identity");
		}
		await screenshot(second.cdp, "browser-private-new-session-844x390.png");
		const browserVersion = await browser.cdp.send("Browser.getVersion");
		console.log("WEB_PRIVATE_STORAGE_SMOKE_PASS");
		console.log(JSON.stringify({
			candidate: candidate.revision,
			browser: browserVersion.product,
			incognito_persisted: persisted,
			same_session_reload_preserved: true,
			new_context_created_distinct_save: true,
			first_save_sha256: firstFingerprint,
			second_save_sha256: reopenedFingerprint,
			first_session_key_count: created.keys.length,
			second_session_key_count: reopened.keys.length,
			evidence: [
				"artifacts/browser-private-storage-warning-844x390.png",
				"artifacts/browser-private-new-session-844x390.png",
			],
			limitation: "This proves Chrome incognito-session behavior, not fully blocked IndexedDB.",
		}, null, 2));
	} finally {
		if (browser && first) await disposePrivatePage(browser, first);
		if (browser && second) await disposePrivatePage(browser, second);
		if (browser) await closeChrome(browser);
		await new Promise((accept) => server.close(accept));
		await rm(profile, { recursive: true, force: true });
	}
}

main().catch((error) => {
	console.error("WEB_PRIVATE_STORAGE_SMOKE_FAIL");
	console.error(error?.stack ?? String(error));
	process.exitCode = 1;
});
