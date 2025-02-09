@tool
extends Resource
class_name EntityBlueprint

@export var entity_name: String = ""
@export var blocks_movement: bool = false
@export var type: Entity.EntityType = Entity.EntityType.ACTOR
@export var key: String = ""

@export_category("Components")
@export var components: Array[Dictionary] = []

func get_components() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	# Convert each component blueprint to a dictionary with name and properties
	for component in components:
		if component and component.has("name") and component.has("properties"):
			result.append({
				"name": component.name,
				"properties": component.properties
			})
	
	return result

func add_component(name: String, properties: Dictionary = {}) -> void:
	components.append({
		"name": name,
		"properties": properties
	})
