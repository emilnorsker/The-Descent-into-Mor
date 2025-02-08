class_name Entity
extends Sprite2D

enum AIType {NONE, HOSTILE}
enum EntityType {CORPSE, ITEM, ACTOR}

const entity_types = {
	"player": "res://assets/blueprints/entities/actors/entity_definition_player.tres",
	"orc": "res://assets/blueprints/entities/actors/entity_definition_orc.tres",
	"troll": "res://assets/blueprints/entities/actors/entity_definition_troll.tres",
	"dagger": "res://assets/blueprints/entities/items/dagger_definition.tres",
	"sword": "res://assets/blueprints/entities/items/sword_definition.tres",
	"chainmail": "res://assets/blueprints/entities/items/chainmail_definition.tres",
	"leather_armor": "res://assets/blueprints/entities/items/leather_armor_definition.tres",
	"torch": "res://assets/blueprints/entities/items/torch_definition.tres",
}

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
var map_data: MapData
var key: String

var combat_component: CombatComponent
var ai_component: BaseAIComponent
var consumable_component: ConsumableComponent
var equippable_component: EquippableComponent
var inventory_component: InventoryComponent
var progression_component: ProgressionComponent
var equipment_component: EquipmentComponent
var light_component: LightComponent

# Action queue for all entities
var action_queue: Array[Action] = []

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

func _init(map_data: MapData, start_position: Vector2i, key: String = "") -> void:
	centered = false
	grid_position = start_position
	self.map_data = map_data
	if key != "":
		set_entity_type(key)


func set_entity_type(key: String) -> void:
	self.key = key
	var entity_blueprint: EntityBlueprint = load(entity_types[key])
	_blueprint = entity_blueprint
	type = _blueprint.type
	blocks_movement = _blueprint.is_blocking_movment
	entity_name = _blueprint.name
	texture = entity_blueprint.texture
	modulate = entity_blueprint.color
	
	match entity_blueprint.ai_type:
		AIType.HOSTILE:
			ai_component = HostileEnemyAIComponent.new()
			add_child(ai_component)
	
	if entity_blueprint.combat_definition:
		combat_component = CombatComponent.new(entity_blueprint.combat_definition)
		add_child(combat_component)
		
	var item_definition: ItemComponentDefinition = entity_blueprint.item_definition
	if item_definition:
		if item_definition is ConsumableComponentDefinition:
			_handle_consumable(item_definition)
		else:
			equippable_component = EquippableComponent.new(item_definition)
	
	if entity_blueprint.light_definition:
		light_component = LightComponent.new(entity_blueprint.light_definition)
		add_child(light_component)
	
	if entity_blueprint.inventory_capacity > 0:
		inventory_component = InventoryComponent.new(entity_blueprint.inventory_capacity)
		add_child(inventory_component)
	
	if entity_blueprint.progression_info:
		progression_component = ProgressionComponent.new(entity_blueprint.progression_info)
		add_child(progression_component)
	
	if entity_blueprint.has_equipment:
		equipment_component = EquipmentComponent.new()
		add_child(equipment_component)
		equipment_component.entity = self


func move(move_offset: Vector2i) -> void:
	map_data.unregister_blocking_entity(self)
	grid_position += move_offset
	map_data.register_blocking_entity(self)
	visible = true 	# map_data.get_tile(grid_position).is_in_view


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


func _handle_consumable(consumable_definition: ConsumableComponentDefinition) -> void:
	if consumable_definition is HealingConsumableComponentDefinition:
		consumable_component = HealingConsumableComponent.new(consumable_definition)
	elif consumable_definition is LightningDamageConsumableComponentDefinition:
		consumable_component = LightningDamageConsumableComponent.new(consumable_definition)
	elif consumable_definition is ConfusionConsumableComponentDefinition:
		consumable_component = ConfusionConsumableComponent.new(consumable_definition)
	elif consumable_definition is FireballDamageConsumableComponentDefinition:
		consumable_component = FireballDamageConsumableComponent.new(consumable_definition)
	
	if consumable_component:
		add_child(consumable_component)
	consumable_component.entity = self
