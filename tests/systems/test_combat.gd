extends GutTest

var attacker: Entity  # We'll use this instead of 'player' to be more generic
var target: Entity
var bystander: Entity  # For testing AOE effects

func before_each() -> void:
	var test_level = load("res://tests/fixtures/test_level.tres")
	GameMap.load_level(test_level)
	
	# We'll create entities in a specific formation for testing different attack patterns
	attacker = Entity.new(preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres"), Vector2i(2, 2))
	attacker.entity_name = "Attacker"
	target = Entity.new(preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres"), Vector2i(3, 2))
	target.entity_name = "Target"
	bystander = Entity.new(preload("res://tests/fixtures/blueprints/actors/test_humanoid.tres"), Vector2i(4, 2))
	bystander.entity_name = "Bystander"
	GameMap.register_entity(attacker, attacker.grid_position)
	GameMap.register_entity(target, target.grid_position)
	GameMap.register_entity(bystander, bystander.grid_position)

func after_each() -> void:
	attacker.queue_free()
	target.queue_free()
	bystander.queue_free()
	GameMap.clear()

# Test Different Attack Types
func test_melee_attack() -> void:
	var melee_action = MeleeAction.new(attacker, target, BodyComponent.BodyPart.CHEST)

	var consciousness = target.body.consciousness
	attacker.next_roll = 10
	target.next_roll = 0
	var result = melee_action.perform()
	target.next_roll = -1
	
	assert_true(result, "Melee action should succeed")
	assert_lt(target.body.consciousness, consciousness, "Target should lose consciousness on succesfull attack")

func test_throw_attack() -> void:
	var weapon = Entity.new(preload("res://tests/fixtures/blueprints/items/test_weapon.tres"), Vector2i(0, 0))
	attacker.inventory.add_item(weapon)
	target.next_roll = 0
	
	var throw_action = ThrowAction.new(attacker, target, weapon)
	
	var consciousness = target.body.consciousness
	var result = throw_action.perform()
	target.next_roll = -1
	assert_true(result, "Throw action should succeed")
	assert_lt(target.body.consciousness, consciousness, "Target should lose consciousness on succesfull attack")

# # Test Combat Stats
# func test_defense_calculation() -> void:
# 	var armor = Entity.new(preload("res://tests/fixtures/blueprints/items/test_armor.tres"), Vector2i(0, 0))
# 	target.inventory.add_item(armor)
# 	target.equipment.equip(armor)
	
# 	var melee_action = MeleeAction.new(attacker, target,  BodyComponent.BodyPart.CHEST)
# 	attacker.test_mode = true
# 	target.next_roll = 0
# 	melee_action.perform()
# 	target.next_roll = -1
	
# 	var consciousness = target.body.consciousness
# 	assert_gt(consciousness, 80, "Armor should reduce damage taken")

# remove weapon from attacker
# test damage by calculating consciousness loss
# add weapon to attacker
# test damage by calculating consciousness loss
# assert that the second loss is greater than the first
func test_power_calculation() -> void:
	# First create and equip a weapon
	var con_start = target.body.consciousness

	var weapon = attacker.equipment.get_equipped_item(BodyComponent.BodyPart.RIGHT_EQUIPMENT)
	assert_null(weapon, "Weapon should not be equipped on attacker")
	
	target.next_roll = 0
	attacker.next_roll = 10
	var melee_action = MeleeAction.new(attacker, target,  BodyComponent.BodyPart.CHEST)
	melee_action.perform()
	var con_loss_1 = con_start - target.body.consciousness

	var new_weapon = Entity.new(preload("res://tests/fixtures/blueprints/items/test_weapon.tres"), Vector2i(0, 0))
	attacker.equipment.equip(new_weapon)
	assert_not_null(attacker.equipment.get_equipped_item(BodyComponent.BodyPart.RIGHT_EQUIPMENT), "Weapon should be equipped on attacker")

	target.next_roll = 0
	attacker.next_roll = 10
	var melee_action_with_weapon = MeleeAction.new(attacker, target,  BodyComponent.BodyPart.CHEST)
	melee_action_with_weapon.perform()
	var con_loss_2 = con_start - target.body.consciousness

	assert_gt(con_loss_2, con_loss_1, "Weapon should increase damage dealt")
# Test Death
func test_death() -> void:
	target.body.consciousness = 1  # Set target to almost dead
	# watch for the death siganl
	watch_signals(target.body)
	
	# test that consciousness can go under 0 without dying
	target.next_roll = 100000
	attacker.next_roll = 10 # ensure hit
	var melee_action = MeleeAction.new(attacker, target,  BodyComponent.BodyPart.CHEST)
	melee_action.perform()
	assert_signal_not_emitted(target.body, "died")

	# Now test if it dies
	attacker.equipment.equip(Entity.new(preload("res://tests/fixtures/blueprints/items/test_weapon.tres"), Vector2i(0, 0)))
	target.next_roll = -1000
	attacker.next_roll = 1000
	var melee_action_with_weapon = MeleeAction.new(attacker, target,  BodyComponent.BodyPart.CHEST)
	melee_action_with_weapon.perform()


	assert_signal_emitted(target.body, "died")
	assert_eq(GameMap.get_entities_of_type_at(target.grid_position, Entity.EntityType.CORPSE).size(), 1, "Dead target should be removed from map") 
