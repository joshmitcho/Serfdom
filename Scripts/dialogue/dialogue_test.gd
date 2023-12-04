extends BaseDialogueTestScene


func _ready():
	DialogueManager.dialogue_ended.connect(loop_dialogue)
	#SettingsManager.toggle_fullscreen()
	loop_dialogue(resource)


func loop_dialogue(_resource):
	NpcManager.test_dialogue(resource, title)
