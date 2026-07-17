# 手机端随机英雄放置远征：RALPLAN Planner Draft v3

> 状态：Planner iteration 3，等待 Architect 与 Critic 复审。只规划，不授权写游戏源码。
>
> Source of truth：`.omx/specs/deep-interview-fantasy-idle-expedition.md`；上下文：`.omx/context/fantasy-idle-expedition-20260717T080734Z.md`；前版：`.omx/drafts/ralplan-fantasy-idle-expedition-v2.md`。

## 1. Requirements Summary

### 产品目标

- 手机端、单机、休闲放置；核心体验是培养随机冒险者、理解差异、调整 2 前排 + 2 后排编队并跨过旧卡点（Source Spec L24-L41）。
- P0 为英雄培养与编队，P1 为装备词条/无失败强化，P2 为三座线性营地设施；5 大 + 16 小任务只做软引导，不硬锁关卡（Source Spec L43-L74）。
- 30 分钟内至少 8 英雄、理解 2 个差异维度、主动编队调整至少 2 次、获得并使用稀有装备、成长后击败此前失败关卡（Source Spec L126-L145）。
- 非目标：固定抽卡英雄、重剧情/立绘、复杂营地、多队、转职、星级、套装、联网、商业化、多语言、PvP、公会、云存档（Source Spec L87-L94）。

### 仓库与默认边界

- 新建独立 `game/`；不修改、移动、格式化、暂存或清理当前含用户改动的 `project-a/**`。
- Godot 4.7.1 stable、纯 GDScript、2D、Mobile renderer；Compatibility renderer 做兼容冒烟。可逆默认：竖屏 1080x1920、Android-first、灰盒美术。
- `.tres` 只存只读内容定义；persistent `GameState` 只保存稳定 ID/实例字段；用户存档 `user://save_v1.json`；领域逻辑可 headless 测试（Source Spec L114-L145）。
- 美术主题、最终朝向、商业化、发布平台组合、单机边界改变时必须重新确认（Source Spec L96-L112、L155-L164）。

## 2. RALPLAN-DR（short mode）

### Principles

1. **先证 P0 乐趣**：功能必须促成“看懂差异 -> 调队/培养 -> 过卡点”。
2. **executor 是唯一写入口**：调用方不能自选 durability，也不能绕过同步 command transaction 改 `GameState`。
3. **价值先持久化再成功**：招募、培养、强化、设施、领奖、战斗与离线结算都必须 candidate save 成功后才 swap/回包。
4. **时间与随机性单一语义**：offline 只认 anchor；seed 只认明确字节算法；逻辑只认 tick_index。
5. **预注册证据**：测试 seed、build/content hash、paired intervention 与 pass rule 在运行前冻结，禁止看结果挑样本。

### Top 3 Drivers

1. 5 人观察测试是否证实两次主动编队决策和一次失败后成长再胜。
2. 应用崩溃/杀进程、重复 request/resume 和超过 512 条历史后仍不重复价值或任务进度。
3. 结果能跨存档 ID、帧率、设备复现，同时不让调试战力替代英雄差异。

### 决策轴 A：运行架构

| 选项 | 优点 | 缺点 | 结论 |
|---|---|---|---|
| A1. **领域内核 + 薄 Godot 外壳** | headless、持久化、决定性边界清楚；UI 可换 | command/DTO 样板增加；要防过度抽象 | **选择**；禁用 DI 框架/ECS/数据库/自定义编辑器插件 |
| A2. Node/场景为状态真值 | 编辑器直观，动画原型快 | Node 难安全保存/重放；跨 screen 易重复状态 | 仅限表现层，不作领域真值 |
| A3. ECS/表格批模拟 | 多队、大单位吞吐好 | 当前 4vN 不偿还工具和调试成本 | 多队成为已证需求后重评 |

### 决策轴 B：交付方式

| 选项 | 优点 | 缺点 | 结论 |
|---|---|---|---|
| B1. **Vertical slice milestone** | 早验证玩家价值，每步可试玩 | 模块需渐进补齐 | **选择** |
| B2. Horizontal system completion | 专家并行清楚 | 整合与乐趣验证过晚 | 仅作为同一 slice 内 Team lane |

推荐 **A1 + B1**；A2/B2 可局部使用但不能改变真值所有权和 milestone exit criteria。

## 3. 30 分钟 PRD、内容与经济

### 玩家旅程

| 时间 | 内容 | 行为目标 |
|---:|---|---|
| 0-3 | 4 初始英雄、1-1 | 查看职业、资质、天赋，不以综合战力代替理解 |
| 3-7 | 2 次券招募、1-2 | 到 6 人；第一次 unprompted 换人/换位 |
| 7-12 | 再招 2 人、1-3 首败、训练 | 到 8 人；培养/调队后过 1-3 |
| 12-18 | 铁匠、保底稀有件 | 比较词条，合理装备并强化 |
| 18-23 | 1-4 | 第二次 unprompted 编队调整 |
| 23-28 | 三设施入口、一次升级、离线弹窗 | 理解营地是效率辅助 |
| 28-30 | 1-5 Boss 首败与复战 | 组合培养/装备/编队后获胜 |

### 内容硬预算

