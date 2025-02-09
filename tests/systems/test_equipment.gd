extends GutTest

const MapScene = preload("res://src/Map/Map.tscn")
const Level = preload("res://src/Map/level.gd")
const Constants = preload("res://src/constants.gd")
const BodyComponent = preload("res://src/Components/body_component.gd")
const ItemAction = preload("res://src/Actions/item_action.gd")
const EquipAction = preload("res://src/Actions/equip_action.gd")
const MeleeAction = preload("res://src/Actions/melee_action.gd")
const Entity = preload("res://src/entity.gd")

var BodyPart = Constants.BodyPart

var entity: Entity
var equipment: EquipmentComponent
var body: BodyComponent

func before_each() -> void:
	var map_scene = MapScene.instantiate()
	add_child_autofree(map_scene)
	
	# Create test entity with body
	entity = Entity.new()
	entity.add_component("BodyComponent", {
		"type": "humanoid",
		"parts": {
			BodyPart.HEAD: {"slots": ["helm", "coif"]},
			BodyPart.NECK: {"slots": ["gorget", "coif"]},
			BodyPart.CHEST: {"slots": ["cuirass", "mail", "padding"]},
			BodyPart.ABDOMEN: {"slots": ["fauld", "mail", "padding"]},
			BodyPart.LEFT_ARM: {"slots": ["pauldron", "mail", "padding"]},
			BodyPart.RIGHT_ARM: {"slots": ["pauldron", "mail", "padding"]},
			BodyPart.LEFT_LEG: {"slots": ["greave", "mail", "padding"]},
			BodyPart.RIGHT_LEG: {"slots": ["greave", "mail", "padding"]}
		}
	})
	entity.add_component("EquipmentComponent")
	entity.add_component("InventoryComponent")
	GameMap.register_entity(entity, Vector2i(1, 1))
	
	body = entity.get_component("BodyComponent")
	equipment = entity.get_component("EquipmentComponent")
	add_child_autofree(equipment)

func after_each() -> void:
	GameMap.clear()
	equipment = null
	body = null

# Body Part Equipment Tests
func test_body_part_equipment() -> void:
	var chest_armor = create_armor_entity([
		["ArmorComponent", {
			"slot": "cuirass",
			"protection": 3
		}],
		["MaterialComponent", {"type": "metal"}],
		["WeightComponent", {"weight": 5}]
	])
	
	equipment.equip_to_slot(chest_armor, "cuirass")
	
	assert_true(body.has_equipment_in_slot(BodyPart.CHEST, "cuirass"), "Chest should have cuirass equipped")
	assert_eq(body.get_protection_for_part(BodyPart.CHEST), 3, "Chest should have plate protection")

func test_layered_body_protection() -> void:
	var padding = create_armor_entity([
		["ArmorComponent", {
			"slot": "padding",
			"protection": 1
		}],
		["MaterialComponent", {"type": "cloth"}]
	])
	
	var mail = create_armor_entity([
		["ArmorComponent", {
			"slot": "mail",
			"protection": 2
		}],
		["MaterialComponent", {"type": "metal"}]
	])
	
	var plate = create_armor_entity([
		["ArmorComponent", {
			"slot": "cuirass",
			"protection": 3
		}],
		["MaterialComponent", {"type": "metal"}]
	])
	
	equipment.equip_to_slot(padding, "padding")
	equipment.equip_to_slot(mail, "mail")
	equipment.equip_to_slot(plate, "cuirass")
	
	var chest_protection = body.get_total_protection_for_part(BodyPart.CHEST)
	assert_eq(chest_protection, 6, "Chest should have combined protection from all layers")

func test_partial_coverage() -> void:
	var mail_shirt = create_armor_entity([
		["ArmorComponent", {
			"slot": "mail",
			"protection": 2
		}],
		["MaterialComponent", {"type": "metal"}],
		["CoverageComponent", {
			"parts": [BodyPart.CHEST, BodyPart.ABDOMEN, BodyPart.LEFT_ARM, BodyPart.RIGHT_ARM]
		}]
	])
	
	equipment.equip_to_slot(mail_shirt, "mail")
	
	assert_true(body.has_protection(BodyPart.CHEST), "Chest should be protected")
	assert_true(body.has_protection(BodyPart.LEFT_ARM), "Left arm should be protected")
	assert_false(body.has_protection(BodyPart.LEFT_LEG), "Left leg should not be protected")

