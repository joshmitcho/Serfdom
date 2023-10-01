# daynightcycle.gd
extends CanvasModulate
class_name DayNightCycle

const MINUTES_PER_DAY = 1440
const MINUTES_PER_HOUR = 60
const INGAME_TO_REAL_MINUTE_DURATION = (2 * PI) / MINUTES_PER_DAY
const MIN_SHADOW_MODULATE: Color = Color(0, 0, 0, 0) 

signal time_tick(day: int, hour: int, minute: int)

@export var lantern_with_shadows: PointLight2D
@export var lantern_no_shadows: PointLight2D
@export var lanternColour = Color("#ff9945")
@export var gradient_texture: GradientTexture1D

var INGAME_SPEED = 1.2
var INITIAL_HOUR = 16
var time: float = 0.0
var day: int
var hour: int
var minute: int
var last_displayed_time: int = -1

static var degree: float
static var shadow_modulate: Color

@onready var lantern_with_shadow_max_energy: float = lantern_with_shadows.energy
@onready var lantern_no_shadow_max_energy: float = lantern_no_shadows.energy


func _ready() -> void:
	time = INGAME_TO_REAL_MINUTE_DURATION * MINUTES_PER_HOUR * INITIAL_HOUR
	lantern_no_shadows.color = lanternColour
	lantern_with_shadows.color = lanternColour
	lantern_no_shadows.enabled = Inventory.has_lantern
	lantern_with_shadows.enabled = Inventory.has_lantern


func _process(delta: float) -> void:
	time += delta * INGAME_TO_REAL_MINUTE_DURATION * INGAME_SPEED
	if Input.is_action_just_pressed("next_day"):
		time += MINUTES_PER_DAY * INGAME_TO_REAL_MINUTE_DURATION
		TimeManager.emit_signal("new_day")
	
	degree = (sin(time - PI / 2.0) + 1.0) / 2.0
	color = gradient_texture.gradient.sample(degree)
	shadow_modulate = lerp(MIN_SHADOW_MODULATE, color, degree / 2)

	lantern_with_shadows.energy = lantern_with_shadow_max_energy * (1 - degree)
	lantern_no_shadows.energy = lantern_no_shadow_max_energy * (1 - degree)
	
	_recalculate_time()


func _recalculate_time() -> void:
	var total_minutes = int(time / INGAME_TO_REAL_MINUTE_DURATION)
	var current_day_minutes = total_minutes % MINUTES_PER_DAY
	
	day = int(total_minutes / float(MINUTES_PER_DAY))
	hour = int(current_day_minutes / float(MINUTES_PER_HOUR))
	minute = int(current_day_minutes % MINUTES_PER_HOUR)
	
	if total_minutes >= last_displayed_time + 10:
		last_displayed_time = total_minutes
		time_tick.emit(day, hour, minute)


func new_day():
	print("new day")
