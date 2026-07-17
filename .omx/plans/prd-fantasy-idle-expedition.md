# 手机端随机英雄放置远征：执行级共识 PRD

> 状态：RALPLAN consensus approved（Architect APPROVE / Critic APPROVE）
>
> 需求源：`.omx/specs/deep-interview-fantasy-idle-expedition.md`（Source Spec）
>
> 上下文：`.omx/context/fantasy-idle-expedition-20260717T080734Z.md`
>
> 测试规格：`.omx/plans/test-spec-fantasy-idle-expedition.md`
>
> 规划基线：`.omx/drafts/ralplan-fantasy-idle-expedition-v3.md`

## 1. Requirements Summary

### 1.1 产品目标

- 制作手机端、单机、休闲放置的 30 分钟 vertical slice；核心体验是培养随机冒险者、理解英雄差异、调整 2 前排 + 2 后排编队并跨过此前失败的关卡（Source Spec L24-L41）。
- 系统主次固定：P0 随机英雄培养与编队；P1 装备词条/无失败强化；P2 三座线性营地设施；5 大 + 16 小任务是软引导，不得硬锁关卡（Source Spec L43-L74）。
- 30 分钟内至少获得 8 名英雄；玩家能理解至少 2 个英雄差异维度；主动换人/换位至少 2 次；获得并使用 1 件可理解的稀有装备；通过成长击败此前失败的关卡（Source Spec L126-L145）。
- 非目标：固定英雄抽卡、重剧情/立绘、复杂营地、多队、转职、星级、套装、联网、商业化、多语言、PvP、公会、云存档（Source Spec L87-L94）。

### 1.2 仓库与技术边界

- 新游戏是独立 `game/` Godot 子项目。现有 `project-a/` 是无关 Godot AI 插件且工作树含用户改动；任何实施 lane 不得修改、移动、格式化、暂存或清理 `project-a/**`。
- 基线：Godot 4.7.1 stable、纯 GDScript、2D、Mobile renderer；Compatibility renderer 做兼容冒烟。原型可逆默认：竖屏 1080x1920、Android-first、灰盒美术。
- `.tres` 只保存只读内容定义；persistent `GameState` 只保存稳定 ID 和实例字段，不保存 Node/Resource；用户存档为 `user://save_v1.json`；领域逻辑必须可 headless 测试（Source Spec L114-L145）。
- 美术主题、最终朝向、商业化、发布平台组合或单机边界改变时必须重新确认（Source Spec L96-L112、L155-L164）。

## 2. RALPLAN-DR Decision Record

### Principles

1. **先证 P0 乐趣**：功能必须促成“看懂差异 -> 调队/培养 -> 过卡点”。
2. **executor 是唯一写入口**：调用方不能自选 durability，也不能绕过同步 command transaction 改 GameState。
3. **价值先持久化再成功**：招募、培养、强化、设施、领奖、战斗、离线结算均在 candidate save 成功后才 swap/回包。
4. **时间与随机性只有一个语义源**：offline 只认 anchor；seed 只认字节算法；战斗逻辑只认 tick_index。
5. **证据预注册**：test seed、build/content hash、paired intervention 与 pass rule 在运行前冻结。

### Top 3 Drivers

1. 5 人观察测试是否证实两次主动编队决策和一次失败后成长再胜。
2. 应用崩溃/杀进程、重复 request/resume 和超过 512 条历史后仍不重复价值或任务进度。
3. 结果能跨 save_id、帧率、设备复现，同时不让调试战力替代英雄差异。

### Architecture Axis

| 选项 | 优点 | 缺点 | 决策 |
|---|---|---|---|
| A1. 领域内核 + 薄 Godot 外壳 | headless、持久化、决定性边界清楚；UI 可换 | command/DTO 样板增加 | **采用**；禁止 DI 框架/ECS/数据库/自定义编辑器插件 |
| A2. Node/场景为状态真值 | 编辑器直观、动画原型快 | Node 难安全保存/重放；跨 screen 易重复状态 | 仅作表现层 |
| A3. ECS/表格批模拟 | 多队/大量单位扩展好 | 当前 4vN 不偿还工具和调试成本 | 多队成为已证需求后重评 |

### Delivery Axis

| 选项 | 优点 | 缺点 | 决策 |
|---|---|---|---|
| B1. Vertical slice milestones | 早验证玩家价值，每步可试玩 | 模块需渐进补齐 | **采用** |
| B2. Horizontal systems | 专家并行清楚 | 整合与乐趣验证过晚 | 仅作为同一 slice 内 Team lane |

