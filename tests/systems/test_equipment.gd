extends GutTest

const MapScene = preload("res://src/Map/Map.tscn")

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