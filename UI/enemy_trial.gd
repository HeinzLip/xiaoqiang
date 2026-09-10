class_name EnemyTrial extends Node2D
## 怪物试炼场: 玩家无敌可自由移动 (WASD), 选择怪物类型 + 原型 (默认/tank/fast/ranged)
## 批量生成, 观察不同怪物的移速/血量/远程攻击/动画表现。带默认子弹武器可击杀观察受击/死亡动画。
## 试炼怪经验设为 0 (避免击杀升级弹技能选择导致暂停卡死), 金币掉落正常(无害)。

const ENEMY_SCENE := preload("res://scenes/enemy/Enemy.tscn")
const SPAWN_COUNT := 6
const SPAWN_RADIUS := 340.0
## 试炼固定基值: 用中等关卡血量, 配合原型乘数直观对比 (fast=20/tank=120/ranged=20)
const TRIAL_BASE_HP := BalanceConfig.ENEMY_HP_BY_LEVEL[1]
const TRIAL_BASE_DAMAGE := 8.0
const TRIAL_BASE_SPEED := 80.0

## 试炼怪物类型表 (类型 = 精灵表 + 展示名; 列/行与各怪配置一致)
const ENEMY_TYPES := {
	"kulou": {"name": "骷髅", "resource": "res://assets/enemies/kulou_standard_sheet.png", "columns": 10, "rows": 5},
	"zombie": {"name": "僵尸", "resource": "res://assets/enemies/rotten_zombie_standard_sheet.png", "columns": 10, "rows": 4},
	"bug": {"name": "虫", "resource": "res://assets/enemies/evil_bug_standard_sheet.png", "columns": 10, "rows": 4},
	"alien": {"name": "外星", "resource": "res://assets/enemies/alien_creature_standard_sheet.png", "columns": 10, "rows": 4},
	"boss": {"name": "Boss", "resource": "res://assets/enemies/sci_fi_monster_standard_sheet.png", "columns": 10, "rows": 4},
}
const ARCHETYPES := ["", "tank", "fast", "ranged"]
const ARCHETYPE_NAMES := {"": "默认", "tank": "重装·tank", "fast": "疾行·fast", "ranged": "远程·ranged"}

var _selected_type := "kulou"
var _selected_archetype := ""
var _buttons: Dictionary = {}
var _status_label: Label

func _ready() -> void:
	get_tree().paused = false
	CurrencyManager.begin_run()
	PlayerExperienceSystem.clear_by_player_dead()
	CountManager.clear()
	WeaponManager.reset_run()
	Global.bind_game_scene(null, $WeaponSystem, $Player)
	# 玩家无敌: 受击立即回满 (health_changed 先于死亡判定 emit, 可拦截死亡)
	if is_instance_valid(Global.player):
		Global.player.health_changed.connect(func(_current: float, _maximum: float) -> void:
			Global.player.current_health = Global.player.max_health
		)
	# 默认子弹武器, 便于击杀试炼怪观察受击/死亡动画
	WeaponManager.call_deferred("add_starter_weapon")
	_build_ui()
	_spawn_trial_enemies()

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	layer.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "怪物试炼场（玩家无敌 · WASD 移动观察 · 默认子弹可击杀）"
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var type_label := Label.new()
	type_label.text = "怪物类型:"
	vbox.add_child(type_label)
	var type_row := HBoxContainer.new()
	vbox.add_child(type_row)
	for key in ENEMY_TYPES:
		var btn := Button.new()
		btn.text = ENEMY_TYPES[key]["name"]
		btn.custom_minimum_size = Vector2(86, 36)
		btn.pressed.connect(_select_type.bind(key))
		type_row.add_child(btn)
		_buttons[key] = btn

	var archetype_label := Label.new()
	archetype_label.text = "原型:"
	vbox.add_child(archetype_label)
	var archetype_row := HBoxContainer.new()
	vbox.add_child(archetype_row)
	for archetype in ARCHETYPES:
		var btn := Button.new()
		btn.text = ARCHETYPE_NAMES[archetype]
		btn.custom_minimum_size = Vector2(96, 36)
		btn.pressed.connect(_select_archetype.bind(archetype))
		archetype_row.add_child(btn)
		_buttons["arch_" + archetype] = btn

	var action_row := HBoxContainer.new()
	vbox.add_child(action_row)
	var spawn_btn := Button.new()
	spawn_btn.text = "生成 %d 只" % SPAWN_COUNT
	spawn_btn.pressed.connect(_spawn_trial_enemies)
	action_row.add_child(spawn_btn)
	var clear_btn := Button.new()
	clear_btn.text = "清场"
	clear_btn.pressed.connect(_clear_enemies)
	action_row.add_child(clear_btn)
	var return_btn := Button.new()
	return_btn.text = "返回"
	return_btn.pressed.connect(_return_to_level_select)
	action_row.add_child(return_btn)

	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_status_label)
	_refresh_ui()

