# 手机端随机英雄放置远征：测试规格

> 状态：与 RALPLAN 共识 PRD 同步批准
>
> 被测计划：`.omx/plans/prd-fantasy-idle-expedition.md`
>
> 需求源：`.omx/specs/deep-interview-fantasy-idle-expedition.md`

## 1. Purpose and Quality Gates

本规格验证 30 分钟 vertical slice 是否同时满足：玩家能理解并主动调整随机英雄队伍；经济可达且不靠任务硬锁；战斗/seed 可复现；价值转移、存档、离线结算在单设备应用崩溃/杀进程下不重复；移动 UI 和三档 Android 设备可用。

### Global pass rules

- 自动测试、内容校验、crash/lifecycle/设备硬门槛：**100% 通过**，不允许以观察满意度豁免。
- 5 人观察：每个 critical criterion >=4/5；固定 50 checkpoints 总计 >=45/50；无人因任务硬锁或崩溃无法继续。
- paired 1000：预注册同 seed、单一 intervention，win delta >=30pp。
- 任何 build/content/economy/seed/golden hash 漂移使对应证据失效，按重测规则处理。
- exact-once 范围只涵盖单设备、单 writer、应用进程崩溃/Android kill；不宣称防文件回滚、root 修改、云合并、多进程、恶意时钟或存储谎报 fsync。

## 2. Test Environment and Artifact Gates

### Godot/GUT

- Godot 4.7.1 stable；纯 GDScript；Mobile renderer，Compatibility renderer 兼容 smoke。
- GUT 必须来自官方 repository、明确支持 4.7.1；锁 exact tag/commit/checksum，保留实际 LICENSE。兼容性、许可、checksum、headless smoke 任一不明则停止 M0。

### Required commands

```bash
godot --version
godot --headless --path game --editor --quit
godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
godot --headless --path game -s tools/validate_content.gd
godot --headless --path game -s tools/simulate_first_30m.gd -- --manifest=res://tests/fixtures/battle/paired_1000_v1.json
git diff --check -- game .omx
```

### Dirty-worktree evidence

Pre-M0 baseline 必须保存：HEAD、`git status --porcelain=v2 -z --untracked-files=all`、unstaged/cached binary patch、各自 NUL path lists、dirty/untracked existing file SHA-256、MISSING sentinel、`project-a` 全文件 manifest、artifact hashes。

- 路径全程 NUL；hash record 为 `sha256\0path\0`，禁止 newline 解析。
- `project-a` path source：`git ls-files -z --cached --others --exclude-standard -- project-a`。
- 每 milestone 重采。批准差异仅 `game/**`、`.omx/**`；发现其他差异则停工并请求重新确认 baseline，不回滚用户改动。

## 3. Test Inventory and File Map

```text
game/tests/
├── unit/
│   ├── commands/test_command_class_registry.gd
│   ├── commands/test_command_fingerprint.gd
│   ├── commands/test_receipt_retention.gd
│   ├── progression/test_progression_curve.gd
│   ├── battle/test_stable_seed.gd
│   ├── battle/test_tick_and_tiebreak.gd
│   ├── quests/test_quest_reducer.gd
│   ├── idle/test_offline_anchor.gd
│   ├── persistence/test_save_codec.gd
│   ├── persistence/test_atomic_writer.gd
│   └── platform/test_platform_metrics.gd
├── integration/
│   ├── test_new_game_30m.gd
│   ├── test_command_crash_matrix.gd
│   ├── test_offline_anchor.gd
│   ├── test_quest_replay_600.gd
│   └── test_save_resume.gd
└── fixtures/
    ├── economy/first_30m_v1.json
    ├── battle/{paired_1000_v1,onboarding_seed,scripted_rng_cases}.json
    ├── playtest/p01-p05-seeds-v1.json
    ├── golden/{seed_hash_v1,battle_tiebreak_v1,safe_area_transforms_v1}.json
    └── saves/{save_v0,save_v1,save_corrupt}.json
```

## 4. Unit and Contract Tests

### 4.1 Autoload and bootstrap

Assert exact tree and order before main scene `_ready`：

```text
/root/SystemClock
/root/SaveManager
/root/ContentCatalog
/root/EventBus
/root/Game
/root/AppLifecycle
```

