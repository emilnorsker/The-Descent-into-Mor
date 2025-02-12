@tool
class_name CombatComponent extends Component

signal died

var _max_hp: int = 30
var _defense: int = 2
var _power: int = 5
var _hp: int = _max_hp

@export var max_hp: int:
    get:
        return _max_hp
    set(value):
        _max_hp = value
        _hp = mini(_hp, _max_hp)  # Ensure HP doesn't exceed new max

@export var defense: int:
    get:
        return _defense
    set(value):
        _defense = value

@export var power: int:
    get:
        return _power
    set(value):
        _power = value

@export var hp: int:
    get:
        return _hp
    set(value):
        _hp = mini(value, _max_hp)  # Ensure HP doesn't exceed max

func _init() -> void:
    super()
    name = "CombatComponent"

func setup_from_dict(data: Dictionary) -> Component:
    if data.has("health"):
        max_hp = data.health
        hp = data.health
    if data.has("damage"):
        power = data.damage
    return self

func setup_from_blueprint(blueprint: Resource) -> CombatComponent:
    if blueprint:
        max_hp = blueprint.max_hp
        defense = blueprint.defense
        power = blueprint.power
        hp = blueprint.max_hp

    return self

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
