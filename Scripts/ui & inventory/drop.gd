# drop.gd

extends Area2D
class_name Drop

@export_range(1, 12) var frequency: int = 4
@export_range(1, 16) var amplitude: int = 2

var sprite

var time = 0
var item: Item
var offset: int

var pickupable: bool = false
var gravity_center: Vector2

@onready var rand_seed = randi_range(1, 100)

func initialize(p_item: Item, pos: Vector2, p_offset: int ):
	item = p_item
	position = pos
	offset = p_offset
	sprite = $Sprite2D
	sprite.texture = Compendium.items_spritesheet
	sprite.hframes = Compendium.num_sprites.x
	sprite.vframes = Compendium.num_sprites.y
	sprite.frame = item.compendium_index

func spawn():
	var tween = create_tween()
	offset *= randi_range(1, 2)
	position.y += randi_range(2, 6) * [-1, 1].pick_random()
	
	$BounceTween.play(sprite, randi_range(-5, 20))
	tween.tween_property(self, "position:x", position.x + offset, 0.6).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	pickupable = true
	gravity_center = position
	

func set_gravity_center(center: Vector2):
	gravity_center = center

func _physics_process(delta):
	if pickupable:
		time += delta
		var movement = sin(time * frequency + rand_seed) * amplitude
		sprite.set_offset(Vector2(0, movement))
		
		position = position.lerp(gravity_center, 0.06)
	