- 4 职业 ×（1 普攻规则 + 1 主动技能）；4 资质；8 天赋/性格；40+ 姓名组合。
- 1 队 4 槽；3 装备槽、12 模板、10 词条、4 品质、+0..+5；6 普通敌人 + 1 Boss；5 关。
- 酒馆/铁匠/训练场各 3 级；5 大 + 16 小任务；金币/招募券/经验书/锻造石。
- 灰盒：4 职业 × 2 动画状态、7 敌方剪影、6 通用 VFX、约 30 UI 图标、1 BGM、10 SFX。

### 0-30 分钟 Source/Sink ledger

写入 `game/tests/fixtures/economy/first_30m_v1.json`，模拟器逐 command 输出账本：

| 阶段 | Sources | Sinks |
|---|---|---|
| 新档 | 4 英雄、金币 250、书 2 | 无 |
| 1-1 + 任务 | +金币 200、+券 2、+书 2 | 券 2 -> 招 2 人 |
| 1-2 + 任务 | +金币 260、+券 2、+书 2、+石 2 | 券 2 -> 再招 2 人 |
| 1-3 首败（仅一次） | +金币 60、+书 2 | 推荐训练：书 6、金币 180；换位免费 |
| 1-3 首胜 | +金币 260、+石 4、1 稀有候选 | 强化 +1/+2/+3：金币 80/140/220、石 1/2/3 |
| 1-4 + 任务 | +金币 520、+石 3、+书 3 | 可追加训练书 3、金币 120 |
| 营地教学 | +金币 300 | 任一设施升 2 级：金币 300 |
| 1-5 首败（仅一次） | +金币 80 | 无强制 sink |
| 总计 | 金币 1930、券 4、书 11、石 9 | 推荐金币 960-1080、券 4、书 6-9、石 3-6 |

- 第 8 个合格装备掉落前仍无蓝色及以上则升级为蓝色；1-3 首胜也给职业可用蓝色候选，两者取较早者，触发后 `rare_pity_counter` 归零并持久化。
- 预注册 1000-seed 目标：1-1 裸队 95-100%；1-2 80-95%；1-3 干预前 15-30%、单一预注册干预后提升至少 30pp；1-4 35-50% -> 75-90%；1-5 干预前 10-25%、单一预注册关键干预后提升至少 30pp。

## 4. Hero L1-L5 Progression and Combat Mapping

### 最小成长曲线

| Level | 累计 XP | 本级所需 XP | 等效经验书（20 XP/本） |
|---:|---:|---:|---:|
| 1 | 0 | - | - |
| 2 | 40 | 40 | 2 |
| 3 | 100 | 60 | 3 |
| 4 | 200 | 100 | 5 |
| 5 | 320 | 120 | 6 |

- 经验可溢出到下一级，L5 封顶但保留 overflow 字段为 0；训练 command 一次消耗明确本数/金币并 durable。
- 四项原始属性：体魄 VIG、力量 STR、敏捷 AGI、智力 INT。L1 职业基线：守卫 `(14,7,6,4)`、斗士 `(10,12,8,4)`、游侠 `(8,8,13,5)`、秘术师 `(7,4,8,14)`。
- 每级基础成长向量：守卫 `(2.0,0.8,0.4,0.2)`、斗士 `(1.0,1.8,0.8,0.2)`、游侠 `(0.6,0.8,2.0,0.4)`、秘术师 `(0.5,0.3,0.7,2.1)`。配置用千分整数而非 float。
- 每项资质倍率：C=8500、B=10000、A=11500、S=13000 basis points；仅作用于对应属性的逐级成长。每次升级累积定点 remainder，整点向下取整并保留 remainder，保证逐级与批量升级相同。
- L1 每项另有 seeded `-1/0/+1` 初始差异；UI 同时显示当前属性和资质箭头，避免 L1 资质只有未来意义。

### 战斗映射

```text
max_hp       = 50 + VIG * 10 + flat_hp
defense      = class_armor + VIG * 2 + flat_def
physical_atk = weapon_power + STR * 3
magic_atk    = focus_power + INT * 3
speed_milli  = 60_000 + AGI * 4_000 + flat_speed_milli
crit_bp      = clamp(500 + AGI * 50 + affix_crit_bp, 0, 5000)
```

- SkillDef 明确使用 physical/magic coefficient basis points；游侠技能可组合 AGI coefficient，但不建立隐式职业特判。
- `debug_power` 只用于开发诊断和测试日志，不参与 AI、掉落、配对、任务或胜负；默认英雄卡不显示、不按它默认排序。详情页若 debug build 显示，必须标“估算”并同时保留职业/资质/天赋。
- `test_progression_curve.gd` 验证逐级/批量一致、四资质 golden values、L5 cap、同 seed 初始差异与战斗派生属性。

## 5. State, Time and Lifecycle Contracts

### 5.1 Persistent vs transient

```text
Persistent GameState
├── schema_version / content_version / save_id / run_seed / revision
├── roster / inventory / formation / economy / camp / quest / pity
├── stage_progress / attempt_counters / receipt ledgers
└── saved_at_unix / last_seen_wall_unix / last_settled_unix / offline_anchor_unix

Transient BattleSession
├── session_id / stage_id / attempt / seed / tick_index / accumulator
├── BattleState (units, fixed meters, local RNG state)
└── presentation queue

Immutable BattleResult
└── result_id / outcome / ticks / reward_roll / event_digest
```

