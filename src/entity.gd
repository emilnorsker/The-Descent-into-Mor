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

static func from_blueprint(blueprint: EntityBlueprint, pos: Vector2i) -> Entity:
	var entity = Entity.new()
	entity.setup_from_blueprint(blueprint)
	entity.grid_position = pos
	return entity

func _init(blueprint: EntityBlueprint = null, grid_position: Vector2i = Vector2i.ZERO) -> void:
	self.grid_position = grid_position
	
	if blueprint:
		setup_from_blueprint(blueprint)

func setup_from_blueprint(blueprint: EntityBlueprint) -> void:
	_blueprint = blueprint
	type = blueprint.type
	blocks_movement = blueprint.is_blocking_movment
	entity_name = blueprint.name
	texture = blueprint.texture
	modulate = blueprint.color
	
	# Setup components
	if blueprint.terrain_blueprint:
		terrain_component = TerrainComponent.new(blueprint.terrain_blueprint)
		add_child(terrain_component)
	
	if blueprint.combat_blueprint:
		combat_component = CombatComponent.new(blueprint.combat_blueprint)
		add_child(combat_component)
	
	if blueprint.ai_type == AIType.HOSTILE:
		ai_component = HostileEnemyAIComponent.new(blueprint.ai_blueprint)
		add_child(ai_component)
	
	if blueprint.item_blueprint:
		if blueprint.item_blueprint is ConsumableComponentBlueprint:
			consumable_component = ConsumableComponent.new(blueprint.item_blueprint)
			add_child(consumable_component)
		else:
			equippable_component = EquippableComponent.new(blueprint.item_blueprint)
			add_child(equippable_component)
	
	if blueprint.light_blueprint:
		light_component = LightComponent.new(blueprint.light_blueprint)
		add_child(light_component)
	
	if blueprint.inventory_blueprint:
		inventory_component = InventoryComponent.new(blueprint.inventory_blueprint)
		add_child(inventory_component)
	
	if blueprint.progression_blueprint:
		progression_component = ProgressionComponent.new(blueprint.progression_blueprint)
		add_child(progression_component)
	
	if blueprint.equipment_blueprint:
		equipment_component = EquipmentComponent.new(blueprint.equipment_blueprint)
		add_child(equipment_component)

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
	return blocks_movement

func get_entity_name() -> String:
	return entity_name

func get_entity_type() -> int:
	return _blueprint.type

func is_alive() -> bool:
	return ai_component != null

func blocks_sight() -> bool:
	if terrain_component:
		return terrain_component.blocks_sight()
	return false

func get_movement_cost() -> float:
	if terrain_component:
		return terrain_component.movement_cost()
	return 1.0
