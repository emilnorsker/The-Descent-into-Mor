@tool
class_name Entity
extends Sprite2D

enum AIType {NONE, HOSTILE}
enum EntityType {CORPSE, ITEM, ACTOR, TERRAIN, FIXTURE}

var grid_position: Vector2i:
	set(value):
		grid_position = value
		position = Grid.grid_to_world(grid_position)

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

func setup_from_blueprint(blueprint: EntityBlueprint) -> void:
	_blueprint = blueprint
	type = blueprint.type
	blocks_movement = blueprint.is_blocking_movment
	entity_name = blueprint.name
	texture = blueprint.texture
	modulate = blueprint.color
	
	# Setup components
	if blueprint.terrain_blueprint:
		var comp = TerrainComponent.new(blueprint.terrain_blueprint)
		add_child(comp)
		terrain_component = comp
		terrain_component.entity = self
	
	if blueprint.combat_blueprint:
		var comp = CombatComponent.new(blueprint.combat_blueprint)
		add_child(comp)
		combat_component = comp
	
	if blueprint.ai_type == AIType.HOSTILE:
		var comp = HostileEnemyAIComponent.new()
		add_child(comp)
		ai_component = comp
	
	var item_blueprint: ItemComponentBlueprint = blueprint.item_blueprint
	if item_blueprint:
		if item_blueprint is ConsumableComponentBlueprint:
			consumable_component = ConsumableComponent.new(item_blueprint)
			add_child(consumable_component)
			consumable_component.entity = self
		else:
			equippable_component = EquippableComponent.new(item_blueprint)
			add_child(equippable_component)
			equippable_component.entity = self
	
	if blueprint.light_blueprint:
		light_component = LightComponent.new(blueprint.light_blueprint)
		add_child(light_component)
		light_component.entity = self
	
	if blueprint.inventory_capacity > 0:
		inventory_component = InventoryComponent.new(blueprint.inventory_capacity)
		add_child(inventory_component)
		inventory_component.entity = self
	
	if blueprint.progression_blueprint:
		progression_component = ProgressionComponent.new(blueprint.progression_blueprint)
		add_child(progression_component)
		progression_component.entity = self
	
	if blueprint.has_equipment:
		equipment_component = EquipmentComponent.new()
		add_child(equipment_component)
		equipment_component.entity = self

func _init(start_position: Vector2i = Vector2i.ZERO, blueprint: EntityBlueprint = null) -> void:
	super()
	centered = false
	grid_position = start_position
	
	if blueprint:
		setup_from_blueprint(blueprint)

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

func move(move_offset: Vector2i) -> void:
	GameMap.move_entity(self, grid_position, grid_position + move_offset)
	grid_position += move_offset
	visible = true

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
		return terrain_component.get_movement_cost()
	return 1.0
