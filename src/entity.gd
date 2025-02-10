@tool
class_name Entity extends Node2D

enum AIType {NONE, HOSTILE}
enum EntityType {CORPSE, ITEM, ACTOR, TERRAIN, FIXTURE}

var _grid_position: Vector2i
var grid_position: Vector2i:
    set(value):
        _grid_position = value
        global_position = Grid.grid_to_world(value)
    get:
        return _grid_position

var entity_name: String
var blocks_movement: bool
var _type: EntityType
var type: EntityType:
    set(value):
        _type = value
    get:
        return _type
var key: String

var action_queue: Array[Action] = []

# Store actual component instances
var components: Dictionary = {
    "inventory": null,
    "combat": null,
    "equipment": null,
    "progression": null,
    "light": null,
    "material": null,
    "combat_modifier": null,
    "terrain": null,
    "ai": null,
    "consumable": null,
    "item": null,
    "body": null
}

# Property getters for component access
var inventory_component: InventoryComponent:
    get: return components.inventory
var combat_component: CombatComponent:
    get: return components.combat
var equipment_component: EquipmentComponent:
    get: return components.equipment
var progression_component: ProgressionComponent:
    get: return components.progression
var light_component: LightComponent:
    get: return components.light
var material_component: MaterialComponent:
    get: return components.material
var combat_modifier_component: CombatModifierComponent:
    get: return components.combat_modifier
var terrain_component: TerrainComponent:
    get: return components.terrain
var ai_component: BaseAIComponent:
    get: return components.ai
var consumable_component: ConsumableComponent:
    get: return components.consumable
var item_component: ItemComponent:
    get: return components.item
var body_component: BodyComponent:
    get: return components.body

func _init() -> void:
    grid_position = Vector2i.ZERO

func setup_from_blueprint(blueprint: Resource, position: Vector2i = Vector2i.ZERO) -> Entity:
    if not blueprint or not blueprint is EntityBlueprint:
        push_error("Invalid blueprint provided to Entity.setup_from_blueprint")
        return self
    
    grid_position = position
    entity_name = blueprint.entity_name
    blocks_movement = blueprint.blocks_movement
    type = blueprint.type
    key = blueprint.key
    
    # TODO: find a better pattern
    if blueprint.inventory_blueprint:
        components.inventory = InventoryComponent.new()
        components.inventory.setup_from_blueprint(blueprint.inventory_blueprint)
        add_child(components.inventory)
        
    if blueprint.combat_blueprint:
        components.combat = CombatComponent.new()
        components.combat.setup_from_blueprint(blueprint.combat_blueprint)
        add_child(components.combat)
        
    if blueprint.equipment_blueprint:
        components.equipment = EquipmentComponent.new()
        components.equipment.setup_from_blueprint(blueprint.equipment_blueprint)
        add_child(components.equipment)
        
    if blueprint.progression_blueprint:
        components.progression = ProgressionComponent.new()
        components.progression.setup_from_blueprint(blueprint.progression_blueprint)
        add_child(components.progression)
        
    if blueprint.light_blueprint:
        components.light = LightComponent.new()
        components.light.setup_from_blueprint(blueprint.light_blueprint)
        add_child(components.light)
        
    if blueprint.material_blueprint:
        components.material = MaterialComponent.new()
        components.material.setup_from_blueprint(blueprint.material_blueprint)
        add_child(components.material)
        
    if blueprint.combat_modifier_blueprint:
        components.combat_modifier = CombatModifierComponent.new()
        components.combat_modifier.setup_from_blueprint(blueprint.combat_modifier_blueprint)
        add_child(components.combat_modifier)
        
    if blueprint.terrain_blueprint:
        components.terrain = TerrainComponent.new()
        components.terrain.setup_from_blueprint(blueprint.terrain_blueprint)
        add_child(components.terrain)
        
    if blueprint.ai_blueprint:
        components.ai = BaseAIComponent.new()
        components.ai.setup_from_blueprint(blueprint.ai_blueprint)
        add_child(components.ai)
        
    if blueprint.consumable_blueprint:
        components.consumable = ConsumableComponent.new()
        components.consumable.setup_from_blueprint(blueprint.consumable_blueprint)
        add_child(components.consumable)
        
    if blueprint.item_blueprint:
        components.item = ItemComponent.new()
        components.item.setup_from_blueprint(blueprint.item_blueprint)
        add_child(components.item)
        
    if blueprint.body_blueprint:
        components.body = BodyComponent.new()
        components.body.setup_from_blueprint(blueprint.body_blueprint)
        add_child(components.body)
    
    return self

# Delegate common methods to appropriate components
func roll_balance_check() -> bool:
    return combat_modifier_component.roll_balance_check() if combat_modifier_component else false

func has_state(state: Constants.StatusEffect) -> bool:
    return combat_modifier_component.has_state(state) if combat_modifier_component else false

func has_status(status: Constants.StatusEffect) -> bool:
    return combat_modifier_component.has_status(status) if combat_modifier_component else false

func get_action() -> Action:
    # First check components that can generate actions
    for component in components.values():
        var action = component.get_action(self)
        if action:
            return action
    return null

func queue_action(action: Action) -> void:
    action_queue.append(action)

func process_action_queue() -> bool:
    if action_queue.is_empty():
        # Try to get a new action from components
        var new_action = get_action()
        if new_action:
            action_queue.append(new_action)
        else:
            return false
        
    var current_action = action_queue[0]
    if current_action.perform():
        action_queue.remove_at(0)
        return true
        
    # If action failed (returned false), clear it and the rest of the queue
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