- GameState 不保存 BattleSession/State、动画或 scene path。手动退出销毁 session、无奖励；后台冻结不追 wall time；进程存活则同 tick 恢复，被杀则以新 attempt 从 tick 0 重开，无入场资源损失。
- BattleResult 只经 durable `settle_battle_result` 发奖；失败安慰奖也在该事务内，按 result_id 去重。

### 5.2 四个时间字段的唯一职责

| 字段 | 唯一职责 | 明确禁止 |
|---|---|---|
| `saved_at_unix` | 该 JSON snapshot 成功 materialize 的审计时间，由 writer 在 serialize 时写 | 不参与离线时长、回拨或奖励 |
| `last_seen_wall_unix` | 记录成功事务观察到的最大 wall time，用于 anomaly/诊断 | 不作为 accrual 起点，不因回拨下降 |
| `last_settled_unix` | 最近一次成功 offline settlement 的结束审计时间 | 不参与下一次 delta 计算 |
| `offline_anchor_unix` | **唯一**离线 accrual 起点；resume 只用 `now - offline_anchor` | 其他字段不得回退/替代它 |

### 5.3 AppLifecycle ownership and registration

- 唯一 owner 是 Autoload **`/root/AppLifecycle`**，文件 `game/scripts/app/app_lifecycle.gd`；它在场景切换、main scene reload、战斗 scene 销毁时始终存活。任何 screen/scene 禁止直接处理 APPLICATION_PAUSED/RESUMED 或调用 offline settlement。
- `project.godot` `[autoload]` 必须按依赖顺序声明：`SystemClock` -> `SaveManager` -> `ContentCatalog` -> `EventBus` -> `Game` -> `AppLifecycle`（最后）。测试断言 `/root/AppLifecycle` 唯一且先于 main scene `_ready` 完成 bootstrap。
- 首次启动：AppLifecycle 调 `Game.bootstrap()`；无主档/备份时创建 `GameState`，令 `offline_anchor = last_seen_wall = now`、`last_settled = 0`，durable 写首档成功后才发 `game_ready` 并开放 main UI。首次启动绝不发离线奖。
- PAUSED edge（250ms 去重）：冻结 battle -> clone candidate -> `offline_anchor=max(old_anchor,now)`、`last_seen=max(old,now)` -> durable save -> swap。保存失败不推进内存 anchor，5 秒预算内串行重试并记录错误；不能宣称已保存。
- RESUMED edge（250ms 去重）：先重算 PlatformMetrics；唯一 settlement gate 令 `effective_end=max(old_offline_anchor, now)`，计算 `delta=effective_end-old_offline_anchor`、cap 8h，candidate 更新 `offline_anchor=effective_end`、`last_settled=max(old_last_settled,effective_end)`、`last_seen=max(old,now)`，durable save 后 swap/弹窗。回拨时奖励 0、anchor/last_settled 不下降；前跳超 cap 只发 8h但 anchor 移到 now。
- 前台 heartbeat autosave 每 60 秒执行；所有 DURABLE_VALUE save 也把 candidate `offline_anchor` 推到 `max(old_anchor, current_foreground_now)`。REVERSIBLE_META dirty debounce 为 1000ms，但若触发 durable write 同样推进 anchor。这样无 PAUSED 的系统 kill 最多把最后 heartbeat 后的 <=60s 前台误算为离线，不会把 20 分钟前台整体算离线。

### 5.4 Required clock/lifecycle tests

- 新档 `t=0`，前台 20 分钟，60 秒 heartbeat 共 20 次，最后磁盘 anchor=`t=1200`；直接 kill，后台 5 分钟，重启 `t=1500`：只结算 300 秒一次，saved_at/last_seen 不参与计算。
- 前台 20 分钟 -> PAUSED candidate 在 `t=1200` durable -> 后台 5 分钟 -> RESUMED：300 秒；重复 RESUMED、弹窗前 kill、响应后 retry 均仍只 300 秒。
- PAUSED save 在 tmp/backup/rename 各故障点：未 rename 则磁盘 anchor 仍为最近 heartbeat（最坏多计 <=60s，明确记录），rename 后则为 1200；不得出现同一已持久区间发两次。
- wall 回拨 10 分钟：0 奖励、anchor 不降；向前跳 48h：只发 8h、anchor 移到 now；恢复正确时间前不再发奖。

## 6. Command, Receipt and Crash Contracts

### 6.1 Executor-enforced command classification

`CommandExecutor` 内置 sealed registry `command_type -> CommandClass`；调用者不能传 class/override。未知 command type 直接 `UNKNOWN_COMMAND`。

| Class | Command types | Commit/save policy |
|---|---|---|
| `DURABLE_VALUE` | `recruit_hero`, `train_hero`, `enhance_item`, `upgrade_facility`, `claim_reward`, `settle_battle_result`, `settle_offline`, `reserve_battle_attempt` | clone -> validate/apply/reduce -> durable save candidate -> swap -> success |
| `REVERSIBLE_META` | `set_formation`, `equip_item`, `unequip_item`, `set_roster_filter`, `rename_hero` | clone -> swap -> 1000ms debounce；崩溃可丢最近操作但状态不撕裂 |
| `EPHEMERAL` | screen navigation、打开详情、BattleSession tick、动画/VFX、排序预览 | 不进 GameState、不写 receipt、不触发 quest/save |

