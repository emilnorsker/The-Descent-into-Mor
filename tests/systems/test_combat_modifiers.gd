extends GutTest

const MapScene = preload("res://src/Map/Map.tscn")
const Level = preload("res://src/Map/level.gd")
const Constants = preload("res://src/constants.gd")
const CombatModifierComponent = preload("res://src/Components/combat_modifier_component.gd")
const MeleeAction = preload("res://src/Actions/melee_action.gd")

var entity: Entity
var modifiers: CombatModifierComponent

func before_each() -> void:
	var map_scene = MapScene.instantiate()
	add_child_autofree(map_scene)
	
	# Create test entity
	var blueprint = preload("res://assets/blueprints/actors/player.tres")
	entity = Entity.from_blueprint(blueprint, Vector2i(1, 1))
	GameMap.register_entity(entity, entity.grid_position)
	
	modifiers = CombatModifierComponent.new()
	add_child_autofree(modifiers)

func after_each() -> void:
	GameMap.clear()
	modifiers = null

# Environmental State Tests
func test_oiled_state() -> void:
	# Test floor tile effects
	var floor_tile = Entity.from_blueprint(preload("res://assets/blueprints/terrain/floor.tres"), Vector2i(1, 1))
	modifiers.apply_state("oiled", floor_tile)
	
	# Test creature movement on oiled floor
	var creature = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
	var balance_check = creature.roll_balance_check()
	if balance_check < 4:  # Failed check
		assert_true(creature.has_status(Constants.StatusEffect.PRONE), "Should fall prone on oiled floor")
	
	# Test entity being oiled
	var weapon = Entity.from_blueprint(preload("res://assets/blueprints/items/sword.tres"), Vector2i(1, 1))
	modifiers.apply_state("oiled", weapon)
	assert_true(weapon.is_slippery(), "Oiled weapon should be slippery")
	assert_true(weapon.is_flammable(), "Oiled weapon should be flammable")
	
	# Test combat effects
	var attacker = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
	attacker.equipment_component.equip_weapon(weapon)
	var grip_check = attacker.roll_grip_check()
	if grip_check < 4:  # Failed check
		assert_true(weapon.is_dropped(), "Should drop oiled weapon on failed check")

func test_ablaze_state() -> void:
	# Test entity on fire
	var creature = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
	modifiers.apply_state("ablaze", creature)
	
	# Should cause wounds to entities with health
	if creature.has_component("HealthComponent"):
		assert_true(creature.body_component.has_wound(Constants.BodyPart.CHEST), "Ablaze should cause wounds")
		assert_eq(creature.body_component.get_wound_type(Constants.BodyPart.CHEST, 0), Constants.WoundType.MODERATE, 
				"Fire should cause moderate wounds")
	
	# Test smoke effects
	var nearby_tile = Vector2i(2, 1)
	assert_true(GameMap.is_line_of_sight_blocked(Vector2i(1, 1), Vector2i(3, 1)), 
			"Smoke should block line of sight")
	
	# Test fire spreading
	var flammable_object = Entity.from_blueprint(preload("res://assets/blueprints/items/wooden_chair.tres"), Vector2i(2, 1))
	GameMap.register_entity(flammable_object, flammable_object.grid_position)
	
	GameMap.process_turn()  # Let fire spread
	assert_true(flammable_object.has_state("ablaze"), "Fire should spread to nearby flammable objects")
	
	# Test equipment damage from fire
	var sword = Entity.from_blueprint(preload("res://assets/blueprints/items/sword.tres"), Vector2i(1, 1))
	creature.equipment_component.equip_weapon(sword)
	
	watch_signals(creature.equipment_component)
	GameMap.process_turn()  # Process fire damage
	assert_signal_emitted(creature.equipment_component, "equipment_damaged", "Fire should damage equipment")

func test_mud_covered() -> void:
	# Test mud on floor
	var floor_tile = Entity.from_blueprint(preload("res://assets/blueprints/terrain/floor.tres"), Vector2i(1, 1))
	modifiers.apply_state("mud_covered", floor_tile)
	
	# Test movement impairment
	var creature = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
	var initial_movement = creature.get_movement_points()
	creature.move_through(floor_tile.grid_position)
	assert_lt(creature.get_movement_points(), initial_movement, "Mud should cost extra movement")
	
	# Test fire protection
	modifiers.apply_state("mud_covered", creature)
	modifiers.apply_state("ablaze", creature)
	assert_false(creature.has_state("ablaze"), "Mud should prevent catching fire")
	
	# Test equipment effects
	var armor = Entity.from_blueprint(preload("res://assets/blueprints/items/plate_armor.tres"), Vector2i(1, 1))
	creature.equipment_component.equip_armor(armor)
	var initial_protection = armor.get_protection_value()
	modifiers.apply_state("mud_covered", armor)
	assert_lt(armor.get_protection_value(), initial_protection, "Mud should reduce armor effectiveness")
	
	# Test camouflage
	assert_true(creature.is_harder_to_detect(), "Mud should provide camouflage")
	var detection_check = Entity.new().roll_detection_check(creature)
	assert_lt(detection_check, 4, "Should be harder to detect when mud covered")

