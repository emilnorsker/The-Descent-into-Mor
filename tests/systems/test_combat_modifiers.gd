extends GutTest

const MapScene = preload("res://src/Map/Map.tscn")

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
	modifiers.apply_state("oiled")
	
	assert_true(modifiers.is_slippery(), "Oiled should make slippery")
	assert_true(modifiers.is_flammable(), "Oiled should be flammable")
	assert_true(modifiers.affects_grip(), "Oiled should affect grip")

func test_ablaze_state() -> void:
	modifiers.apply_state("ablaze")
	
	assert_true(modifiers.causes_pain(), "Ablaze should cause pain")
	assert_true(modifiers.creates_smoke(), "Ablaze should create smoke")
	assert_true(modifiers.can_spread(), "Ablaze should be able to spread")
	
	# Test equipment damage
	watch_signals(entity.equipment_component)
	assert_signal_emitted(entity.equipment_component, "equipment_damaged")

func test_mud_covered() -> void:
	modifiers.apply_state("mud_covered")
	
	assert_true(modifiers.movement_impaired(), "Mud should impair movement")
	assert_true(modifiers.provides_camouflage(), "Mud should provide camouflage")
	assert_true(modifiers.affects_equipment(), "Mud should affect equipment")

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
	modifiers.apply_state("dazed")
	
	assert_true(modifiers.balance_affected(), "Dazed should affect balance")
	assert_true(modifiers.vision_blurred(), "Dazed should blur vision")
	assert_true(modifiers.easy_to_disarm(), "Dazed should make disarming easier")

# Positional Advantage Tests
func test_high_ground() -> void:
	modifiers.apply_position("high_ground")
	
	assert_true(modifiers.has_leverage(), "High ground should give leverage")
	assert_true(modifiers.easier_defense(), "High ground should make defense easier")
	assert_true(modifiers.controls_space_below(), "High ground should control space below")

func test_wall_at_back() -> void:
	modifiers.apply_position("wall_at_back")
	
	assert_false(modifiers.can_be_flanked(), "Wall should prevent flanking")
	assert_true(modifiers.has_brace(), "Wall should provide brace")
	assert_true(modifiers.limited_movement(), "Wall should limit movement")

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
	modifiers.apply_position("wall_at_back")
	
	assert_true(modifiers.causes_panic(), "Should cause panic")
	assert_true(modifiers.must_move(), "Should force movement")
	assert_true(modifiers.smoke_concentrated(), "Smoke should be concentrated")

func test_bleeding_and_winded() -> void:
	modifiers.apply_state("bleeding")
	modifiers.apply_state("winded")
	
	assert_true(modifiers.growing_faint(), "Should cause fainting")
	assert_true(modifiers.requires_rest(), "Should require rest")
	assert_true(modifiers.easy_target(), "Should be an easy target")

# Environmental Factor Tests
func test_rain_effects() -> void:
	modifiers.apply_environment("rain")
	
	assert_true(modifiers.ground_slick(), "Rain should make ground slick")
	assert_true(modifiers.vision_reduced(), "Rain should reduce vision")
	assert_true(modifiers.metal_slippery(), "Rain should make metal slippery")

func test_darkness_effects() -> void:
	modifiers.apply_environment("darkness")
	
	assert_true(modifiers.movement_hidden(), "Darkness should hide movement")
	assert_true(modifiers.surprise_likely(), "Darkness should enable surprise")
	assert_true(modifiers.distance_unclear(), "Darkness should make distance unclear")

func test_confined_space() -> void:
	modifiers.apply_environment("confined")
	
	assert_true(modifiers.swings_limited(), "Confined space should limit swings")
	assert_true(modifiers.close_quarters(), "Should be close quarters")
	assert_true(modifiers.echo_effects(), "Should have echo effects")

# Edge Cases
func test_conflicting_states() -> void:
	modifiers.apply_state("ablaze")
	modifiers.apply_state("mud_covered")
	
	# Mud should reduce ablaze effectiveness
	assert_lt(modifiers.get_ablaze_intensity(), 1.0, "Mud should reduce ablaze intensity")

func test_position_changes() -> void:
	modifiers.apply_position("high_ground")
	modifiers.apply_position("flanking")  # Should remove high ground
	
	assert_false(modifiers.has_position("high_ground"), "Should not have multiple positions")
	assert_true(modifiers.has_position("flanking"), "Should have new position")

func test_environmental_stacking() -> void:
	modifiers.apply_environment("rain")
	modifiers.apply_environment("darkness")
	
	assert_true(modifiers.has_environment("rain"), "Should have rain effects")
	assert_true(modifiers.has_environment("darkness"), "Should have darkness effects")
	assert_true(modifiers.vision_severely_reduced(), "Effects should stack")

# Behavioral Interaction Tests
func test_panic_behavior() -> void:
	# Setup panic conditions
	modifiers.apply_state("ablaze")
	modifiers.apply_position("wall_at_back")
	watch_signals(entity)
	
	# Process AI decision
	entity.process_turn()
	
	# Verify panic behavior
	assert_true(entity.is_panicked(), "Entity should be panicked")
	assert_signal_emitted(entity, "started_fleeing")
	assert_true(entity.get_next_action() is FleeAction, "Entity should choose to flee")
	
	# Check random movement
	var initial_pos = entity.grid_position
	entity.execute_turn()
	assert_ne(entity.grid_position, initial_pos, "Panicked entity should move randomly")

