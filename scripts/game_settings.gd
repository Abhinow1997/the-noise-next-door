extends RefCounted
## The player's settings from the title screen's Settings page: how loud the music and the
## effects are (0..STEPS) and full screen. Kept in user://settings.cfg between runs.
## The volumes are each an amplifier at the end of its bus, so they stack with the
## level's own pause dip and its M and N mutes (main.gd) without touching them.

const PATH := "user://settings.cfg"
const STEPS := 10

static var music := STEPS
static var effects := STEPS
static var fullscreen := false


static func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	music = clampi(cfg.get_value("audio", "music", STEPS), 0, STEPS)
	effects = clampi(cfg.get_value("audio", "effects", STEPS), 0, STEPS)
	fullscreen = cfg.get_value("display", "fullscreen", false)


static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "effects", effects)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.save(PATH)


## Sets the buses' volumes and the window to the settings. The buses must exist.
static func apply() -> void:
	_set_volume("Music", music)
	_set_volume("SFX", effects)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)


static func _set_volume(bus_name: String, step: int) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus == -1:
		return
	var amp: AudioEffectAmplify
	for i in AudioServer.get_bus_effect_count(bus):
		if AudioServer.get_bus_effect(bus, i) is AudioEffectAmplify:
			amp = AudioServer.get_bus_effect(bus, i)
	if amp == null:
		amp = AudioEffectAmplify.new()
		AudioServer.add_bus_effect(bus, amp)
	amp.volume_db = linear_to_db(float(step) / STEPS) if step > 0 else -80.0