- 任务进度是同一 command 的 DomainEvent 经纯 `QuestReducer` 得出；Reducer 不发奖、不创建 command、不读 UI。
- `claim_reward` 顺序：存在 -> complete -> unclaimed -> 解析 QuestDef -> candidate 标 claimed -> credit -> event -> reducer（禁止当前奖励递归）-> invariants -> receipt -> durable save -> swap -> UI success。

### 6.2 ID fingerprint and mismatch rule

- `CommandEnvelope`：`command_id`、`type`、`payload`、`business_key`、`expected_revision`、`requested_at_unix`。
- canonical payload 只允许 null/bool/int/UTF-8 string/ordered array/string-key dictionary；dictionary key 按 UTF-8 byte lexicographic 排序；禁止 float/Node/Resource。编码为无空白 canonical JSON。
- receipt 保存 `fingerprint = SHA-256(LP(type_utf8) || LP(canonical_payload_utf8) || LP(business_key_utf8))`；`LP` 是 4-byte unsigned big-endian length + bytes。
- 命中同 `command_id` 且 fingerprint 相同：返回原 receipt；同 ID 但任一字段不同：返回 `COMMAND_ID_REUSE_MISMATCH`、记录安全错误、绝不执行。仅 business key 相同且已有 durable receipt 时，fingerprint 相同则返回原业务结果，fingerprint 不同则 `BUSINESS_KEY_REUSE_MISMATCH`，绝不以新 payload 覆盖旧业务。

### 6.3 Receipt retention and >512 replay

- `DURABLE_VALUE` 的 business receipt（招募/训练/强化/设施/claim/result/offline interval/attempt）保留整个存档生命周期；首版内容量可接受，不进 512 ring。
- 任何能推进任务的 command，其 `(command_id, fingerprint, emitted event_ids)` 保留到所有可能消费该 event type/target 的任务均 terminal 且 claimed/retired。每个活跃 QuestState 另保留 `consumed_event_ids`，terminal 后 reducer 永久忽略新/旧 event。
- 只有不转移价值且不推进任何活跃/未来任务的 REVERSIBLE_META receipt 可进入 512 ring；淘汰不影响 quest/value exact-once。
- 强制测试：连续 600 条任务相关 formation/equip events 后重放第 1、256、512 条，任务 progress/奖励不变；完成并 claimed 后再重放也不变化；600 条纯 filter commands 可按 ring 淘汰。

### 6.4 Command class × crash point matrix

exact-once 仅承诺**单设备、单 writer、应用进程崩溃/Android 杀进程**模型；不承诺用户回滚文件、root 修改、跨设备云合并、多个进程并写、介质谎报 fsync 或恶意时钟攻击。

| Class / crash point | P0 接收/校验前后 | P1 candidate 已算、未 commit | P2 memory/tmp 已变、未 durable rename | P3 durable rename 后、response 前 | P4 response 后 retry |
|---|---|---|---|---|---|
| EPHEMERAL | 无 persistent 效果 | 仅瞬态对象 | 进程结束即丢弃 | N/A | 可重新表现，不产生价值/任务事件 |
| REVERSIBLE_META | 无效果 | candidate 丢弃 | memory swap 可丢；若 autosave tmp 未 rename，重启旧状态 | debounce rename 已完成则恢复该 revision | receipt 尚在则原结果；淘汰后仅允许 set-style 幂等重放 |
| DURABLE_VALUE | 无效果 | candidate 丢弃 | tmp 可删、主档仍旧，重试执行一次；内存尚未 swap | 新档含 value + fingerprint，启动加载新档，重试原结果 | 原结果，资源 delta 恰好一次 |
| `settle_offline` | anchor/资源不变 | 计算结果丢弃 | 旧 anchor，重启重新计算尚未提交区间 | 新 anchor/资源/interval receipt，重启不再发 | 同一 interval 原结果 |
| `claim_reward` | unclaimed | candidate claimed/credit 一并丢弃 | 旧档仍 unclaimed，重试一次 | claimed + credit + receipt 同 snapshot | 原结果，reward delta 恰好一次 |

- SaveManager 单 writer；request 带 state_revision，拒绝 `< last_durable_revision`；barrier 取消 pending debounce、等待旧 in-flight write，再写 candidate，禁止旧快照覆盖新价值。
- 文件协议：serialize -> `save_v1.tmp` -> flush/close -> parse/validate -> 主档备份到 `.bak` -> tmp 原子 rename；启动主档失败才回退 backup，保留 corrupt 文件。

## 7. Deterministic Seed and Battle Contract

### 7.1 Stable seed algorithm