func test_bleeding_behavior() -> void:
	# Setup heavy bleeding
	modifiers.apply_state("bleeding")
	modifiers.apply_state("bleeding")  # Stack bleeding
	watch_signals(entity)
	
	# Process AI decision
	entity.process_turn()
	
	# Verify behavior
	assert_true(entity.is_seeking_treatment(), "Entity should seek treatment")
	assert_true(entity.get_next_action() is SeekHealingAction, "Entity should try to heal")
	
	# Check if entity prioritizes healing over attacking
	var enemy = create_enemy_nearby()
	entity.process_turn()
	assert_false(entity.get_next_action() is AttackAction, "Bleeding entity should prioritize healing")

func test_combat_state_influence() -> void:
	var enemy = create_enemy_nearby()
	
	# Test normal combat behavior
	entity.process_turn()
	var normal_action = entity.get_next_action()
	assert_true(normal_action is AttackAction, "Should attack normally")
	
	# Apply states that should affect combat
	modifiers.apply_state("winded")
	modifiers.apply_state("dazed")
	entity.process_turn()
	
	# Verify defensive behavior
	var defensive_action = entity.get_next_action()
	assert_true(defensive_action is DefendAction or defensive_action is RetreatAction,
			   "Impaired entity should be defensive")

func test_positional_tactics() -> void:
	var enemy = create_enemy_nearby()
	
	# Test high ground advantage
	modifiers.apply_position("high_ground")
	entity.process_turn()
	var high_ground_action = entity.get_next_action()
	assert_true(high_ground_action is AttackAction, "Should attack from high ground")
	assert_true(entity.is_maintaining_position(), "Should maintain high ground")
	
	# Test flanking behavior
	modifiers.apply_position("flanking")
	entity.process_turn()
	var flanking_action = entity.get_next_action()
	assert_true(flanking_action is AttackAction, "Should exploit flanking")
	assert_gt(flanking_action.get_advantage(), 0, "Should have attack advantage")

func test_environmental_adaptation() -> void:
	# Test behavior in darkness
	modifiers.apply_environment("darkness")
	entity.process_turn()
	assert_true(entity.is_being_cautious(), "Should be cautious in darkness")
	assert_true(entity.get_next_action().is_careful(), "Actions should be careful")
	
	# Test behavior in confined space
	modifiers.apply_environment("confined")
	entity.process_turn()
	var confined_action = entity.get_next_action()
	assert_false(confined_action is SwingWeaponAction, "Should not swing in confined space")
	assert_true(confined_action is ThrustWeaponAction, "Should thrust in confined space")

func test_equipment_interaction() -> void:
	# Setup equipment
	var sword = create_weapon("Sword")
	entity.equipment_component.equip_weapon(sword)
	
	# Test oiled state affecting weapon
	modifiers.apply_state("oiled")
	entity.process_turn()
	assert_true(entity.is_at_risk_of_dropping(), "Should risk dropping oiled weapon")
	
	# Test mud affecting armor
	var armor = create_armor("Plate")
	entity.equipment_component.equip_armor(armor)
	modifiers.apply_state("mud_covered")
	assert_lt(entity.get_effective_armor(), armor.base_protection, "Mud should reduce armor effectiveness")

func test_condition_combinations() -> void:
	# Test multiple impairing conditions
	modifiers.apply_state("winded")
	modifiers.apply_state("dazed")
	modifiers.apply_state("mud_covered")
	
	entity.process_turn()
	
	# Verify severely impaired behavior
	assert_true(entity.is_severely_impaired(), "Should be severely impaired")
	assert_eq(entity.get_available_actions().size(), 1, "Should only have one action available")
	assert_true(entity.get_next_action() is RestAction, "Should be forced to rest")

func test_progressive_state_effects() -> void:
	# Test bleeding getting worse
	modifiers.apply_state("bleeding")
	var initial_consciousness = entity.health_component.consciousness
	
	for i in range(3):
		entity.process_turn()  # Let bleeding progress
		
	assert_gt(entity.health_component.consciousness, initial_consciousness, 
			 "Consciousness should increase from bleeding")
	assert_true(entity.is_getting_weaker(), "Should be weakening from blood loss")

# Utility Functions
func create_enemy_nearby() -> Entity:
	var enemy = Entity.from_blueprint(
		preload("res://assets/blueprints/actors/monsters/orc.tres"),
		entity.grid_position + Vector2i(1, 0)
	)
	GameMap.register_entity(enemy, enemy.grid_position)
	return enemy

func create_weapon(name: String) -> Dictionary:
	return {
		"name": name,
		"type": "weapon",
		"properties": {
			"damage": 5,
			"range": 1
		}
	}

func create_armor(name: String) -> Dictionary:
	return {
		"name": name,
		"type": "armor",
		"base_protection": 3,
		"coverage": ["torso"]
	} 