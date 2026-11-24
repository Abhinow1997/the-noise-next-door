extends SceneTree
## Makes the game's two task sounds from the author's downloads, the MP3s kept (out of GitHub, as
## MP3s are) in design/sfx/ (22 Nov 2026, the author: "use the sound effect when u complete a task
## replace it with the current vesrion"; SOURCES.md, Assignment 7):
##   - assets/audio/sfx/task-done-coin.wav, from "Get Coin" by KoiRoylers (Pixabay 351945): played
##     as a task is done, in place of the raccoon's laugh (main.gd);
##   - assets/audio/sfx/scribble-pencil.wav, from "Scribble" by Tomoyo Ichijouji (Freesound, via
##     Pixabay 6144): looped while a task is written out and crossed off, in place of the chalk
##     scribble Claude Code made from noise (plan_note.gd).
## There's no ffmpeg here, so each is decoded by Godot's own MP3 player and recorded, in real time,
## on a bus of its own through an AudioEffectRecord (16-bit stereo at the mix rate, 44.1 kHz). Then:
##   - the coin is recorded 3 dB down: its MP3 peaks just over full scale (three samples clipped
##     at 0 dB), and at -3 dB it peaks at -2.6 dB with none;
##   - the scribble, 20 dB quieter than the old scribble, is raised GAIN times (+20 dB) to its level;
##   - since 24 Nov 2026, assets/audio/sfx/camper-huh.wav, from "Huh SFX" by Mrstokes302 (Pixabay
##     418238): a camper's "huh?" as the "?" comes up over them (camp_person.gd). Its MP3 peaks at
##     -12.4 dB; raised 3 times (+9.5 dB), it peaks at -2.9 dB, about the coin's. Imported as mono.
##   - each is trimmed to its sound: from LEAD before the first sample over QUIET to TAIL after the
##     last, so it starts the moment it's played; the TAIL fades out, so the cut can't click (the
##     coin's ring is under -45 dB by then).
## Run it from the project folder, with the Dummy audio driver (it still mixes):
##   ../Godot/Godot_v4.7.2-stable_win64_console.exe --headless --audio-driver Dummy --path . --script res://tools/make_task_sounds.gd
## (add `-- huh` to make only the huh). Then reimport (the import files set the scribble to loop and
## the huh to mono). Written by Claude Code on 22 Nov 2026; the huh added on 24 Nov 2026.

const JOBS := [
	["res://design/sfx/koiroylers-get-coin-351945.mp3", "res://assets/audio/sfx/task-done-coin.wav", -3.0, 1.0],
	["res://design/sfx/freesound_community-scribble-6144.mp3", "res://assets/audio/sfx/scribble-pencil.wav", 0.0, 10.0],
	["res://design/sfx/mrstokes302-huh-sfx-mrstokes302-418238.mp3", "res://assets/audio/sfx/camper-huh.wav", 0.0, 3.0],
]
## Only the jobs whose output's file name has one of these in it, when any are given after `--`
## (say `-- huh`); all of them otherwise. Each run records afresh, so a job left out keeps its file.
var _only := Array(OS.get_cmdline_user_args())
## Under this (of full scale) counts as silence; kept before the first sound and after the last (s).
const QUIET := 0.003
const LEAD := 0.005
const TAIL := 0.05

var _job := -1
var _player: AudioStreamPlayer
var _rec: AudioEffectRecord
var _started := 0
var _length := 0.0


func _initialize() -> void:
	var bus := AudioServer.bus_count
	AudioServer.add_bus(bus)
	AudioServer.set_bus_name(bus, "Rec")
	_rec = AudioEffectRecord.new()
	_rec.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(bus, _rec)
	_player = AudioStreamPlayer.new()
	_player.bus = "Rec"
	root.add_child(_player)


func _process(_delta: float) -> bool:
	if _job >= 0 and Time.get_ticks_msec() - _started < int((_length + 0.4) * 1000.0):
		return false
	if _job >= 0:
		_rec.set_recording_active(false)
		_finish(_rec.get_recording(), JOBS[_job])
	_job += 1
	while _job < JOBS.size() and not _only.is_empty() \
			and not _only.any(func(o: String) -> bool: return String(JOBS[_job][1]).get_file().contains(o)):
		_job += 1
	if _job >= JOBS.size():
		return true
	var job: Array = JOBS[_job]
	var mp3 := AudioStreamMP3.load_from_file(ProjectSettings.globalize_path(job[0]))
	if mp3 == null:
		push_error("Couldn't read %s" % job[0])
		return true
	_length = mp3.get_length()
	_player.stream = mp3
	_player.volume_db = job[2]
	_rec.set_recording_active(true)
	_player.play()
	_started = Time.get_ticks_msec()
	return false


## Raised by the job's gain, trimmed to its sound, and saved.
func _finish(wav: AudioStreamWAV, job: Array) -> void:
	var data := wav.data
	var frames := data.size() / 4
	var gain: float = job[3]
	var first := -1
	var last := -1
	var out := PackedByteArray()
	out.resize(data.size())
	for i in frames * 2:
		var v := clampi(roundi(data.decode_s16(i * 2) * gain), -32768, 32767)
		out.encode_s16(i * 2, v)
		if absf(v / 32768.0) > QUIET:
			if first < 0:
				first = i / 2
			last = i / 2
	var rate := wav.mix_rate
	var from := maxi(first - int(LEAD * rate), 0)
	var to := mini(last + int(TAIL * rate), frames - 1)
	var kept := out.slice(from * 4, (to + 1) * 4)
	var fade := int(TAIL * rate)
	var n := to - from + 1
	for f in range(maxi(n - fade, 0), n):
		var k := float(n - 1 - f) / fade
		for c in 2:
			kept.encode_s16((f * 2 + c) * 2, roundi(kept.decode_s16((f * 2 + c) * 2) * k))
	wav.data = kept
	var peak := 0
	for i in (to - from + 1) * 2:
		peak = maxi(peak, absi(wav.data.decode_s16(i * 2)))
	var err := wav.save_to_wav(ProjectSettings.globalize_path(job[1]))
	print("%s: %d Hz stereo, %.3f s (sound from %.3f s of the recording), gain x%.1f, volume %.1f dB, peak %.3f: %s" % [
		String(job[1]).get_file(), rate, (to - from + 1) / float(rate), from / float(rate), gain, job[2], peak / 32768.0,
		error_string(err)])