- 输入字段全部先转 UTF-8；每字段编码为 `uint32_be(byte_length) || bytes` 后顺序拼接；SHA-256；取 digest 前 8 bytes 按 **unsigned 64-bit big-endian** 解释。传给 Godot signed int 时若 `u >= 2^63`，使用 two's-complement `u - 2^64`。
- battle parts 固定：`["battle-seed-v1", content_version, stage_id, decimal(attempt_index), run_seed_token]`；生产 `run_seed_token` 是 unsigned run_seed 的十进制 UTF-8，canonical onboarding 则固定 literal `"onboarding-v1"`。hero parts 使用独立 domain tag。`save_id` **永不进入 seed**；复制/改名 save_id 不改变结果。
- `game/tests/fixtures/golden/seed_hash_v1.json` 固定 golden vectors：

| Parts | SHA-256 | u64 / signed |
|---|---|---|
| `battle-seed-v1,content-v1,stage-1-3,0,onboarding-v1` | `871416107395887412f0fe2604e0bc00d5c958abe112a670d82455031480b532` | `0x8714161073958874` / `-8713315119140599692` |
| `battle-seed-v1,content-v1,stage-1-5,0,onboarding-v1` | `7c3345f99bb534e9fc0affe8e81ca5250ce492daaadc6d487d801f3c6b380be2` | `0x7c3345f99bb534e9` / `8949573822876824809` |
| `hero-seed-v1,content-v1,P01,0,81985529216486895` | `bb4b4843206b1aefdd1b46290cd333394c3704f8ea721678c763874919027cdb` | `0xbb4b4843206b1aef` / `-4950783912219829521` |

### 7.2 Fixed simulation

- 5Hz、`dt=0.2`、单调 `tick_index`；局部 RngPort，禁止全局 rand；行动条整数 `meter_milli += speed_milli_per_tick`，阈值 100000；百分比 basis points。
- 同 tick tie-break：`overflow DESC -> speed_milli DESC -> formation_slot ASC -> stable unit_id UTF-8 ASC`；同权重目标先按 slot/id 排序再用局部 RNG。
- 每 frame 最多追 5 ticks；积压 >1s 时逻辑继续批处理，但 BattleView 可丢普通挥击/飘字，必须保留死亡、波次、关键技能、终局。队列上限 10 ticks/2s；PAUSED 清 accumulator，不把后台 wall time灌入 battle。
- golden fixtures：`golden/battle_tiebreak_v1.json` 覆盖 overflow/speed/slot/id；`golden/seed_hash_v1.json` 覆盖 hash/端序；`golden/safe_area_transforms_v1.json` 覆盖 transform/48dp。

### 7.3 Pre-registered 1000 paired runs

- 测试前提交 `game/tests/fixtures/battle/paired_1000_v1.json`：固定 1000 个 run_seed、content hash、stage snapshot hash、before state hash、唯一 `intervention_command` 与预期方向；运行后不得删 seed。
- 每 seed 做 before/after 成对运行：同英雄、敌人、等级、装备、attempt、RNG seed、目标规则；唯一变量是一个预注册 command。1-3 主实验仅 `set_formation`；1-5 主实验仅 `equip_item(guaranteed_rare_id)`。不得把“整套策略包”伪装为单变量。
- 指标是 paired win delta：`mean(after_win - before_win) >= 0.30`（至少 30 percentage points），并报告 discordant pairs；before/after digest 和 intervention payload 全部保存。阈值未达则 content validation 失败，禁止事后换 intervention/seed。
- 辅助 ablation（单次 `train_hero`、单次 `enhance_item`）另建 manifest，不与主实验混算。

## 8. Safe Area and 48dp

- PlatformMetrics 读取 physical safe rect，用 `Viewport.get_screen_transform().affine_inverse()` 转换两个角到逻辑 viewport；四边 Margin 取逻辑 rect 与 safe rect 差的 `max(0,value)`。
- Android `px_per_dp=max(reported_dpi,160)/160`，未知 fallback 1；物理 `48*px_per_dp` 经 inverse basis 转逻辑宽高，取较大轴作为 tap token。iOS/桌面经 platform scale adapter；UI 不自行猜 DPI。
- `_ready call_deferred`、viewport size、orientation、screen/window change、RESUMED 重算；旋转后 100ms trailing debounce 再读 inset。
- `safe_area_transforms_v1.json` 预注册 portrait/landscape、四边刘海、非整数 scale、零 DPI、screen offset 的 physical input 与逻辑 margin/48dp golden output。

## 9. Files and Vertical Implementation

