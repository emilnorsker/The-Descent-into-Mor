class_name ProgressionComponent
extends Component

func get_xp_to_next_level() -> int:
	return data.level_up_base + data.level * data.level_up_factor

func add_xp(xp: int) -> void:
	if xp == 0 or data.level >= 20:
		return
		
	data.current_xp += xp
	SignalBus.message_sent.emit("You gain %d experience points." % xp, Color.WHITE)
	
	if data.current_xp > get_xp_to_next_level():
		data.current_xp -= get_xp_to_next_level()
		data.level += 1
		
		SignalBus.message_sent.emit(
			"You advance to level %d!" % data.level, Color.YELLOW
		)
		
		var combat: CombatComponent = entity.combat_component
		var max_hp_increase: int = randi_range(1, 4)
		combat.data.max_hp += max_hp_increase
		combat.data.hp += max_hp_increase
		
		var power_increase: int = randi_range(1, 2)
		combat.data.power += power_increase
		
		var defense_increase: int = randi_range(0, 1)
		combat.data.defense += defense_increase
