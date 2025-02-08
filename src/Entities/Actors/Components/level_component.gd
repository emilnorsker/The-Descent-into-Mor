class_name ProgressionComponent
extends Component

var current_level: int
var current_xp: int
var level_up_base: int
var level_up_factor: int

func _init(definition: ProgressionComponentDefinition) -> void:
	current_level = definition.level
	current_xp = definition.current_xp
	level_up_base = definition.level_up_base
	level_up_factor = definition.level_up_factor

func get_xp_to_next_level() -> int:
	return level_up_base + current_level * level_up_factor

func add_xp(xp: int) -> void:
	if xp == 0 or current_level >= 20:
		return
		
	current_xp += xp
	SignalBus.message_sent.emit("You gain %d experience points." % xp, Color.WHITE)
	
	if current_xp > get_xp_to_next_level():
		current_xp -= get_xp_to_next_level()
		current_level += 1
		
		SignalBus.message_sent.emit(
			"You advance to level %d!" % current_level, Color.YELLOW
		)
		
		var combat: CombatComponent = entity.combat_component
		var max_hp_increase: int = randi_range(1, 4)
		combat.max_hp += max_hp_increase
		combat.hp += max_hp_increase
		
		var power_increase: int = randi_range(1, 2)
		combat.power += power_increase
		
		var defense_increase: int = randi_range(0, 1)
		combat.defense += defense_increase

func get_save_data() -> Dictionary:
	return {
		"current_level": current_level,
		"current_xp": current_xp,
		"level_up_base": level_up_base,
		"level_up_factor": level_up_factor
	}

func restore(save_data: Dictionary) -> void:
	current_level = save_data["current_level"]
	current_xp = save_data["current_xp"]
	level_up_base = save_data["level_up_base"]
	level_up_factor = save_data["level_up_factor"]
