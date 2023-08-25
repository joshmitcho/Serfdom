class_name Animator
extends Node

# Dependencies
const SPRITE_PATH = "Sprite2D"
const ANIMATED_SPRITE_PATH = "AnimatedSprite2D"
const SHADOW_SPRITE_PATH = "ShadowSprite"
@onready var host = get_parent()
@onready var host_sprite

# Options
@export var single_use: bool = false

# Variables
var active_tween: Tween

# Signals
signal completed
signal stopped


func _ready():
	if host.has_node(SPRITE_PATH):
		host_sprite = host.get_node(SPRITE_PATH)
	elif host.has_node(ANIMATED_SPRITE_PATH):
		host_sprite = host.get_node(ANIMATED_SPRITE_PATH)
	elif host.has_node(SHADOW_SPRITE_PATH):
		host_sprite = host.get_node(SHADOW_SPRITE_PATH)
	
	# Pass host down to all descendant Animators
	for child in get_children():
		child.host = host
		child.single_use = single_use
		child._initialize()

func play():
	emit_signal("completed")
	if single_use:
		queue_free()
