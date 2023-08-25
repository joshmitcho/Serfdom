# light_manager.gd
extends CanvasModulate

class_name LightManager

@export var lanternShadow: PointLight2D
@export var lantern: PointLight2D

@export var nightColour = Color("00173b")
@export var dayColour = Color("#ffffff")
@export var lanternColour = Color("#ff9945")

const TIME_SCALE = 0.1

var time: float = 0
var degree: float = 0
var interpolation: float = 0

var A1: float
var A2: float

func _ready():
	lantern.color = lanternColour
	lanternShadow.color = lanternColour
	A1 = lanternShadow.energy
	A2 = lantern.energy

func _process(delta):
	time += delta * TIME_SCALE
	degree = clamp(sin(time) + 0.5, 0, 1)
	
	lanternShadow.energy = A1 * (1 - degree)
	lantern.energy = A2 * (1 - degree)
	
	color = nightColour.lerp(dayColour, degree)
