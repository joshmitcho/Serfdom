# pickup_notification.gd
extends Control

class_name PickupNotification

@onready var pickup_name_display: Label = $PickupText
@onready var item_sprite: ShadowedSprite = %ShadowSprite
@onready var item_amount_label = %PickupQuantity

var item: Item

var alive_time: float
const LIFETIME: float = 3.0
const FADE_TIME: float = 0.8

func initialize(p_item: Item, amount: int):
	
	item = p_item.duplicate()
	item.amount = amount
	
	pickup_name_display.text = item.item_name.capitalize()
	
	var name_size = pickup_name_display.get_theme_font("font").get_string_size(
		pickup_name_display.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
	
	$StretchSprite.scale.x = name_size.x / 22.0
	$EndCapSprite.position.x = name_size.x + 22
	
	item_sprite.initialize(Compendium.items_spritesheet, Compendium.num_sprites)
	item_sprite.change_frame(item.compendium_index)
	
	if item.amount > 1:
		item_amount_label.text = str(item.amount)
	else:
		item_amount_label.text = ""
	
	$BounceTween.play(item_sprite)
	alive_time = 0.0

func _physics_process(delta):
	modulate = Color(1, 1, 1, 1)
	if alive_time > LIFETIME:
		modulate = Color(1, 1, 1, FADE_TIME - sqrt(alive_time - LIFETIME))
	if alive_time > LIFETIME + FADE_TIME:
		queue_free()
	
	alive_time += delta
	
