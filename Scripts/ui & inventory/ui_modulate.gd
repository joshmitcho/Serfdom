extends CanvasModulate
class_name UIModulate

@export var gradient_texture: GradientTexture1D
static var current_color: Color

func _physics_process(_delta):
	current_color = gradient_texture.gradient.sample(TimeManager.canvas_modulate_degree)
	set_color(current_color)
