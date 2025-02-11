@tool
class_name Entity extends Node2D

enum AIType {NONE, HOSTILE}
enum EntityType {CORPSE, ITEM, ACTOR, TERRAIN, FIXTURE}

var next_roll: int = -1

var _grid_position: Vector2i
var grid_position: Vector2i:
    set(value):
        _grid_position = value
        global_position = Grid.grid_to_world(value)
    get:
        return _grid_position

var entity_name: String
var blocks_movement: bool
var movement_cost: float = 1.0
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
    "modifiers": null,
    "terrain": null,
    "ai": null,
    "consumable": null,
    "item": null,
    "body": null,
    "weight": null
}

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
    
    # Set up components from the components dictionary
    if blueprint.components:
        for component_name in blueprint.components:
            var component_blueprint = blueprint.components[component_name]
            if component_blueprint:
                match component_name:
                    "inventory":
                        components.inventory = InventoryComponent.new()
                        components.inventory.setup_from_blueprint(component_blueprint)
                        add_child(components.inventory)
                    "combat":
                        components.combat = CombatComponent.new()
                        components.combat.setup_from_blueprint(component_blueprint)
                        add_child(components.combat)
                    "equipment":
                        components.equipment = EquipmentComponent.new()
                        components.equipment.setup_from_blueprint(component_blueprint)
                        add_child(components.equipment)
                    "progression":
                        components.progression = ProgressionComponent.new()
                        components.progression.setup_from_blueprint(component_blueprint)
                        add_child(components.progression)
                    "light":
                        components.light = LightComponent.new()
                        components.light.setup_from_blueprint(component_blueprint)
                        add_child(components.light)
                    "material":
                        components.material = MaterialComponent.new()
                        components.material.setup_from_blueprint(component_blueprint)
                        add_child(components.material)
                    "modifiers":
                        components.modifiers = ModifierComponent.new()
                        components.modifiers.setup_from_blueprint(component_blueprint)
                        add_child(components.modifiers)
                    "terrain":
                        components.terrain = TerrainComponent.new()
                        components.terrain.setup_from_blueprint(component_blueprint)
                        add_child(components.terrain)
                    "ai":
                        components.ai = BaseAIComponent.new()
                        components.ai.setup_from_blueprint(component_blueprint)
                        add_child(components.ai)
                    "consumable":
                        components.consumable = ConsumableComponent.new()
                        components.consumable.setup_from_blueprint(component_blueprint)
                        add_child(components.consumable)
                    "item":
                        components.item = ItemComponent.new()
                        components.item.setup_from_blueprint(component_blueprint)
                        add_child(components.item)
                    "body":
                        components.body = BodyComponent.new()
                        components.body.setup_from_blueprint(component_blueprint)
                        add_child(components.body)
                    "weight":
                        components.weight = WeightComponent.new()
                        components.weight.setup_from_blueprint(component_blueprint)
                        add_child(components.weight)
    
    return self

# Delegate common methods to appropriate components


# Roll a check against a difficulty class (DC)
# dc: The difficulty class to beat (must roll >= this number)
# modifiers: Array of integers that modify the roll (can be positive or negative)
# dice_size: The size of the die to roll (e.g. 6 for d6, 20 for d20). Defaults to 6.
# Returns: bool - Whether the check succeeded
func roll(dc: int, modifiers: Array = [], dice_size: int = 6) -> bool:
    var roll_value: int
    
    # If in test mode and next_roll is set, use that
    if next_roll != -1:
        roll_value = next_roll
    else:
        # Roll a random number between 1 and dice_size
        roll_value = (randi() % dice_size) + 1
    
    # Apply all modifiers
    for modifier in modifiers:
        roll_value += modifier as int
    
    # Check if we beat or meet the DC
    print(entity_name, " rolled: ", roll_value, " dc: ", dc, " success: ", roll_value >= dc)
    return roll_value >= dc

# Get the raw roll value without checking against DC
# Useful for damage rolls etc.
func roll_value(dice_size: int = 6, modifiers: Array = []) -> int:
    var roll_value: int
    
    # If in test mode and next_roll is set, use that
    if next_roll != -1:
        roll_value = next_roll
    else:
        # Roll a random number between 1 and dice_size
        roll_value = (randi() % dice_size) + 1
    
    # Apply all modifiers
    for modifier in modifiers:
        roll_value += modifier as int
    
    print(entity_name, " rolled value: ", roll_value)
    return roll_value

func has_state(state: ModifierComponent) -> bool:
    return components.modifiers.has_state(state) if components.modifiers else false

func has_status(status: ModifierComponent) -> bool:
    return components.modifiers.has_status(status) if components.modifiers else false


func queue_action(action: Action) -> void:
    action_queue.append(action)

func process_action_queue() -> bool:
    if action_queue.is_empty():
        # Try to get a new action from components
        if components.ai:
            var new_action = components.ai.get_action(self)
            if new_action:
                action_queue.append(new_action)
            else:
                return false
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

func get_movement_cost() -> float:
    return movement_cost

func has_component(component_name: String) -> bool:
    return components.has(component_name) and components[component_name] != null
