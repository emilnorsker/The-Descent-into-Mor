@tool
class_name AnatomyMapper extends Node

# Result of a mapping operation
class MappingResult:
    var target_nodes: Array[String]  # IDs of target nodes
    var damage_modifiers: Array[float]  # Corresponding damage modifiers
    var distribution_type: String  # How damage should be distributed

# Cache of loaded anatomies
var _anatomies: Dictionary = {}  # type -> AnatomyBlueprint
var _base_anatomy: AnatomyBlueprint

func _init() -> void:
    # Load base anatomy blueprint
    _base_anatomy = load("res://assets/blueprints/base_anatomy.tres") as AnatomyBlueprint

func register_anatomy(blueprint: AnatomyBlueprint) -> void:
    _anatomies[blueprint.anatomy_type] = blueprint

func map_damage_location(source_location: String, source_anatomy_type: String, target_anatomy_type: String) -> MappingResult:
    var result = MappingResult.new()
    
    # Get the anatomies
    var source_anatomy = _anatomies.get(source_anatomy_type)
    var target_anatomy = _anatomies.get(target_anatomy_type)
    
    if not source_anatomy or not target_anatomy:
        push_error("Missing anatomy blueprint for mapping")
        return result
        
    # 1. Find the node in source anatomy
    var source_node = source_anatomy.get_node(source_location)
    if not source_node:
        # Try to find similar node
        source_node = _find_similar_node(source_location, source_anatomy)
        if not source_node:
            return result
    
    # 2. Get mapping rules
    var mapping_rules = source_anatomy.get_mapping_rules_for(source_node.type)
    if mapping_rules.is_empty():
        # Use default mapping based on node type
        mapping_rules = _get_default_mapping_rules(source_node.type)
    
    # 3. Apply mapping rules to find target nodes
    for rule in mapping_rules:
        var mapped_nodes = _apply_mapping_rule(rule, source_node, target_anatomy)
        result.target_nodes.append_array(mapped_nodes)
        
        # Calculate damage modifiers for each target
        for node in mapped_nodes:
            var target_node = target_anatomy.get_node(node)
            result.damage_modifiers.append(
                target_node.properties.damage_multiplier * rule.rule.get("damage_modifier", 1.0)
            )
    
    # 4. Set distribution type
    result.distribution_type = _get_distribution_type(mapping_rules)
    
    return result

func _find_similar_node(location: String, anatomy: AnatomyBlueprint) -> AnatomyBlueprint.AnatomyNode:
    # Try to find nodes with similar names or types
    for node_id in anatomy.nodes:
        var node = anatomy.get_node(node_id)
        if _is_similar_location(location, node_id):
            return node
    return null

func _is_similar_location(location: String, node_id: String) -> bool:
    # Simple similarity check - can be made more sophisticated
    return location.to_lower().contains(node_id.to_lower()) or \
           node_id.to_lower().contains(location.to_lower())

func _get_default_mapping_rules(node_type: AnatomyBlueprint.NodeType) -> Array:
    # Default mappings based on node type
    match node_type:
        AnatomyBlueprint.NodeType.VITAL:
            return [{"source": "vital", "target": "vital", "rule": {"priority": 1}}]
        AnatomyBlueprint.NodeType.APPENDAGE:
            return [{"source": "appendage", "target": "closest_appendage", "rule": {"priority": 1}}]
        _:
            return [{"source": "any", "target": "core", "rule": {"priority": 1}}]

func _apply_mapping_rule(rule: Dictionary, source_node: AnatomyBlueprint.AnatomyNode, target_anatomy: AnatomyBlueprint) -> Array[String]:
    var result: Array[String] = []
    
    match rule.rule.get("distribution", "single"):
        "single":
            var target = _find_best_target(rule.target, target_anatomy)
            if target:
                result.append(target)
        "multiple":
            var count = rule.rule.get("count", 1)
            var targets = _find_multiple_targets(rule.target, target_anatomy, count)
            result.append_array(targets)
        "closest":
            var target = _find_closest_target(source_node, target_anatomy)
            if target:
                result.append(target)
    
    return result

func _find_best_target(target_type: String, anatomy: AnatomyBlueprint) -> String:
    # Find the most appropriate target based on type
    for node_id in anatomy.nodes:
        var node = anatomy.get_node(node_id)
        if node.type == target_type:
            return node_id
    return ""

func _find_multiple_targets(target_type: String, anatomy: AnatomyBlueprint, count: int) -> Array[String]:
    var result: Array[String] = []
    
    for node_id in anatomy.nodes:
        var node = anatomy.get_node(node_id)
        if node.type == target_type:
            result.append(node_id)
            if result.size() >= count:
                break
    
    return result

func _find_closest_target(source_node: AnatomyBlueprint.AnatomyNode, target_anatomy: AnatomyBlueprint) -> String:
    # Find target node closest to source in the anatomy hierarchy
    var current = target_anatomy.get_node(target_anatomy.root_node)
    while current:
        if current.type == source_node.type:
            return current.id
        
        # Check children
        for child_id in current.children:
            var child = target_anatomy.get_node(child_id)
            if child.type == source_node.type:
                return child_id
        
        # Move to next sibling or parent
        current = target_anatomy.get_parent(current.id)
    
    return ""

func _get_distribution_type(mapping_rules: Array) -> String:
    # Determine how damage should be distributed based on rules
    for rule in mapping_rules:
        if rule.rule.has("distribution"):
            return rule.rule.distribution
    return "single" 