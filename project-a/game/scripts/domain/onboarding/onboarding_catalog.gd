class_name OnboardingCatalog
extends RefCounted

const CATALOG_VERSION: int = 4

# 新手链先建立 Gman 单人攻城体验，再用 1-4 首败暴露增援需求。
# 工厂经营和角色成长不得出现在首次出征之前。
const TASKS: Array[Dictionary] = [
	{
		"id": "operation.lone_vanguard",
		"title": "行动一：孤身先锋",
		"lesson": "让 Gman 直接进攻第一座城镇，先体验自动推进与技能介入。",
		"reward": {"toilet_coins": 30},
		"objectives": [
			{
				"id": "capture_1_1",
				"label": "使用 Gman 攻克 1-1 无防备城市",
				"event_type": "battle_settled",
				"stage_id": "stage_1_1",
				"outcome": "victory",
				"target": "expedition",
				"stage_target": "stage_1_1",
				"cta_label": "立即进攻 1-1",
			},
		],
	},
	{
		"id": "operation.keep_advancing",
		"title": "行动二：压力升级",
		"lesson": "连续突破远程守军与轻炮预警；关卡战果已经包含工业材料。",
		"reward": {},
		"objectives": [
			{
				"id": "capture_1_2",
				"label": "攻克 1-2 城市警报",
				"event_type": "battle_settled",
				"stage_id": "stage_1_2",
				"outcome": "victory",
				"target": "expedition",
				"stage_target": "stage_1_2",
				"cta_label": "继续进攻 1-2",
			},
			{
				"id": "capture_1_3",
				"label": "攻克 1-3 联盟集结",
				"event_type": "battle_settled",
				"stage_id": "stage_1_3",
				"outcome": "victory",
				"target": "expedition",
				"stage_target": "stage_1_3",
				"cta_label": "继续进攻 1-3",
			},
		],
	},
	{
		"id": "operation.high_wall",
		"title": "行动三：撞击高墙",
		"lesson": "挑战 1-4 重炮防线；这次失败会揭示 Gman 缺少前排增援。",
		"reward": {"toilet_coins": 70},
		"objectives": [
			{
				"id": "fail_1_4",
				"label": "完成 1-4 首次挑战并寻找失败原因",
				"event_type": "battle_settled",
				"stage_id": "stage_1_4",
				"outcome": "defeat",
				"target": "expedition",
				"stage_target": "stage_1_4",
				"cta_label": "挑战 1-4 高墙",
			},
		],
	},
	{
		"id": "operation.research_reinforcements",
		"title": "行动四：研究突破",
		"lesson": "启动一次免费的研究突破十连，确定获得冲锋与装甲两名永久援军。",
		"reward": {},
		"objectives": [
			{
				"id": "resolve_research_breakthrough",
				"label": "完成研究突破十连",
				"event_type": "research_breakthrough_resolved",
				"target": "research",
				"cta_label": "启动免费十连",
			},
		],
	},
	{
		"id": "operation.counterattack",
		"title": "行动五：带队反攻",
		"lesson": "让两名新马桶人加入编队，分担重炮火力并攻克灰镜高墙。",
		"reward": {
			"toilet_coins": 80,
			"hero_shards": 4,
			"skill_chips": 1,
			"porcelain": 18,
			"parts": 10,
			"sludge": 8,
		},
		"objectives": [
			{
				"id": "capture_1_4",
				"label": "带领三人编队攻克 1-4 灰镜高墙",
				"event_type": "battle_settled",
				"stage_id": "stage_1_4",
				"outcome": "victory",
				"target": "expedition",
				"stage_target": "stage_1_4",
				"cta_label": "反攻 1-4",
			},
		],
	},
	{
		"id": "operation.choose_growth",
		"title": "行动六：选择成长",
		"lesson": "比较冲锋与装甲的职责差异，选择一名升到二星；两条路线都能改变 Boss 战结果。",
		"reward": {},
		"objectives": [
			{
				"id": "complete_combat_growth",
				"label": "选择冲锋或装甲马桶人升到二星",
				"event_types": [
					"hero_star_upgraded",
					"permanent_hero_star_upgraded",
				],
				"archetype_ids": ["assault", "armored"],
				"target": "legion",
				"cta_label": "比较两名援军",
			},
		],
	},
	{
		"id": "operation.chapter_boss",
		"title": "行动七：摧毁灰镜核心",
		"lesson": "用刚才选择的永久成长击破核心巨炮，完成工厂—军团—攻城闭环。",
		"reward": {"industrial_tech": 8, "hero_shards": 4},
		"objectives": [
			{
				"id": "capture_1_5",
				"label": "击败 1-5 灰镜核心巨炮",
				"event_type": "battle_settled",
				"stage_id": "stage_1_5",
				"outcome": "victory",
				"target": "expedition",
				"stage_target": "stage_1_5",
				"cta_label": "进攻章节 Boss",
			},
		],
	},
]
const HURDLES: Dictionary = {
	"operation.lone_vanguard": {
		"scale": "小坎", "title": "第一次出征",
		"reason": "还不熟悉自动推进与主动技能。",
		"recovery": "直接进攻 1-1；失败无永久损失，可立即重试。",
	},
	"operation.keep_advancing": {
		"scale": "小坎", "title": "远程与轻炮施压",
		"reason": "敌人开始从安全距离持续消耗 Gman。",
		"recovery": "观察炮击预警，在满能量时释放技能。",
	},
	"operation.high_wall": {
		"scale": "大坎", "title": "1-4 灰镜高墙",
		"reason": "单人 Gman 缺少承伤与快速压制职责；首战预期会失败。",
		"recovery": "完成首战后用保障币建研究所，启动免费突破十连。",
	},
	"operation.research_reinforcements": {
		"scale": "中坎", "title": "把失败战报转成援军",
		"reason": "研究所已经定位两种关键职责，但需要玩家主动启动突破。",
		"recovery": "免费十连固定获得冲锋与装甲，不消耗招募券或长期保底。",
	},
	"operation.counterattack": {
		"scale": "中坎", "title": "把援军变成战力",
		"reason": "新角色未上阵就不会改变战斗结果。",
		"recovery": "将冲锋、装甲放入前排，再反攻 1-4。",
	},
	"operation.choose_growth": {
		"scale": "中坎", "title": "1-5 巨炮前的成长选择",
		"reason": "基础三人编队无法稳定跨过 Boss 巨炮。",
		"recovery": "冲锋二星或装甲二星都是已验证路线，按喜欢的职责选择。",
	},
	"operation.chapter_boss": {
		"scale": "大坎", "title": "灰镜核心巨炮",
		"reason": "Boss 会检验刚才选择的成长与炮击应对。",
		"recovery": "读取炮击倒计时，用二星援军压制核心；失败后资产完全保留。",
	},
}


static func count() -> int:
	return TASKS.size()


static func task_at(index: int) -> Dictionary:
	if index < 0 or index >= TASKS.size():
		return {}
	return (TASKS[index] as Dictionary).duplicate(true)


static func task_by_id(task_id: String) -> Dictionary:
	for definition in TASKS:
		if String(definition.get("id", "")) == task_id:
			return (definition as Dictionary).duplicate(true)
	return {}


static func hurdle_for_task(task_id: String) -> Dictionary:
	return (HURDLES.get(task_id, {}) as Dictionary).duplicate(true)
