extends Node

## 音效管理 Autoload: 预加载武器音效并通过 AudioStreamPlayer 播放。
## 支持音量控制与同类音效叠播 (不打断已播音效)。

const SOUND_POOL_SIZE := 8
const BATTLE_BGM_PATH := "res://assets/audio/battle_loop.wav"
const BGM_VOLUME_DB := -18.0
const BGM_SILENT_VOLUME_DB := -60.0
const BGM_FADE_SECONDS := 0.8

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _battle_bgm: AudioStreamWAV
var _bgm_player: AudioStreamPlayer
var _bgm_fade: Tween

func _ready() -> void:
	# 结算页会暂停 SceneTree；音频淡出必须继续执行，避免 BGM 卡在半音量。
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_stream("missile_fire")
	_load_stream("missile_hit")
	_load_stream("dart_fire")
	_load_stream("dart_hit")
	_load_stream("arc")
	_load_stream("sound_wave")
	_load_stream("ice_spike")
	_load_stream("lightning")
	_build_player_pool()
	_battle_bgm = load(BATTLE_BGM_PATH) as AudioStreamWAV
	if _battle_bgm == null:
		push_warning("AudioManager: 无法加载战斗背景音乐")
		return
	_battle_bgm.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.volume_db = BGM_SILENT_VOLUME_DB
	_bgm_player.stream = _battle_bgm
	add_child(_bgm_player)

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

## 正式关卡进入时调用。BGM 使用独立播放器，不影响武器音效的并发播放。
func play_battle_bgm() -> void:
	if not is_instance_valid(_bgm_player):
		return
	_stop_bgm_fade()
	if not _bgm_player.playing:
		_bgm_player.volume_db = BGM_SILENT_VOLUME_DB
		_bgm_player.play()
	_fade_bgm_to(BGM_VOLUME_DB)

## 对局结算或离开正式关卡时调用，淡出后停止以便下一局从循环起点开始。
func stop_battle_bgm() -> void:
	if not is_instance_valid(_bgm_player) or not _bgm_player.playing:
		return
	_stop_bgm_fade()
	_bgm_fade = create_tween()
	_bgm_fade.tween_property(_bgm_player, "volume_db", BGM_SILENT_VOLUME_DB, BGM_FADE_SECONDS)
	_bgm_fade.tween_callback(_bgm_player.stop)

func _fade_bgm_to(volume_db: float) -> void:
	_bgm_fade = create_tween()
	_bgm_fade.tween_property(_bgm_player, "volume_db", volume_db, BGM_FADE_SECONDS)

func _stop_bgm_fade() -> void:
	if is_instance_valid(_bgm_fade):
		_bgm_fade.kill()
		_bgm_fade = null

func play_missile_fire(volume_db: float = 0.0) -> void: play("missile_fire", volume_db)
func play_missile_hit(volume_db: float = 0.0) -> void: play("missile_hit", volume_db)
func play_dart_fire(volume_db: float = 0.0) -> void: play("dart_fire", volume_db)
func play_dart_hit(volume_db: float = 0.0) -> void: play("dart_hit", volume_db)
func play_arc(volume_db: float = 0.0) -> void: play("arc", volume_db)
func play_sound_wave(volume_db: float = 0.0) -> void: play("sound_wave", volume_db)
func play_ice_spike(volume_db: float = 0.0) -> void: play("ice_spike", volume_db)
func play_lightning(volume_db: float = 0.0) -> void: play("lightning", volume_db)