# Combat State Tests
func test_bleeding_state() -> void:
	modifiers.apply_state("bleeding")
	
	assert_true(modifiers.leaves_trail(), "Bleeding should leave trail")
	assert_true(modifiers.causes_weakness(), "Bleeding should cause weakness")
	assert_true(modifiers.attracts_predators(), "Bleeding should attract predators")

func test_winded_state() -> void:
	modifiers.apply_state("winded")
	
	assert_true(modifiers.needs_recovery(), "Winded should need recovery")
	assert_true(modifiers.affects_reactions(), "Winded should affect reactions")
	assert_true(modifiers.vision_affected(), "Winded should affect vision")

func test_dazed_state() -> void:
	var creature = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
	
	# Test dazed right arm
	var sword = Entity.from_blueprint(preload("res://assets/blueprints/items/sword.tres"), Vector2i(1, 1))
	creature.equipment_component.equip_weapon(sword, Constants.BodyPart.RIGHT_ARM)
	modifiers.apply_state("dazed", creature, Constants.BodyPart.RIGHT_ARM)
	
	# Should only affect right arm
	var grip_check = creature.roll_grip_check(Constants.BodyPart.RIGHT_ARM)
	if grip_check < 4:  # Failed check
		assert_true(sword.is_dropped(), "Should drop weapon from dazed arm")
	
	# Test dazed left arm with shield
	var shield = Entity.from_blueprint(preload("res://assets/blueprints/items/shield.tres"), Vector2i(1, 1))
	creature.equipment_component.equip_weapon(shield, Constants.BodyPart.LEFT_ARM)
	modifiers.apply_state("dazed", creature, Constants.BodyPart.LEFT_ARM)
	
	# Right arm weapon should be unaffected
	assert_false(sword.is_dropped(), "Weapon in undazed arm should not be dropped")
	
	# Test vision effects when head is dazed
	modifiers.apply_state("dazed", creature, Constants.BodyPart.HEAD)
	assert_true(creature.vision_is_blurred(), "Dazed head should blur vision")
	assert_lt(creature.get_vision_range(), creature.get_base_vision_range(), "Dazed head should reduce vision range")
	
	# Test balance effects when legs are dazed
	modifiers.apply_state("dazed", creature, Constants.BodyPart.LEFT_LEG)
	modifiers.apply_state("dazed", creature, Constants.BodyPart.RIGHT_LEG)
	assert_true(creature.has_status(Constants.StatusEffect.PRONE_TO_FALLING), "Dazed legs should risk falling")

# Positional Advantage Tests
func test_high_ground() -> void:
	# Setup terrain with elevation
	var high_ground = Entity.from_blueprint(preload("res://assets/blueprints/terrain/hill.tres"), Vector2i(1, 1))
	var low_ground = Entity.from_blueprint(preload("res://assets/blueprints/terrain/floor.tres"), Vector2i(2, 1))
	
	# Test ranged weapon from high ground
	var orc = Entity.from_blueprint(preload("res://assets/blueprints/actors/monsters/orc.tres"), Vector2i(1, 1))
	var bow = Entity.from_blueprint(preload("res://assets/blueprints/items/bow.tres"), Vector2i(1, 1))
	orc.equipment_component.equip_weapon(bow)
	
	var base_range = bow.get_range()
	var high_ground_range = orc.get_attack_range()
	assert_eq(high_ground_range, ceil(base_range * 1.5), "High ground should multiply range by 1.5")
	
	# Test defense bonus against melee
	var attacker = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(2, 1))
	var attack = MeleeAction.new(attacker, orc, Constants.BodyPart.CHEST)
	assert_lt(attack.get_hit_chance(), 0.5, "Should be harder to hit target on high ground")
	
	# Test downward melee attack advantage
	var sword = Entity.from_blueprint(preload("res://assets/blueprints/items/sword.tres"), Vector2i(1, 1))
	orc.equipment_component.equip_weapon(sword)
	var downward_strike = MeleeAction.new(orc, attacker, Constants.BodyPart.CHEST)
	assert_gt(downward_strike.get_damage_bonus(), 0, "Should get damage bonus attacking downward")

func test_flanking() -> void:
	modifiers.apply_position("flanking")
	
	assert_true(modifiers.hard_to_defend(), "Flanking should be hard to defend against")
	assert_true(modifiers.better_angles(), "Flanking should give better angles")
	assert_true(modifiers.exposed_position(), "Flanking should be exposed")

# Combination Tests
func test_mud_and_high_ground() -> void:
	modifiers.apply_state("mud_covered")
	modifiers.apply_position("high_ground")
	
	assert_true(modifiers.is_treacherous(), "Mud on high ground should be treacherous")
	assert_true(modifiers.can_cause_slides(), "Should enable sliding")
	assert_true(modifiers.provides_defense(), "Should still provide defense")

func test_ablaze_and_cornered() -> void:
	modifiers.apply_state("ablaze")
	modifiers.apply_position("pinned")
	
	assert_true(modifiers.causes_panic(), "Should cause panic")