最终组合：**A1 + B1**。A2/B2 可以局部使用，但不得改变状态真值与 milestone 关闭标准。

## 3. 30 分钟 Vertical Slice

### 3.1 玩家旅程

| 时间 | 暴露内容 | 必须产生的行为/反馈 |
|---:|---|---|
| 0-3 | 4 名初始英雄、1-1 | 查看职业、资质、天赋，不以综合战力代替理解 |
| 3-7 | 两次券招募、1-2 | 队伍扩到 6 人；第一次 unprompted 换人/换位 |
| 7-12 | 再招 2 人、1-3 首败、训练 | 达到 8 人；培养/调队后通过 1-3 |
| 12-18 | 铁匠、保底稀有件 | 比较词条，合理装备并强化 |
| 18-23 | 1-4 | 第二次 unprompted 编队调整 |
| 23-28 | 三设施入口、一次升级、离线弹窗 | 理解营地是效率辅助而非主系统 |
| 28-30 | 1-5 Boss 首败与复战 | 组合培养、装备、编队后获胜 |

### 3.2 内容预算

- 英雄：4 职业；每职业 1 普攻规则 + 1 主动技能；4 资质；8 天赋/性格；40+ 姓名组合。
- 编队：1 队 4 槽，前 2 后 2；位置影响受击、目标与技能修正。
- 装备：武器/防具/饰品；12 模板；10 词条；白/绿/蓝/紫；+0..+5，无失败/降级。
- 战斗：6 普通敌人 + 1 Boss；5 关，每关 3 波。
- 营地：酒馆/铁匠/训练场，各 3 级、线性升级，无自由摆放。
- 任务：5 大 + 16 小；只观察领域事件，不负责 stage unlock。
- 经济：金币、招募券、经验书、锻造石；无付费货币。
- 灰盒：4 职业 × 2 动画状态、7 敌方剪影、6 VFX、约 30 UI 图标、1 BGM、10 SFX。

### 3.3 0-30 分钟经济

唯一 fixture：`game/tests/fixtures/economy/first_30m_v1.json`。

| 阶段 | Sources | Sinks |
|---|---|---|
| 新档 | 4 英雄、金币 250、书 2 | 无 |
| 1-1 + 任务 | +金币 200、+券 2、+书 2 | 券 2 -> 招 2 人 |
| 1-2 + 任务 | +金币 260、+券 2、+书 2、+石 2 | 券 2 -> 再招 2 人 |
| 1-3 首败（一次） | +金币 60、+书 2 | 推荐训练：书 6、金币 180；换位免费 |
| 1-3 首胜 | +金币 260、+石 4、稀有候选 1 | 强化 +1/+2/+3：金币 80/140/220、石 1/2/3 |
| 1-4 + 任务 | +金币 520、+石 3、+书 3 | 可训练：书 3、金币 120 |
| 营地教学 | +金币 300 | 任一设施升 2 级：金币 300 |
| 1-5 首败（一次） | +金币 80 | 无强制 sink |
| 总计 | 金币 1930、券 4、书 11、石 9 | 推荐金币 960-1080、券 4、书 6-9、石 3-6 |

- 第 8 个合格装备掉落前仍无蓝色以上则升级为蓝色；1-3 首胜也给职业可用蓝色候选，两者取较早者，触发后 pity 归零并持久化。
- 1000-seed 目标：1-1 裸队 95-100%；1-2 80-95%；1-3 干预前 15-30%、单一预注册干预后至少 +30pp；1-4 35-50% -> 75-90%；1-5 干预前 10-25%、单一预注册关键干预后至少 +30pp。

## 4. Hero Progression and Combat Mapping

### L1-L5 经验规则

| Level | 累计 XP | 本级所需 XP | 经验书（20 XP/本） |
|---:|---:|---:|---:|
| 1 | 0 | - | - |
| 2 | 40 | 40 | 2 |
| 3 | 100 | 60 | 3 |
| 4 | 200 | 100 | 5 |
| 5 | 320 | 120 | 6 |

