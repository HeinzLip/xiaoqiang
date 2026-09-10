class_name PlayerVisual extends AnimatedSprite2D

const IDLE_ANIMATION := &"idle"
const WALK_FRONT_ANIMATION := &"walk_front"
const WALK_SIDE_ANIMATION := &"walk_side"
const HURT_ANIMATION := &"hurt"
const HURT_DURATION := 0.30

var _is_moving := false
var _use_side_walk := false
var _walk_time := 0.0
var _animation_time := 0.0
var _hurt_remaining := 0.0
var _base_position := Vector2.ZERO
var _base_scale := Vector2.ONE


func _ready() -> void:
	_base_position = position
	_base_scale = scale
	rotation = 0.0
	_set_animation(IDLE_ANIMATION, true)


func set_movement(direction: Vector2) -> void:
	_is_moving = direction.length_squared() > 0.0001
	_use_side_walk = absf(direction.x) > absf(direction.y)
	if _use_side_walk:
		# Sidewalk frames face left by default; mirror them only for rightward travel.
		flip_h = direction.x > 0.0
	else:
		flip_h = false
	if _hurt_remaining <= 0.0:
		_play_movement_animation()


func play_hit_flash() -> void:
	_hurt_remaining = HURT_DURATION
	_set_animation(HURT_ANIMATION, true)


## Called by Player._physics_process so movement and visual frames always
## advance together, regardless of this child node's process mode.
func update_animation(delta: float) -> void:
	if _is_moving:
		_walk_time += delta * 10.0
	else:
		_walk_time = move_toward(_walk_time, roundf(_walk_time / TAU) * TAU, delta * 10.0)

	rotation = 0.0
	# A wider vertical step makes the cycle legible even at the game's zoom level.
	var bob_amount := 4.0 if _is_moving and _hurt_remaining <= 0.0 else 0.0
	position = _base_position + Vector2(0.0, sin(_walk_time) * bob_amount)

	_hurt_remaining = maxf(_hurt_remaining - delta, 0.0)
	if _hurt_remaining > 0.0:
		var impact := sin((1.0 - _hurt_remaining / HURT_DURATION) * PI)
		scale = _base_scale * Vector2(1.0 - impact * 0.08, 1.0 + impact * 0.08)
		modulate = Color(1.0, 0.55, 0.55)
	else:
		scale = _base_scale
		modulate = Color.WHITE
		if animation == HURT_ANIMATION:
			_play_movement_animation()
		_advance_animation_frame(delta)


func _play_movement_animation() -> void:
	var target_animation := IDLE_ANIMATION
	if _is_moving:
		target_animation = WALK_SIDE_ANIMATION if _use_side_walk else WALK_FRONT_ANIMATION
	_set_animation(target_animation)


## The visual script owns frame timing so walking remains reliable even when
## the AnimatedSprite2D internal playback is paused by another state.
func _advance_animation_frame(delta: float) -> void:
	if not _is_moving:
		frame = 0
		frame_progress = 0.0
		return
	var frame_count := sprite_frames.get_frame_count(animation)
	if frame_count <= 1:
		return
	var animation_speed := maxf(sprite_frames.get_animation_speed(animation), 1.0)
	_animation_time += delta
	frame = int(floor(_animation_time * animation_speed)) % frame_count
	frame_progress = 0.0


func _set_animation(next_animation: StringName, force_reset: bool = false) -> void:
	if not force_reset and animation == next_animation:
		return
	stop()
	animation = next_animation
	frame = 0
	frame_progress = 0.0
	_animation_time = 0.0