- Each path exists exactly once and maps to `scripts/autoloads/{system_clock,save_manager,content_catalog,event_bus,game,app_lifecycle}.gd`。
- AppLifecycle persists across screen/main/battle scene changes and remains the only PAUSED/RESUMED owner。
- First launch: `offline_anchor=last_seen=now`、`last_settled=0`; first save must be durable before `game_ready`; no offline reward。

### 4.2 Sealed command classification

| Class | Must include | Assertions |
|---|---|---|
| DURABLE_VALUE | recruit/train/enhance/upgrade/claim/battle/offline/reserve attempt | caller cannot override class; save-before-swap |
| INTERNAL_DURABLE | pause anchor/heartbeat anchor/resume settle | only internal capability accepted; AppLifecycle cannot direct-write GameState/SaveManager |
| REVERSIBLE_META | formation/equip/unequip/filter/rename | debounce allowed；never partially persists |
| EPHEMERAL | navigation/detail/tick/VFX/preview | no GameState/receipt/quest/save |

- Unknown type -> `UNKNOWN_COMMAND`。
- Public execute attempting `__lifecycle_*` -> authorization error。
- Envelope field `class`/override, if provided, is rejected rather than trusted。

### 4.3 Canonical fingerprint

- Payload domain only null/bool/int/UTF-8 string/ordered arrays/string-key dictionaries; float/Node/Resource rejected。
- Dictionary key order permutations produce same canonical bytes/fingerprint；array order changes fingerprint。
- `fingerprint=SHA-256(LP(type)||LP(payload)||LP(business_key))` with uint32 BE length。
- Same command ID/same fingerprint -> original result；same ID/different fingerprint -> `COMMAND_ID_REUSE_MISMATCH`；same business key/different fingerprint -> `BUSINESS_KEY_REUSE_MISMATCH`；state unchanged。

### 4.4 Hero progression

Expected cumulative XP: L1=0、L2=40、L3=100、L4=200、L5=320；one book=20 XP。

- L5 rule: **clamp xp to 320 and discard all overflow; no persisted overflow field**。
- One bulk train and equivalent incremental trains yield identical level/xp/attributes/remainder。
- C/B/A/S growth multipliers `8500/10000/11500/13000` bp match golden values。
- Same hero seed reproduces L1 `-1/0/+1` differences；different approved seed produces expected variation。
- Derived HP/DEF/physical/magic/speed/crit match PRD formulas。
- `debug_power` is absent from default hero card sorting and all battle/loot/task decisions。

### 4.5 Content/Resource

- Unique content IDs；all references resolve；affix slot pool legal；quest targets/event types valid；content version present。
- Resource definition field/content hashes identical before/after every unit/integration suite。
- Runtime instances contain stable IDs/serializable primitives only, no Node/Resource references。

## 5. Economy and 30-minute Integration

### Source/sink fixture assertions

`first_30m_v1.json` exact totals：金币 source=1930、券=4、书=11、石=9；recommended sink 金币 960-1080、券 4、书 6-9、石 3-6。

- Minute <=10 reaches 8 heroes without random drop dependency。
- 1-3 first-fail consolation grants once；1-5 consolation grants once。
- Pity: by qualifying drop 8 or 1-3 reward, whichever first, player receives usable blue+ item；counter resets once and persists。
- +1/+2/+3 costs exact 80/140/220 gold and 1/2/3 stone；no fail/downgrade。
- At least one facility reaches L2 for 300 gold；not all three required。
- Skipping task claim never blocks `start_stage` or content access。
- Ledger never negative；different valid player choices retain 850±150 gold target envelope by 30m。

### Canonical onboarding

- Stable onboarding seed reaches prescribed 0-30 journey。
- 1-3 and 1-5 each fail first, then pass after allowed, understandable changes。
- Exactly two or more formation commands can be made meaningfully; automated test verifies availability/effect, while unprompted intent is observation-only。

## 6. Stable Seed, Tick and Paired 1000

### Hash golden

Algorithm: length-prefixed UTF-8 fields -> SHA-256 -> first 8 bytes unsigned u64 big-endian -> two's-complement signed for Godot。

- stage-1-3 expected SHA `871416107395887412f0fe2604e0bc00d5c958abe112a670d82455031480b532`, u64 `0x8714161073958874`。
- stage-1-5 expected SHA `7c3345f99bb534e9fc0affe8e81ca5250ce492daaadc6d487d801f3c6b380be2`, u64 `0x7c3345f99bb534e9`。
- Hero P01 vector expected SHA `bb4b4843206b1aefdd1b46290cd333394c3704f8ea721678c763874919027cdb`。
- Copy/rename save_id with same run_seed/content/stage/attempt gives identical seed/digest。

