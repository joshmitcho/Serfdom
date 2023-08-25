# state_idle_move.gd
extends PlayerState

var scroll_time: int = 0
const SCROLL_DELAY: int = 8
const HOTBAR_SIZE: int = 9

func enter(_msg := {}) -> void:
	player.velocity = Vector2.ZERO
	var facing = player.animator.animation.split("_")[-1]
	player.animator.set_animation(player.holding + "move_" + facing)
	if not Input.is_action_pressed("use_tool"):
		player.animator.stop()
	player.tool_animator.visible = false


func handle_input(_event):
	if Input.is_action_just_pressed("zoom"):
		Utils.toggle_zoom()
		return
	
	if Input.is_action_just_pressed("fullscreen"):
		Utils.toggle_fullscreen()
		return
	
	if Input.is_action_just_pressed("use_tool"):
		if Inventory.does_cursor_have_item():
			Inventory.drop_item()
			print("drop")
			return
	
	if Input.is_action_just_pressed("menu"):
		Inventory.emit_signal("toggle_menu", 0)
		state_machine.transition_to("MenuOpen")
		return
	if Input.is_action_just_pressed("crafting_menu") and not Inventory.does_cursor_have_item():
		Inventory.emit_signal("toggle_menu", 1)
		state_machine.transition_to("MenuOpen")
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


func physics_update(_delta: float) -> void:
	player_movement()
	
	if Input.is_action_pressed("use_tool") and not Inventory.does_cursor_have_item():
		if player.holding == "":
			state_machine.transition_to("UseTool", {"is_static": true})
			return
		else:
			state_machine.transition_to("UseTool", {"is_static": false})
			return


func player_movement():
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