```text
game/
├── project.godot / export_presets.cfg / README.md / CLAUDE.md / .gitignore / .gitattributes
├── addons/gut/                         # exact commit + LICENSE
├── assets/{audio,fonts,sprites,ui}/
├── resources/definitions/{classes,skills,traits,enemies,equipment,affixes,stages,quests,facilities}/
├── scenes/{app,battle,screens,dialogs,ui}/
├── scripts/
│   ├── autoloads/{game,event_bus,save_manager,content_catalog}.gd
│   ├── app/{app_lifecycle,platform_metrics,screen_router}.gd
│   ├── ports/{clock_port,system_clock,rng_port,godot_rng,scripted_rng}.gd
│   ├── commands/{command_class_registry,command_envelope,command_fingerprint,command_result,command_executor,command_receipt}.gd
│   ├── state/{game_state,hero_state,item_state,formation_state,quest_state,camp_state,receipt_ledger}.gd
│   ├── definitions/{class_def,skill_def,trait_def,item_def,affix_def,enemy_def,stage_def,quest_def,facility_def}.gd
│   ├── domain/recruitment/{hero_generator,recruitment_service}.gd
│   ├── domain/formation/formation_service.gd
│   ├── domain/battle/{battle_session,battle_state,battle_unit,battle_simulator,battle_result,targeting,stable_seed}.gd
│   ├── domain/loot/{loot_generator,equipment_service,pity_state}.gd
│   ├── domain/progression/{hero_progression,stat_derive,economy_service,camp_service}.gd
│   ├── domain/quests/{quest_reducer,quest_service,domain_event}.gd
│   ├── domain/idle/{idle_reward_service,offline_settlement}.gd
│   ├── persistence/{save_codec,save_migrations,save_validator,atomic_file_writer}.gd
│   └── ui/{screen controllers and presenters}.gd
├── tests/
│   ├── unit/{commands,progression,recruitment,formation,battle,loot,quests,idle,persistence,platform}/test_*.gd
│   ├── integration/{test_new_game_30m,test_command_crash_matrix,test_offline_anchor,test_quest_replay_600,test_save_resume}.gd
│   └── fixtures/
│       ├── economy/first_30m_v1.json
│       ├── battle/{paired_1000_v1,onboarding_seed,scripted_rng_cases}.json
│       ├── playtest/p01-p05-seeds-v1.json
│       ├── golden/{seed_hash_v1,battle_tiebreak_v1,safe_area_transforms_v1}.json
│       └── saves/{save_v0,save_v1,save_corrupt}.json
└── tools/{validate_content.gd,simulate_first_30m.gd,capture_worktree_baseline.sh,run_headless_tests.sh,smoke_project.sh}
```

### Ordered slices

1. **M0 Baseline/project shell**：先采 dirty baseline，再建独立 project、autoload 顺序、SafeArea、GUT gate。
2. **M1 Transaction/time spine**：command registry/fingerprint/receipts、QuestReducer、SaveManager、四时间字段、crash matrix、600 replay。
3. **M2 Hero/formation**：L1-L5 curve、4 职业/资质、8 人、第一次调整。
4. **M3 Deterministic 1-3**：stable seed、5Hz、golden fixtures、paired 1000、先败后胜。
5. **M4 Equipment/quest/camp**：economy ledger、pity、强化、第二次调整、soft quest、一次设施升级。
6. **M5 Lifecycle/Boss/Android**：offline anchor、1-5、设备矩阵、5 人观察测试。

相关 skills：`godot-project-setup`、`resource-pattern`、`save-load`、`mobile-development`、`responsive-ui`、`godot-ui`、`component-system`、`event-bus`、`inventory-system`、`state-machine`、`animation-system`、`godot-testing`。

## 10. Verification, Baseline and Android

### Dirty-worktree baseline

- 在创建 `game/` 前保存 HEAD、`git status --porcelain=v2 -z --untracked-files=all`、unstaged/cached binary patches、各自 NUL path list、untracked/dirty existing content SHA-256、MISSING sentinel、`project-a` 全文件 manifest与 artifact hashes。
- `capture_worktree_baseline.sh` 路径处理**全程 NUL**：`git diff --name-only -z`、`git diff --cached --name-only -z`、`git ls-files -z --others --exclude-standard`；hash manifest 记录为 `sha256\0path\0`，禁止按 newline 解析。`project-a` 路径源用 `git ls-files -z --cached --others --exclude-standard -- project-a`。
- 每 milestone 重采；批准差异只允许 `game/**`、`.omx/**`。若用户同时修改其他路径，立即停并重新确认 baseline，不自行回滚。

### GUT gate and commands

- 仅采用官方 GUT 明确支持 Godot 4.7.1 的 tag/commit；锁 checksum，保留实际 LICENSE，headless smoke。兼容/许可/checksum 任一不明则不 vendor，回报用户。

```bash
godot --version
godot --headless --path game --editor --quit
godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
godot --headless --path game -s tools/validate_content.gd
godot --headless --path game -s tools/simulate_first_30m.gd -- --manifest=res://tests/fixtures/battle/paired_1000_v1.json
git diff --check -- game .omx
```

### Android export/install/finite logs

```bash
mkdir -p game/build/android
godot --headless --path game --export-debug "Android Debug" game/build/android/fantasy_idle-debug.apk
shasum -a 256 game/build/android/fantasy_idle-debug.apk
adb devices -l
adb install -r game/build/android/fantasy_idle-debug.apk
adb shell am force-stop com.caesar.fantasyidle.prototype
adb shell monkey -p com.caesar.fantasyidle.prototype -c android.intent.category.LAUNCHER 1
adb shell pidof -s com.caesar.fantasyidle.prototype
adb logcat -d --pid="$(adb shell pidof -s com.caesar.fantasyidle.prototype)" > game/build/android/logcat.txt
```

- 使用 `logcat -d` 有限 dump，不开无限阻塞 stream；设备 runner 对 install/launch/pid 各设 60 秒超时并在失败时保存全局 `adb logcat -d -t 2000`。
- 设备：Low API26/3GB/720x1600；Main API33/6GB/1080x2400；Current/cutout API35+/8GB/异形屏。发布 target/compile SDK 以当时 Godot 4.7.1 template/官方要求为准，不凭记忆锁死。
- M5：Main 目标 60fps、Low 下限 30fps；30 分钟峰值 RAM <300MB、持续增长 <20MB。超标才启动 `$performance-goal`。