### 5Hz simulation

- dt=.2、tick_index monotonic；no wall clock/global rand/float action meter。
- Tie-break golden order: overflow DESC -> speed DESC -> slot ASC -> UTF-8 unit ID ASC。
- 30/60/120fps and a stalled-frame schedule yield identical BattleResult digest/ticks/end state。
- Backlog >1s may drop only presentational normal attacks/flytext；death/wave/key skill/result preserved。
- PAUSED clears accumulator；5m background adds zero battle ticks。

### Paired 1000 pre-registration

`paired_1000_v1.json` is the **single distribution manifest** for every absolute interval and paired assertion below. It freezes one `seed_set_id` with exactly 1000 run_seed values, content hash, all stage snapshot hashes, deterministic state-recipe hashes and intervention payloads before any battle outcome is executed. Every scenario consumes the same 1000 seeds in the same order；no stage-specific filtering or replacement seed is allowed。

Manifest preflight first materializes every per-seed before snapshot and optional after snapshot, records their hashes, verifies the stated single-variable delta, then signs the manifest；only afterward may the runner execute battles and observe wins. Thus generated hero variation is frozen before outcome inspection rather than becoming a post-result sample choice。

| Scenario | Frozen before state | After state / only permitted variable | Required distribution over the same 1000 seeds |
|---|---|---|---|
| 1-1 naked | 4 onboarding L1 heroes；default 2-front/2-back formation；no training、equipment、facility bonus；stage-1-1 enemy snapshot | none；absolute baseline only | before win rate **95-100%** |
| 1-2 baseline | The same 4 L1 heroes and default formation；1-1 rewards may exist in inventory but none are spent/equipped；no training/facility bonus；stage-1-2 snapshot | none；absolute baseline only | before win rate **80-95%** |
| 1-3 paired | Deterministically generated 8-hero roster；the manifest's 4 designated active L1 heroes in default formation；no training、rare item or facility bonus；stage-1-3 snapshot | exactly one predeclared `set_formation` command；heroes、levels、equipment、enemy、attempt、RNG and targeting unchanged | before **15-30%**；`mean(after-before) >= 0.30` |
| 1-4 paired distribution | Canonical post-1-3 settlement snapshot；manifest-fixed active heroes、levels、equipment and resources；default 1-4 formation；stage-1-4 snapshot | exactly one predeclared second `set_formation` command；all non-formation fields byte-identical | before **35-50%**；after **75-90%** |
| 1-5 paired | Canonical post-1-4 snapshot；guaranteed rare item exists in inventory but is unequipped；manifest-fixed formation、levels、resources；stage-1-5 snapshot | exactly one `equip_item(guaranteed_rare_id)` command；formation、levels、enemy、attempt、RNG and targeting unchanged | before **10-25%**；`mean(after-before) >= 0.30` |

- Pair validator compares canonical snapshots and must report exactly the whitelisted command delta；any second field difference invalidates that pair and the entire scenario run。
- Report numerator/denominator and rate for every absolute interval, paired delta for 1-3/1-5, and 1-4 before/after rates；save discordant pairs and both digests。
- No seed removal、scenario-specific resampling、intervention substitution、state-recipe edit or threshold change after manifest sign-off。Train/enhance ablations use a separate pre-registered manifest and do not replace or mix with these results。

## 7. Receipt Retention and 600 Replay

- DURABLE_VALUE business receipts remain for save lifetime and never enter 512 ring。
- Task-affecting command `(id,fingerprint,event_ids)` remains until all possible consuming quests are terminal + claimed/retired。
- Active QuestState stores consumed_event_ids；terminal quest permanently ignores new/old matching events。

Test sequence：

1. Emit 600 task-related formation/equip events with unique IDs。
2. Replay event/command 1, 256 and 512 with same fingerprint：return original result, progress/reward unchanged。
3. Replay same IDs with changed payload/business key：hard mismatch, state unchanged。
4. Complete and claim related quest, then replay again：terminal progress/reward unchanged。
5. Emit 600 pure filter commands：ring may evict old receipts without changing value/quest state。

