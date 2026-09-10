extends Node

## 单局数值验收数据。只记录正式关卡，暂停选择强化时不累计战斗时间。
const TTK_KEYS := ["normal", "elite", "boss"]

var _run_active := false
var _elapsed_seconds := 0.0
var _level_name := ""
var _difficulty_name := ""
var _first_damage_time_by_enemy_id: Dictionary = {}
var _ttk_total_by_kind := {"normal": 0.0, "elite": 0.0, "boss": 0.0}
var _ttk_count_by_kind := {"normal": 0, "elite": 0, "boss": 0}
var _damage_by_kind := {"normal": 0.0, "elite": 0.0, "boss": 0.0}
var _final_report: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	if _run_active:
		_elapsed_seconds += delta

func begin_run(level_name: String, difficulty_name: String) -> void:
	_run_active = true
	_elapsed_seconds = 0.0
	_level_name = level_name
	_difficulty_name = difficulty_name
	_first_damage_time_by_enemy_id.clear()
	_final_report.clear()
	for key in TTK_KEYS:
		_ttk_total_by_kind[key] = 0.0
		_ttk_count_by_kind[key] = 0
		_damage_by_kind[key] = 0.0

func register_enemy(enemy: Enemy) -> void:
	if not _run_active or enemy == null:
		return
	# 敌人出生到进入战斗的移动时间不属于 TTK；首次有效受伤时才开始计时。
	_first_damage_time_by_enemy_id.erase(enemy.get_instance_id())

func record_damage(enemy: Enemy, amount: float) -> void:
	if not _run_active or enemy == null or amount <= 0.0:
		return
	var enemy_id := enemy.get_instance_id()
	if not _first_damage_time_by_enemy_id.has(enemy_id):
		_first_damage_time_by_enemy_id[enemy_id] = _elapsed_seconds
	var kind := _get_enemy_kind(enemy)
	_damage_by_kind[kind] = float(_damage_by_kind[kind]) + amount

func record_defeat(enemy: Enemy) -> void:
	if not _run_active or enemy == null:
		return
	var enemy_id := enemy.get_instance_id()
	var kind := _get_enemy_kind(enemy)
	if _first_damage_time_by_enemy_id.has(enemy_id):
		var ttk := maxf(_elapsed_seconds - float(_first_damage_time_by_enemy_id[enemy_id]), 0.0)
		_ttk_total_by_kind[kind] = float(_ttk_total_by_kind[kind]) + ttk
		_ttk_count_by_kind[kind] = int(_ttk_count_by_kind[kind]) + 1
		_first_damage_time_by_enemy_id.erase(enemy_id)

func finish_run(carried_gold: int) -> void:
	if not _run_active:
		return
	_run_active = false
	var total_damage := 0.0
	for key in TTK_KEYS:
		total_damage += float(_damage_by_kind[key])
	_final_report = {
		"level_name": _level_name,
		"difficulty_name": _difficulty_name,
		"elapsed_seconds": _elapsed_seconds,
		"player_level": PlayerExperienceSystem.current_level,
		"kills": CountManager.get_destroyed_enemy(),
		"carried_gold": maxi(carried_gold, 0),
		"total_damage": total_damage,
		"average_dps": 0.0 if _elapsed_seconds <= 0.0 else total_damage / _elapsed_seconds,
		"ttk_total_by_kind": _ttk_total_by_kind.duplicate(),
		"ttk_count_by_kind": _ttk_count_by_kind.duplicate(),
	}

func get_report_text() -> String:
	if _final_report.is_empty():
		return "本局尚无可用的数值报告"
	var lines: Array[String] = []
	lines.append("战斗 %s · 等级 %d · 击败 %d" % [
		_format_duration(float(_final_report["elapsed_seconds"])),
		int(_final_report["player_level"]),
		int(_final_report["kills"]),
	])
	lines.append("造成伤害 %.0f · 平均 DPS %.1f · 带出金币 +%d" % [
		float(_final_report["total_damage"]),
		float(_final_report["average_dps"]),
		int(_final_report["carried_gold"]),
	])
	var ttk_total: Dictionary = _final_report["ttk_total_by_kind"]
	var ttk_count: Dictionary = _final_report["ttk_count_by_kind"]
	lines.append("实测 TTK  普通 %s / %.1fs  精英 %s / %.1fs  Boss %s / %.1fs" % [
		_format_ttk("normal", ttk_total, ttk_count), BalanceConfig.TTK["normal"],
		_format_ttk("elite", ttk_total, ttk_count), BalanceConfig.TTK["elite"],
		_format_ttk("boss", ttk_total, ttk_count), BalanceConfig.TTK["boss"],
	])
	return "\n".join(lines)

func _get_enemy_kind(enemy: Enemy) -> String:
	if enemy.is_boss:
		return "boss"
	if enemy.is_elite:
		return "elite"
	return "normal"

func _format_ttk(kind: String, totals: Dictionary, counts: Dictionary) -> String:
	var count := int(counts.get(kind, 0))
	if count <= 0:
		return "--"
	return "%.1fs" % (float(totals.get(kind, 0.0)) / float(count))

func _format_duration(seconds: float) -> String:
	var total_seconds := maxi(roundi(seconds), 0)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
