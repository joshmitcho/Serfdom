# sound_manager.gd
extends Node

var soundscape_player: AudioStreamPlayer = AudioStreamPlayer.new()


func _ready():
	soundscape_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(soundscape_player)


func play_soundscape(soundscape: AudioStream, volume: float):
	soundscape_player.set_stream(soundscape)
	soundscape_player.set_volume_db(volume)
	soundscape_player.play()


func is_soundscape_playing(soundscape: AudioStream):
	return soundscape_player.is_playing() and soundscape_player.get_stream() == soundscape


func play_pitched_sfx(sfx: AudioStream, pitch: float = 1.0, volume: float = 0):
	var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(sfx_player)
	sfx_player.set_stream(sfx)
	sfx_player.set_pitch_scale(pitch)
	sfx_player.set_volume_db(volume)
	sfx_player.play()
	await sfx_player.finished
	remove_child(sfx_player)
	sfx_player.queue_free()
