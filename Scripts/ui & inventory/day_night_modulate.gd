# day_night_modulate.gd
extends CanvasModulate
class_name DayNightModulate

const MIN_SHADOW_MODULATE: Color = Color(0, 0, 0, 0) 

@export var lantern_with_shadows: PointLight2D
@export var lantern_no_shadows: PointLight2D
@export var lanternColour = Color("#ff9945")
@export var gradient_texture: GradientTexture1D

static var shadow_modulate: Color

@onready var lantern_with_shadow_max_energy: float = lantern_with_shadows.energy
@onready var lantern_no_shadow_max_energy: float = lantern_no_shadows.energy


func _ready() -> void:
	lantern_no_shadows.color = lanternColour
	lantern_with_shadows.color = lanternColour
	lantern_no_shadows.enabled = Inventory.has_lantern
	lantern_with_shadows.enabled = Inventory.has_lantern


func _process(_delta) -> void:
	var degree = TimeManager.canvas_modulate_degree
	color = gradient_texture.gradient.sample(degree)
	shadow_modulate = lerp(MIN_SHADOW_MODULATE, color, degree / 2)

	lantern_with_shadows.energy = lantern_with_shadow_max_energy * (1 - degree)
	lantern_no_shadows.energy = lantern_no_shadow_max_energy * (1 - degree)
