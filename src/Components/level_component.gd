class_name ProgressionComponent
extends Component

var _level: int = 1
var _current_xp: int = 0
var _level_up_base: int = 200
var _level_up_factor: int = 150

func _init() -> void:
    super()

func setup_from_blueprint(blueprint: Resource) -> ProgressionComponent:
    if blueprint:
        _level = blueprint.current_level
        _current_xp = blueprint.current_xp
        _level_up_base = blueprint.level_up_base
        _level_up_factor = blueprint.level_up_factor

    return self

func get_xp_to_next_level() -> int:
    return _level_up_base + _level * _level_up_factor

func add_xp(xp: int) -> void:
    if xp == 0 or _level >= 20:
        return
        
    _current_xp += xp
    SignalBus.message_sent.emit("You gain %d experience points." % xp, Color.WHITE)
    
    if _current_xp > get_xp_to_next_level():
        _current_xp -= get_xp_to_next_level()
        _level += 1
        
        SignalBus.message_sent.emit(
            "You advance to level %d!" % _level, Color.YELLOW
        )
        
        var combat: CombatComponent = get_parent().combat
        var max_hp_increase: int = randi_range(1, 4)
        combat.max_hp += max_hp_increase
        combat.hp += max_hp_increase
        
        var power_increase: int = randi_range(1, 2)
        combat.power += power_increase
        
        var defense_increase: int = randi_range(0, 1)
        combat.defense += defense_increase

func get_level() -> int:
    return _level

func get_current_xp() -> int:
    return _current_xp

func get_level_up_base() -> int:
    return _level_up_base

func get_level_up_factor() -> int:
    return _level_up_factor
