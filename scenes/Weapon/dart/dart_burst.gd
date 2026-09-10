class_name DartBurst extends Node2D
## 飞镖爆炸特效: 中心闪光 + 扩散圆环 + 放射尖刺 (代码绘制) + CPUParticles2D 粒子迸溅。
## 粒子使用程序化柔边圆点贴图 (assets/effects/spark.png) 由 color_ramp 染成蓝/金色碎屑。
## 节点在绘制动画与粒子生命周期结束后自毁。

const DURATION := 0.25
const MAX_RADIUS := 34.0
const SPIKE_COUNT := 8

const PARTICLE_COUNT := 26
const PARTICLE_LIFETIME := 0.45
const PARTICLE_SPEED_MIN := 120.0
const PARTICLE_SPEED_MAX := 340.0
const PARTICLE_SCALE_MIN := 2.0
const PARTICLE_SCALE_MAX := 5.0
const PARTICLE_TEXTURE := preload("res://assets/effects/spark.png")

var _elapsed := 0.0
var _seed_rotation := randf() * TAU
var _particles: CPUParticles2D

func _ready() -> void:
	_setup_particles()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION + PARTICLE_LIFETIME:
		queue_free()
		return
	queue_redraw()

func _setup_particles() -> void:
	_particles = CPUParticles2D.new()
	_particles.amount = PARTICLE_COUNT
	_particles.lifetime = PARTICLE_LIFETIME
	_particles.one_shot = true
	_particles.emitting = true
	_particles.explosiveness = 0.85
	_particles.local_coords = false
	# 全方向迸溅: 方向随机旋转 + 180° 扇形
	_particles.direction = Vector2.RIGHT.rotated(_seed_rotation)
	_particles.spread = 180.0
	_particles.initial_velocity_min = PARTICLE_SPEED_MIN
	_particles.initial_velocity_max = PARTICLE_SPEED_MAX
	_particles.gravity = Vector2.ZERO
	_particles.damping_min = 0.0
	_particles.damping_max = 80.0
	_particles.scale_amount_min = PARTICLE_SCALE_MIN
	_particles.scale_amount_max = PARTICLE_SCALE_MAX
	_particles.texture = PARTICLE_TEXTURE
	# 蓝 -> 金 -> 透明 (呼应飞镖 3 蓝刃 + 1 金刃)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0.55, 0.85, 1.0, 1.0),
		Color(1.0, 0.95, 0.8, 0.9),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	_particles.color_ramp = gradient
	add_child(_particles)

func _draw() -> void:
	var progress := clampf(_elapsed / DURATION, 0.0, 1.0)
	var fade := 1.0 - progress
	var radius := lerpf(6.0, MAX_RADIUS, ease(progress, 0.3))
	# 中心闪光 (快速缩小淡出)
	draw_circle(Vector2.ZERO, lerpf(12.0, 1.0, progress), Color(1.0, 0.97, 0.85, fade * 0.9))
	# 扩散圆环
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0.55, 0.85, 1.0, fade), 3.0, true)
	# 放射尖刺
	for index in range(SPIKE_COUNT):
		var angle := _seed_rotation + TAU * float(index) / SPIKE_COUNT
		var dir := Vector2.from_angle(angle)
		draw_line(dir * radius * 0.35, dir * radius, Color(1.0, 0.95, 0.8, fade * 0.8), 2.5)