- **最终规则：累计 XP clamp 到 320；达到 L5 后丢弃全部溢出 XP，不保存 overflow。** 单次/批量训练必须得到相同的 `level=5, xp=320`。
- 训练 command 一次声明经验书数量与金币，属于 `DURABLE_VALUE`。
- 四项属性：VIG/STR/AGI/INT。L1 职业基线：守卫 `(14,7,6,4)`、斗士 `(10,12,8,4)`、游侠 `(8,8,13,5)`、秘术师 `(7,4,8,14)`。
- 每级成长（千分整数配置）：守卫 `(2.0,0.8,0.4,0.2)`、斗士 `(1.0,1.8,0.8,0.2)`、游侠 `(0.6,0.8,2.0,0.4)`、秘术师 `(0.5,0.3,0.7,2.1)`。
- 资质倍率 C/B/A/S=`8500/10000/11500/13000` bp，只作用于对应属性成长；定点 remainder 保证逐级与批量一致。L1 每项有 seeded `-1/0/+1` 差异。

### Battle derive

```text
max_hp       = 50 + VIG * 10 + flat_hp
defense      = class_armor + VIG * 2 + flat_def
physical_atk = weapon_power + STR * 3
magic_atk    = focus_power + INT * 3
speed_milli  = 60_000 + AGI * 4_000 + flat_speed_milli
crit_bp      = clamp(500 + AGI * 50 + affix_crit_bp, 0, 5000)
```

- SkillDef 使用 physical/magic coefficient bp；游侠可显式使用 AGI coefficient，不写隐式职业特判。
- `debug_power` 只用于开发日志；不参与 AI、掉落、任务、胜负、默认 UI 或默认排序。debug build 详情若显示必须标“估算”。

## 5. Persistent State and Battle Boundary

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

- GameState 不保存 BattleSession/State、动画或 scene path。
- 手动退出销毁 session、无奖励；后台冻结，不追 wall time；进程存活则同 tick 恢复，被杀则以新 attempt 从 tick 0 重开，无入场资源损失。
- BattleResult 只经 `settle_battle_result` 发奖；失败安慰奖同事务，按 result_id 去重。

## 6. Time and AppLifecycle Contract

### 6.1 时间字段

| 字段 | 唯一职责 | 禁止用途 |
|---|---|---|
| `saved_at_unix` | **成功提交的快照中所记录的该次写入尝试时间**；writer 在序列化 candidate 前赋值，只有该 candidate 成为主档才可见 | 不参与离线时长、回拨或奖励 |
| `last_seen_wall_unix` | 成功事务观察到的最大 wall time，仅用于 anomaly/诊断 | 不作为 accrual 起点，不下降 |
| `last_settled_unix` | 最近一次成功 offline settlement 的结束审计时间 | 不参与下一次 delta |
| `offline_anchor_unix` | 唯一 offline accrual 起点；resume 只算 `now-anchor` | 不被其他字段替代，不下降 |

### 6.2 Explicit Autoload tree

```text
/root/SystemClock    -> res://scripts/autoloads/system_clock.gd
/root/SaveManager    -> res://scripts/autoloads/save_manager.gd
/root/ContentCatalog -> res://scripts/autoloads/content_catalog.gd
/root/EventBus       -> res://scripts/autoloads/event_bus.gd
/root/Game           -> res://scripts/autoloads/game.gd
/root/AppLifecycle   -> res://scripts/autoloads/app_lifecycle.gd
```

- `project.godot` 按上序注册；AppLifecycle 最后、main scene 之前完成 bootstrap。Autoload 跨 scene/reload/battle 销毁存活；scene/screen 禁止直接处理 PAUSED/RESUMED。
- 首启无存档：创建 GameState，`offline_anchor=last_seen=now`、`last_settled=0`，durable 首档成功后才 `game_ready`；不发离线奖。

### 6.3 Sealed lifecycle commands

- `AppLifecycle` **不能直接写 GameState/SaveManager**；它只能调用 `CommandExecutor.execute_internal()`。该 API 要求仅 executor 持有的 internal capability，普通 caller/API 不可构造或降级。
- sealed registry 内部 command：
  - `__lifecycle_pause_anchor`：冻结 battle，candidate `anchor=max(old,now)`、`last_seen=max(old,now)`，durable save -> swap。
  - `__lifecycle_heartbeat_anchor`：前台每 60 秒 candidate 推进 anchor/last_seen，durable save -> swap；可与正在执行的 value write 合并，但不能跳过超过 60 秒。
  - `__lifecycle_resume_settle`：唯一 resume gate，按 anchor 算 delta/cap，credit、推进 anchor/last_settled/last_seen，durable save -> swap。
