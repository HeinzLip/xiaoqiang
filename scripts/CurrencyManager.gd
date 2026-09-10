extends Node

signal run_gold_changed(amount: int)
signal banked_gold_changed(amount: int)

const SAVE_PATH := "user://player_progress.cfg"

## UI 元数据 (成本与每级数值在 BalanceConfig 单一数据源)
const UPGRADE_INFO: Dictionary = {
	"health": {"name": "体魄", "description": "生命上限 +20"},
	"speed": {"name": "迅捷", "description": "移动速度 +30"},
	"damage": {"name": "火力", "description": "所有武器伤害 +12%"},
}

var banked_gold := 0
var run_gold := 0
var last_carried_gold := 0
var _run_active := false
var _upgrade_levels: Dictionary = {"health": 0, "speed": 0, "damage": 0}

func _ready() -> void:
	_load_progress()

func begin_run() -> void:
	run_gold = 0
	last_carried_gold = 0
	_run_active = true
	run_gold_changed.emit(run_gold)

func add_run_gold(amount: int) -> void:
	if not _run_active or amount <= 0:
		return
	run_gold += amount
	run_gold_changed.emit(run_gold)

func finish_run() -> int:
	if not _run_active:
		return 0
	var carried_gold := run_gold
	last_carried_gold = carried_gold
	banked_gold += carried_gold
	run_gold = 0
	_run_active = false
	run_gold_changed.emit(run_gold)
	banked_gold_changed.emit(banked_gold)
	_save_progress()
	return carried_gold

func get_upgrade_keys() -> Array[String]:
	return ["health", "speed", "damage"]

func get_upgrade_name(upgrade_key: String) -> String:
	return str(UPGRADE_INFO.get(upgrade_key, {}).get("name", "未知强化"))

func get_upgrade_description(upgrade_key: String) -> String:
	return str(UPGRADE_INFO.get(upgrade_key, {}).get("description", ""))

func get_upgrade_level(upgrade_key: String) -> int:
	return int(_upgrade_levels.get(upgrade_key, 0))

func get_upgrade_cost(upgrade_key: String) -> int:
	var cost_info: Dictionary = BalanceConfig.UPGRADE_COST.get(upgrade_key, {})
	if cost_info.is_empty():
		return 0
	return int(cost_info["base"]) + get_upgrade_level(upgrade_key) * int(cost_info["step"])

func purchase_upgrade(upgrade_key: String) -> bool:
	if not UPGRADE_INFO.has(upgrade_key):
		return false
	var cost := get_upgrade_cost(upgrade_key)
	if banked_gold < cost:
		return false
	banked_gold -= cost
	_upgrade_levels[upgrade_key] = get_upgrade_level(upgrade_key) + 1
	banked_gold_changed.emit(banked_gold)
	_save_progress()
	return true

func get_max_health_bonus() -> float:
	return float(get_upgrade_level("health")) * BalanceConfig.HEALTH_PER_UPGRADE

func get_move_speed_bonus() -> float:
	return float(get_upgrade_level("speed")) * BalanceConfig.SPEED_PER_UPGRADE

func get_damage_multiplier() -> float:
	return 1.0 + float(get_upgrade_level("damage")) * BalanceConfig.PERM_DAMAGE_PER_LEVEL

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	banked_gold = maxi(int(config.get_value("currency", "banked_gold", 0)), 0)
	var saved_upgrades: Variant = config.get_value("currency", "upgrades", {})
	if saved_upgrades is Dictionary:
		for upgrade_key in _upgrade_levels:
			_upgrade_levels[upgrade_key] = maxi(int(saved_upgrades.get(upgrade_key, 0)), 0)

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("currency", "banked_gold", banked_gold)
	config.set_value("currency", "upgrades", _upgrade_levels)
	config.save(SAVE_PATH)
