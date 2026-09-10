extends Node

## 音效管理 Autoload: 预加载武器音效并通过 AudioStreamPlayer 播放。
## 支持音量控制与同类音效叠播 (不打断已播音效)。

const SOUND_POOL_SIZE := 8

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	_load_stream("missile_fire")
	_load_stream("missile_hit")
	_load_stream("dart_fire")
	_load_stream("dart_hit")
	_load_stream("arc")
	_load_stream("sound_wave")
	_load_stream("ice_spike")
	_load_stream("lightning")
	_build_player_pool()

func _load_stream(name: String) -> void:
	var stream := load("res://assets/audio/%s.wav" % name) as AudioStream
	if stream != null:
		_streams[name] = stream
	else:
		push_warning("AudioManager: 无法加载音效 %s" % name)

func _build_player_pool() -> void:
	for index in range(SOUND_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)

func play(sound_name: String, volume_db: float = 0.0) -> void:
	if not _streams.has(sound_name):
		return
	# 找一个空闲播放器; 若都忙则用音量最小的那个(叠播)
	var target: AudioStreamPlayer = null
	for player in _players:
		if not player.playing:
			target = player
			break
	if target == null:
		var quietest := _players[0]
		for player in _players:
			if player.get_playback_position() < quietest.get_playback_position():
				quietest = player
		target = quietest
	target.stream = _streams[sound_name]
	target.volume_db = volume_db
	target.play()

func play_missile_fire(volume_db: float = 0.0) -> void: play("missile_fire", volume_db)
func play_missile_hit(volume_db: float = 0.0) -> void: play("missile_hit", volume_db)
func play_dart_fire(volume_db: float = 0.0) -> void: play("dart_fire", volume_db)
func play_dart_hit(volume_db: float = 0.0) -> void: play("dart_hit", volume_db)
func play_arc(volume_db: float = 0.0) -> void: play("arc", volume_db)
func play_sound_wave(volume_db: float = 0.0) -> void: play("sound_wave", volume_db)
func play_ice_spike(volume_db: float = 0.0) -> void: play("ice_spike", volume_db)
func play_lightning(volume_db: float = 0.0) -> void: play("lightning", volume_db)