Pass：no duplicate progress/reward; task claim delta exactly once; receipt retention matches class/lifecycle。

## 8. Crash and Replay Matrix

Fault injection points：P0 validation、P1 candidate computed、P2 tmp/memory changed before rename、P3 rename before response、P4 response retry。

| Class | P0/P1 | P2 | P3 | P4 retry |
|---|---|---|---|---|
| EPHEMERAL | no persistent effect | transient lost | N/A | may replay presentation only |
| REVERSIBLE_META | candidate lost | memory change may be lost if no rename | renamed revision restores | original while receipt retained; evicted commands must be set-style idempotent |
| DURABLE_VALUE | no effect | old main remains; retry once | new snapshot has value+receipt | same result, one delta |
| INTERNAL_DURABLE pause/heartbeat | no anchor movement | old anchor remains before rename | committed anchor + internal receipt restore | same internal result; anchor moves once |
| settle_offline | old anchor/resources | old interval uncommitted | new anchor/resource/interval receipt | interval not paid again |
| claim_reward | unclaimed | old save unclaimed | claimed+credit+receipt same snapshot | reward not paid again |

### Save writer assertions

- Single writer; lower state_revision cannot overwrite last durable revision。
- Barrier cancels pending debounce, drains older in-flight write, then persists candidate。
- tmp incomplete -> ignored/removed；main corrupt -> validated backup recovery；corrupt file retained for diagnostics。
- Test process kill immediately before/after rename, before UI response and during retry。

## 9. Lifecycle and Offline Anchor

### Field contract

- `saved_at_unix` is the write-attempt time recorded in the successfully committed snapshot; never used for reward。
- `last_seen_wall_unix` is monotonic diagnostic max only。
- `last_settled_unix` is latest successful settlement audit end only。
- `offline_anchor_unix` is the only delta start。

### Required scenarios

1. New save at t=0 -> foreground 20m with 20 sealed 60s heartbeat commands -> last disk anchor t=1200 -> kill -> background 5m -> boot t=1500 -> credit exactly 300s once。
2. Foreground 20m -> sealed pause command durable t=1200 -> 5m -> sealed resume settlement -> 300s；duplicate RESUMED/response retry/popup-before-kill remain once。
3. Pause save failure before rename -> disk retains latest heartbeat; possible over-credit <=60s is logged; committed interval never paid twice。
4. Wall rollback 10m -> zero reward, anchor/last_settled do not decrease。
5. Wall jump 48h -> credit 8h cap once, anchor moves to now; returning clock produces no reward until catch-up。
6. Public caller cannot invoke internal heartbeat/pause/resume commands; AppLifecycle cannot mutate state or call SaveManager directly。
7. AppLifecycle remains `/root/AppLifecycle` through scene changes and is sole notification owner。

## 10. Safe Area and 48dp

Use `safe_area_transforms_v1.json` golden cases：portrait、landscape、notch on each edge、non-integer stretch、screen offset、zero/unknown DPI。

- Physical safe rect corners transformed by inverse screen transform produce expected logical margins。
- Android `max(dpi,160)/160` and 48dp convert to expected logical minimum; unknown DPI fallback is 1。
- Tap token uses larger logical axis；all primary interactives meet/exceed it。
- Recompute on ready deferred、viewport size、orientation、screen change、resume；orientation uses 100ms trailing debounce and final inset sample。
- Android screenshots confirm clickable physical area and no notch overlap。

## 11. Android Device Matrix

### Build/install/launch

```bash
godot --headless --path game --export-debug "Android Debug" game/build/android/fantasy_idle-debug.apk
shasum -a 256 game/build/android/fantasy_idle-debug.apk
adb install -r game/build/android/fantasy_idle-debug.apk
adb shell am force-stop com.caesar.fantasyidle.prototype
adb shell monkey -p com.caesar.fantasyidle.prototype -c android.intent.category.LAUNCHER 1
adb logcat -d --pid="$(adb shell pidof -s com.caesar.fantasyidle.prototype)" > game/build/android/logcat.txt
```

- Finite `logcat -d`; runner timeout 60s for install/launch/pid；failure saves global latest 2000 lines。

