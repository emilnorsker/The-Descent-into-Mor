extends GutTest

var BodyPart = Constants.BodyPart

var entity: Entity
var equipment: EquipmentComponent
var body: BodyComponent

func before_each() -> void:
    var map_scene = MapScene.instantiate()
    add_child_autofree(map_scene)
    
    # Create test entity with body
    entity = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
    body = entity.body
    equipment = entity.equipment
   
    body = entity.body_component
    equipment = entity.components.equipment
    add_child_autofree(equipment)

func after_each() -> void:
    GameMap.clear()
    equipment = null
    body = null

# Body Part Equipment Tests
func test_body_part_equipment() -> void:
    var chest_armor = create_armor_entity([
        ["ArmorComponent", {
            "slot": Constants.BodyPart.CHEST,
            "protection": 3
        }],
        ["MaterialComponent", {"type": "metal"}],
        ["WeightComponent", {"weight": 5}]
    ])
    
    body.equip_to_slot(chest_armor)
    
    assert_true(body.has_equipment_in_slot(BodyPart.CHEST, Constants.BodyPart.CHEST), "Chest should have cuirass equipped")
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
            "slot": Constants.BodyPart.CHEST,
            "protection": 3
        }],
        ["MaterialComponent", {"type": "metal"}]
    ])
    
    body.equip_to_slot(padding, "padding")
    body.equip_to_slot(mail, "mail")
    body.equip_to_slot(plate, Constants.BodyPart.CHEST)
    
    var chest_protection = body.get_total_protection_for_part(BodyPart.CHEST)
    assert_eq(chest_protection, 6, "Chest should have combined protection from all layers")
    
    body.unequip_from_slot(padding)
    chest_protection = body.get_total_protection_for_part(BodyPart.CHEST)
    assert_eq(chest_protection, 3, "Chest should have protection from only plate")

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
    
    body.equip_to_slot(mail_shirt)
    
    assert_true(body.has_protection(BodyPart.CHEST), "Chest should be protected")
    assert_true(body.has_protection(BodyPart.LEFT_ARM), "Left arm should be protected")
    assert_false(body.has_protection(BodyPart.LEFT_LEG), "Left leg should not be protected")

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
    
#     assert_true(wolf.body.has_equipment_in_slot(BodyPart.CHEST, "barding"), "Quadruped should have barding equipped")
#     assert_false(wolf.body.has_slot(BodyPart.LEFT_ARM), "Quadruped should not have arm slots")

func test_equipment_wound_interaction() -> void:
    var plate = create_armor_entity([
        ["ArmorComponent", {
            "slot": Constants.BodyPart.CHEST,
            "protection": 3
        }],
        ["MaterialComponent", {"type": "metal"}],
        ["ResistanceComponent", {
            "slash": 3,
            "pierce": 1,
            "blunt": -1
        }]
    ])
    
    body.equip_to_slot(plate)
    
    # Test wound protection
    var protection = body.get_wound_protection(BodyPart.CHEST, "slash")
    assert_eq(protection, 3, "Chest should have high slash protection")
    
    # Test damage to armor
    assert_eq(entity.components.body.consciousness, 0, "Should start with consciousness 0")
    entity.components.body.apply_wound(Constants.WoundType.LIGHT, BodyPart.CHEST)
    assert_eq(entity.components.body.consciousness, 0, "Should still be unconscious after light wound")

# Utility Functions
func create_armor_entity(components: Array) -> Entity:
    # Create a temporary blueprint
    var blueprint = EntityBlueprint.new()
    blueprint.entity_name = "Test Armor"
    blueprint.type = Entity.EntityType.ITEM
    blueprint.blocks_movement = false
    
    # Create equipment blueprint (always needed for armor)
    var equipment_blueprint = EquipmentComponentBlueprint.new()
    blueprint.equipment_blueprint = equipment_blueprint
    
    # Convert the test components to our blueprint system
    for component_data in components:
        var type = component_data[0]
        var data = component_data[1]
        
        match type:
            "ArmorComponent":
                # Add to equipment blueprint
                equipment_blueprint.slots[data.get("slot", Constants.BodyPart.CHEST)] = true
                equipment_blueprint.defense_bonus = data.get("protection", 0)
                
            "MaterialComponent":
                var material_blueprint = MaterialComponentBlueprint.new()
                material_blueprint.material_type = data.get("type", "metal")
                material_blueprint.is_flammable = data.get("flammable", false)
                blueprint.material_blueprint = material_blueprint
                
            "WeightComponent":
                var weight_blueprint = WeightComponentBlueprint.new()
                weight_blueprint.weight = data.get("weight", 1.0)
                blueprint.weight_blueprint = weight_blueprint
                
            "ResistanceComponent":
                # Add resistance data to material blueprint if it exists
                if blueprint.material_blueprint:
                    blueprint.material_blueprint.slash_resistance = data.get("slash", 0)
                    blueprint.material_blueprint.pierce_resistance = data.get("pierce", 0)
                    blueprint.material_blueprint.blunt_resistance = data.get("blunt", 0)
    
    # Create entity from blueprint
    return Entity.new().setup_from_blueprint(blueprint, Vector2i.ZERO) 

func test_component_misuse() -> void:
    # Test trying to eat armor
    var metal_plate = create_armor_entity([
        ["ArmorComponent", {
            "slot": Constants.BodyPart.CHEST,
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
    var target_wounds = entity.body.get_wounds_of_type(Constants.WoundType.LIGHT)
    assert_eq(target_wounds.size(), 0, "Should do no damage with cloth item")
    
    # Test metal armor as weapon
    var armor_plate = create_armor_entity([
        ["ArmorComponent", {
            "slot": Constants.BodyPart.CHEST,
            "protection": 3
        }],
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
    target_wounds = entity.body.get_wounds_of_type(Constants.WoundType.MODERATE)
    assert_gt(target_wounds.size(), 0, "Should do damage with heavy metal item")

func test_quadruped_equipment() -> void:
    var quadruped = Entity.new().setup_from_blueprint(preload("res://assets/blueprints/actors/monsters/wolf.tres"), Vector2i(1, 1))
    var quad_equipment = quadruped.equipment
    var quad_body = quadruped.body
    
    # Test equipment slots
    assert_eq(quad_equipment.get_slots().size(), 4, "Quadruped should have 4 equipment slots")
    assert_true(quad_body.has_part(Constants.BodyPart.FRONT_LEFT_LEG), "Should have front left leg")

func test_wound_effects() -> void:
    var target_wounds = entity.body.get_wounds_of_type(Constants.WoundType.LIGHT)
    assert_eq(target_wounds.size(), 0, "Should start with no wounds")
    
    # Apply wound and check effects
    entity.body.apply_wound(Constants.BodyPart.HEAD, Constants.WoundType.MODERATE)
    target_wounds = entity.body.get_wounds_of_type(Constants.WoundType.MODERATE)
    assert_eq(target_wounds.size(), 1, "Should have one moderate wound") 