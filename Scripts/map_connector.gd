extends Node
class_name MapConnector

signal map_connector_triggered(
	destination_map: StringName,
	connector_number: int,
)

@export var connector_number: int
@export var destination_map: StringName

@onready var exit_point: Marker2D = $ExitPoint


func _on_body_entered(body):
	if body is Player:
		map_connector_triggered.emit(destination_map, connector_number)
