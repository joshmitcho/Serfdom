# state_idle_move.gd
extends PlayerState

signal do_action_pressed(offsets: Array)

var direction: Vector2
var scroll_time: int = 0
const SCROLL_DELAY: int = 7

func _ready():
	Inventory.chest_opened.connect(chest_opened)
	super._ready()

func enter(_msg := {}) -> void:
	player.velocity = Vector2.ZERO
	var facing = player.animator.animation.split("_")[-1]
	if facing == "right":
		player.facing = Vector2i(1,0)
	elif facing == "left":
		player.facing = Vector2i(-1,0)

	player.animator.set_animation(player.holding + "move_" + facing)
	if not Input.is_action_pressed("use_item"):
		player.animator.stop()
	player.tool_animator.hide()


func handle_input(_event):
	if Input.is_action_just_pressed("zoom"):
		SettingsManager.toggle_zoom()
		return
	
	if Input.is_action_just_pressed("fullscreen"):
		SettingsManager.toggle_fullscreen()
		return
	
	if Input.is_action_just_pressed("use_item"):
		if Inventory.does_cursor_have_item():
			Inventory.drop_item()
		else:
			state_machine.transition_to("UseItem")
		return

	if Input.is_action_just_pressed("do_action") and not Inventory.does_cursor_have_item():
		do_action_pressed.emit([Vector2i.ZERO, player.facing])
		direction = Vector2.ZERO
		return
	
	if not ChestUI.is_open:
		if Input.is_action_just_pressed("menu"):
			Inventory.toggle_menu.emit(0)
			state_machine.transition_to("MenuOpen")
			return
		elif Input.is_action_just_pressed("crafting_menu") and not Inventory.does_cursor_have_item():
			Inventory.toggle_menu.emit(1)
			state_machine.transition_to("MenuOpen")
			return
	
	if Input.is_action_just_pressed("shift_toolbar"):
		Inventory.shift_toolbar()
		Inventory.learn_new_recipe("deluxe_chest")
		return
	
	if Input.is_action_just_released("scroll_down"):
		if scroll_time > SCROLL_DELAY:
			Inventory.increment_active_slot(1)
			scroll_time = 0
		scroll_time += 1
	elif Input.is_action_just_released("scroll_up"):
		if scroll_time > SCROLL_DELAY:
			Inventory.increment_active_slot(-1)
			scroll_time = 0
		scroll_time += 1
		
	for key in range(49, 49 + Inventory.BAR_SIZE):
		if Input.is_physical_key_pressed(key):
			Inventory.set_active_slot(key - 49)
	
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")


func physics_update(_delta: float) -> void:
	if direction.x > 0:
		player.animator.play(player.holding + "move_right")
	elif direction.x < 0:
		player.animator.play(player.holding + "move_left")
	elif direction.y > 0:
		player.animator.play(player.holding + "move_down")
	elif direction.y < 0:
		player.animator.play(player.holding + "move_up")
	else:
		enter()
		return
	
	if direction.x != 0:
		direction.x = direction.x / abs(direction.x)
	if direction.y != 0:
		direction.y = direction.y / abs(direction.y)
	
	player.facing = Vector2i(direction)
	
	if abs(direction.x) + abs(direction.y) > 1:
		player.velocity = direction * player.diagonal_movement_speed
	else:
		player.velocity = direction * player.linear_movement_speed
		
	player.move_and_slide()


func chest_opened():
	state_machine.transition_to("ChestOpen")


func exit():
	direction = Vector2.ZERO
