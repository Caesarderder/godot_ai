#!/usr/bin/env node

import { spawn } from "node:child_process";
import { createServer } from "node:http";
import { mkdir, mkdtemp, readFile, readdir, rm, stat, writeFile } from "node:fs/promises";
import { createReadStream } from "node:fs";
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
const LOCAL_STARTUP_BUDGET_MS = {
	coldEngineReady: 15000,
	warmEngineReady: 10000,
	offlineEngineReady: 10000,
};
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
				const { resolve: accept, reject } = this.pending.get(message.id);
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
		if (this.socket.readyState === WebSocket.OPEN) return;
		await once(this.socket, "open");
	}

	on(method, listener) {
		const values = this.listeners.get(method) ?? [];
		values.push(listener);
		this.listeners.set(method, values);
	}

	send(method, params = {}) {
		const id = ++this.serial;
		return new Promise((accept, reject) => {
			this.pending.set(id, { resolve: accept, reject });
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
	if (!address || typeof address === "string") throw new Error("HTTP server address unavailable");
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

async function waitFor(description, callback, timeoutMs = 20000) {
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
	if (result.exceptionDetails) {
		throw new Error(result.exceptionDetails.text ?? "browser evaluation failed");
	}
	return result.result?.value;
}

async function screenshot(cdp, name) {
	const result = await cdp.send("Page.captureScreenshot", {
		format: "png",
		captureBeyondViewport: false,
	});
	await writeFile(join(EVIDENCE_DIR, name), Buffer.from(result.data, "base64"));
}

async function setViewport(cdp, width, height, description) {
	await cdp.send("Emulation.setDeviceMetricsOverride", {
		width,
		height,
		deviceScaleFactor: 1,
		mobile: false,
	});
	await waitFor(description, async () => evaluate(cdp,
		`window.innerWidth === ${width} && window.innerHeight === ${height}`));
	await new Promise((accept) => setTimeout(accept, 900));
}

async function touch(cdp, x, y) {
	await cdp.send("Input.dispatchTouchEvent", {
		type: "touchStart",
		touchPoints: [{ x, y, radiusX: 2, radiusY: 2, force: 1 }],
	});
	await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
}

async function pressKey(cdp, key, code, windowsVirtualKeyCode) {
	for (const type of ["keyDown", "keyUp"]) {
		await cdp.send("Input.dispatchKeyEvent", {
			type,
			key,
			code,
			windowsVirtualKeyCode,
			nativeVirtualKeyCode: windowsVirtualKeyCode,
		});
	}
}

async function scrollDown(cdp) {
	for (let step = 0; step < 4; step += 1) {
		await cdp.send("Input.dispatchMouseEvent", {
			type: "mouseWheel",
			x: 800,
			y: 300,
			deltaX: 0,
			deltaY: 180,
		});
		await new Promise((accept) => setTimeout(accept, 80));
	}
}

const STORAGE_INSPECTION_EXPRESSION = `new Promise((resolve, reject) => {
	const request = indexedDB.open("/userfs");
	request.onerror = () => reject(request.error);
	request.onsuccess = () => {
		const database = request.result;
		const stores = Array.from(database.objectStoreNames);
		if (stores.length === 0) {
			database.close();
				resolve({ stores: [], keyCount: 0, durableKeys: [], playtestKeys: [] });
			return;
		}
		const transaction = database.transaction(stores, "readonly");
		const keys = [];
		let pending = stores.length;
		for (const storeName of stores) {
			const keyRequest = transaction.objectStore(storeName).getAllKeys();
			keyRequest.onerror = () => reject(keyRequest.error);
			keyRequest.onsuccess = () => {
				for (const key of keyRequest.result) keys.push(String(key));
				pending -= 1;
				if (pending === 0) {
					database.close();
					const sorted = keys.sort();
					resolve({
						stores,
							keyCount: sorted.length,
							durableKeys: sorted.filter((key) => key.includes("save") || key.includes("settings")),
							playtestKeys: sorted.filter((key) => key.includes("local_playtest")),
						});
				}
			};
		}
	};
})`;

async function main() {
	for (const file of ["index.html", "index.js", "index.wasm", "index.pck"]) {
		await readFile(join(ARTIFACT_DIR, file));
	}
	const releaseCandidate = JSON.parse(
		await readFile(join(ARTIFACT_DIR, "release-candidate.json"), "utf8"),
	);
	if (
		releaseCandidate.project !== "project-a"
		|| releaseCandidate.project_dirty !== false
		|| releaseCandidate.reproducible !== true
		|| !/^[0-9a-f]{40}$/.test(releaseCandidate.revision ?? "")
	) {
		throw new Error("Web artifact is not a clean reproducible project-a release candidate");
	}
	await readFile(CHROME);
	const profile = await mkdtemp(join(tmpdir(), "godot-web-smoke-"));
	const downloadDir = join(profile, "downloads");
	await mkdir(downloadDir);
	const { server, url } = await startServer();
	let serverClosed = false;
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
	let chromeStderr = "";
	chrome.stderr.on("data", (chunk) => { chromeStderr += String(chunk); });
	let cdp;
	try {
		const target = await waitFor("Chrome DevTools target", async () => {
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
			if (type === "error") consoleErrors.push(args.map((arg) => arg.value ?? arg.description).join(" "));
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
			cdp.send("Browser.setDownloadBehavior", { behavior: "allow", downloadPath: downloadDir }),
		]);
		const browserVersion = await cdp.send("Browser.getVersion");
		await cdp.send("Emulation.setDeviceMetricsOverride", {
			width: 844,
			height: 390,
			deviceScaleFactor: 1,
			mobile: false,
		});
		await cdp.send("Emulation.setTouchEmulationEnabled", {
			enabled: true,
			maxTouchPoints: 5,
		});
		const coldStartedAt = Date.now();
		await cdp.send("Page.navigate", { url });
		const boot = await waitFor("Godot canvas boot", async () => {
			const value = await evaluate(cdp, `(() => {
				const canvas = document.querySelector("canvas");
				const text = document.body?.innerText ?? "";
				if (text.includes("WebGL2") && text.includes("missing")) {
					throw new Error(text.trim());
				}
				return !document.getElementById("status")
					&& canvas && canvas.width === 844 && canvas.height === 390
					? {
						width: canvas.width,
						height: canvas.height,
						ready: document.readyState,
						navigation: performance.getEntriesByType("navigation")[0]?.toJSON() ?? {},
					}
					: null;
			})()`);
			return value?.ready === "complete" ? value : null;
		}, 30000);
		const coldEngineReadyMs = Date.now() - coldStartedAt;
		if (coldEngineReadyMs > LOCAL_STARTUP_BUDGET_MS.coldEngineReady) {
			throw new Error(`cold engine ready exceeded local budget: ${coldEngineReadyMs}ms`);
		}
		await new Promise((accept) => setTimeout(accept, 2500));
		await screenshot(cdp, "browser-title-844x390.png");
		await setViewport(cdp, 568, 320, "small landscape browser viewport");
		await screenshot(cdp, "browser-title-568x320.png");
		await setViewport(cdp, 667, 375, "legacy phone landscape browser viewport");
		await setViewport(cdp, 932, 430, "modern phone landscape browser viewport");
		await setViewport(cdp, 1024, 768, "tablet landscape browser viewport");
		await screenshot(cdp, "browser-title-1024x768.png");
		await setViewport(cdp, 390, 844, "portrait browser viewport");
		const portraitGate = await evaluate(cdp, `(() => {
			const gate = document.getElementById("godot-landscape-gate");
			return gate && getComputedStyle(gate).display === "flex"
				&& gate.textContent.includes("请旋转至横屏");
		})()`);
		if (!portraitGate) throw new Error("portrait orientation gate is not visible and readable");
		await screenshot(cdp, "browser-portrait-gate-390x844.png");
		await setViewport(cdp, 1280, 540, "ultrawide browser viewport");
		await screenshot(cdp, "browser-title-1280x540.png");
		const safeAreaProbe = await evaluate(cdp,
			"Boolean(document.getElementById('godot-safe-area-probe'))");
		if (!safeAreaProbe) throw new Error("mobile safe-area probe was not installed");
		await setViewport(cdp, 844, 390, "landscape browser viewport recovery");
		// TitleScreen assigns focus to the primary action after responsive layout
		// settles. Activate that real Godot focus target through the exported Canvas.
		await pressKey(cdp, "Enter", "Enter", 13);
		await new Promise((accept) => setTimeout(accept, 800));
		// The title CTA enters the factory. Open the stable top-right settings button
		// before exercising the two-column storage and local playtest controls.
		await touch(cdp, 797, 38);
		await new Promise((accept) => setTimeout(accept, 600));
		await scrollDown(cdp);
		await new Promise((accept) => setTimeout(accept, 500));
		await screenshot(cdp, "browser-settings-storage-844x390.png");
		await touch(cdp, 692, 134);
		await new Promise((accept) => setTimeout(accept, 700));
		await scrollDown(cdp);
		await new Promise((accept) => setTimeout(accept, 400));
		await screenshot(cdp, "browser-settings-playtest-844x390.png");
		await touch(cdp, 566, 158);
		const downloadedPlaytest = await waitFor("local playtest report download", async () => {
			const names = (await readdir(downloadDir)).filter((name) => name.startsWith("toilet-factory-playtest-") && name.endsWith(".json"));
			if (names.length !== 1) return null;
			const path = join(downloadDir, names[0]);
			const text = await readFile(path, "utf8");
			if (text.length === 0) return null;
			JSON.parse(text);
			return path;
		}, 10000);
		const playtestJson = JSON.parse(await readFile(downloadedPlaytest, "utf8"));
		if (
			playtestJson.schema_version !== 1
				|| playtestJson.product_version !== "0.11.0-audio-feedback.1"
				|| playtestJson.event_count < 2
				|| !Array.isArray(playtestJson.events)
				|| typeof playtestJson.first_session_metrics !== "object"
				|| playtestJson.first_session_metrics.milestone_total !== 12
				|| typeof playtestJson.first_session_metrics.milestone_intervals_seconds !== "object"
				|| typeof playtestJson.first_session_metrics.next_missing_milestone !== "string"
				|| typeof playtestJson.evidence_limit !== "string"
			|| "save_id" in playtestJson
			|| "device_id" in playtestJson
			|| "account_id" in playtestJson
		) {
			throw new Error("downloaded local playtest report violates its version/sample/privacy contract");
		}
		await touch(cdp, 560, 246);
		const downloadedSave = await waitFor("save backup download", async () => {
			const names = (await readdir(downloadDir)).filter((name) => name.startsWith("toilet-factory-save-") && name.endsWith(".json"));
			return names.length === 1 ? join(downloadDir, names[0]) : null;
		}, 10000);
		const downloadedText = await readFile(downloadedSave, "utf8");
		const downloadedJson = JSON.parse(downloadedText);
		if (downloadedJson.schema_version !== 8 || downloadedJson.content_version !== "toilet-factory-slg-v2") {
			throw new Error("downloaded save backup does not match the active schema/content contract");
		}
		await cdp.send("Page.setInterceptFileChooserDialog", { enabled: true });
		const chooser = new Promise((accept) => cdp.on("Page.fileChooserOpened", accept));
		await touch(cdp, 685, 246);
		const chooserEvent = await Promise.race([
			chooser,
			new Promise((_, reject) => setTimeout(() => reject(new Error("save import file chooser did not open")), 5000)),
		]);
		await cdp.send("DOM.setFileInputFiles", {
			files: [downloadedSave],
			backendNodeId: chooserEvent.backendNodeId,
		});
		await new Promise((accept) => setTimeout(accept, 900));
		await scrollDown(cdp);
		await new Promise((accept) => setTimeout(accept, 400));
		await screenshot(cdp, "browser-settings-import-preview-844x390.png");
		await touch(cdp, 685, 216);
		await new Promise((accept) => setTimeout(accept, 900));
		await touch(cdp, 422, 263);
		await new Promise((accept) => setTimeout(accept, 1800));
		await screenshot(cdp, "browser-base-844x390.png");
		const storageBeforeReload = await evaluate(cdp, `Promise.all([
			indexedDB.databases ? indexedDB.databases() : Promise.resolve([])
		]).then(([databases]) => ({
			databases: databases.map((entry) => entry.name).filter(Boolean),
			localStorageKeys: Object.keys(localStorage)
		}))`);
		storageBeforeReload.userfs = await evaluate(cdp, STORAGE_INSPECTION_EXPRESSION);
		const registrations = await evaluate(cdp, `navigator.serviceWorker
			? navigator.serviceWorker.getRegistrations().then((values) => values.map((value) => value.scope))
			: Promise.resolve([])`);
			await evaluate(cdp, `navigator.serviceWorker
				? navigator.serviceWorker.ready.then((registration) => registration.scope)
				: Promise.reject(new Error("service worker unavailable"))`);
			if (exceptions.length || consoleErrors.length || failedRequests.length) {
				throw new Error(`initial runtime errors: ${JSON.stringify({ exceptions, consoleErrors, failedRequests })}`);
			}
			exceptions.length = 0;
			consoleErrors.length = 0;
			failedRequests.length = 0;
			const warmStartedAt = Date.now();
			await cdp.send("Page.reload", { ignoreCache: false });
		await waitFor("Godot canvas reload", async () => {
			const value = await evaluate(cdp, `(() => {
				const canvas = document.querySelector("canvas");
				return !document.getElementById("status")
					&& document.readyState === "complete" && canvas
					&& canvas.width === 844 && canvas.height === 390;
			})()`);
			return value === true;
		}, 30000);
		const warmEngineReadyMs = Date.now() - warmStartedAt;
		if (warmEngineReadyMs > LOCAL_STARTUP_BUDGET_MS.warmEngineReady) {
			throw new Error(`warm engine ready exceeded local budget: ${warmEngineReadyMs}ms`);
		}
		await new Promise((accept) => setTimeout(accept, 1800));
		const storageAfterReload = await evaluate(cdp, `Promise.all([
			indexedDB.databases ? indexedDB.databases() : Promise.resolve([])
		]).then(([databases]) => ({
			databases: databases.map((entry) => entry.name).filter(Boolean),
			localStorageKeys: Object.keys(localStorage)
		}))`);
		storageAfterReload.userfs = await evaluate(cdp, STORAGE_INSPECTION_EXPRESSION);
			await screenshot(cdp, "browser-reload-844x390.png");
			const serviceWorkerControlsPage = await evaluate(cdp, "Boolean(navigator.serviceWorker?.controller)");
			if (!serviceWorkerControlsPage) throw new Error("PWA service worker does not control the reloaded page");
			const knownTeardownLines = new Set([
				'ERROR: Condition "!is_inside_tree()" is true. Returning: false',
				"   at: can_process (scene/main/node.cpp:902)",
			]);
			const onlineTeardownWarnings = consoleErrors.filter((line) => knownTeardownLines.has(line));
			const unexpectedOnlineErrors = consoleErrors.filter((line) => !knownTeardownLines.has(line));
			if (exceptions.length || unexpectedOnlineErrors.length || failedRequests.length) {
				throw new Error(`online runtime errors: ${JSON.stringify({
					exceptions,
					consoleErrors: unexpectedOnlineErrors,
					failedRequests,
				})}`);
			}
			exceptions.length = 0;
			consoleErrors.length = 0;
			failedRequests.length = 0;
			await new Promise((accept, reject) => server.close((error) => error ? reject(error) : accept()));
			serverClosed = true;
		const offlineStartedAt = Date.now();
		await cdp.send("Page.reload", { ignoreCache: false });
		await waitFor("offline PWA canvas boot", async () => {
			const value = await evaluate(cdp, `(() => {
				const canvas = document.querySelector("canvas");
				return !document.getElementById("status")
					&& document.readyState === "complete" && canvas
					&& canvas.width === 844 && canvas.height === 390;
			})()`);
			return value === true;
		}, 30000);
		const offlineEngineReadyMs = Date.now() - offlineStartedAt;
		if (offlineEngineReadyMs > LOCAL_STARTUP_BUDGET_MS.offlineEngineReady) {
			throw new Error(`offline engine ready exceeded local budget: ${offlineEngineReadyMs}ms`);
		}
		await new Promise((accept) => setTimeout(accept, 1800));
		const offlineStorage = await evaluate(cdp, STORAGE_INSPECTION_EXPRESSION);
		await screenshot(cdp, "browser-offline-844x390.png");
		if (boot.width !== 844 || boot.height !== 390) {
			throw new Error(`unexpected canvas size ${boot.width}x${boot.height}`);
		}
		if (registrations.length === 0) throw new Error("PWA service worker did not register");
		if (storageBeforeReload.databases.length === 0) throw new Error("Godot IndexedDB storage was not created");
			if (!storageBeforeReload.userfs.durableKeys.some((key) => key.endsWith("/save_v1.json"))) {
				throw new Error("Godot userfs contains no durable save file");
			}
			if (!storageBeforeReload.userfs.durableKeys.some((key) => key.endsWith("/save_v1.json.bak"))) {
				throw new Error("save import did not preserve the previous durable save as a backup");
			}
			if (!storageBeforeReload.userfs.playtestKeys.some((key) => key.endsWith("/local_playtest_session.json"))) {
				throw new Error("opted-in local playtest report was not persisted");
			}
		if (JSON.stringify(storageBeforeReload.databases) !== JSON.stringify(storageAfterReload.databases)) {
			throw new Error("IndexedDB database identity changed after reload");
		}
		if (JSON.stringify(storageBeforeReload.userfs.durableKeys) !== JSON.stringify(storageAfterReload.userfs.durableKeys)) {
			throw new Error("Godot durable file identity changed after reload");
		}
				if (JSON.stringify(storageAfterReload.userfs.durableKeys) !== JSON.stringify(offlineStorage.durableKeys)) {
					throw new Error("Godot durable file identity changed during offline restart");
				}
				if (JSON.stringify(storageAfterReload.userfs.playtestKeys) !== JSON.stringify(offlineStorage.playtestKeys)) {
					throw new Error("local playtest report identity changed during offline restart");
				}
				await touch(cdp, 422, 276);
				await new Promise((accept) => setTimeout(accept, 700));
				await touch(cdp, 797, 38);
				await new Promise((accept) => setTimeout(accept, 600));
				await scrollDown(cdp);
				await new Promise((accept) => setTimeout(accept, 400));
				await screenshot(cdp, "browser-settings-playtest-offline-844x390.png");
				await touch(cdp, 700, 134);
				await new Promise((accept) => setTimeout(accept, 700));
				const storageAfterOptOut = await evaluate(cdp, STORAGE_INSPECTION_EXPRESSION);
				if (storageAfterOptOut.playtestKeys.length !== 0) {
					throw new Error("opting out did not delete the local playtest report");
				}
			const offlineNetworkFallbacks = failedRequests.filter((failure) =>
				failure.errorText === "net::ERR_CONNECTION_REFUSED"
					&& new URL(failure.url).origin === new URL(url).origin
			);
			const offlineTeardownWarnings = consoleErrors.filter((line) => knownTeardownLines.has(line));
			const unexpectedOfflineErrors = consoleErrors.filter((line) => !knownTeardownLines.has(line));
			const unexpectedOfflineFailures = failedRequests.filter((failure) =>
				!offlineNetworkFallbacks.includes(failure)
			);
			if (exceptions.length || unexpectedOfflineErrors.length || unexpectedOfflineFailures.length) {
				throw new Error(`offline runtime errors: ${JSON.stringify({
					exceptions,
					consoleErrors: unexpectedOfflineErrors,
					failedRequests: unexpectedOfflineFailures,
				})}`);
			}
		console.log("WEB_BROWSER_SMOKE_PASS");
		console.log(JSON.stringify({
			url,
			candidate: {
				revision: releaseCandidate.revision,
				version: releaseCandidate.version,
				godotVersion: releaseCandidate.godot_version,
			},
			browser: {
				product: browserVersion.product,
				userAgent: browserVersion.userAgent,
				jsVersion: browserVersion.jsVersion,
			},
			canvas: boot,
			startupMs: {
				coldEngineReady: coldEngineReadyMs,
				warmEngineReady: warmEngineReadyMs,
				offlineEngineReady: offlineEngineReadyMs,
				budget: LOCAL_STARTUP_BUDGET_MS,
			},
				serviceWorkers: registrations,
					keyboardPrimaryAction: true,
					touchInput: true,
					saveBackupDownload: true,
					saveImportPreview: true,
					saveImportRestore: true,
					localPlaytestReportDownload: true,
					localPlaytestOptOutDeletion: true,
					offlinePwaRestart: true,
				godotReloadTeardownWarnings: onlineTeardownWarnings.length + offlineTeardownWarnings.length,
				offlineNetworkFallbacks,
				storage: storageAfterReload,
				evidence: [
					"artifacts/browser-title-844x390.png",
					"artifacts/browser-title-568x320.png",
					"artifacts/browser-title-1024x768.png",
					"artifacts/browser-portrait-gate-390x844.png",
					"artifacts/browser-title-1280x540.png",
					"artifacts/browser-settings-storage-844x390.png",
					"artifacts/browser-settings-playtest-844x390.png",
					"artifacts/browser-settings-import-preview-844x390.png",
					"artifacts/browser-base-844x390.png",
				"artifacts/browser-reload-844x390.png",
				"artifacts/browser-offline-844x390.png",
			],
		}, null, 2));
	} finally {
		cdp?.close();
		chrome.kill("SIGTERM");
		const exited = await Promise.race([
			once(chrome, "exit").then(() => true),
			new Promise((accept) => setTimeout(() => accept(false), 2000)),
		]);
		if (!exited && chrome.exitCode === null) {
			chrome.kill("SIGKILL");
			await Promise.race([
				once(chrome, "exit"),
				new Promise((_, reject) => setTimeout(
					() => reject(new Error("Chrome did not terminate after SIGKILL")),
					5000,
				)),
			]);
		}
		if (!serverClosed) await new Promise((accept) => server.close(accept));
		await rm(profile, { recursive: true, force: true });
		if (chrome.exitCode && chrome.exitCode !== 0 && !chrome.killed) {
			throw new Error(`Chrome exited ${chrome.exitCode}: ${chromeStderr}`);
		}
	}
}

main().then(
	() => process.exit(0),
	(error) => {
		console.error("WEB_BROWSER_SMOKE_FAIL");
		console.error(error.stack ?? error.message);
		process.exit(1);
	},
);
