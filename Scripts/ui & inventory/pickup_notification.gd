# pickup_notification.gd
extends Control 

class_name PickupNotification

@onready var notification_container: NinePatchRect = $NotificationContainer
@onready var pickup_name_display: Label = $PickupNameDisplay
@onready var item_sprite: ShadowedSprite = %ShadowSprite
@onready var pickup_quantity: Label = $PickupQuantity

var item: Item

var alive_time := 0.0
const LIFETIME := 3.0
const FADE_TIME := 0.8

func initialize(p_item: Item, amount: int):
	item = p_item.duplicate()
	item.amount = amount
	
	pickup_name_display.text = item.item_name.capitalize()
	
	var name_size = pickup_name_display.get_theme_font("font").get_string_size(
		pickup_name_display.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
	
	notification_container.set_size(Vector2(name_size.x + 46, 25))
	
	item_sprite.initialize(Compendium.items_spritesheet, Compendium.num_sprites)
	item_sprite.change_frame(item.compendium_index)
	
	if item.amount > 1:
		pickup_quantity.text = str(item.amount)
	else:
		pickup_quantity.text = ""
	
	$BounceTween.play(item_sprite)
	alive_time = 0.0


func _physics_process(delta):
	modulate = Color(1, 1, 1, 1)
	if alive_time > LIFETIME:
		modulate = Color(1, 1, 1, FADE_TIME - sqrt(alive_time - LIFETIME))
	if alive_time > LIFETIME + FADE_TIME:
		queue_free()
	
	alive_time += delta
	
