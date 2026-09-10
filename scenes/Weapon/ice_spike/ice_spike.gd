class_name IceSpike extends Node2D

const SLOW_DURATION := 0.55
const FADE_DURATION := 0.20
const GROW_SEGMENT_LENGTH := 52.0
const GROW_SEGMENT_INTERVAL := 0.055
const POP_DURATION := 0.12
const ICE_SPIKE_TEXTURE := preload("res://assets/effects/ice_spike_single.png")

@onready var ice_pieces: Node2D = $IcePieces

var _damage := 0.5
var _distance := 210.0
var _width := 40.0
var _duration := 1.0
var _damage_interval := 0.2
var _slow_ratio := 0.0
var _elapsed := 0.0
var _damage_timer: Timer
var _segment_count := 1
var _visible_segment_count := 0
var _current_reach := 0.0
var _piece_sprites: Array[Sprite2D] = []
var _piece_base_scale := Vector2.ONE
var _visual_height := 150.0
var _direction := Vector2.RIGHT

func configure(
		origin: Vector2,
		direction: Vector2,
		damage: float,
		distance: float,
		width: float,
		duration: float,
		damage_interval: float,
		slow_ratio: float
	) -> void:
	global_position = origin
	# 不旋转节点: 尖刺贴图锚点固定朝上, 方向仅用于沿射线排列冰晶
	_direction = direction.normalized()
	if _direction.length_squared() < 0.0001:
		_direction = Vector2.RIGHT
	rotation = 0.0
	scale = Vector2.ONE
	_damage = maxf(damage, 0.0)
	_distance = maxf(distance, 90.0)
	_width = maxf(width, 32.0)
	_duration = maxf(duration, 0.2)
	_damage_interval = maxf(damage_interval, 0.04)
	_slow_ratio = clampf(slow_ratio, 0.0, 0.85)

func _ready() -> void:
	_update_visual()
	_damage_timer = Timer.new()
	_damage_timer.wait_time = _damage_interval
	add_child(_damage_timer)
	_damage_timer.timeout.connect(_deal_damage)
	_damage_timer.start()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= _duration:
		queue_free()
		return
	_update_reveal()
	var fade_ratio := clampf((_duration - _elapsed) / minf(FADE_DURATION, _duration), 0.0, 1.0)
	_update_piece_pop_animations(fade_ratio)

func _deal_damage() -> void:
	for raw_enemy in get_tree().get_nodes_in_group(GroupConfig.get_instance().Enemy_Group):
		var enemy := raw_enemy as Enemy
		if enemy == null or not is_instance_valid(enemy) or not _contains(enemy.global_position):
			continue
		if _slow_ratio > 0.0:
			enemy.apply_slow(_slow_ratio, SLOW_DURATION)
		enemy.apply_damage(-_damage)

func _contains(world_position: Vector2) -> bool:
	var offset := world_position - global_position
	# 沿发射方向的投影距离 (0.._current_reach)
	var along := offset.dot(_direction)
	if along < 0.0 or along > _current_reach:
		return false
	# 垂直方向的偏移距离
	var lateral := offset - _direction * along
	var lateral_distance := lateral.length()
	var normalized_distance := along / _distance
	var tapered_width := _width * lerpf(0.72, 1.0, normalized_distance)
	return lateral_distance <= tapered_width * 0.5

func _update_visual() -> void:
	if not is_instance_valid(ice_pieces):
		return
	var texture := ICE_SPIKE_TEXTURE as Texture2D
	if texture == null:
		return
	var texture_size := texture.get_size()
	_visual_height = maxf(_width * 1.65, 48.0)
	_segment_count = maxi(ceili(_distance / GROW_SEGMENT_LENGTH), 1)
	# 每根独立刺: 贴图保持原始比例, 宽度按 _width 缩放, 高度按 _visual_height 缩放
	_piece_base_scale = Vector2(_width / texture_size.x, _visual_height / texture_size.y)
	for child in ice_pieces.get_children():
		child.queue_free()
	_piece_sprites.clear()
	for index in range(_segment_count):
		var piece := Sprite2D.new()
		piece.texture = texture
		piece.centered = true
		piece.hide()
		ice_pieces.add_child(piece)
		_piece_sprites.append(piece)

func _update_reveal() -> void:
	var next_segment_count := mini(floori(_elapsed / GROW_SEGMENT_INTERVAL) + 1, _segment_count)
	if next_segment_count == _visible_segment_count:
		return
	_visible_segment_count = next_segment_count
	_current_reach = _distance * float(_visible_segment_count) / float(_segment_count)

func _update_piece_pop_animations(fade_ratio: float) -> void:
	for index in range(_visible_segment_count):
		if index >= _piece_sprites.size():
			return
		var piece := _piece_sprites[index]
		var piece_age := _elapsed - float(index) * GROW_SEGMENT_INTERVAL
		var progress := clampf(piece_age / POP_DURATION, 0.0, 1.0)
		var eased_progress := 1.0 - pow(1.0 - progress, 3.0)
		# 每根独立刺: 从地面破土向上刺出 (scale.y 0 -> 1)
		# 锚点(centered=true)=贴图中心=刺根部, 根部固定在路径上, scale.y 从根部向上生长
		var grow_scale := lerpf(0.0, 1.0, eased_progress)
		var piece_start := _distance * float(index) / float(_segment_count)
		var base_position := _direction * piece_start
		piece.position = base_position
		piece.scale = Vector2(_piece_base_scale.x, _piece_base_scale.y * grow_scale)
		piece.modulate.a = minf(piece_age / 0.06, 1.0) * fade_ratio
		piece.show()
