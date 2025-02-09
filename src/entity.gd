@tool
class_name Entity
extends Sprite2D

enum AIType {NONE, HOSTILE}
enum EntityType {CORPSE, ITEM, ACTOR, TERRAIN, FIXTURE}

var _grid_position: Vector2i
var grid_position: Vector2i:
	set(value):
		_grid_position = value
		position = Grid.grid_to_world(value)
	get:
		return _grid_position

var _blueprint: EntityBlueprint
var entity_name: String
var blocks_movement: bool
var type: EntityType:
	set(value):
		type = value
		z_index = type
var key: String

var combat_component: CombatComponent
var ai_component: BaseAIComponent
var consumable_component: ConsumableComponent
var equippable_component: EquippableComponent
var inventory_component: InventoryComponent
var progression_component: ProgressionComponent
var equipment_component: EquipmentComponent
var light_component: LightComponent
var terrain_component: TerrainComponent

# Action queue for all entities
var action_queue: Array[Action] = []

var components: Dictionary = {}

func _init() -> void:
	grid_position = Vector2i.ZERO

static func from_blueprint(blueprint: Resource, position: Vector2i) -> Entity:
	var entity = Entity.new()
	entity.grid_position = position
	entity.setup_from_blueprint(blueprint)
	return entity

func setup_from_blueprint(blueprint: Resource) -> void:
	if not blueprint or not blueprint is EntityBlueprint:
		return
		
	_blueprint = blueprint
	entity_name = blueprint.entity_name
	blocks_movement = blueprint.blocks_movement
	type = blueprint.type
	key = blueprint.key
	
	for component_data in blueprint.get_components():
		var component_name = component_data.name
		var component_properties = component_data.properties
		add_component(component_name, component_properties)

func add_component(component_name: String, properties: Dictionary = {}) -> void:
	var component_script = load("res://src/Components/" + component_name + ".gd")
	if component_script:
		var component = component_script.new()
		for key in properties:
			component.set(key, properties[key])
		components[component_name] = component
		add_child(component)

func get_component(component_name: String) -> Node:
	return components.get(component_name)

func has_component(component_name: String) -> bool:
	return components.has(component_name)

func queue_action(action: Action) -> void:
	action_queue.append(action)

func process_action_queue() -> bool:
	if action_queue.is_empty():
		return false
		
	var current_action = action_queue[0]
	if current_action.perform():
		action_queue.remove_at(0)
		return true
		
	# If action failed (returned false), clear it and the rest of the queue
	# This prevents getting stuck on impossible actions
	action_queue.clear()
	return false

func move(offset: Vector2i) -> void:
	var from_pos = grid_position
	var to_pos = grid_position + offset
	grid_position = to_pos
	GameMap.move_entity(self, from_pos, to_pos)

func distance(other_position: Vector2i) -> int:
	var relative: Vector2i = other_position - grid_position
	return maxi(abs(relative.x), abs(relative.y))

func is_blocking_movement() -> bool:
	return blocks_movement or (type == EntityType.ACTOR)

func get_entity_name() -> String:
	return entity_name

func get_entity_type() -> int:
	return type

func is_alive() -> bool:
	return has_component("AIComponent")

func blocks_sight() -> bool:
	if has_component("TerrainComponent"):
		return get_component("TerrainComponent").blocks_sight()
	return false

func get_movement_cost() -> float:
	if has_component("TerrainComponent"):
		return get_component("TerrainComponent").movement_cost()
	return 1.0
