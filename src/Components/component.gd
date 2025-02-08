class_name Component
extends Node

@onready var entity: Entity = get_parent() as Entity

var data: Resource = null

func _init(blueprint: Resource) -> void:
	data = blueprint

func get_action(actor: Entity) -> Action:
	return null