func _select_type(key: String) -> void:
	_selected_type = key
	_refresh_ui()

func _select_archetype(key: String) -> void:
	_selected_archetype = key
	_refresh_ui()

func _refresh_ui() -> void:
	for key in ENEMY_TYPES:
		var btn: Button = _buttons[key]
		btn.modulate = Color(1.3, 1.3, 0.7) if key == _selected_type else Color.WHITE
	for archetype in ARCHETYPES:
		var btn: Button = _buttons["arch_" + archetype]
		btn.modulate = Color(1.3, 1.3, 0.7) if archetype == _selected_archetype else Color.WHITE

func _spawn_trial_enemies() -> void:
	_clear_enemies()
	if not is_instance_valid(Global.player):
		return
	var type_info: Dictionary = ENEMY_TYPES[_selected_type]
	var mods: Dictionary = {}
	var is_ranged := false
	if not _selected_archetype.is_empty() and BalanceConfig.ENEMY_ARCHETYPE.has(_selected_archetype):
		mods = BalanceConfig.ENEMY_ARCHETYPE[_selected_archetype]
		is_ranged = _selected_archetype == "ranged"
	var wave_config := {
		"health": TRIAL_BASE_HP,
		"attack_damage": TRIAL_BASE_DAMAGE,
		"move_speed": TRIAL_BASE_SPEED,
		"resource": type_info["resource"],
		"animation_columns": type_info["columns"],
		"animation_rows": type_info["rows"],
		"archetype": _selected_archetype,
	}
	for index in range(SPAWN_COUNT):
		var enemy := ENEMY_SCENE.instantiate() as Enemy
		enemy.setup(wave_config, 1.0, false)
		# 试炼怪经验=0: 击杀不会触发升级技能选择 (避免无 UIPanel 场景下暂停卡死)
		enemy.experience_reward = 0
		var angle := TAU * float(index) / SPAWN_COUNT
		enemy.global_position = Global.player.global_position + Vector2.from_angle(angle) * SPAWN_RADIUS
		add_child(enemy)
	var effective_hp := TRIAL_BASE_HP * float(mods.get("health", 1.0))
	var effective_speed := TRIAL_BASE_SPEED * float(mods.get("move_speed", 1.0))
	var effective_damage := TRIAL_BASE_DAMAGE * float(mods.get("attack_damage", 1.0))
	_status_label.text = "已生成 %d 只  %s · %s\n血量 %.0f | 速度 %.0f | 伤害 %.1f%s" % [
		SPAWN_COUNT,
		type_info["name"],
		ARCHETYPE_NAMES[_selected_archetype],
		effective_hp,
		effective_speed,
		effective_damage,
		"  |  远程射击(380px)" if is_ranged else "",
	]

func _clear_enemies() -> void:
	for raw_enemy in get_tree().get_nodes_in_group(GroupConfig.get_instance().Enemy_Group):
		var enemy := raw_enemy as Enemy
		if enemy != null:
			enemy.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_return_to_level_select()

func _return_to_level_select() -> void:
	Global.return_to_level_select()
