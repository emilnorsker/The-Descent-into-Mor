@tool
class_name Entity extends Node2D

enum AIType {NONE, HOSTILE}
enum EntityType {CORPSE, ITEM, ACTOR, TERRAIN, FIXTURE}

# Component Registry with default configurations
const COMPONENT_REGISTRY = {
    "inventory": {
        "type_name": "inventory_component",
        "hint": "InventoryComponent",
        "default": {
            "capacity": 1,  # Everything can hold at least 1 item
            "weight_limit": 0.1  # Everything has minimal carry capacity
        }
    },
    "combat": {
        "type_name": "combat_component",
        "hint": "CombatComponent",
        "default": {
            "health": 1,  # Everything has 1 HP
            "damage": 0  # Not everything can deal damage
        }
    },
    "equipment": {
        "type_name": "equipment_component",
        "hint": "EquipmentComponent",
        "default": {
            "slots": ["held"]  # Everything can be held
        }
    },
    "consumable": {
        "type_name": "consumable_component",
        "hint": "ConsumableComponent",
        "default": {
            "nutrition": 0,  # Not everything is nutritious
            "effect": "inedible"  # But everything can be attempted to be eaten
        }
    }, 
    "body": { # TODO replace with anatomy component
        "type_name": "body_component",
        "hint": "BodyComponent",
        "default": {
            "parts": ["core"],  # Everything has at least a core
            "wounds": {}  # Start with no wounds
        }
    },
    "material": {
        "type_name": "material_component",
        "hint": "MaterialComponent",
        "default": {
            "type": "organic",  # Everything is made of something
            "flammable": true,  # Most things can burn
            "hardness": 1  # Basic hardness
        }
    },
    "modifiers": {
        "type_name": "modifier_component",
        "hint": "ModifierComponent",
        "default": {
            "states": [],  # No default states
            "positions": [],  # No default positions
            "environments": []  # No default environments
        }
    },
    "weight": {
        "type_name": "weight_component",
        "hint": "WeightComponent",
        "default": {
            "weight": 0.1  # Everything has some weight
        }
    }
}

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

# Internal component storage
var _components: Dictionary = {}

# Helper function to get component type from registry
func _get_component_type(component_name: String) -> GDScript:
    assert(component_name in COMPONENT_REGISTRY, "Invalid component requested: %s. Available components: %s" % [component_name, COMPONENT_REGISTRY.keys()])
    # Load the script directly by name
    var script_path = "res://src/Components/%s.gd" % COMPONENT_REGISTRY[component_name].type_name
    var script = load(script_path)
    if not script:
        push_error("Failed to load component script: %s" % script_path)
    return script as GDScript

func _init(blueprint: Resource = null, position: Vector2i = Vector2i.ZERO) -> void:
    # Initialize base entity properties
    grid_position = position
    
    # Create all components with default configurations
    for component_name in COMPONENT_REGISTRY:
        var component_script = _get_component_type(component_name)
        if component_script:
            var component = component_script.new()
            
            # Store and add as child if it's a Node first
            _components[component_name] = component
            if component is Node:
                add_child(component)
            
            # Then apply default configuration
            if COMPONENT_REGISTRY[component_name].has("default"):
                component.setup_from_dict(COMPONENT_REGISTRY[component_name].default)
    
    # If blueprint provided, override defaults
    if blueprint != null and blueprint is EntityBlueprint:
        entity_name = blueprint.entity_name
        blocks_movement = blueprint.blocks_movement
        type = blueprint.type
        key = blueprint.key
        
        # Override component configurations from blueprint
        if blueprint.components:
            for component_name in blueprint.components:
                if component_name in COMPONENT_REGISTRY:
                    var component_blueprint = blueprint.components[component_name]
                    if component_blueprint:
                        _components[component_name].setup_from_blueprint(component_blueprint)

func _get_property_list() -> Array[Dictionary]:
    var properties: Array[Dictionary] = []
    
    # Register each component as a property
    for component_name in COMPONENT_REGISTRY:
        var component_info = COMPONENT_REGISTRY[component_name]
        properties.append({
            "name": component_name,
            "type": TYPE_OBJECT,
            "hint": PROPERTY_HINT_RESOURCE_TYPE,
            "hint_string": component_info.hint,
            "usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE
        })
    
    return properties

func _get(property: StringName) -> Variant:
    # Check if this is a component property
    if property in COMPONENT_REGISTRY:
        return _components.get(property)
    return null

func _set(property: StringName, value: Variant) -> bool:
    # Check if this is a component property
    if property in COMPONENT_REGISTRY:
        # Type checking
        var component_script = _get_component_type(property)
        assert_not_null (component_script, "Component script not found for %s" % property)
            
        if value != null and not value.get_script() == component_script:
            push_error("Invalid type for %s component" % property)
            return false
            
        # Handle component replacement
        if _components.has(property):
            var old_component = _components[property]
            if old_component is Node:
                remove_child(old_component)
        
        # Update component
        _components[property] = value
        if value is Node:
            add_child(value)
        
        return true
        
    return false

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
    return selfs.modifiers.has_state(state) if _components.modifiers else false

func queue_action(action: Action) -> void:
    action_queue.append(action)

func process_action_queue() -> bool:
    if action_queue.is_empty():
        # Try to get a new action from components
        if _components.ai:
            var new_action = _components.ai.get_action(self)
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

func setup_from_blueprint(blueprint: Resource, position: Vector2i = Vector2i.ZERO) -> Entity:
    _init(blueprint, position)
    return self