## 11. Playtest Pre-registration and Evidence

### Fixed P01-P05 manifest

- 在测试招募/运行前把 `game/tests/fixtures/playtest/p01-p05-seeds-v1.json` 纳入同一 game release-candidate Git commit，固定：P01=`0x0123456789abcdef`、P02=`0x1020304050607080`、P03=`0x7ffffffffffffffe`、P04=`0x13579bdf2468ace0`、P05=`0x55aa55aa33cc33cc`。不得因先看结果换 seed/participant 映射；仓库可保留 baseline 已记录的无关用户 dirty changes，但 `game/**` 不得有未记录漂移。
- 每次 test run 另冻结 `.omx/evidence/m5/<run_id>/manifest.json`：Git HEAD、APK SHA-256、PCK/content bundle SHA-256、所有 `.tres` sorted hash、economy fixture hash、seed/golden fixture hashes、Godot version、设备/API/RAM、P01-P05 assignment；整个 manifest 再 SHA-256 并在首位参与者开始前 timestamp/sign-off。
- 仅 UI 文案/布局改动且 battle/content/economy/golden hashes 完全不变：同 P/seed 可定向重测，但结果标 `retest`，不能与首次结果混算。任何战斗、成长、装备、任务、经济、seed algorithm 或 content hash 改动：原最终证据失效，新增并预提交新 cohort `p06-p10-seeds-v2.json`（全新 5 seed + 5 名未玩过的新参与者），重新完整测试；不得只重跑失败者，也不得让已学习系统的 P01-P05 冒充新用户。
- 中断/设备故障保留记录；同 participant 用同 seed 从新档重开。更换 participant 需预先追加 `P06` 固定 seed 和原因，不能删除失败 run。

### Observation script and thresholds

- 5 名未参与开发的目标用户，匿名 P01-P05。统一开场：“请像自己下载的新游戏一样玩 30 分钟，可以说出想法；我不会教操作。”卡住 120 秒才可给中性提示，提示后行为不算 unprompted。
- 10 checkpoints：8 英雄；解释职业；解释资质/天赋；第一次 unprompted 编队；1-3 败后胜；查看稀有词条；合理装备；第二次 unprompted 编队；理解任务可跳过；1-5 败后胜。
- 每个 critical（8 英雄、2 差异、2 次编队、稀有装备、败后胜）>=4/5；总计 >=45/50；无人被任务硬锁/崩溃阻断。阈值未达则 M5 失败。
- Evidence 每人记录 build/manifest hash、device、seed、timecode、干预、formation before/after/reason、装备、1-3/1-5 action chain、10 checkpoint；无 PII。

### Acceptance traceability

| Source criterion | Evidence |
|---|---|
| 8 英雄、2 差异、2 编队、稀有件、败后胜、任务软引导（L130-L135） | first_30m integration + 10 checkpoints + 4/5/45-of-50 thresholds |
| seed 复现（L139） | length-prefix SHA golden + paired 1000 + cross save_id/FPS/device digest |
| pause/offline（L140） | foreground20/background5、重复 resume、crash matrix、Android kill |
| 重启恢复（L141） | round-trip、backup、schema migration |
| Resource 不污染（L142） | 测试前后 content hash 0 change |
| reward once（L143） | ID fingerprint mismatch、600 replay、claim/offline crash rows |
| 无效 formation（L144） | load validator 缺失 hero fixture，拒绝或规则化修复、0 dangling ID |

## 12. Risks and Stop Rules

| 风险 | Stop/Mitigation |
|---|---|
| 前台时间误算离线 | offline 只认 anchor；60s heartbeat；pause durable；20m+5m golden test |
| 调用方降级 durability | sealed executor registry；未知 type 拒绝；分类 contract test |
| ID 重用偷换 payload | canonical fingerprint；mismatch hard error |
| >512 后任务重放 | value ledger save-lifetime；quest causal receipt 到 lifecycle end；600 replay |
| seed/样本挑选 | manifest 预提交、save_id 排除、paired before/after、hash sign-off |
| 战力遮蔽差异 | debug_power 不进默认 UI/排序/逻辑；观察 rubric 必须解释维度 |
| 数值墙 | 单一干预 paired delta <30pp 则 content validation 失败 |
| dirty tree 污染 | NUL-safe full baseline；越界立即停，不回滚用户改动 |

## 13. ADR Draft: ADR-0001 Durable Domain Kernel

### Decision

独立 `game/` 采用 Godot 4.7.1 GDScript 的 A1+B1：只读 Resource、persistent GameState、executor-enforced command class、canonical fingerprints、durability barrier、唯一 offline anchor、transient deterministic BattleSession、薄 Autoload/Control 表现，按 vertical slice 交付。

### Drivers

- P0 乐趣需最早真人验证；价值、时间与随机结果需在应用 crash/kill 下可解释、可复现。
- 移动生命周期不保证后台运行；场景与 UI 不应成为持久真值。
- 内容扩展以 Resource 为主，协议变化受 Architect 评审。

### Alternatives and antithesis