- 三者固定为 `INTERNAL_DURABLE`（sealed 的 `DURABLE_VALUE` 子类），因此属于完整 durable-value 覆盖面；调用方不能把它们注册为 reversible/ephemeral，也不能绕过 executor 调 SaveManager。
- PAUSED/RESUMED edge 各 250ms 去重。pause save 失败不推进内存 anchor，5 秒预算内串行重试并记录错误。
- resume：`effective_end=max(old_anchor,now)`；`delta=effective_end-old_anchor`；最多 8h；回拨奖励 0 且 anchor/last_settled 不降；前跳超 cap 只发 8h但 anchor 移到 now。
- 无 pause 的系统 kill 最多把最后 60 秒 foreground 算入离线；明确作为 heartbeat 粒度边界。

## 7. Command and Receipt Protocol

### 7.1 Executor-enforced classes

| Class | Types | Policy |
|---|---|---|
| `DURABLE_VALUE` | recruit/train/enhance/upgrade/claim/battle settlement/offline settlement/reserve attempt | candidate -> durable save -> swap -> success |
| `INTERNAL_DURABLE` | pause anchor/heartbeat anchor/resume settlement | internal capability only；同 durable barrier |
| `REVERSIBLE_META` | formation/equip/unequip/filter/rename | candidate -> swap -> 1000ms debounce；允许崩溃丢最近操作 |
| `EPHEMERAL` | navigation/detail/battle ticks/VFX/sort preview | 不进 GameState、不写 receipt/quest/save |

- class 由 sealed registry 决定；envelope/caller 不能提交 class override；未知 type 返回 `UNKNOWN_COMMAND`。
- Domain service 改 candidate 并产生 DomainEvent；纯 QuestReducer 在同事务更新任务，不发奖/command/读取 UI。
- claim 顺序：存在 -> complete -> unclaimed -> 解析定义 -> 标 claimed -> credit -> event/reducer -> invariants -> receipt -> durable save -> swap -> success。

### 7.2 Canonical fingerprint

- Envelope：command_id/type/payload/business_key/expected_revision/requested_at。
- payload 只允许 null/bool/int/UTF-8 string/ordered array/string-key dictionary；key 按 UTF-8 byte 排序；禁 float/Node/Resource；无空白 canonical JSON。
- `fingerprint=SHA-256(LP(type)||LP(canonical_payload)||LP(business_key))`；LP 是 uint32 big-endian length + UTF-8 bytes。
- 同 command ID + 同 fingerprint 返回原 receipt；同 ID + 不同 fingerprint 为 `COMMAND_ID_REUSE_MISMATCH`。同 business key + 不同 fingerprint 为 `BUSINESS_KEY_REUSE_MISMATCH`。两者均不执行。

### 7.3 Retention

- DURABLE_VALUE business receipts 保留整个 save lifetime，不进 512 ring。
- 能推进任务的 command receipt/event IDs 保留至所有相关任务 terminal 且 claimed/retired；活跃 QuestState 保存 consumed_event_ids，terminal 后永久忽略新旧 event。
- 仅不转移价值、不推进任务的 reversible receipt 可进入 512 ring。
- 强制测试：600 条任务相关 formation/equip 后重放第 1/256/512 条，progress/reward 不变；terminal/claimed 后亦不变。

### 7.4 Crash scope

exact-once 仅承诺单设备、单 writer、应用崩溃/Android 杀进程；不承诺文件回滚/root 修改/云合并/多进程并写/介质谎报 fsync/恶意时钟。

- DURABLE：rename 前旧档，重试执行一次；rename 后新档含 value + receipt，重试原结果。
- REVERSIBLE：memory swap 后、debounce rename 前崩溃可丢最近操作，但不会半状态。
- Offline/claim：anchor/claimed、credit 与 receipt 必须在同 snapshot。
- SaveManager 单 writer；state_revision 低于 last durable 的请求拒绝；barrier 取消 pending debounce、等待旧 in-flight，再写 candidate。
- 文件：tmp write -> flush/close -> parse/validate -> 备份主档 -> atomic rename；主档坏才回退 `.bak` 并保留 corrupt 文件。

## 8. Deterministic Seed and Battle

### Seed algorithm

- 每字段 UTF-8，编码 `uint32_be(length)||bytes`，顺序拼接后 SHA-256；取前 8 bytes 为 unsigned u64 big-endian；传 Godot signed int 时用 two's complement。
- battle parts：`[battle-seed-v1, content_version, stage_id, decimal(attempt), run_seed_token]`。生产 token 为 unsigned run_seed 十进制；onboarding 为 literal `onboarding-v1`。save_id 永不进入 seed。
- Golden fixture：`game/tests/fixtures/golden/seed_hash_v1.json`，至少包含：
  - stage-1-3 SHA `871416107395887412f0fe2604e0bc00d5c958abe112a670d82455031480b532`，seed `0x8714161073958874`。
  - stage-1-5 SHA `7c3345f99bb534e9fc0affe8e81ca5250ce492daaadc6d487d801f3c6b380be2`，seed `0x7c3345f99bb534e9`。

