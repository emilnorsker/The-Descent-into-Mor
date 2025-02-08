class_name CombatComponent
extends Component

signal died

func is_dead() -> bool:
	return data.hp <= 0

func heal(amount: int) -> void:
	if is_dead():
		return
		
	var old_hp: int = data.hp
	data.hp = mini(data.hp + amount, data.max_hp)
	var amount_recovered: int = data.hp - old_hp
	
	if amount_recovered > 0:
		SignalBus.message_sent.emit(
			"%s recovers %d HP!" % [entity.get_entity_name(), amount_recovered],
			Color.GREEN
		)

func take_damage(amount: int) -> void:
	data.hp -= amount
	SignalBus.message_sent.emit(
		"%s takes %d damage!" % [entity.get_entity_name(), amount],
		Color.RED
	)
	
	if is_dead():
		die()

func die() -> void:
	if entity.has_component("InventoryComponent"):
		var inventory: InventoryComponent = entity.inventory_component
		for item: Entity in inventory.items():
			inventory.drop(item)
	
	GameMap.erase(entity)
	
	if entity.has_component("LightComponent"):
		entity.light_component.queue_free()
	
	died.emit()
	entity.queue_free()

func max_hp() -> int:
	return data.max_hp

func current_hp() -> int:
	return data.hp

func defense() -> int:
	return data.defense + defense_bonus()

func power() -> int:
	return data.power + power_bonus()

func defense_bonus() -> int:
	if entity.equipment_component:
		return entity.equipment_component.defense_bonus()
	return 0

func power_bonus() -> int:
	if entity.equipment_component:
		return entity.equipment_component.power_bonus()
	return 0
