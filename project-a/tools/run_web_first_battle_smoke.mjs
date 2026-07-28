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


async function pressEnter(cdp) {
	for (const type of ["keyDown", "keyUp"]) {
		await cdp.send("Input.dispatchKeyEvent", {
			type,
			key: "Enter",
			code: "Enter",
			windowsVirtualKeyCode: 13,
			nativeVirtualKeyCode: 13,
		});
	}
}


async function click(cdp, x, y) {
	for (const type of ["mousePressed", "mouseReleased"]) {
		await cdp.send("Input.dispatchMouseEvent", {
			type,
			x,
			y,
			button: "left",
			clickCount: 1,
		});
	}
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
						highestUnlockedStage: parsed.stage_progress?.highest_unlocked_stage,
						attempts: parsed.attempt_counters,
						onboardingActiveIndex: parsed.onboarding?.active_index,
						onboardingFinished: parsed.onboarding?.finished,
						facilities: parsed.factory?.facilities,
						facilityPlacements: parsed.factory?.facility_placements,
						facilityWork: parsed.factory?.facility_work,
						blueprintResearch: parsed.factory?.blueprint_research,
						materials: parsed.factory?.materials,
						economy: {
							toiletCoins: parsed.economy?.toilet_coins,
							industrialTech: parsed.economy?.industrial_tech,
							skillChips: parsed.economy?.skill_chips,
						},
						formation: parsed.formation,
						roster: (parsed.roster ?? []).map((hero) => ({
							heroId: hero.hero_id,
							archetypeId: hero.archetype_id,
							star: hero.star,
							activeSkillLevel: hero.active_skill_level,
						})),
						onboardingClaimed: parsed.onboarding?.claimed,
					});
				} catch (error) {
					database.close();
					reject(error);
				}
			};
		};
	};
})`;

async function finishActiveBattle(
	cdp,
	stageId,
	completion,
	evidenceName,
	skillCardXs = [420],
	skillCardY = 306,
	skillInputIntervalMs = 900,
	settlementTimeoutMs = 90000,
	midBattleEvidence = null,
) {
	await new Promise((accept) => setTimeout(accept, 2200));
	let skillTouches = 0;
	let skillCardIndex = 0;
	const midBattleEvidencePromise = midBattleEvidence
		? new Promise((accept, reject) => {
			setTimeout(() => {
				screenshot(cdp, midBattleEvidence.name).then(accept, reject);
			}, midBattleEvidence.delayMs);
		})
		: Promise.resolve();
	const skillInput = setInterval(() => {
		skillTouches += 1;
		const x = skillCardXs[skillCardIndex % skillCardXs.length];
		skillCardIndex += 1;
		void touch(cdp, x, skillCardY);
	}, skillInputIntervalMs);
	try {
		const settledSave = await waitFor(`${stageId} settlement persisted to IndexedDB`, async () => {
			const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
			return save && completion(save) ? save : null;
		}, settlementTimeoutMs, 400);
		clearInterval(skillInput);
		await midBattleEvidencePromise;
		await new Promise((accept) => setTimeout(accept, 700));
		await screenshot(cdp, evidenceName);
		return { save: settledSave, skillTouches };
	} finally {
		clearInterval(skillInput);
	}
}

async function continueBattle(cdp, stageId, completion, evidenceName) {
	await touch(cdp, 650, 210);
	return finishActiveBattle(cdp, stageId, completion, evidenceName);
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
				|| freshSave.schemaVersion !== 11
				|| freshSave.contentVersion !== "toilet-factory-slg-v3-factions"
				|| !Array.isArray(freshSave.clearedStages)
				|| freshSave.clearedStages.length !== 0
				|| typeof freshSave.attempts !== "object"
		) {
			throw new Error(`expected a fresh playable save: ${JSON.stringify(freshSave)}`);
		}
		// The current onboarding contract builds the research lab before 1-1.
		await click(cdp, 630, 322);
		await new Promise((accept) => setTimeout(accept, 900));
		await touch(cdp, 280, 270);
		await new Promise((accept) => setTimeout(accept, 500));
		await touch(cdp, 650, 350);
		await new Promise((accept) => setTimeout(accept, 700));
		await screenshot(cdp, "browser-opening-research-placement-844x390.png");
		const openingResearchWork = await waitFor(
			"opening research construction persisted to IndexedDB",
			async () => {
				const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
				return save?.facilityWork?.facility_id === "research_lab" ? save : null;
			},
			10000,
			250,
		);
		const openingCompletesAt = Number(openingResearchWork.facilityWork?.completes_at_unix ?? 0);
		const openingWaitMs = Math.max(0, openingCompletesAt * 1000 - Date.now() + 1200);
		if (openingCompletesAt <= 0 || openingWaitMs > 15000) {
			throw new Error(`opening research construction wait is invalid: ${openingWaitMs}ms`);
		}
		await new Promise((accept) => setTimeout(accept, openingWaitMs));
		const openingClaimInput = setInterval(() => {
			void touch(cdp, 650, 318);
		}, 600);
		try {
			await waitFor(
				"opening research lab claim persisted to IndexedDB",
				async () => {
					const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
					return Number(save?.facilities?.research_lab ?? 0) === 1 ? save : null;
				},
				10000,
				250,
			);
		} finally {
			clearInterval(openingClaimInput);
		}
		await touch(cdp, 570, 184);
		await new Promise((accept) => setTimeout(accept, 600));
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
		// The research lab already exists. The defeat CTA must now open the
		// exact first stage-earned blueprint, then keep the second research
		// objective focused until both permanent reinforcements exist.
		await touch(cdp, 650, 240);
		await new Promise((accept) => setTimeout(accept, 1000));
		await screenshot(cdp, "browser-research-placement-ready-844x390.png");
		await touch(cdp, 260, 287);
		const assaultResearch = await waitFor(
			"assault blueprint research persisted to IndexedDB",
			async () => {
				const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
				return save?.blueprintResearch?.recipe_id === "ordinary.assault"
					? save
					: null;
			},
			10000,
			250,
		);
		await screenshot(cdp, "browser-research-construction-started-844x390.png");
		const assaultCompletesAt = Number(assaultResearch.blueprintResearch?.completes_at_unix ?? 0);
		const assaultWaitMs = Math.max(0, assaultCompletesAt * 1000 - Date.now() + 1200);
		if (assaultCompletesAt <= 0 || assaultWaitMs > 15000) {
			throw new Error(`assault blueprint wait is invalid: ${assaultWaitMs}ms`);
		}
		await new Promise((accept) => setTimeout(accept, assaultWaitMs));
		await screenshot(cdp, "browser-research-ready-to-claim-844x390.png");
		await touch(cdp, 260, 287);
		const assaultUnlocked = await waitFor(
			"assault permanent hero persisted to IndexedDB",
			async () => {
				const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
				return save?.roster?.some((hero) => hero.archetypeId === "assault")
					&& Object.keys(save?.blueprintResearch ?? {}).length === 0
					? save
					: null;
			},
			10000,
			250,
		);
		await screenshot(cdp, "browser-research-lab-built-844x390.png");
		await touch(cdp, 260, 287);
		const armoredResearch = await waitFor(
			"armored blueprint research persisted to IndexedDB",
			async () => {
				const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
				return save?.blueprintResearch?.recipe_id === "heavy.armored"
					? save
					: null;
			},
			10000,
			250,
		);
		await screenshot(cdp, "browser-research-breakthrough-ready-844x390.png");
		const armoredCompletesAt = Number(armoredResearch.blueprintResearch?.completes_at_unix ?? 0);
		const armoredWaitMs = Math.max(0, armoredCompletesAt * 1000 - Date.now() + 1200);
		if (armoredCompletesAt <= 0 || armoredWaitMs > 20000) {
			throw new Error(`armored blueprint wait is invalid: ${armoredWaitMs}ms`);
		}
		await new Promise((accept) => setTimeout(accept, armoredWaitMs));
		await touch(cdp, 260, 287);
		const breakthrough = await waitFor(
			"both permanent reinforcements persisted to IndexedDB",
			async () => {
				const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
				const archetypes = (save?.roster ?? []).map((hero) => hero.archetypeId);
				return archetypes.includes("assault")
					&& archetypes.includes("armored")
					? save
					: null;
			},
			10000,
			250,
		);
		await new Promise((accept) => setTimeout(accept, 900));
		await screenshot(cdp, "browser-research-breakthrough-result-844x390.png");
		await screenshot(cdp, "browser-first-formation-step-one-844x390.png");
		const armoredHero = breakthrough.roster.find((hero) => hero.archetypeId === "armored");
		const assaultHero = breakthrough.roster.find((hero) => hero.archetypeId === "assault");
		if (!armoredHero || !assaultHero) throw new Error("breakthrough roster lacks guaranteed heroes");
		await touch(cdp, 570, 260);
		await waitFor(
			"armored reinforcement assignment persisted to IndexedDB",
			async () => {
				const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
				return save?.formation?.troop_1 === armoredHero.heroId ? save : null;
			},
			10000,
			250,
		);
		await new Promise((accept) => setTimeout(accept, 700));
		await touch(cdp, 350, 260);
		const firstFormation = await waitFor(
			"assault reinforcement assignment persisted to IndexedDB",
			async () => {
				const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
				return save?.formation?.troop_1 === armoredHero.heroId
					&& save?.formation?.troop_2 === assaultHero.heroId
					? save
					: null;
			},
			10000,
			250,
		);
		await new Promise((accept) => setTimeout(accept, 700));
		await screenshot(cdp, "browser-first-formation-complete-844x390.png");
		await touch(cdp, 420, 187);
		await new Promise((accept) => setTimeout(accept, 1000));
		await screenshot(cdp, "browser-first-wall-counterattack-started-844x390.png");
		let counterattack;
		try {
			counterattack = await finishActiveBattle(
				cdp,
				"stage_1_4 counterattack",
				(save) => Number(save.attempts?.stage_1_4 ?? 0) === 2
					&& save.clearedStages?.includes("stage_1_4"),
				"browser-first-wall-counterattack-victory-844x390.png",
				[145, 420, 700],
				330,
				300,
				120000,
			);
		} catch (error) {
			await screenshot(cdp, "browser-first-wall-counterattack-timeout-844x390.png");
			const timeoutSave = await evaluate(cdp, READ_SAVE_EXPRESSION);
			throw new Error(`${error.message}; final save=${JSON.stringify(timeoutSave)}`);
		}
		await touch(cdp, 650, 210);
		await new Promise((accept) => setTimeout(accept, 1000));
		await touch(cdp, 630, 322);
		await new Promise((accept) => setTimeout(accept, 900));
		await screenshot(cdp, "browser-first-growth-choice-844x390.png");
		await touch(cdp, 210, 250);
		const firstGrowth = await waitFor(
			"assault two-star growth persisted to IndexedDB",
			async () => {
				const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
				const assault = save?.roster?.find((hero) => hero.archetypeId === "assault");
				return Number(assault?.star ?? 0) === 2 ? save : null;
			},
			10000,
			250,
		);
		await new Promise((accept) => setTimeout(accept, 700));
		await screenshot(cdp, "browser-first-growth-committed-844x390.png");
		await touch(cdp, 110, 357);
		await new Promise((accept) => setTimeout(accept, 700));
		await touch(cdp, 630, 322);
		await new Promise((accept) => setTimeout(accept, 700));
		await screenshot(cdp, "browser-first-industrial-choice-844x390.png");
		await touch(cdp, 545, 304);
		await new Promise((accept) => setTimeout(accept, 700));
		await touch(cdp, 350, 270);
		await new Promise((accept) => setTimeout(accept, 500));
		await screenshot(cdp, "browser-first-industrial-placement-844x390.png");
		await touch(cdp, 630, 362);
		const industrialConstruction = await waitFor(
			"porcelain plant construction persisted to IndexedDB",
			async () => {
				const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
				return save?.facilityWork?.facility_id === "porcelain_plant"
					&& save?.facilityWork?.work_type === "construction"
					? save
					: null;
			},
			10000,
			250,
		);
		const industrialCompletesAt = Number(industrialConstruction.facilityWork?.completes_at_unix ?? 0);
		const industrialWaitMs = Math.max(0, industrialCompletesAt * 1000 - Date.now() + 1200);
		if (industrialCompletesAt <= 0 || industrialWaitMs > 45000) {
			throw new Error(`porcelain construction wait is invalid: ${industrialWaitMs}ms`);
		}
		await new Promise((accept) => setTimeout(accept, industrialWaitMs));
		await screenshot(cdp, "browser-first-industrial-ready-844x390.png");
		const industrialClaimInput = setInterval(() => {
			void touch(cdp, 650, 318);
		}, 700);
		let industrialBuilt;
		try {
			await touch(cdp, 650, 318);
			industrialBuilt = await waitFor(
				"completed porcelain plant persisted to IndexedDB",
				async () => {
					const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
					return Number(save?.facilities?.porcelain_plant ?? 0) === 1
						&& Object.keys(save?.facilityWork ?? {}).length === 0
						? save
						: null;
				},
				10000,
				250,
			);
		} finally {
			clearInterval(industrialClaimInput);
		}
		await new Promise((accept) => setTimeout(accept, 500));
		await screenshot(cdp, "browser-first-industrial-commissioned-844x390.png");
		const porcelainBeforeClaim = Number(industrialBuilt.materials?.porcelain ?? 0);
		await touch(cdp, 650, 325);
		const commissioningClaim = await waitFor(
			"commissioning output persisted to IndexedDB",
			async () => {
				const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
				return Number(save?.materials?.porcelain ?? 0) > porcelainBeforeClaim ? save : null;
			},
			10000,
			250,
		);
		await new Promise((accept) => setTimeout(accept, 500));
		await screenshot(cdp, "browser-first-industrial-collected-844x390.png");
		await touch(cdp, 570, 184);
		await new Promise((accept) => setTimeout(accept, 500));
		await touch(cdp, 630, 300);
		await new Promise((accept) => setTimeout(accept, 1000));
		await screenshot(cdp, "browser-first-boss-started-844x390.png");
		const chapterOne = await finishActiveBattle(
			cdp,
			"stage_1_5 chapter boss",
			(save) => save.clearedStages?.includes("stage_1_5")
				&& save.highestUnlockedStage === "stage_2_1",
			"browser-chapter-one-complete-844x390.png",
			[145, 420, 700],
			330,
			300,
			150000,
			{
				delayMs: 55000,
				name: "browser-first-boss-cannon-window-844x390.png",
			},
		);
		await touch(cdp, 640, 248);
		await new Promise((accept) => setTimeout(accept, 900));
		const chapterTwoHandoff = await evaluate(cdp, READ_SAVE_EXPRESSION);
		if (
			Number(chapterTwoHandoff?.attempts?.stage_2_1 ?? 0) !== 0
				|| chapterTwoHandoff?.highestUnlockedStage !== "stage_2_1"
		) {
			throw new Error(`chapter-two reconnaissance must not auto-start battle: ${JSON.stringify(chapterTwoHandoff)}`);
		}
		await screenshot(cdp, "browser-chapter-two-reconnaissance-844x390.png");
		const skillResearchBefore = chapterTwoHandoff;
		await touch(cdp, 600, 330);
		await new Promise((accept) => setTimeout(accept, 900));
		await screenshot(cdp, "browser-chapter-two-skill-growth-ready-844x390.png");
		await touch(cdp, 515, 216);
		const skillResearchAfter = await waitFor(
			"G-Man active skill level two persisted to IndexedDB",
			async () => {
				const save = await evaluate(cdp, READ_SAVE_EXPRESSION);
				const commander = save?.roster?.find((hero) => hero.archetypeId === "gman");
				return Number(commander?.activeSkillLevel ?? 0) === 2 ? save : null;
			},
			10000,
			250,
		);
		const expectedSkillResearchDelta = {
			toiletCoins: 80,
			industrialTech: 6,
			skillChips: 1,
			porcelain: 24,
			parts: 16,
			sludge: 20,
		};
		const actualSkillResearchDelta = {
			toiletCoins:
				Number(skillResearchBefore.economy?.toiletCoins ?? 0)
				- Number(skillResearchAfter.economy?.toiletCoins ?? 0),
			industrialTech:
				Number(skillResearchBefore.economy?.industrialTech ?? 0)
				- Number(skillResearchAfter.economy?.industrialTech ?? 0),
			skillChips:
				Number(skillResearchBefore.economy?.skillChips ?? 0)
				- Number(skillResearchAfter.economy?.skillChips ?? 0),
			porcelain:
				Number(skillResearchBefore.materials?.porcelain ?? 0)
				- Number(skillResearchAfter.materials?.porcelain ?? 0),
			parts:
				Number(skillResearchBefore.materials?.parts ?? 0)
				- Number(skillResearchAfter.materials?.parts ?? 0),
			sludge:
				Number(skillResearchBefore.materials?.sludge ?? 0)
				- Number(skillResearchAfter.materials?.sludge ?? 0),
		};
		if (JSON.stringify(actualSkillResearchDelta) !== JSON.stringify(expectedSkillResearchDelta)) {
			throw new Error(`skill research cost drifted: ${JSON.stringify({
				expectedSkillResearchDelta,
				actualSkillResearchDelta,
			})}`);
		}
		await new Promise((accept) => setTimeout(accept, 700));
		await screenshot(cdp, "browser-chapter-two-skill-growth-committed-844x390.png");
		await touch(cdp, 315, 358);
		await new Promise((accept) => setTimeout(accept, 900));
		const chapterTwoAfterGrowth = await evaluate(cdp, READ_SAVE_EXPRESSION);
		if (
			Number(chapterTwoAfterGrowth?.attempts?.stage_2_1 ?? 0) !== 0
				|| chapterTwoAfterGrowth?.highestUnlockedStage !== "stage_2_1"
		) {
			throw new Error(`skill growth return must preserve reconnaissance state: ${JSON.stringify(chapterTwoAfterGrowth)}`);
		}
		await screenshot(cdp, "browser-chapter-two-after-skill-growth-844x390.png");

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
		console.log("WEB_FIRST_CHAPTER_SMOKE_PASS");
		console.log(JSON.stringify({
			candidate: {
				revision: candidate.revision,
				version: candidate.version,
				godotVersion: candidate.godot_version,
			},
			browser: browserVersion.product,
			viewport: VIEWPORT,
			journey: "fresh profile through every chapter-one core loop, boss victory, chapter-two reconnaissance, and first skill-II growth",
			openingStageCleared: true,
			attempts: settledSave.attempts.stage_1_1,
			firstWallReached: true,
			firstWallOutcome: "defeat",
			firstWallAttempts: firstWall.save.attempts.stage_1_4,
			researchLabBuiltBeforeFirstBattle: Number(breakthrough.facilities?.research_lab) === 1,
			researchPlacement: breakthrough.facilityPlacements?.research_lab,
			stageBlueprintsResearched: ["assault", "armored"],
			guaranteedReinforcements: ["assault", "armored"],
			firstFormation: firstFormation.formation,
			counterattackOutcome: "victory",
			counterattackAttempts: counterattack.save.attempts.stage_1_4,
			industrialFacility: "porcelain_plant",
			industrialPlacement: industrialBuilt.facilityPlacements?.porcelain_plant,
			commissioningPorcelainDelta:
				Number(commissioningClaim.materials?.porcelain ?? 0) - porcelainBeforeClaim,
			firstGrowthChoice: "assault",
			firstGrowthStar: firstGrowth.roster.find((hero) => hero.archetypeId === "assault")?.star,
			chapterBossOutcome: "victory",
			chapterBossAttempts: chapterOne.save.attempts.stage_1_5,
			chapterOneComplete: chapterOne.save.clearedStages.includes("stage_1_5"),
			chapterTwoUnlocked: chapterTwoHandoff.highestUnlockedStage,
			chapterTwoReconnaissanceAutoStarted: false,
			firstSkillGrowth: {
				archetypeId: "gman",
				activeSkillLevel: skillResearchAfter.roster.find((hero) => hero.archetypeId === "gman")?.activeSkillLevel,
				cost: actualSkillResearchDelta,
				chapterTwoAttemptsAfterReturn: Number(chapterTwoAfterGrowth.attempts?.stage_2_1 ?? 0),
			},
			clearedStages: chapterOne.save.clearedStages,
			skillCardTouchInputs: skillTouches
				+ stage12.skillTouches
				+ stage13.skillTouches
				+ firstWall.skillTouches
				+ counterattack.skillTouches
				+ chapterOne.skillTouches,
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
				"artifacts/browser-research-placement-ready-844x390.png",
				"artifacts/browser-research-construction-started-844x390.png",
				"artifacts/browser-research-ready-to-claim-844x390.png",
				"artifacts/browser-research-lab-built-844x390.png",
				"artifacts/browser-research-breakthrough-ready-844x390.png",
				"artifacts/browser-research-breakthrough-result-844x390.png",
				"artifacts/browser-first-formation-step-one-844x390.png",
				"artifacts/browser-first-formation-complete-844x390.png",
				"artifacts/browser-first-wall-counterattack-started-844x390.png",
				"artifacts/browser-first-wall-counterattack-victory-844x390.png",
				"artifacts/browser-first-industrial-choice-844x390.png",
				"artifacts/browser-first-industrial-placement-844x390.png",
				"artifacts/browser-first-industrial-ready-844x390.png",
				"artifacts/browser-first-industrial-commissioned-844x390.png",
				"artifacts/browser-first-industrial-collected-844x390.png",
				"artifacts/browser-first-growth-choice-844x390.png",
				"artifacts/browser-first-growth-committed-844x390.png",
				"artifacts/browser-first-boss-started-844x390.png",
				"artifacts/browser-first-boss-cannon-window-844x390.png",
				"artifacts/browser-chapter-one-complete-844x390.png",
				"artifacts/browser-chapter-two-reconnaissance-844x390.png",
				"artifacts/browser-chapter-two-skill-growth-ready-844x390.png",
				"artifacts/browser-chapter-two-skill-growth-committed-844x390.png",
				"artifacts/browser-chapter-two-after-skill-growth-844x390.png",
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
	console.error("WEB_FIRST_CHAPTER_SMOKE_FAIL");
	console.error(error?.stack ?? String(error));
	process.exitCode = 1;
});
