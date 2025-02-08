class_name MeleeAction
extends Action

var target: Entity

func _init(entity: Entity, target: Entity) -> void:
	super._init(entity)
	self.target = target

func perform() -> bool:
	var damage: int = entity.combat_component.power - target.combat_component.defense
	var attack_color = Color.WHITE
	var attack_desc = "%s attacks %s" % [entity.get_entity_name(), target.get_entity_name()]
	
	if damage > 0:
		attack_desc += " for %d hit points." % damage
		target.combat_component.hp -= damage
	else:
		damage = 0
		attack_desc += " but does no damage."
		
	SignalBus.message_sent.emit(attack_desc, attack_color)
	return true
