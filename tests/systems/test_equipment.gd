extends GutTest

const TestHumanoid = preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres")
const TestArmor = preload("res://tests/fixtures/blueprints/items/test_armor.tres")
const TestConsumable = preload("res://tests/fixtures/blueprints/items/test_consumable.tres")

var entity: Entity
var equipment: EquipmentComponent
var body: BodyComponent

func before_each() -> void:
    var test_level = load("res://tests/fixtures/test_level.tres")
    GameMap.load_level(test_level)
    
    # Create test entity using blueprint
    entity = Entity.new().setup_from_blueprint(TestHumanoid, Vector2i(1, 1))
    body = entity.body
    equipment = entity.equipment

func after_each() -> void:
    GameMap.clear()
    equipment = null
#     body = null

# # Body Part Equipment Tests
# func test_body_part_equipment() -> void:
#     var chest_armor = Entity.new().setup_from_blueprint(TestArmor, Vector2i.ZERO)
    
#     equipment.equip(chest_armor,  BodyComponent.BodyPart.CHEST)
    
#     assert_true(equipment.has_equipped_item(BodyComponent.BodyPart.CHEST), "Chest should have armor equipped")
#     assert_eq(body.get_protection_for_part(BodyComponent.BodyPart.CHEST), 3, "Chest should have plate protection")

# func test_layered_body_protection() -> void:
#     var padding = create_armor_entity([
#         ["ArmorComponent", {
#             "slot": "padding",
#             "protection": 1
#         }],
#         ["MaterialComponent", {"type": "cloth"}]
#     ])
    
#     var mail = create_armor_entity([
#         ["ArmorComponent", {
#             "slot": "mail",
#             "protection": 2
#         }],
#         ["MaterialComponent", {"type": "metal"}]
#     ])
    
#     var plate = create_armor_entity([
#         ["ArmorComponent", {
#             "slot":  BodyComponent.BodyPart.CHEST,
#             "protection": 3
#         }],
#         ["MaterialComponent", {"type": "metal"}]
#     ])
    
#     equipment.equip(padding, "padding")
#     equipment.equip(mail, "mail")
#     equipment.equip(plate,  BodyComponent.BodyPart.CHEST)
    
#     var chest_protection = body.get_total_protection_for_part(BodyComponent.BodyPart.CHEST)
#     assert_eq(chest_protection, 6, "Chest should have combined protection from all layers")
    
#     equipment.unequip(padding)
#     chest_protection = body.get_total_protection_for_part(BodyComponent.BodyPart.CHEST)
#     assert_eq(chest_protection, 5, "Chest should have protection from mail and plate")

# func test_partial_coverage() -> void:
#     var mail_shirt = create_armor_entity([
#         ["ArmorComponent", {
#             "slot": "mail",
#             "protection": 2
#         }],
#         ["MaterialComponent", {"type": "metal"}]
#     ])
    
#     equipment.equip(mail_shirt, "mail")
    
#     assert_true(body.has_protection(BodyComponent.BodyPart.CHEST), "Chest should be protected")
#     assert_true(body.has_protection(BodyComponent.BodyPart.LEFT_ARM), "Left arm should be protected")
#     assert_false(body.has_protection(BodyComponent.BodyPart.LEFT_LEG), "Left leg should not be protected")

# func test_different_body_types() -> void:
#     # Create quadruped entity
#     var wolf = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/actors/monsters/wolf.tres"), Vector2i(1, 1))
#     var wolf_equipment = wolf.equipment
    
#     var barding = create_armor_entity([
#         ["ArmorComponent", {
#             "slot": "barding",
#             "protection": 3
#         }],
#         ["MaterialComponent", {"type": "metal"}]
#     ])
    
#     wolf.body.equip_to_slot(barding)
    
#     assert_true(wolf.body.has_equipment_in_slot(BodyComponent.BodyPart.CHEST, "barding"), "Quadruped should have barding equipped")
#     assert_false(wolf.body.has_slot(BodyComponent.BodyPart.LEFT_ARM), "Quadruped should not have arm slots")

# func test_equipment_wound_interaction() -> void:
#     var plate = create_armor_entity([
#         ["ArmorComponent", {
#             "slot":  BodyComponent.BodyPart.CHEST,
#             "protection": 3
#         }],
#         ["MaterialComponent", {"type": "metal"}],
#         ["ResistanceComponent", {
#             "slash": 3,
#             "pierce": 1,
#             "blunt": -1
#         }]
#     ])
    
#     equipment.equip(plate,  BodyComponent.BodyPart.CHEST)
    
#     # Test wound protection
#     var protection = body.get_wound_protection(BodyComponent.BodyPart.CHEST, "slash")
#     assert_eq(protection, 3, "Chest should have high slash protection")
    
#     # Test damage to armor
#     assert_eq(body.consciousness, 0, "Should start with consciousness 0")
#     body.apply_wound(BodyComponent.WoundType.LIGHT,  BodyComponent.BodyPart.CHEST)
#     assert_eq(body.consciousness, 0, "Should still be unconscious after light wound")

