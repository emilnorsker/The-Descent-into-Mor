class_name MeleeAction
extends Action

var dx: int
var dy: int

func _init(entity: Entity, dx: int, dy: int) -> void:
	super(entity)
	self.dx = dx
	self.dy = dy

func perform() -> bool:
	var destination := entity.grid_position + Vector2i(dx, dy)
	var target: Entity = GameMap.get_blocking_entity_at_location(destination)
	
	if not target or not target.combat_component:
		return false
	
	var damage: int = entity.combat_component.power()
	if entity.equipment_component:
		damage += entity.equipment_component.power_bonus()
	
	var defense: int = target.combat_component.defense()
	if target.equipment_component:
		defense += target.equipment_component.defense_bonus()
	
	var damage_dealt: int = damage - defense
	
	if damage_dealt > 0:
		SignalBus.message_sent.emit(
			"%s attacks %s for %d hit points." % [entity.get_entity_name(), target.get_entity_name(), damage_dealt],
			Color.WHITE
		)
		target.combat_component.take_damage(damage_dealt)
	else:
		SignalBus.message_sent.emit(
			"%s attacks %s but does no damage." % [entity.get_entity_name(), target.get_entity_name()],
			Color.WHITE
		)
	
	return true 