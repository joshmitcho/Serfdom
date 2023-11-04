extends BaseDialogueTestScene


func _ready():
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	SettingsManager.toggle_fullscreen()
	NpcManager.test_dialogue(resource, title)