| Tier | Device | Scenarios | Pass |
|---|---|---|---|
| Low | API26, 3GB, ~720x1600 | cold boot、30m、battle backlog、kill/resume | >=30fps；peak RAM <300MB；growth <20MB |
| Main | API33, 6GB, 1080x2400 | primary lifecycle、cutout、30m | target 60fps；all lifecycle exact-once |
| Current | API35+, 8GB, cutout/rotation | orientation/inset/background policy | no overlap；correct final safe area；no duplicate owner |

Each tier：cold launch、Home 10s/5m、process kill、double resume、rotation、clock rollback fixture、save write failure where injectable、battle foreground/background。

## 12. Five-person Pre-registered Observation

### Manifest before test

Committed RC fixture `p01-p05-seeds-v1.json`：

| ID | Seed |
|---|---|
| P01 | `0x0123456789abcdef` |
| P02 | `0x1020304050607080` |
| P03 | `0x7ffffffffffffffe` |
| P04 | `0x13579bdf2468ace0` |
| P05 | `0x55aa55aa33cc33cc` |

Evidence manifest freezes before P01：Git HEAD、APK SHA、PCK/content bundle SHA、sorted `.tres` hash、economy/seed/golden fixture hashes、Godot version、device/API/RAM、participant mapping；manifest is hashed and signed off。

### Facilitator script

1. Recruit 5 target users not involved in development；anonymous P01-P05。
2. Say only：“请像自己下载的新游戏一样玩 30 分钟，可以说出想法；我不会教操作。”
3. Record screen + observer sheet；only after 120s stuck may say neutral：“你可以查看当前界面里的信息。” Prompted actions do not count unprompted。
4. Post-test ask：为什么换人/位置？哪次提升最明显？任务不领能否继续？Use fixed rubric。

### Fixed 10 checkpoints

1. 10m 内 8 英雄。
2. 能解释职业差异。
3. 能解释资质或天赋差异。
4. 第一次 unprompted formation change。
5. 1-3 先败后通过成长获胜。
6. 查看稀有词条。
7. 有理由地装备稀有件。
8. 第二次 unprompted formation change。
9. 理解任务可跳过仍能推进。
10. 1-5 先败后通过组合调整获胜。

Pass：critical（8英雄、2差异、2调整、稀有件、败后胜）各 >=4/5；总 >=45/50；no hard lock/crash blocker。

### Retest rule

- UI-only change and all domain/content/economy/golden hashes identical：same P/seed targeted retest, label `retest`, do not pool first/retest。
- Any battle/progression/equipment/quest/economy/seed/content change：old final evidence invalid；precommit new P06-P10 seeds and recruit 5 new users；full rerun；never rerun failed only。
- Interrupted/device-failure run retained；same participant restarts same seed。Replacement requires predeclared P06 seed/reason, never delete failure。

### Per-participant evidence

`Participant/build/manifest/device/API/RAM/seed/start/end/interventions`；formation before/after/reason/timecode；rare acquisition/equip/enhance；1-3 and 1-5 action chain；task understanding；10 bits；crash/anomaly；observer signature；no PII。

## 13. PRD Traceability Matrix

| Requirement | Test/evidence | Exit |
|---|---|---|
| 8 heroes（Source L130） | economy fixture + new_game_30m + checkpoint 1 | auto 100%; observe >=4/5 |
| 2 dimensions（L131） | progression/UI contract + checkpoints 2/3 rubric | >=4/5 both |
| 2 formation changes（L132） | command evidence/timecode, prompted excluded | >=4/5 each >=2 |
| rare shift（L133） | pity/ledger + checkpoints 6/7 + result comparison | auto 100%; observe >=4/5 |
| fail then win（L134） | canonical + checkpoints 5/10 | auto 100%; observe >=4/5 |
| soft tasks（L135） | skip claim then start_stage + checkpoint 9 | auto 100%; observe >=4/5 |
| battle pacing distributions（PRD §3.3） | one signed `paired_1000_v1.json` seed set reused for 1-1 through 1-5；preflight state hashes + absolute/paired reports | 1-1 95-100%；1-2 80-95%；1-3 before 15-30% and +30pp；1-4 before 35-50% / after 75-90%；1-5 before 10-25% and +30pp |
| same seed（L139） | hash golden + paired 1000 + save_id/FPS/device digest | 100% identical |
| pause/offline once（L140） | 20m+5m、crash matrix、Android kill | 100% |
| restart state（L141） | round-trip、backup、migration | field equality 100% |
| Resource immutable（L142） | before/after content hashes | zero changes |
| reward once（L143） | fingerprint mismatches、600 replay、crash rows | exactly one delta |
| formation invalid ref（L144） | missing/deleted hero save fixtures | reject or documented repair; zero dangling IDs |

