class_name SkillLab extends Node2D

const ENEMY_SCENE := preload("res://scenes/enemy/Enemy.tscn")
const PRACTICE_ENEMY_CONFIG := {
	"health": 999999.0,
	"attack_damage": 0.0,
	"move_speed": 48.0,
	"resource": "res://assets/enemies/rotten_zombie_standard_sheet.png",
	"animation_columns": 10,
	"animation_rows": 4,
}
const TARGET_POSITIONS := [
	Vector2(360.0, -220.0),
	Vector2(460.0, -100.0),
	Vector2(560.0, 0.0),
	Vector2(460.0, 120.0),
	Vector2(350.0, 240.0),
	Vector2(-310.0, -150.0),
	Vector2(-390.0, 110.0),
]

const WEAPON_DESCRIPTIONS := {
	"missile": "发射瞬间自动瞄准最近敌人，扇形齐射直线子弹，可检查穿透与反弹。",
	"dart": "环形发射，飞出后原地旋转造成伤害，最后爆炸，可检查伤害频率与爆炸范围。",
	"arc": "围绕角色的持续电弧，可检查范围和命中频率。",
	"sound_wave": "从发射点扩散的圆形声波，可检查扩散和减速。",
	"ice_spike": "朝最近目标逐段破土的冰刺，可检查推进、范围和减速。",
	"lightning": "从天上随机落下的落雷，可检查范围、感电和数量。",
}

@onready var weapon_system: WeaponSystem = $WeaponSystem
@onready var player: Player = $Player
@onready var status_label: Label = $LabUI/Control/StatusPanel/Content/StatusLabel
@onready var selected_skill_label: Label = $LabUI/Control/StatusPanel/Content/SelectedSkillLabel
@onready var respawn_button: Button = $LabUI/Control/Actions/RespawnButton
@onready var return_button: Button = $LabUI/Control/Actions/ReturnButton
@onready var upgrade_buttons_box: VBoxContainer = $LabUI/Control/UpgradePanel/Content/UpgradeButtons
@onready var reset_upgrade_button: Button = $LabUI/Control/UpgradePanel/Content/ResetUpgradeButton

var _weapon_buttons: Dictionary[Button, String] = {}
var _upgrade_buttons: Array[Button] = []
var _current_weapon_type := ""

func _ready() -> void:
	get_tree().paused = false
	CurrencyManager.begin_run()
	PlayerExperienceSystem.clear_by_player_dead()
	CountManager.clear()
	WeaponManager.reset_run()
	Global.bind_game_scene($UIPanel, weapon_system, player)
	_weapon_buttons = {
		$LabUI/Control/SkillButtons/MissileButton: WeaponType.Missile_Weapon,
		$LabUI/Control/SkillButtons/DartButton: WeaponType.Dart_Weapon,
		$LabUI/Control/SkillButtons/ArcButton: WeaponType.Arc_Weapon,
		$LabUI/Control/SkillButtons/SoundWaveButton: WeaponType.Sound_Wave_Weapon,
		$LabUI/Control/SkillButtons/IceSpikeButton: WeaponType.Ice_Spike_Weapon,
		$LabUI/Control/SkillButtons/LightningButton: WeaponType.Lightning_Weapon,
	}
	for button in _weapon_buttons:
		button.pressed.connect(_equip_weapon.bind(_weapon_buttons[button]))
	respawn_button.pressed.connect(_spawn_practice_targets)
	return_button.pressed.connect(_return_to_level_select)
	reset_upgrade_button.pressed.connect(_reset_upgrades)
	_spawn_practice_targets()
	_equip_weapon(WeaponType.Missile_Weapon)

func _equip_weapon(weapon_type: String) -> void:
	weapon_system.clear_weapons()
	WeaponManager.reset_run()
	if not WeaponManager.add_weapon(weapon_type):
		status_label.text = "技能装配失败，请重新进入体验场。"
		return
	# 解锁武器到运行状态, 让专属强化可以被 SkillService 应用
	SkillService.register_starter_weapon(StringName(weapon_type))
	_current_weapon_type = weapon_type
	var display_name := WeaponManager.get_weapon_display_name(weapon_type)
	selected_skill_label.text = "当前体验：%s" % display_name
	status_label.text = str(WEAPON_DESCRIPTIONS.get(weapon_type, "观察该技能的实际表现。"))
	for button in _weapon_buttons:
		button.disabled = _weapon_buttons[button] == weapon_type
	_build_upgrade_buttons(weapon_type)

## 列出当前武器的专属强化 (含数量卡), 每个一个可点击叠加的按钮。
func _build_upgrade_buttons(weapon_type: String) -> void:
	for button in _upgrade_buttons:
		if is_instance_valid(button):
			button.queue_free()
	_upgrade_buttons.clear()
	var definitions := SkillCatalog.get_weapon_upgrade_definitions(StringName(weapon_type))
	for definition in definitions:
		if definition == null:
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 42)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_apply_lab_upgrade.bind(definition))
		upgrade_buttons_box.add_child(button)
		_upgrade_buttons.append(button)
	_refresh_upgrade_buttons()

func _apply_lab_upgrade(definition: SkillDefinition) -> void:
	if not SkillService.apply_definition(definition):
		status_label.text = "强化已达上限。"
		return
	_refresh_upgrade_buttons()
	status_label.text = "已应用：%s（Lv.%d）" % [
		definition.title,
		SkillService.build_state.get_level(definition.id),
	]

func _refresh_upgrade_buttons() -> void:
	var definitions := SkillCatalog.get_weapon_upgrade_definitions(StringName(_current_weapon_type))
	for index in range(_upgrade_buttons.size()):
		if index >= definitions.size():
			continue
		var definition := definitions[index]
		var button := _upgrade_buttons[index]
		var level := SkillService.build_state.get_level(definition.id)
		var capped := definition.has_level_cap() and level >= definition.max_level
		button.text = "%s  Lv.%d/%d" % [definition.title, level, definition.max_level]
		button.disabled = capped

func _reset_upgrades() -> void:
	if _current_weapon_type.is_empty():
		return
	_equip_weapon(_current_weapon_type)
	status_label.text = "强化已重置。"

func _spawn_practice_targets() -> void:
	for raw_enemy in get_tree().get_nodes_in_group(GroupConfig.get_instance().Enemy_Group):
		var enemy := raw_enemy as Enemy
		if enemy != null:
			enemy.queue_free()
	for target_position in TARGET_POSITIONS:
		var target := ENEMY_SCENE.instantiate() as Enemy
		target.setup(PRACTICE_ENEMY_CONFIG, 1.0, false)
		target.global_position = target_position
		add_child(target)
	status_label.text = "练习靶已刷新：它们不会造成伤害，会缓慢靠近角色以便观察减速。"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_return_to_level_select()

func _return_to_level_select() -> void:
	weapon_system.clear_weapons()
	Global.return_to_level_select()
