extends Node

const SFX_DIR := "res://assets/audio/sfx/"

var throw_streams: Array[AudioStream] = []
var wood_hit_streams: Array[AudioStream] = []
var knife_hit_streams: Array[AudioStream] = []
var apple_hit_streams: Array[AudioStream] = []

var sfx_stage_clear: AudioStream
var sfx_game_over: AudioStream
var sfx_boss_defeated: AudioStream
var sfx_button_click: AudioStream

var players: Array[AudioStreamPlayer] = []
const POOL_SIZE := 8

func _ready() -> void:
	# Instantiate player pool
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	
	load_audio_resources()
	connect_signals()

func load_audio_resources() -> void:
	for i in [1, 2, 3]:
		var th := load_stream(SFX_DIR + "ev_throw_%d.mp3" % i)
		if th: throw_streams.append(th)
		
		var wh := load_stream(SFX_DIR + "ev_hit_%d.mp3" % i)
		if wh: wood_hit_streams.append(wh)
		
		var kh := load_stream(SFX_DIR + "ev_knife_hit_%d.mp3" % i)
		if kh: knife_hit_streams.append(kh)
		
		var ah := load_stream(SFX_DIR + "ev_apple_hit_%d.mp3" % i)
		if ah: apple_hit_streams.append(ah)
	
	sfx_stage_clear = load_stream(SFX_DIR + "ev_hit_last.mp3")
	sfx_game_over = load_stream(SFX_DIR + "ev_game_over.mp3")
	sfx_boss_defeated = load_stream(SFX_DIR + "ev_boss_defeated.mp3")
	sfx_button_click = load_stream(SFX_DIR + "ev_button_click.mp3")

func load_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path) as AudioStream
	return null

func connect_signals() -> void:
	EventBus.knife_thrown.connect(play_throw)
	EventBus.knife_hit_target.connect(func(_p, _a): play_wood_hit())
	EventBus.knife_hit_knife.connect(func(_p): play_knife_hit())
	EventBus.apple_collected.connect(func(_p): play_apple_hit())
	EventBus.stage_cleared.connect(func(_s): play_stage_clear())
	EventBus.game_over.connect(func(_s, _sc): play_game_over())

func play_stream(stream: AudioStream, pitch_jitter: float = 0.05, volume_db: float = 0.0) -> void:
	if not Save.sound_enabled or stream == null:
		return
	for p in players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
			p.play()
			return

func play_throw() -> void:
	if throw_streams.size() > 0:
		play_stream(throw_streams.pick_random(), 0.08, -2.0)

func play_wood_hit() -> void:
	if wood_hit_streams.size() > 0:
		play_stream(wood_hit_streams.pick_random(), 0.06, 1.0)

func play_knife_hit() -> void:
	if knife_hit_streams.size() > 0:
		play_stream(knife_hit_streams.pick_random(), 0.04, 3.0)

func play_apple_hit() -> void:
	if apple_hit_streams.size() > 0:
		play_stream(apple_hit_streams.pick_random(), 0.05, 2.0)

func play_stage_clear() -> void:
	if Game.is_boss_stage and sfx_boss_defeated:
		play_stream(sfx_boss_defeated, 0.0, 2.0)
	elif sfx_stage_clear:
		play_stream(sfx_stage_clear, 0.0, 2.0)

func play_game_over() -> void:
	if sfx_game_over:
		play_stream(sfx_game_over, 0.0, 1.0)

func play_click() -> void:
	if sfx_button_click:
		play_stream(sfx_button_click, 0.02, 0.0)
