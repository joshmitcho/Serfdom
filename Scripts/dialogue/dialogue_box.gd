#dialogue_box.gd
extends CanvasLayer

@export var monarchy_balloon: Texture2D
@export var serf_balloon: Texture2D

@onready var response_template: Node = %ResponseTemplate
@onready var talk_sound: AudioStreamPlayer = $TalkSound
@onready var balloon: TextureRect = $Balloon
@onready var margin: MarginContainer = $Balloon/Margin
@onready var portrait_container: VBoxContainer = %PortraitContainer
@onready var character_portrait: Sprite2D = %CharacterPortrait
@onready var monarchy_label: RichTextLabel = %MonarchyLabel
@onready var serf_label: RichTextLabel = %SerfLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_menu: VBoxContainer = %Responses

const MOODS: Array = ["oh", "neutral", "angry", "smile", "love", "cry", "dead", "teeth"]

## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## The current line
var dialogue_line: DialogueLine:
	set(next_dialogue_line):
		if not next_dialogue_line:
			queue_free()
			return

		is_waiting_for_input = false

		# Remove any previous responses
		for child in responses_menu.get_children():
			responses_menu.remove_child(child)
			child.queue_free()

		dialogue_line = next_dialogue_line
		
		if Compendium.ALL_NPCS[dialogue_line.character][0] == "serf":
			balloon.texture = serf_balloon
			serf_label.text = "[center]" + tr(dialogue_line.character, "dialogue").capitalize()
			serf_label.show()
			monarchy_label.hide()
			portrait_container.add_theme_constant_override("separation", 9)
		else:
			balloon.texture = monarchy_balloon
			monarchy_label.text = "[center]" + tr(dialogue_line.character, "dialogue").capitalize()
			monarchy_label.show()
			serf_label.hide()
			portrait_container.add_theme_constant_override("separation", 7)
		
		character_portrait.frame = Compendium.ALL_NPCS.keys().find(dialogue_line.character) * 8
		if dialogue_line.tags.size() > 0:
			character_portrait.frame += MOODS.find(dialogue_line.tags[0])
		else:
			character_portrait.frame += 1

		dialogue_label.modulate.a = 0
		dialogue_label.custom_minimum_size.x = dialogue_label.get_parent().size.x - 1
		dialogue_label.dialogue_line = dialogue_line

		# Show any responses we have
		responses_menu.modulate.a = 0
		if dialogue_line.responses.size() > 0:
			for response in dialogue_line.responses:
				# Duplicate the template so we can grab the fonts, sizing, etc
				var item: RichTextLabel = response_template.duplicate(0)
				item.name = "Response%d" % responses_menu.get_child_count()
				if not response.is_allowed:
					item.name = String(item.name) + "Disallowed"
					item.modulate.a = 0.4
				item.text = response.text
				item.show()
				responses_menu.add_child(item)

		# Show our balloon if it was previously hidden
		balloon.show()
		balloon.set_modulate(UIModulate.current_color.lerp(Color.WHITE, 0.5))
		
		dialogue_label.modulate.a = 1
		dialogue_label.type_out()
		await dialogue_label.finished_typing

		# Wait for input
		if dialogue_line.responses.size() > 0:
			responses_menu.modulate.a = 1
			configure_menu()
		elif dialogue_line.time != "":
			var time = dialogue_line.dialogue.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
			await get_tree().create_timer(time).timeout
			next(dialogue_line.next_id)
		else:
			is_waiting_for_input = true
			balloon.focus_mode = Control.FOCUS_ALL
			balloon.grab_focus()
	get:
		return dialogue_line


func _ready() -> void:
	response_template.hide()
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()


## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	temporary_game_states = extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)


## Go to the next line
func next(next_id: String) -> void:
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


### Helpers


# Set up keyboard movement and signals for the response menu
func configure_menu() -> void:
	balloon.focus_mode = Control.FOCUS_NONE

	var items = get_responses()
	for i in items.size():
		var item: Control = items[i]

		item.focus_mode = Control.FOCUS_ALL

		item.focus_neighbor_left = item.get_path()
		item.focus_neighbor_right = item.get_path()

		if i == 0:
			item.focus_neighbor_top = item.get_path()
			item.focus_previous = item.get_path()
		else:
			item.focus_neighbor_top = items[i - 1].get_path()
			item.focus_previous = items[i - 1].get_path()

		if i == items.size() - 1:
			item.focus_neighbor_bottom = item.get_path()
			item.focus_next = item.get_path()
		else:
			item.focus_neighbor_bottom = items[i + 1].get_path()
			item.focus_next = items[i + 1].get_path()

		item.mouse_entered.connect(_on_response_mouse_entered.bind(item))
		item.gui_input.connect(_on_response_gui_input.bind(item))

	items[0].grab_focus()


# Get a list of enabled items
func get_responses() -> Array:
	var items: Array = []
	for child in responses_menu.get_children():
		if "Disallowed" in child.name: continue
		items.append(child)

	return items


func handle_resize() -> void:
	if not is_instance_valid(margin):
		call_deferred("handle_resize")
		return

	balloon.custom_minimum_size.y = margin.size.y
	balloon.size.y = 0
	var viewport_size = balloon.get_viewport_rect().size
	balloon.global_position = Vector2((viewport_size.x - balloon.size.x) * 0.5, viewport_size.y - balloon.size.y)


### Signals


func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	balloon.hide()


func _on_response_mouse_entered(item: Control) -> void:
	if "Disallowed" in item.name: return

	item.grab_focus()


func _on_response_gui_input(event: InputEvent, item: Control) -> void:
	if "Disallowed" in item.name: return

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		next(dialogue_line.responses[item.get_index()].next_id)
	elif event.is_action_pressed("ui_accept") and item in get_responses():
		next(dialogue_line.responses[item.get_index()].next_id)


func _on_balloon_gui_input(event: InputEvent) -> void:
	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		next(dialogue_line.next_id)
	elif event.is_action_pressed("ui_accept") and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_margin_resized() -> void:
	handle_resize()


func _on_dialogue_label_spoke(letter: String, letter_index: int, speed: float) -> void:
	if letter != " ":
		var actual_speed: int = 4 if speed >= 1 else 2
		if letter_index % actual_speed == 0:
			talk_sound.play()
			var pitch = Compendium.ALL_NPCS[dialogue_line.character][1]
			talk_sound.pitch_scale = randf_range(pitch - 0.1, pitch + 0.1)
