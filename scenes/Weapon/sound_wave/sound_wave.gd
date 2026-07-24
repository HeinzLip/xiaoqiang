class_name SoundWave extends Node2D

const RING_THICKNESS := 24.0
const SLOW_DURATION := 0.5

var _damage := 0.8
var _expand_speed := 420.0
var _slow_ratio := 0.0
var _radius := 0.0
var _previous_radius := 0.0
var _direction := 1.0
var _remaining_rebounds := 0
var _maximum_radius := 1100.0
var _hit_enemy_ids: Dictionary = {}

func configure(damage: float, expand_speed: float, slow_ratio: float, rebound_count: int, start_delay: float) -> void:
	set_damage(damage)
	_expand_speed = maxf(expand_speed, 60.0)
	_slow_ratio = clampf(slow_ratio, 0.0, 0.85)
	_remaining_rebounds = maxi(rebound_count, 0)
	_radius = -_expand_speed * maxf(start_delay, 0.0)
	_previous_radius = _radius

func set_damage(damage: float) -> void:
	_damage = maxf(damage, 0.0)

func _ready() -> void:
	var viewport_size := get_viewport_rect().size
	_maximum_radius = maxf(viewport_size.length() * 0.6, 720.0)
	if is_instance_valid(Global.player):
		global_position = Global.player.global_position

func _process(delta: float) -> void:
	if not is_instance_valid(Global.player):
		queue_free()
		return
	global_position = Global.player.global_position
	_previous_radius = _radius
	_radius += _expand_speed * _direction * delta
	_apply_wave_hits()
	_update_wave_direction()
	queue_redraw()

func _apply_wave_hits() -> void:
	if _radius < 0.0:
		return
	var inner_radius := maxf(minf(_previous_radius, _radius) - RING_THICKNESS * 0.5, 0.0)
	var outer_radius := maxf(_previous_radius, _radius) + RING_THICKNESS * 0.5
	for raw_enemy in get_tree().get_nodes_in_group(GroupConfig.get_instance().Enemy_Group):
		var enemy := raw_enemy as Enemy
		if enemy == null or not is_instance_valid(enemy):
			continue
		var enemy_id := enemy.get_instance_id()
		if _hit_enemy_ids.has(enemy_id):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < inner_radius or distance > outer_radius:
			continue
		_hit_enemy_ids[enemy_id] = true
		if _slow_ratio > 0.0:
			enemy.apply_slow(_slow_ratio, SLOW_DURATION)
		enemy.apply_damage(-_damage)

func _update_wave_direction() -> void:
	if _direction > 0.0 and _radius >= _maximum_radius:
		if _remaining_rebounds <= 0:
			queue_free()
			return
		_direction = -1.0
		_hit_enemy_ids.clear()
		return
	if _direction < 0.0 and _radius <= RING_THICKNESS * 0.5:
		if _remaining_rebounds <= 1:
			queue_free()
			return
		_remaining_rebounds -= 1
		_direction = 1.0
		_hit_enemy_ids.clear()

func _draw() -> void:
	if _radius <= 0.0:
		return
	var alpha := clampf(1.0 - _radius / (_maximum_radius * 1.15), 0.2, 0.9)
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 72, Color(0.34, 0.92, 1.0, alpha), RING_THICKNESS, true)
	draw_arc(Vector2.ZERO, maxf(_radius - 16.0, 0.0), 0.0, TAU, 72, Color(0.72, 0.98, 1.0, alpha * 0.55), 4.0, true)
