class_name ItemAction
extends Action

const EquipAction = preload("res://src/Actions/equip_action.gd")

var item: Entity
var target_position: Vector2i

func _init(performer: Entity, item: Entity, target_position = null) -> void:
	var target = GameMap.get_actor_at_location(target_position) if target_position else performer
	super._init(performer, target)
	self.item = item
	if not target_position is Vector2i:
		target_position = performer.grid_position
	self.target_position = target_position

func get_target_actor() -> Entity:
	return GameMap.get_actor_at_location(target_position)

func perform() -> bool:
	if item == null:
		return false
		
	# Try to use item based on its components
	if item.equippable_component:
		return EquipAction.new(performer, item).perform()
	elif item.consumable_component:
		return item.consumable_component.activate(self)
	else:
		# Trying to use an invalid item causes self-damage
		var body = performer.get_component("BodyComponent")
		if body and item.has_component("MaterialComponent"):
			var material = item.get_component("MaterialComponent")
			if material.type == "metal":
				# Trying to eat metal causes a light head wound
				body.apply_wound(Constants.BodyPart.HEAD, Constants.WoundType.LIGHT)
		return false