# Environmental Factor Tests
func test_rain_effects() -> void:
	modifiers.apply_environment("rain")
	
	assert_true(modifiers.ground_slick(), "Rain should make ground slick")
	assert_true(modifiers.vision_reduced(), "Rain should reduce vision")
	assert_true(modifiers.metal_slippery(), "Rain should make metal slippery")

func test_darkness_effects() -> void:
	modifiers.apply_environment("darkness")
	
	assert_true(modifiers.movement_hidden(), "Darkness should hide the entitiy unless close")

# Edge Cases
func test_conflicting_states() -> void:
	modifiers.apply_state("ablaze")
	modifiers.apply_state("mud_covered")
	
	# Mud should reduce ablaze effectiveness
	assert_lt(modifiers.get_ablaze_intensity(), 1.0, "Mud should reduce ablaze intensity")

func test_environmental_stacking() -> void:
	modifiers.apply_environment("rain")
	modifiers.apply_environment("darkness")
	
	assert_true(modifiers.has_environment("rain"), "Should have rain effects")
	assert_true(modifiers.has_environment("darkness"), "Should have darkness effects")
	assert_true(modifiers.vision_severely_reduced(), "Effects should stack")

# Behavioral Interaction Tests
func test_panic_behavior() -> void:
	# Test panic state effects
	var creature = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
	modifiers.apply_state("ablaze", creature)
	
	# Verify panic effects on movement and combat
	assert_true(creature.has_status(Constants.StatusEffect.PANICKED), "Should be panicked when ablaze")
	assert_lt(creature.get_movement_points(), creature.get_base_movement_points(), "Panic should affect movement")
	
	# Test weapon handling while panicked
	var sword = Entity.from_blueprint(preload("res://assets/blueprints/items/sword.tres"), Vector2i(1, 1))
	creature.equipment_component.equip_weapon(sword)
	
	GameMap.process_turn()  # Process panic effects
	assert_true(sword.is_dropped(), "Should drop weapon when panicked")

func test_combat_state_influence() -> void:
	var creature = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
	var target = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(2, 1))
	
	# Test normal combat states
	var base_attack = MeleeAction.new(creature, target, Constants.BodyPart.CHEST)
	var base_hit_chance = base_attack.get_hit_chance()
	
	# Apply impairing states
	modifiers.apply_state("winded", creature)
	modifiers.apply_state("dazed", creature, Constants.BodyPart.HEAD)
	
	# Test impaired combat effectiveness
	var impaired_attack = MeleeAction.new(creature, target, Constants.BodyPart.CHEST)
	assert_lt(impaired_attack.get_hit_chance(), base_hit_chance, "Impaired states should reduce hit chance")

func test_equipment_interaction() -> void:
	var creature = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
	
	# Test weapon with oiled state
	var sword = Entity.from_blueprint(preload("res://assets/blueprints/items/sword.tres"), Vector2i(1, 1))
	creature.equipment_component.equip_weapon(sword)
	modifiers.apply_state("oiled", sword)
	
	# Test grip checks with oiled weapon
	GameMap.process_turn()  # Process weapon state
	assert_true(sword.is_slippery(), "Oiled weapon should be slippery")
	
	# Test armor with mud state
	var armor = Entity.from_blueprint(preload("res://assets/blueprints/items/plate_armor.tres"), Vector2i(1, 1))
	creature.equipment_component.equip_armor(armor)
	var base_protection = armor.get_protection_value()
	
	modifiers.apply_state("mud_covered", armor)
	assert_lt(armor.get_protection_value(), base_protection, "Mud should reduce armor effectiveness")

func test_condition_combinations() -> void:
	var creature = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
	
	# Apply multiple states
	modifiers.apply_state("winded", creature)
	modifiers.apply_state("dazed", creature, Constants.BodyPart.HEAD)
	modifiers.apply_state("mud_covered", creature)
	
	# Test combined effects on combat
	var target = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(2, 1))
	var attack = MeleeAction.new(creature, target, Constants.BodyPart.CHEST)
	
	assert_true(creature.has_status(Constants.StatusEffect.WEAKENED), "Multiple conditions should cause weakness")
	assert_lt(attack.get_hit_chance(), 0.5, "Multiple conditions should severely impact combat")

func test_progressive_state_effects() -> void:
	var creature = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(1, 1))
	modifiers.apply_state("bleeding", creature)
	
	var initial_health = creature.health_component.get_health()
	
	for i in range(3):
		GameMap.process_turn()  # Let bleeding progress
		
	assert_lt(creature.health_component.get_health(), initial_health, "Bleeding should cause progressive damage")
	assert_true(creature.has_status(Constants.StatusEffect.WEAKENED), "Bleeding should cause weakness over time")

# Utility Functions
func create_enemy_nearby() -> Entity:
	var enemy = Entity.from_blueprint(
		preload("res://assets/blueprints/actors/monsters/orc.tres"),
		entity.grid_position + Vector2i(1, 0)
	)
	GameMap.register_entity(enemy, enemy.grid_position)
	return enemy 