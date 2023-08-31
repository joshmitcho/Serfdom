# state_idle_move.gd
extends PlayerState

signal do_action_pressed(offsets: Array)

var scroll_time: int = 0
const SCROLL_DELAY: int = 7
const HOTBAR_SIZE: int = 9

func _ready():
	Inventory.chest_opened.connect(chest_opened)
	super._ready()

func enter(_msg := {}) -> void:
	player.velocity = Vector2.ZERO
	var facing = player.animator.animation.split("_")[-1]
	player.animator.set_animation(player.holding + "move_" + facing)
	if not Input.is_action_pressed("use_item"):
		player.animator.stop()
	player.tool_animator.visible = false


func handle_input(_event):
	if Input.is_action_just_pressed("zoom"):
		Utils.toggle_zoom()
		return
	
	if Input.is_action_just_pressed("fullscreen"):
		Utils.toggle_fullscreen()
		return
	
	if Input.is_action_just_pressed("use_item"):
		if Inventory.does_cursor_have_item():
			Inventory.drop_item()
			return
		else:
			state_machine.transition_to("UseItem")
	
	if Input.is_action_just_pressed("do_action") and not Inventory.does_cursor_have_item():
		emit_signal("do_action_pressed", [Vector2i.ZERO, player.facing])
		return
	
	if not ChestUI.is_open:
		if Input.is_action_just_pressed("menu"):
			Inventory.emit_signal("toggle_menu", 0)
			state_machine.transition_to("MenuOpen")
			return
		if Input.is_action_just_pressed("crafting_menu") and not Inventory.does_cursor_have_item():
			Inventory.emit_signal("toggle_menu", 1)
			state_machine.transition_to("MenuOpen")
			return
	
	if Input.is_action_just_pressed("shift_toolbar"):
		Inventory.shift_toolbar()
		return
	
	if Input.is_action_just_released("scroll_down"):
		if scroll_time > SCROLL_DELAY:
			Inventory.set_active_slot((Inventory.active_index + 1) % HOTBAR_SIZE)
			scroll_time = 0
		scroll_time += 1
	elif Input.is_action_just_released("scroll_up"):
		if scroll_time > SCROLL_DELAY:
			Inventory.set_active_slot((Inventory.active_index - 1) % HOTBAR_SIZE)
			scroll_time = 0
		scroll_time += 1
		
	for key in range(49, 49 + HOTBAR_SIZE):
		if Input.is_physical_key_pressed(key):
			Inventory.set_active_slot(key - 49)


func chest_opened():
	state_machine.transition_to("ChestOpen")


func physics_update(_delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction.x > 0:
		player.animator.play(player.holding + "move_right")
		player.facing = Vector2i(1,0)
	elif direction.x < 0:
		player.animator.play(player.holding + "move_left")
		player.facing = Vector2i(-1,0)
	elif direction.y > 0:
		player.animator.play(player.holding + "move_down")
		player.facing = Vector2i(0,1)
	elif direction.y < 0:
		player.animator.play(player.holding + "move_up")
		player.facing = Vector2i(0,-1)
	else:
		enter()
		return
	
	if direction.x != 0:
		direction.x = direction.x / abs(direction.x)
	if direction.y != 0:
		direction.y = direction.y / abs(direction.y)
	
	if abs(direction.x) + abs(direction.y) > 1:
		player.velocity = direction * player.diagonal_movement_speed
	else:
		player.velocity = direction * player.linear_movement_speed
		
	player.move_and_slide()
