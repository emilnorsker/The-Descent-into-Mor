@tool
class_name CombatComponent extends Component

const DEFAULT_BLUEPRINT = preload("res://new_assets/blueprints/combat/basic.tres")

signal died

var max_hp: int = 30
var power: int = 5
var defense: int = 2
var hp: int = max_hp

func _init(blueprint: Resource = null) -> void:
    super()
    name = "CombatComponent"
    
    if not blueprint:
        blueprint = DEFAULT_BLUEPRINT
    
    if blueprint:
        if not blueprint is CombatComponentBlueprint:
            push_error("Invalid blueprint type provided to CombatComponent")
            return
            
        max_hp = blueprint.max_hp
        defense = blueprint.defense
        power = blueprint.power
        hp = blueprint.max_hp

func is_dead() -> bool:
    return hp <= 0

func heal(amount: int) -> void:
    if is_dead():
        return
        
    var old_hp: int = hp
    hp = mini(hp + amount, max_hp)
    var amount_recovered: int = hp - old_hp
    
    if amount_recovered > 0:
        SignalBus.message_sent.emit(
            "%s recovers %d HP!" % [get_parent().entity_name, amount_recovered],
            Color.GREEN
        )

func take_damage(amount: int) -> void:
    hp -= amount
    SignalBus.message_sent.emit(
        "%s takes %d damage!" % [get_parent().entity_name, amount],
        Color.RED
    )
    
    if is_dead():
        die()

func die() -> void:
    var parent = get_parent() as Entity
    if parent.inventory:
        for item: Entity in parent.inventory.items():
            parent.inventory.drop(item)
    
    GameMap.erase(parent)
    
    if parent.light:
        parent.light.queue_free()
    
    died.emit()
    parent.queue_free()

func get_defense() -> int:
    return defense + get_parent().equipment.total_defense_bonus

func get_power() -> int:
    return power + get_parent().equipment.total_power_bonus

func get_power_bonus() -> int:
    if get_parent().equipment:
        return get_parent().equipment.power_bonus
    return 0

func roll(difficulty: int) -> bool:
    return randi() % 6 + 1 >= difficulty