### Battle

- 5Hz、dt=.2、单调 tick_index；局部 RngPort；禁止全局 rand；整数行动条阈值 100000；百分比 basis points。
- tie-break：overflow DESC -> speed DESC -> formation slot ASC -> stable unit ID UTF-8 ASC；同权目标排序后再局部 RNG。
- 每 frame 最多追 5 ticks；积压 >1s 时逻辑继续，表现可丢普通挥击/飘字，不得丢死亡、波次、关键技能、终局；队列上限 10 ticks/2s。
- PAUSED 清 accumulator，不把后台 wall time灌入战斗。

### Paired 1000

- `game/tests/fixtures/battle/paired_1000_v1.json` 预注册 1000 run seeds、content/stage/before hash、唯一 intervention command。
- 同 seed before/after 唯一变量：1-3 仅 set_formation；1-5 仅 equip guaranteed rare。`mean(after_win-before_win)>=.30`；不得事后换 seed/intervention。

## 9. Safe Area and Touch

- PlatformMetrics 用 `Viewport.get_screen_transform().affine_inverse()` 把 physical safe rect 两角转逻辑坐标，Margin 取逻辑 rect 与 safe rect 差的非负值。
- Android `px_per_dp=max(dpi,160)/160`，unknown fallback 1；`48*px_per_dp` 经 inverse basis 转逻辑宽高，取较大轴作为 tap token。
- ready deferred、viewport size、orientation、screen/window、resume 重算；旋转后 100ms trailing debounce。
- Golden fixture：`game/tests/fixtures/golden/safe_area_transforms_v1.json`；tie-break fixture：`game/tests/fixtures/golden/battle_tiebreak_v1.json`。

## 10. Proposed Files

```text
game/
├── project.godot / export_presets.cfg / README.md / CLAUDE.md / .gitignore / .gitattributes
├── addons/gut/                         # exact commit + LICENSE
├── assets/{audio,fonts,sprites,ui}/
├── resources/definitions/{classes,skills,traits,enemies,equipment,affixes,stages,quests,facilities}/
├── scenes/{app,battle,screens,dialogs,ui}/
├── scripts/
│   ├── autoloads/{system_clock,save_manager,content_catalog,event_bus,game,app_lifecycle}.gd
│   ├── app/{platform_metrics,screen_router}.gd
│   ├── ports/{clock_port,rng_port,godot_rng,scripted_rng}.gd
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
│   └── fixtures/{economy,battle,playtest,golden,saves}/
└── tools/{validate_content.gd,simulate_first_30m.gd,capture_worktree_baseline.sh,run_headless_tests.sh,smoke_project.sh}
```

`tools/` 在目录规划中仅以上述一条作为唯一入口，不再复制第二套工具路径或命令所有权。

## 11. Implementation Milestones

| Milestone | 实施内容 | Exit criteria |
|---|---|---|
| M0 Baseline/project shell | 先采 dirty baseline；独立 project、显式 Autoload、SafeArea、GUT gate | game 独立 headless 启动；autoload 顺序测试；project-a manifest 不变 |
| M1 Transaction/time spine | registry/fingerprint/receipts、internal lifecycle commands、QuestReducer、SaveManager、四时间字段 | crash matrix、20m+5m、600 replay、backup/migration 全过 |
| M2 Hero/formation | L1-L5 clamp、4 职业/资质、8 英雄、第一次调整 | progression golden；差异可读；固定 seed 8 人 |
| M3 Deterministic 1-3 | stable seed、5Hz、golden fixtures、paired 1000 | 1-3 先败后胜；paired +30pp；跨 FPS digest 相同 |
| M4 Full Meta | economy、pity、装备/强化、第二次调整、soft quest、设施 | ledger、稀有件、跳任务进关、claim once 全过 |
| M5 Lifecycle/Boss/Android | 1-5、offline、三档设备、5 人观察 | 全部 Source Spec 验收和预注册阈值达标 |
| M6 Caesar knowledge map | 仅在 M0-M5 全部完成且实现/测试事实冻结后执行 `caesar-docs:init`；以代码、测试、ADR 和 evidence 为事实源初始化中文知识地图 | 完整最小启动集、仓库入口同步和 `python3 tools/docs_lint.py` 全部通过；docs writer、事实 reviewer、独立 verifier 三方证据齐全 |

