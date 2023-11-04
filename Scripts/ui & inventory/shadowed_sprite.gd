#shadowed_sprite.gd
extends Sprite2D
class_name ShadowedSprite

@onready var main_sprite: Sprite2D = $MainSprite

func initialize(spritesheet: Texture2D, num_sprites: Vector2i, separation = Vector2i(-1, 1)):
	texture = spritesheet
	hframes = int(num_sprites.x)
	vframes = int(num_sprites.y)
	
	main_sprite.texture = spritesheet
	main_sprite.hframes = int(num_sprites.x)
	main_sprite.vframes = int(num_sprites.y)
	
	offset = separation


func change_frame(p_frame: int):
	frame = p_frame
	main_sprite.frame = p_frame