func test_different_body_types() -> void:
	# Create quadruped entity
	var quadruped = Entity.new()
	quadruped.add_component("BodyComponent", {
		"type": "quadruped",
		"parts": {
			BodyPart.HEAD: {"slots": ["helm"]},
			BodyPart.NECK: {"slots": ["collar"]},
			BodyPart.CHEST: {"slots": ["barding"]},
			BodyPart.FRONT_LEFT_LEG: {"slots": ["leg_guard"]},
			BodyPart.FRONT_RIGHT_LEG: {"slots": ["leg_guard"]},
			BodyPart.BACK_LEFT_LEG: {"slots": ["leg_guard"]},
			BodyPart.BACK_RIGHT_LEG: {"slots": ["leg_guard"]}
		}
	})
	
	var barding = create_armor_entity([
		["ArmorComponent", {
			"slot": "barding",
			"protection": 3
		}],
		["MaterialComponent", {"type": "metal"}]
	])
	
	var quad_equipment = quadruped.get_component("EquipmentComponent")
	quad_equipment.equip_to_slot(barding, "barding")
	
	var quad_body = quadruped.get_component("BodyComponent")
	assert_true(quad_body.has_equipment_in_slot(BodyPart.CHEST, "barding"), "Quadruped should have barding equipped")
	assert_false(quad_body.has_slot(BodyPart.LEFT_ARM), "Quadruped should not have arm slots")

func test_equipment_wound_interaction() -> void:
	var plate = create_armor_entity([
		["ArmorComponent", {
			"slot": "cuirass",
			"protection": 3
		}],
		["MaterialComponent", {"type": "metal"}],
		["ResistanceComponent", {
			"slash": 3,
			"pierce": 1,
			"blunt": -1
		}]
	])
	
	equipment.equip_to_slot(plate, "cuirass")
	
	# Test wound protection
	var protection = body.get_wound_protection(BodyPart.CHEST, "slash")
	assert_eq(protection, 3, "Chest should have high slash protection")
	
	# Test damage to armor
	equipment.damage_equipment_in_slot("cuirass")
	protection = body.get_wound_protection(BodyPart.CHEST, "slash")
	assert_lt(protection, 3, "Damaged armor should provide less protection")

# Utility Functions
func create_armor_entity(components: Array) -> Entity:
	var armor = Entity.new()
	for component in components:
		armor.add_component(component[0], component[1])
	return armor

func test_component_misuse() -> void:
	# Test trying to eat armor
	var metal_plate = create_armor_entity([
		["ArmorComponent", {
			"slot": "cuirass",
			"protection": 3
		}],
		["MaterialComponent", {"type": "metal"}]
	])
	
	var item_action = ItemAction.new(entity, metal_plate)
	var result = item_action.perform()
	
	assert_false(result, "Should not be able to consume armor")
	assert_true(body.has_wound(BodyPart.HEAD), "Should get head wound from biting metal")
	assert_eq(body.get_wound_type(BodyPart.HEAD, 0), Constants.WoundType.LIGHT, 
			"Should be light wound from biting metal")
	
	# Test trying to equip consumable
	var potion = Entity.new()
	potion.add_component("ConsumableComponent")
	
	var equip_action = EquipAction.new(entity, potion)
	result = equip_action.perform()
	
	assert_false(result, "Should not be able to equip consumable")
	assert_true(body.has_wound(BodyPart.RIGHT_ARM), "Should get arm wound from trying to wear potion")
	
	# Test improvised weapon damage
	var bandage = Entity.new()
	bandage.add_component("ConsumableComponent", {"healing": 5})
	bandage.add_component("WeightComponent", {"weight": 0.1})
	bandage.add_component("DamageTypeComponent", {
		"slash": 0,  # Can't cut with cloth
		"pierce": 0, # Can't stab with cloth
		"blunt": 0   # Too light for blunt damage
	})
	
	var attack_action = MeleeAction.new(entity, entity, BodyPart.RIGHT_ARM, bandage)
	result = attack_action.perform()
	
	assert_true(result, "Should be able to attack with any item")
	# Should do minimal damage due to zero damage stats
	var target_wounds = entity.get_component("BodyComponent").get_wounds_of_type(Constants.WoundType.LIGHT)
	assert_eq(target_wounds.size(), 0, "Should do no damage with cloth item")
	
	# Test metal armor as weapon
	var armor_plate = create_armor_entity([
		["WeightComponent", {"weight": 5.0}],
		["MaterialComponent", {"type": "metal"}],
		["DamageTypeComponent", {
			"slash": 1,  # Sharp edges
			"pierce": 1, # Points and corners
			"blunt": 3  # Heavy metal = good blunt
		}]
	])
	
	attack_action = MeleeAction.new(entity, entity, BodyPart.RIGHT_ARM, armor_plate)
	result = attack_action.perform()
	
	assert_true(result, "Should be able to attack with armor")
	# Should do significant blunt damage
	target_wounds = entity.get_component("BodyComponent").get_wounds_of_type(Constants.WoundType.MODERATE)
	assert_gt(target_wounds.size(), 0, "Should do damage with heavy metal item") 