M0-M5 skills：`godot-project-setup`、`resource-pattern`、`save-load`、`mobile-development`、`responsive-ui`、`godot-ui`、`component-system`、`event-bus`、`inventory-system`、`state-machine`、`animation-system`、`godot-testing`。M6 必须使用 `caesar-docs:init`，不得在实现完成前凭草案编造长期架构事实。

### M6 locked minimum set and ownership

M6 必须创建并验证以下最小启动集，不得以笼统目录占位替代：

```text
docs/index.md
docs/map/{index,schema,workflows,domains,invariants,glossary}.md
docs/workflows/{knowledge-query,code-locating,impact-map,code-writing-review,knowledge-map-maintenance}.md
docs/memory/index.md
docs/quality/{lint-rules,stale-docs}.md
docs/runbooks/docs-lint.md
docs/decisions/ADR-0001-knowledge-map-structure.md
tools/docs_lint.py
```

- docs/writer lane：仅在 M5 通过后顺序执行 `caesar-docs:init`，从最终 code/config/tests/scripts、已批准 ADR 和 evidence 提取事实；未知内容用 `draft`，不猜测。
- facts reviewer：逐条核对 `source_of_truth`、`validated_by`、领域/反边界、文件归属和命令是否来自冻结实现；作者不得自批。
- independent verifier：运行 `python3 tools/docs_lint.py`，检查每个 Markdown 的 YAML frontmatter/必填字段/枚举/日期、唯一 `km_id`、`related`、domain/tag 注册、`KM:*` 目标 id、相对链接、`CODE:*` 路径、`CMD:*` runbook anchor、`source_of_truth` 和 stale/deleted 路径；再检查 README 与所有已存在的 AGENTS/ARCHITECTURE 入口路由。
- 不存在的 AGENTS.md/ARCHITECTURE.md 不因 M6 自动创建；已有 README 只补知识地图入口和维护提示，不改写产品正文。

## 12. Verification and Evidence

### Core commands

```bash
godot --version
godot --headless --path game --editor --quit
godot --headless --path game -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
godot --headless --path game -s tools/validate_content.gd
godot --headless --path game -s tools/simulate_first_30m.gd -- --manifest=res://tests/fixtures/battle/paired_1000_v1.json
git diff --check -- game .omx
rg '^km_id:' docs
rg 'KM:|CODE:|CMD:' docs
find docs -name '*.md' -print
python3 tools/docs_lint.py
```

### Dirty baseline

- 创建 game 前保存 HEAD、porcelain-v2 NUL status、unstaged/cached binary patches、三类 NUL path list、dirty/untracked hashes、MISSING sentinel、project-a 全 manifest 和 artifact hashes。
- 路径全程 NUL：`git diff --name-only -z`、cached `-z`、`git ls-files -z --others`；hash records 为 `sha256\0path\0`，禁止 newline 解析。
- 每 milestone 重采；只允许批准的 game/.omx 差异。用户并行改动触发停工和 baseline 重确认，不回滚。

### GUT gate

- 只使用官方 GUT 明确支持 4.7.1 的 exact tag/commit；记录 checksum，保留实际 LICENSE；兼容/许可/checksum/headless smoke 任一不明则不 vendor，回报用户。

### Android

```bash
mkdir -p game/build/android
godot --headless --path game --export-debug "Android Debug" game/build/android/fantasy_idle-debug.apk
shasum -a 256 game/build/android/fantasy_idle-debug.apk
adb install -r game/build/android/fantasy_idle-debug.apk
adb shell am force-stop com.caesar.fantasyidle.prototype
adb shell monkey -p com.caesar.fantasyidle.prototype -c android.intent.category.LAUNCHER 1
adb logcat -d --pid="$(adb shell pidof -s com.caesar.fantasyidle.prototype)" > game/build/android/logcat.txt
```

- finite `logcat -d`；runner 对 install/launch/pid 各 60s timeout，失败保存全局最近 2000 行。
- Low API26/3GB/720x1600；Main API33/6GB/1080x2400；Current API35+/8GB/cutout。
- Main 60fps 目标、Low 30fps 下限；30 分钟峰值 RAM <300MB，持续增长 <20MB；超标才启动 performance goal。

### 5-person pre-registration

