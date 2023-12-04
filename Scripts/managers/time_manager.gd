#time_manager.gd
extends Node

signal new_day(year: int, season: int)
signal time_tick(day: int, hour: int, minute: int)

const INGAME_SPEED = 1.2
const INITIAL_HOUR = 6.1
const DAY_THRESHOLD_HOUR = 6
const NIGHT_THRESHOLD_HOUR = 20
const SEASONS_PER_YEAR = 4
const DAYS_PER_SEASON = 14
const MINUTES_PER_DAY = 1440
const MINUTES_PER_HOUR = 60
const INGAME_TO_REAL_MINUTE_DURATION = (2 * PI) / MINUTES_PER_DAY

var time: float = 0.0
var year: int
var season: int
var day: int
var hour: int
var minute: int
var last_displayed_time: int = -1
var yesterday: int = -1
var canvas_modulate_degree: float

func _ready():
	time = INGAME_TO_REAL_MINUTE_DURATION * MINUTES_PER_HOUR * INITIAL_HOUR

func _physics_process(delta):
	time += delta * INGAME_TO_REAL_MINUTE_DURATION * INGAME_SPEED
	if PlayScreen.current_map_type == Compendium.MAP_TYPE.CAVE:
		canvas_modulate_degree = 0.4
	else:
		canvas_modulate_degree = (sin(time - PI / 2.0) + 1.0) / 2.0
	
	if Input.is_action_just_pressed("skip_time"):
		time += MINUTES_PER_DAY / 3 * INGAME_TO_REAL_MINUTE_DURATION
	
	var total_minutes = int(time / INGAME_TO_REAL_MINUTE_DURATION)
	
	var current_day_minutes = total_minutes % MINUTES_PER_DAY
	var total_days = total_minutes / MINUTES_PER_DAY
	var total_seasons = total_days / DAYS_PER_SEASON
	
	year = total_seasons / SEASONS_PER_YEAR
	season = total_seasons % SEASONS_PER_YEAR
	
	day = total_days % DAYS_PER_SEASON
	
	hour = current_day_minutes / MINUTES_PER_HOUR
	minute = current_day_minutes % MINUTES_PER_HOUR
	
	if total_minutes >= last_displayed_time + 10:
		last_displayed_time = total_minutes
		time_tick.emit(day, hour, (minute / 10) * 10)
		if PlayScreen.current_map_type != Compendium.MAP_TYPE.CAVE:
			play_soundscapes()
	
	if day != yesterday:
		yesterday = day
		new_day.emit(year, season)


func play_soundscapes() -> void:
	if hour < DAY_THRESHOLD_HOUR or hour > NIGHT_THRESHOLD_HOUR:
		if not SoundManager.is_soundscape_playing(Compendium.NIGHT_SOUNDSCAPE):
			SoundManager.play_soundscape(Compendium.NIGHT_SOUNDSCAPE, 0)
	else:
		if not SoundManager.is_soundscape_playing(Compendium.DAY_SOUNDSCAPE):
			SoundManager.play_soundscape(Compendium.DAY_SOUNDSCAPE, -5)
	
	if hour == DAY_THRESHOLD_HOUR and minute == 0:
		SoundManager.play_pitched_sfx(Compendium.DAY_JINGLE, 1, -20)
	elif hour == NIGHT_THRESHOLD_HOUR and minute == 0:
		SoundManager.play_pitched_sfx(Compendium.NIGHT_JINGLE)


func get_time_dialogue_string() -> String:
	return "_%s_%s_%s" % [year, season, day % 7]