## 14. Milestone Test Exit

| Milestone | Required evidence |
|---|---|
| M0 | baseline、GUT gate、headless shell、explicit Autoload tree、project-a unchanged |
| M1 | classification/fingerprint、internal lifecycle auth、crash matrix、20m+5m、600 replay、save backup |
| M2 | L1-L5 clamp/growth golden、8 heroes、formation contracts、readability formative check |
| M3 | hash/tie-break golden、cross-FPS；the signed common 1000-seed manifest proves 1-1 naked 95-100%、1-2 80-95%、1-3 before 15-30% and the single `set_formation` intervention >=30pp；1-3 canonical |
| M4 | source/sink ledger、pity、claim once、soft task、facility；the same signed 1000-seed manifest proves 1-4 before 35-50% / after 75-90% with only the second `set_formation` change, plus 1-5 before 10-25% and only `equip_item(guaranteed_rare_id)` >=30pp |
| M5 | 1-5、all headless、three device tiers、P01-P05 thresholds、final scope/hash audit |
| M6 | only after M0-M5 pass: run `caesar-docs:init`; require all 17 locked Markdown files plus `tools/docs_lint.py`; docs writer -> facts reviewer -> independent verifier；`python3 tools/docs_lint.py` zero errors and repo-entry routing pass |

## 15. Final Test Exit and Failure Handling

- All PRD trace rows pass against one frozen RC manifest; no mixed build/content evidence。
- Automated/device tests 100%；all six absolute distribution intervals and both >=30pp paired thresholds pass against the same signed 1000-seed manifest；P01-P05 critical and 45/50 pass。
- Independent verifier, not authoring executor, signs final summary and attaches raw outputs/device logs/evidence references。
- Failure remains milestone-active；fix owner cannot self-approve。Protocol changes return to Architect review；content/UI fixes rerun impacted manifests under retest rules。
- Any unexplained `project-a/**` or out-of-scope worktree change blocks final approval。
- M6 is blocked until M0-M5 evidence is frozen；knowledge-map facts must be derived from final code/tests/ADR/evidence, and `rg '^km_id:' docs`、`rg 'KM:|CODE:|CMD:' docs`、`find docs -name '*.md' -print` plus relative-link/path checks must pass。
- Required M6 Markdown set is exact：`docs/index.md`；`docs/map/{index,schema,workflows,domains,invariants,glossary}.md`；`docs/workflows/{knowledge-query,code-locating,impact-map,code-writing-review,knowledge-map-maintenance}.md`；`docs/memory/index.md`；`docs/quality/{lint-rules,stale-docs}.md`；`docs/runbooks/docs-lint.md`；`docs/decisions/ADR-0001-knowledge-map-structure.md`。
- `python3 tools/docs_lint.py` must fail on missing/invalid YAML frontmatter or required fields/enums/date、duplicate `km_id`、unresolved `related`、unregistered domain/tag、bad `KM:*` id target、broken relative/`CODE:*` path、missing `CMD:*` anchor、missing `source_of_truth` target or deleted/stale path；enumeration-only `rg/find` output cannot satisfy M6。
- Existing README/AGENTS/ARCHITECTURE routing is checked according to repository-entry rules；missing AGENTS/ARCHITECTURE files are not created automatically。M6 cannot overlap M0-M5 implementation lanes；author cannot self-review or self-verify。

## 16. Changelog

- Final verification amendment：`paired_1000_v1.json` now supplies one immutable 1000-seed set for every 1-1 through 1-5 distribution assertion。
- Added explicit frozen before-state recipes and single-command after deltas；added absolute gates for 1-1、1-2、1-3 before、1-4 before/after and 1-5 before while retaining 1-3/1-5 paired >=30pp。
- Updated PRD traceability、M3/M4 exits and final exit so no milestone can pass on paired delta alone or on a stage-specific resampled cohort。
- User-added final gate：after the game is complete and verified, use `caesar-docs:init` to initialize and validate the repository's Chinese knowledge map as M6。
- Locked the complete 17-file minimum startup set、failing `tools/docs_lint.py` contract and sequential docs writer/facts reviewer/independent verifier ownership。