- RC commit 固定 `game/tests/fixtures/playtest/p01-p05-seeds-v1.json`：P01 `0123456789abcdef`、P02 `1020304050607080`、P03 `7ffffffffffffffe`、P04 `13579bdf2468ace0`、P05 `55aa55aa33cc33cc`。
- 开测前 evidence manifest 冻结 HEAD、APK/PCK/content/所有 tres/economy/seed/golden hashes、Godot version、device 和 participant mapping，并自 hash/sign-off。
- UI-only 且所有领域/content hash 不变可用同 seed 定向 retest但不混算；任何领域/content 变化启用新 P06-P10 cohort + 新 manifest，完整重测，不能只重跑失败者。
- 10 checkpoint 固定；每个 critical >=4/5，总计 >=45/50，无任务硬锁/崩溃阻断。

完整自动、设备、观察与 PRD traceability 见测试规格。

## 13. Risks and Stop Rules

| 风险 | Stop/Mitigation |
|---|---|
| 前台时间误算离线 | anchor-only；sealed heartbeat；20m foreground + 5m background golden |
| caller 降级 durability | sealed registry/internal capability；contract test |
| ID 重用偷换 payload | canonical fingerprint；hard mismatch errors |
| >512 后任务重放 | value save-lifetime ledger；quest causal lifecycle；600 replay |
| seed/样本挑选 | precommit manifest、save_id 排除、paired runs、hash sign-off |
| 战力遮蔽差异 | debug_power 不进默认 UI/排序/逻辑；观察必须解释维度 |
| 数值墙 | paired delta <30pp 则 content validation 失败 |
| dirty tree 污染 | NUL baseline；越界立即停，不回滚用户改动 |
| heartbeat I/O | 与 value save 合并；先测，超过设备预算才优化，不牺牲 60s 边界 |

## 14. ADR-0001: Durable Domain Kernel

### Decision

独立 `game/` 采用 Godot 4.7.1 GDScript 的 A1+B1：只读 Resource、persistent GameState、executor-enforced command classes、sealed internal lifecycle commands、canonical fingerprints、durability barrier、唯一 offline anchor、transient deterministic BattleSession、薄 Autoload/Control 表现，并按 vertical slice 交付。

### Drivers

- P0 乐趣需尽早真人验证；价值、时间与随机结果需在应用 crash/kill 下可解释、可复现。
- 移动生命周期不保证后台运行；场景/UI 不应成为持久真值。
- 内容扩展以 Resource 为主，协议变化受 Architect 评审。

### Alternatives

- Node 真值 strongest case：Godot 工作流快、signal 自然。拒绝原因：offline/save/fixed seed 是当前产品要求；Node 只保留表现职责。
- ECS strongest case：多队批模拟自然。推迟原因：当前 4vN 不偿还成本；BattleSimulator 保留替换边界。
- Horizontal strongest case：专家并行更快。限制：可作为 Team lane，但 milestone 只按端到端证据关闭。

### Consequences

- 收益：durable value once、跨 save_id/FPS/设备复现、headless 验证、UI/内容可独立迭代。
- 代价：60s heartbeat I/O、candidate clone、receipt ledger、DTO 样板、critical command 同步 I/O。
- Follow-ups：M1 冻结 schema/time/receipt；M3 写 targeting ADR；美术/朝向/双平台确认后写 UI/export ADR；多队证实后重评 ECS。

## 15. Agent Roster and Execution Handoff

### Available agent types

| Type | 责任 | Reasoning |
|---|---|---|
| explore | CLI/version/worktree/dependency facts | medium |
| planner | PRD/economy/milestones/manifests | high |
| architect | command/time/receipt/battle/lifecycle | xhigh |
| executor | domain/scenes/tests | high；persistence/battle xhigh |
| designer | mobile IA/hero readability/playtest | high |
| document-specialist | Godot 4.7.1/GUT/Android official verification | medium |
| code-reviewer | contract/crash/scope review | high |
| tester/verifier | golden/paired/device/hash/final approval | high |

### Staffing

- 默认 `$ultragoal` 持有 M0-M6 顺序账本；milestone 只凭 verifier evidence complete。M6 必须在 M5 通过后顺序执行。
- 4 槽：leader/planner；domain executor；presentation executor/designer；independent tester/verifier。M1/M5 可暂时把 presentation lane 换 persistence/lifecycle executor；verifier 始终独立。
- ownership：domain 仅 scripts/ports/commands/state/definitions/domain/persistence；presentation 仅 scenes/scripts/ui/assets；fixtures/test design 由 verifier，修复由 executor；`.tres` 由 leader 分配单 owner。