func test_item_consumption_misuse() -> void:
    # Test trying to eat armor
    var metal_plate = Entity.new().setup_from_blueprint(TestArmor, Vector2i.ZERO)
    
    var consume_action = ConsumeAction.new(entity, metal_plate)
    var result = consume_action.perform()
    
    assert_false(result, "Should not be able to consume armor")

    assert_eq(body.get_wounds(BodyComponent.BodyPart.HEAD).size(), 1, 
        "Should get head wound from biting metal"
    )
    
    # Test trying to equip consumable
    var potion = Entity.new().setup_from_blueprint(TestConsumable, Vector2i.ZERO)
    
    var equip_action = EquipAction.new(entity, potion)
    result = equip_action.perform()
    
    assert_true(result, "Should be able to equip consumable")
    # Test improvised weapon damage
    var bandage = Entity.new().setup_from_blueprint(TestConsumable, Vector2i.ZERO)
    
    var attack_action = MeleeAction.new(entity, entity, BodyComponent.BodyPart.RIGHT_ARM)
    entity.next_roll = 10
    entity.equipment.equip(bandage, BodyComponent.BodyPart.RIGHT_EQUIPMENT)  # Use RIGHT_EQUIPMENT slot
    result = attack_action.perform()
    
    assert_true(result, "Should be able to attack with any item")
    # Should do minimal damage due to zero damage stats
    var target_wounds = body.get_wounds(BodyComponent.BodyPart.RIGHT_ARM)
    assert_eq(target_wounds.size(), 0, "Should do no damage with cloth item")
    
    # # Test metal armor as weapon
    # var armor_plate = create_armor_entity([
    #     ["ArmorComponent", {
    #         "slot":  BodyComponent.BodyPart.CHEST,
    #         "protection": 3
    #     }],
    #     ["MaterialComponent", {"type": "metal"}],
    #     ["DamageTypeComponent", {
    #         "slash": 1,  # Sharp edges
    #         "pierce": 1, # Points and corners
    #         "blunt": 3  # Heavy metal = good blunt
    #     }]
    # ])
    
    # attack_action = MeleeAction.new(entity, entity,  BodyComponent.BodyPart.RIGHT_ARM)
    # result = attack_action.perform()
    
    # assert_true(result, "Should be able to attack with armor")
    # # Should do significant blunt damage
    # target_wounds = body.get_wounds(BodyComponent.BodyPart.RIGHT_ARM)
    # assert_gt(target_wounds.size(), 0, "Should do damage with heavy metal item")

#func test_quadruped_equipment() -> void:
    # Commented out until we have a proper quadruped test blueprint
    # pending()
    # var quadruped = Entity.new().setup_from_blueprint(preload("res://tests/fixtures/blueprints/actors/test_quadruped.tres"), Vector2i(1, 1))
    # var quad_equipment = quadruped.equipment
    # var quad_body = quadruped.body
    # 
    # # Test equipment slots
    # assert_eq(quad_equipment.get_slots().size(), 4, "Quadruped should have 4 equipment slots")
    # assert_true(quad_body.has_part(BodyComponent.BodyPart.FRONT_LEFT_LEG), "Should have front left leg")

func test_wound_effects() -> void:
    var target_wounds = body.get_wounds(BodyComponent.BodyPart.RIGHT_ARM)
    assert_eq(target_wounds.size(), 0, "Should start with no wounds")
    
    # Apply wound and check effects
    body.apply_wound(BodyComponent.WoundType.MODERATE,  BodyComponent.BodyPart.RIGHT_ARM)
    target_wounds = body.get_wounds(BodyComponent.BodyPart.RIGHT_ARM)
    assert_eq(target_wounds.size(), 1, "Should have one moderate wound") 


# Utility Functions
func create_armor_entity(data: Array) -> Entity:
    # Create a temporary blueprint based on test armor
    var blueprint = TestArmor.duplicate()
    
    # Modify components based on data
    for component_data in data:
        var type = component_data[0]
        var values = component_data[1]
        
        match type:
            "ArmorComponent":
                blueprint.armor.slot = values.get("slot",  BodyComponent.BodyPart.CHEST)
                blueprint.armor.protection = values.get("protection", 3)
            "MaterialComponent":
                blueprint.material.material_type = values.get("type", "metal")
            "WeightComponent":
                blueprint.weight.weight = values.get("weight", 5.0)
            "ResistanceComponent":
                blueprint.resistance = {}
                for damage_type in values:
                    blueprint.resistance[damage_type] = values[damage_type]
            "DamageTypeComponent":
                blueprint.damage = {}
                for damage_type in values:
                    blueprint.damage[damage_type] = values[damage_type]
    
    return Entity.new().setup_from_blueprint(blueprint, Vector2i.ZERO) 
