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
                        print(component_blueprint.material_type)
                        components.material = MaterialComponent.new()
                        components.material.setup_from_blueprint(component_blueprint)
                        add_child(components.material)
                    "combat_modifier":
                        components.combat_modifier = CombatModifierComponent.new()
                        components.combat_modifier.setup_from_blueprint(component_blueprint)
                        add_child(components.combat_modifier)
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
    
    return self

# Delegate common methods to appropriate components
func roll(check: int, modifiers: Array[int] = []) -> bool:
    if not components.combat_modifier: return false
	
    return components.combat_modifier.roll(check, modifiers)

func has_state(state: Constants.StatusEffect) -> bool:
    return components.combat_modifier.has_state(state) if components.combat_modifier else false

func has_status(status: Constants.StatusEffect) -> bool:
    return components.combat_modifier.has_status(status) if components.combat_modifier else false


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