### Team launch hints（用户批准后）

```text
$ultragoal .omx/plans/prd-fantasy-idle-expedition.md
$team .omx/plans/prd-fantasy-idle-expedition.md
```

附着 tmux 时可用等价 `omx team`；当前 Codex App 外部 surface 不直接启动 tmux。`$ralph` 仅用户明确选择单 owner fallback。

### Independent team verification

1. executor 提交需求映射、改动清单、测试和原始命令输出，不自批。
2. code-reviewer 顺序审 class/fingerprint、time/receipt、seed/battle 和 Source Spec。
3. independent verifier 从预注册 manifest 重跑 headless、golden、600 replay、paired 1000、经济、Android 和 NUL baseline scope。
4. M5 通过后 docs/writer 独占 `docs/**`、`tools/docs_lint.py` 和已有仓库入口，执行 `caesar-docs:init`；不得与 M0-M5 实现 lane 并行。
5. 独立 facts reviewer 核对知识节点仅来自最终 code/tests/ADR/evidence，独立 verifier 运行 docs lint、最小启动集和入口路由检查。
6. leader 仅在 build/content/fixture hash、游戏 evidence 与 M6 docs evidence 齐全后关闭 Ultragoal checkpoint。

### Goal-mode suggestions

- **`$ultragoal`（推荐）**：M0-M6 耐久目标。
- **`$team`**：同 slice 领域/UI/验证并行，与 Ultragoal 联用。
- **`$performance-goal`**：仅设备超过 RAM/FPS 门槛。
- **`$autoresearch-goal`**：后续独立竞品/留存/数值研究。
- **`$ralph`**：仅显式 single-owner fallback。

## 16. Final Exit Criteria

- M0-M6 全部通过且 evidence 可追溯至同一 approved PRD/test spec、build/content/fixture hashes。
- Source Spec L130-L145 每项都有自动或观察证据；技术硬门槛要求 100%，观察 critical >=4/5 且总 >=45/50。
- M6 只能在 M0-M5 完成后从最终代码和验证证据初始化；上列 17 个必需 Markdown 与 `tools/docs_lint.py` 全部存在，lint 零错误；所有 `docs/**/*.md` 均有合法 frontmatter，`km_id` 唯一，`related`/domain/tag/source_of_truth 有效，`KM:*` 可解析，relative/`CODE:*` 路径与 `CMD:*` anchor 存在，README/已有仓库入口正确路由到知识地图。
- `project-a/**` 与 pre-M0 manifest 一致；无越权写入、无未解释 GUT/license 或 Android 设备缺口。
- 未经用户确认不得改变核心循环、系统主次、随机英雄模型、美术主题、商业化、平台或单机边界。

## 17. Changelog: v1 -> v2 -> v3 -> Final

### v1 -> v2

- 拆分架构/交付轴；加入同步 transaction、QuestReducer、durability barrier、offline clone-and-commit、persistent/transient 分层、5Hz/定点/tie-break、Safe Area、经济表、观察脚本、Android/baseline。

### v2 -> v3

- 将 offline_anchor 定为唯一 accrual 起点；sealed command 分类；canonical receipt fingerprint；显式 AppLifecycle；L1-L5 成长；P01-P05 和 paired 1000 预注册；>512 receipt 生命周期；完整 crash matrix；NUL manifest 与 finite logcat。

### v3 -> Final

- 显式 Autoload tree 同时包含 `/root/SystemClock` 与 `/root/AppLifecycle`，并统一实际文件路径和注册顺序。
- pause、heartbeat、resume 改为 sealed `INTERNAL_DURABLE` commands；AppLifecycle 不得绕过 executor/直接写 SaveManager。
- L5 规则统一为累计 XP=320 clamp，丢弃溢出，不保存 overflow。
- `saved_at_unix` 精确表述为“成功提交快照中记录的写入尝试时间”，明确不参与离线计算。
- 目录树只保留一条 `tools/`，正式测试规格独立成文并与 PRD 双向 trace。

### Final -> User-added M6

- 在游戏、自动测试、真机和观察验收全部通过后，强制使用 `caesar-docs:init` 初始化中文知识地图；知识地图成为最终交付门禁，不以聊天或隐藏记忆代替仓库事实。
- 锁定 17 个 Markdown 的最小启动集、`tools/docs_lint.py` 可失败门禁，以及 docs writer -> facts reviewer -> independent verifier 的 M6 顺序所有权。