- Node 真值的 strongest case：Godot 工作流更快、signal 自然、切片短，领域协议可能过建。回应：保留 Node 表现，但 offline/save/fixed seed 是当前产品要求；用 sealed 小型 registry 和禁止框架控制样板。
- ECS strongest case：未来多队/批模拟自然。回应：当前 4vN 不偿还成本；BattleSimulator 接口保留未来替换边界。
- Horizontal delivery strongest case：专家并行更快。回应：允许 Team lane，但 milestone 只按端到端证据关闭。

### Consequences

- 收益：durable value once、跨 save_id/FPS/设备复现、headless 验证、UI/内容可迭代。
- 代价：每分钟 heartbeat I/O、candidate clone、receipt ledger 和 DTO 样板；critical command 有同步 I/O latency。
- 缓解：首版 state 小；value/heartbeat 合并写；非 value debounce；profiling 超预算才优化。
- Follow-ups：M1 冻结 schema/time/receipt；M3 写 targeting ADR；美术/朝向/双平台确定后写 UI/export ADR；多队证实后重评 ECS。

## 14. Staffing, Launch and Team Verification

### Agent roster

| Type | 责任 | Reasoning |
|---|---|---|
| explore | CLI/version/worktree/dependency fact gathering | medium |
| planner | PRD/economy/milestones/manifests | high |
| architect | command/time/receipt/battle/lifecycle | xhigh |
| executor | domain/scenes/tests | high；persistence/battle xhigh |
| designer | mobile IA/hero readability/playtest | high |
| document-specialist | Godot 4.7.1/GUT/Android official verification | medium |
| code-reviewer | contract/crash/scope review | high |
| tester/verifier | golden/paired/device/hash/final independent approval | high |

### Ultragoal + Team

- `$ultragoal` 默认持有 M0-M5 账本；milestone 只凭 verifier evidence complete。
- 4 槽：leader/planner；domain executor；presentation executor/designer；independent tester/verifier。M1/M5 可把 presentation lane 临时换 persistence/lifecycle executor，verifier 始终独立。
- ownership：domain 仅 `scripts/{ports,commands,state,definitions,domain,persistence}`；presentation 仅 `scenes/**`、`scripts/ui/**`、assets；fixtures/test design 由 verifier，修复由 executor；`.tres` 由 leader 分配单 owner。

### Launch hints（批准后）

```text
$ultragoal .omx/plans/prd-fantasy-idle-expedition.md
$team .omx/plans/prd-fantasy-idle-expedition.md
```

附着 tmux 时可用等价 `omx team`；当前 Codex App 外部 surface 不直接启动 tmux。`$ralph` 仅用户明确选择单 owner fallback。

### Team verification path

1. executor 提交变更映射、测试、原始命令输出，不自批。
2. code-reviewer 顺序审 command classification/fingerprint、time fields、receipt retention、seed/battle 和 Source Spec。
3. verifier 从预注册 manifest 重跑全量 headless、golden、600 replay、paired 1000、经济、Android、NUL baseline scope。
4. leader 仅在 build/content/fixture hash 与 evidence 全齐后关闭 checkpoint。

### Goal-mode suggestions

- `$ultragoal`（推荐）：耐久顺序目标；`$team`：同 slice 并行；`$performance-goal`：仅设备超 RAM/FPS 门槛；`$autoresearch-goal`：独立研究；`$ralph`：显式 fallback。

## 15. Planning Exit Criteria

Architect 必须确认四时间字段无重叠职责、command 分类不可被调用者降级、receipt >512 安全、seed golden 跨平台、paired run 公平；Critic 必须确认全部 Source Spec 验收可执行并 APPROVE。最终 PRD/test-spec 吸收复审前不进入 M0。

## 16. v2 -> v3 Changelog

- 将 `offline_anchor_unix` 定为唯一 accrual 起点，拆清 saved_at/last_seen/last_settled 职责；增加 pause candidate、60s heartbeat、20m 前台 + 5m 后台和失败边界。
- 增加 executor sealed command 分类；DURABLE_VALUE 覆盖招募、培养、强化、设施、领奖、战斗、离线及 attempt reservation。
- receipt 增加 canonical length-prefixed SHA-256 fingerprint，同 ID 不同 fingerprint hard error。
- 明确 `/root/AppLifecycle` Autoload、project.godot 注册顺序、首次启动 durable bootstrap 与跨 scene 存活。
- 增加 L1-L5 XP/经验书/属性/资质曲线、战斗映射与 debug_power UI 禁令。
- 增加 P01-P05 固定 seed、build/content/APK/fixture hash、重测和 cohort replacement 规则。
- 明确长度前缀 UTF-8 + SHA-256 + u64 big-endian seed 算法、三个 golden vectors；save_id 永不参与 seed。
- 增加预注册 1000 个同 seed paired before/after、唯一 intervention 和 >=30pp 门槛。
- 将价值 receipt 保留到 save lifetime、任务 causal receipt 保留到相关任务 lifecycle 结束；增加 600 条后重放测试。
- 增加 command class × crash point 矩阵，并把 exact-once 限定为单设备应用 crash/kill 模型。
- Android log 改为有限 `logcat -d`；增加 transform/tie-break/hash golden fixtures 与全程 NUL-safe dirty manifest。
