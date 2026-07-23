class_name HeroCatalog
extends RefCounted


const CLASS_ORDER: Array[String] = ["guardian", "fighter", "ranger", "arcanist"]
const APTITUDE_ORDER: Array[String] = ["C", "B", "A", "S"]
const TRAITS: Array[String] = [
	"steadfast", "bold", "watchful", "quick", "patient", "fierce", "clever", "kind"
]

const CLASS_BASE_STATS: Dictionary = {
	"guardian": {"vig": 14, "str": 7, "agi": 6, "int": 4},
	"fighter": {"vig": 10, "str": 12, "agi": 8, "int": 4},
	"ranger": {"vig": 8, "str": 8, "agi": 13, "int": 5},
	"arcanist": {"vig": 7, "str": 4, "agi": 8, "int": 14},
}

# Attribute growth per level in thousandths.
const CLASS_GROWTH_MILLI: Dictionary = {
	"guardian": {"vig": 2000, "str": 800, "agi": 400, "int": 200},
	"fighter": {"vig": 1000, "str": 1800, "agi": 800, "int": 200},
	"ranger": {"vig": 600, "str": 800, "agi": 2000, "int": 400},
	"arcanist": {"vig": 500, "str": 300, "agi": 700, "int": 2100},
}

const APTITUDE_BP: Dictionary = {"C": 8500, "B": 10_000, "A": 11_500, "S": 13_000}
const XP_THRESHOLDS: Array[int] = [0, 40, 100, 200, 320]
const MAX_LEVEL: int = 5
const MAX_XP: int = 320

