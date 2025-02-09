extends GutTest

const MapScene = preload("res://src/Map/Map.tscn")
const Level = preload("res://src/Map/level.gd")

var test_level: Level
var attacker: Entity  # We'll use this instead of 'player' to be more generic
var target: Entity
var bystander: Entity  # For testing AOE effects

func before_each() -> void:
	var map_scene = MapScene.instantiate()
	add_child_autofree(map_scene)
	
	test_level = preload("res://tests/fixtures/test_level.tres")
	GameMap.load_level(test_level)
	
	# We'll create entities in a specific formation for testing different attack patterns
	attacker = Entity.from_blueprint(preload("res://assets/blueprints/actors/player.tres"), Vector2i(2, 2))
	target = Entity.from_blueprint(preload("res://assets/blueprints/actors/monsters/orc.tres"), Vector2i(3, 2))
	bystander = Entity.from_blueprint(preload("res://assets/blueprints/actors/monsters/orc.tres"), Vector2i(4, 2))
	
	GameMap.register_entity(attacker, attacker.grid_position)
	GameMap.register_entity(target, target.grid_position)
	GameMap.register_entity(bystander, bystander.grid_position)

func after_each() -> void:
	GameMap.clear()

# Test Different Damage Types
func test_slash_damage() -> void:
	var slash_action = CombatAction.new(attacker, {
		"damage_type": DamageType.SLASH,
		"target_type": TargetType.SINGLE,
		"target_position": target.grid_position
	})
	
	var initial_health = target.health_component.get_health()
	var result = slash_action.perform()
	
	assert_true(result, "Slash action should succeed")
	assert_lt(target.health_component.get_health(), initial_health, "Target should take slash damage")
	assert_true(target.health_component.has_wound(WoundType.BLEEDING), "Slash should cause bleeding")

func test_pierce_damage() -> void:
	var pierce_action = CombatAction.new(attacker, {
		"damage_type": DamageType.PIERCE,
		"target_type": TargetType.SINGLE,
		"target_position": target.grid_position,
		"target_body_part": BodyPart.CHEST
	})
	
	var initial_health = target.health_component.get_health()
	var result = pierce_action.perform()
	
	assert_true(result, "Pierce action should succeed")
	assert_lt(target.health_component.get_health(), initial_health, "Target should take pierce damage")
	assert_true(target.health_component.has_wound(WoundType.DEEP), "Pierce should cause deep wound")

func test_blunt_damage() -> void:
	var blunt_action = CombatAction.new(attacker, {
		"damage_type": DamageType.BLUNT,
		"target_type": TargetType.SINGLE,
		"target_position": target.grid_position,
		"target_body_part": BodyPart.HEAD
	})
	
	var result = blunt_action.perform()
	
	assert_true(result, "Blunt action should succeed")
	assert_true(target.status_component.has_status(StatusEffect.STUNNED), "Blunt to head should cause stun")

# Test Different Target Areas
func test_line_attack() -> void:
	var line_action = CombatAction.new(attacker, {
		"damage_type": DamageType.PIERCE,
		"target_type": TargetType.LINE,
		"direction": Vector2i(1, 0),
		"range": 3
	})
	
	var result = line_action.perform()
	
	assert_true(result, "Line attack should succeed")
	assert_true(target.health_component.is_damaged(), "First target should be hit")
	assert_true(bystander.health_component.is_damaged(), "Second target should be hit")

func test_cone_attack() -> void:
	var cone_action = CombatAction.new(attacker, {
		"damage_type": DamageType.SLASH,
		"target_type": TargetType.CONE,
		"direction": Vector2i(1, 0),
		"angle": 45
	})
	
	var result = cone_action.perform()
	
	assert_true(result, "Cone attack should succeed")
	var affected_positions = GameMap.get_affected_positions(cone_action)
	assert_true(affected_positions.has(target.grid_position), "Target should be in cone")

func test_cleave_attack() -> void:
	var cleave_action = CombatAction.new(attacker, {
		"damage_type": DamageType.SLASH,
		"target_type": TargetType.CLEAVE,
		"direction": Vector2i(1, 0)
	})
	
	var result = cleave_action.perform()
	
	assert_true(result, "Cleave attack should succeed")
	assert_true(target.health_component.is_damaged(), "Primary target should be hit")
	# Check adjacent tiles for cleave damage

# Test Status Effects
func test_bleeding_effect() -> void:
	var bleeding_action = CombatAction.new(attacker, {
		"damage_type": DamageType.SLASH,
		"target_type": TargetType.SINGLE,
		"target_position": target.grid_position,
		"effects": [StatusEffect.BLEEDING]
	})
	
	var result = bleeding_action.perform()
	
	assert_true(result, "Bleeding attack should succeed")
	assert_true(target.status_component.has_status(StatusEffect.BLEEDING), "Target should be bleeding")
	# Test bleeding damage over time would go here

func test_stun_effect() -> void:
	var stun_action = CombatAction.new(attacker, {
		"damage_type": DamageType.BLUNT,
		"target_type": TargetType.SINGLE,
		"target_position": target.grid_position,
		"target_body_part": BodyPart.HEAD,
		"effects": [StatusEffect.STUNNED]
	})
	
	var result = stun_action.perform()
	
	assert_true(result, "Stun attack should succeed")
	assert_true(target.status_component.has_status(StatusEffect.STUNNED), "Target should be stunned")
	# Test that stunned target skips their next turn

# Test Body Part Targeting
func test_targeted_attack() -> void:
	var head_attack = CombatAction.new(attacker, {
		"damage_type": DamageType.PIERCE,
		"target_type": TargetType.SINGLE,
		"target_position": target.grid_position,
		"target_body_part": BodyPart.HEAD
	})
	
	var result = head_attack.perform()
	
	assert_true(result, "Targeted attack should succeed")
	assert_true(target.health_component.get_body_part_damage(BodyPart.HEAD) > 0, "Head should take damage")
	# Test for specific head injury effects

# Test Health System
func test_wound_system() -> void:
	var deep_wound = CombatAction.new(attacker, {
		"damage_type": DamageType.PIERCE,
		"target_type": TargetType.SINGLE,
		"target_position": target.grid_position,
		"target_body_part": BodyPart.CHEST
	})
	
	var result = deep_wound.perform()
	
	assert_true(result, "Deep wound attack should succeed")
	var wounds = target.health_component.get_wounds()
	assert_true(wounds.has(WoundType.DEEP), "Should have deep wound")
	assert_true(target.status_component.has_status(StatusEffect.BLEEDING), "Deep wound should cause bleeding")

func test_critical_hit() -> void:
	var vital_strike = CombatAction.new(attacker, {
		"damage_type": DamageType.PIERCE,
		"target_type": TargetType.SINGLE,
		"target_position": target.grid_position,
		"target_body_part": BodyPart.HEART,
		"critical": true
	})
	
	var result = vital_strike.perform()
	
	assert_true(result, "Critical hit should succeed")
	assert_true(target.health_component.is_critical(), "Target should be in critical condition")
	# Test for death if not treated 