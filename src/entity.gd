@tool
class_name Entity extends Node2D

# Enums
enum AIType {NONE, HOSTILE}
enum EntityType {CORPSE, ITEM, ACTOR, TERRAIN, FIXTURE}

const DEFAULT_BLUEPRINT = preload("res://new_assets/entities/entity_blueprint.tres")

# Core Properties
var entity_name: String
var entity_type: EntityType

var _components: Dictionary = {}

func _init(blueprint: Resource = null, start_grid_position: Vector2i = Vector2i.ZERO) -> void:
    # Initialize base entity properties
    grid_position = start_grid_position
    
    # If no blueprint provided, use default
    if blueprint == null: blueprint = DEFAULT_BLUEPRINT
    # duplicating the resource will make it into a blueprint instance
    blueprint = blueprint.duplicate() as EntityBlueprint
    # the only case where this happens, should be if the DEFAULT_BLUEPRINT is not set up correctly
    assert(blueprint is EntityBlueprint, "Blueprint %s must be an instance of EntityBlueprint" % blueprint.get_class())
    assert(blueprint.components, "Blueprint must have components")
    
    
    entity_name = blueprint.entity_name
    entity_type = blueprint.entity_type
    
    for component_name in blueprint.components:
        var component_blueprint = blueprint.components[component_name]
        assert(component_blueprint is ComponentBlueprint, "Component blueprint must be an instance of ComponentBlueprint")
        
        var component = null
        match component_name:
            "body":
                component = BodyComponent.new(component_blueprint)
            "combat":
                component = CombatComponent.new(component_blueprint)
            "inventory":
                component = InventoryComponent.new(component_blueprint)
            "equipment":
                component = EquipmentComponent.new(component_blueprint)
            "material":
                component = MaterialComponent.new(component_blueprint)
            "modifiers":
                component = ModifierComponent.new(component_blueprint)
            "weight":
                component = WeightComponent.new(component_blueprint)
            "light":
                component = LightComponent.new(component_blueprint)
            "terrain":
                component = TerrainComponent.new(component_blueprint)
        
        if component: 
            _components[component_name] = component
            if component is Node:
                add_child(component)
        else:
            push_warning("Component not found: %s in entity blueprint: %s, entity: %s" % [component_name, blueprint, self])


func _get(property: StringName) -> Variant:
    # Special handling for component_type - this should never be accessed directly

    # first check if we have the property in our own property list
    for prop in get_property_list():
        if prop.name == property:
            return get(property)

    if property == &"component_type":
        push_warning("Attempting to access component_type directly on entity. Access specific component instead.")
        return null

    # then check if the property is one of our components
    if property in _components:
        return _components[property]
    
    # then check component properties
    for component in _components.values():
        var properties = component.get_property_list()
        for prop in properties:
            if prop.name == property:
                return component.get(property)
        
    return null

func _set(property: StringName, value: Variant) -> bool:
    # First check if this is a component
    if property in _components:
        if value == null:
            # Remove component
            var old_component = _components[property]
            if old_component is Node:
                remove_child(old_component)
            _components.erase(property)
            return true
            
        # Replace component
        if value is Component:
            var old_component = _components.get(property)
            if old_component is Node:
                remove_child(old_component)
                
            _components[property] = value
            if value is Node:
                add_child(value)
            return true
            
        return false
        
    # Then try to set component properties
    for component in _components.values():
        if component and component is Object:
            var properties = component.get_property_list()
            for prop in properties:
                if prop.name == property:
                    component.set(property, value)
                    return true
    
    # keep this at the end for performance
    # Special handling for component_type - this should never be accessed directly
    if property == "component_type":
        push_warning("Attempting to access component_type directly on entity. Access specific component instead.")
        return false
    
    return false

var grid_position: Vector2i:
    set(value):
        global_position = Grid.grid_to_world(value)
        grid_position = value
    get:
        return grid_position

# Movement System
func move(offset: Vector2i) -> void:
    var from_pos = grid_position
    var to_pos = grid_position + offset
    grid_position = to_pos
    GameMap.move_entity(self, from_pos, to_pos)

func distance(other_position: Vector2i) -> int:
    var relative: Vector2i = other_position - grid_position
    return maxi(abs(relative.x), abs(relative.y))

# Action System
var action_queue: Array[Action] = []

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

# Utility Functions
var next_roll: int = -1

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
