class_name SoundWaveWeapon extends Weapon

const SOUND_WAVE_SCENE := preload("res://scenes/Weapon/sound_wave/SoundWave.tscn")
const WAVE_INTERVAL := 0.5
const WAVE_DAMAGE := BalanceConfig.WEAPON_BASE["sound_wave_damage"]
const WAVE_EXPAND_SPEED := 420.0
const WAVE_DELAY_BETWEEN := 0.16

var _wave_interval := WAVE_INTERVAL
var _wave_damage := WAVE_DAMAGE
var _base_wave_damage := WAVE_DAMAGE
var _wave_expand_speed := WAVE_EXPAND_SPEED
var _wave_count := 1
var _slow_ratio := 0.0
var _player_speed_bonus := 0.0
var _rebound_count := 0
var _fire_timer: Timer
var _universal_damage_multiplier := 1.0
var _universal_attack_rate_multiplier := 1.0
var _active_waves: Array[Node2D] = []

func _ready() -> void:
	if attr_set == null:
		attr_set = AttributeSet.new()
	attr_set.attrs = {}
	_add_attribute(AttributeEnum.instance.SOUND_WAVE_EXPAND_SPEED, _wave_expand_speed, _on_wave_expand_speed_changed)
	_add_attribute(AttributeEnum.instance.SOUND_WAVE_COUNT, _wave_count, _on_wave_count_changed)
	_add_attribute(AttributeEnum.instance.SOUND_WAVE_SLOW, _slow_ratio, _on_slow_changed)
	_add_attribute(AttributeEnum.instance.SOUND_WAVE_PLAYER_SPEED, _player_speed_bonus, _on_player_speed_changed)
	_add_attribute(AttributeEnum.instance.SOUND_WAVE_REBOUND, _rebound_count, _on_rebound_count_changed)
	_base_wave_damage = WAVE_DAMAGE * CurrencyManager.get_damage_multiplier()
	_refresh_wave_damage()
	_fire_timer = Timer.new()
	add_child(_fire_timer)
	_fire_timer.timeout.connect(_fire_sound_waves)
	_update_fire_timer()
	_fire_timer.start()

func _add_attribute(attribute_key: String, value: float, callback: Callable) -> void:
	var attribute := Attribute.new(0)
	attribute.add_base_value(value)
	attribute.register_value_changed(callback)
	attr_set.attrs[attribute_key] = attribute

func _fire_sound_waves() -> void:
	if not is_instance_valid(Global.player):
		return
	for index in range(maxi(_wave_count, 1)):
		var wave := SOUND_WAVE_SCENE.instantiate() as SoundWave
		if wave == null:
			continue
		wave.configure(
			_wave_damage,
			_wave_expand_speed,
			_slow_ratio,
			_rebound_count,
			float(index) * WAVE_DELAY_BETWEEN
		)
		# 声波挂到场景根, 锁定原点后不受 WeaponSystem/玩家移动影响
		var wave_parent := get_tree().current_scene
		wave_parent.add_child(wave)
		_active_waves.append(wave)
	AudioManager.play_sound_wave(-6.0)

func _on_wave_expand_speed_changed(value: float) -> void:
	_wave_expand_speed = maxf(value, 60.0)

func _on_wave_count_changed(value: float) -> void:
	_wave_count = maxi(roundi(value), 1)

func _on_slow_changed(value: float) -> void:
	_slow_ratio = clampf(value, 0.0, 0.85)

func _on_player_speed_changed(value: float) -> void:
	_player_speed_bonus = maxf(value, 0.0)
	if is_instance_valid(Global.player):
		Global.player.set_skill_move_speed_bonus(_player_speed_bonus)

func _on_rebound_count_changed(value: float) -> void:
	_rebound_count = maxi(roundi(value), 0)

func set_universal_modifiers(damage_multiplier: float, attack_rate_multiplier: float) -> void:
	_universal_damage_multiplier = maxf(damage_multiplier, 0.0)
	_universal_attack_rate_multiplier = maxf(attack_rate_multiplier, 0.1)
	_refresh_wave_damage()
	var living_waves: Array[Node2D] = []
	for wave in _active_waves:
		if is_instance_valid(wave):
			wave.call("set_damage", _wave_damage)
			living_waves.append(wave)
	_active_waves = living_waves
	_update_fire_timer()

func _refresh_wave_damage() -> void:
	_wave_damage = _base_wave_damage * _universal_damage_multiplier

func _update_fire_timer() -> void:
	if is_instance_valid(_fire_timer):
		_fire_timer.wait_time = _wave_interval / _universal_attack_rate_multiplier
