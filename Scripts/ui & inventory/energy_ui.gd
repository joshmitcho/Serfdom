extends Control

const ENERGY_TO_PIXEL_RATIO: float = 15.0
const EXTRA_PIXELS: int = 15
const GRADIENT: Image = preload("res://Art/UI/green red gradient.png")

var max_bar_size: float
var bar_size: float


func update_bar_size(new_current_energy: int):
	bar_size = max(new_current_energy, 0) / ENERGY_TO_PIXEL_RATIO
	bar_size += EXTRA_PIXELS * (bar_size / max_bar_size)
	
	var energy_bar: ColorRect = $EnergyBar
	energy_bar.scale.y = bar_size / energy_bar.size.y
	
	var gradient_sample_x = 1 - (bar_size / (max_bar_size + EXTRA_PIXELS))
	energy_bar.color = GRADIENT.get_pixel(max(128 * gradient_sample_x - 1, 1), 8)


func new_max_bar_size(new_max_energy: int):
	max_bar_size = new_max_energy / ENERGY_TO_PIXEL_RATIO
	$Stretch.scale.y = max_bar_size / $Stretch.size.y
	$Top.position.y = int(-max_bar_size) - $Top.size.y
