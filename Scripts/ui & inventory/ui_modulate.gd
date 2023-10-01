extends CanvasModulate
class_name UIModulate

@export var gradient_texture: GradientTexture1D
static var current_color: Color

func _process(_delta):
	current_color = gradient_texture.gradient.sample(DayNightCycle.degree)
	set_color(current_color)
