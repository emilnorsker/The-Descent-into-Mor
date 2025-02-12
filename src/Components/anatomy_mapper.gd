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
    result.distribution_type = "single"  # Always use single distribution since we pick one target
    
    # Get the anatomies
    var source_anatomy = _anatomies.get(source_anatomy_type)
    var target_anatomy = _anatomies.get(target_anatomy_type)
    
    if not source_anatomy or not target_anatomy:
        push_error("Missing anatomy blueprint for mapping")
        return result
        
    # 1. Get mapping rules from target anatomy first
    var mapping_rules = target_anatomy.get_mapping_rules_for(source_location)
    print("Initial mapping rules for %s: %s" % [source_location, mapping_rules])
    
    if mapping_rules.is_empty():
        # Try to find source node for type-based mapping
        var source_node = source_anatomy.get_node(source_location)
        print("Source node for %s: %s (type: %s)" % [source_location, source_node, source_node.type if source_node else "none"])
        
        if source_node:
            # First try exact match for vital areas like 'head'
            mapping_rules = target_anatomy.get_mapping_rules_for(source_location)
            print("Exact match rules for %s: %s" % [source_location, mapping_rules])
            
            if mapping_rules.is_empty():
                var node_type_str = AnatomyBlueprint.NodeType.keys()[source_node.type].to_lower()
                print("Node type for %s: %s" % [source_location, node_type_str])
                mapping_rules = target_anatomy.get_mapping_rules_for(node_type_str)
                print("Type-based rules for %s: %s" % [source_location, mapping_rules])
                
                if mapping_rules.is_empty():
                    mapping_rules = _get_default_mapping_rules(source_node.type)
                    print("Default rules for %s: %s" % [source_location, mapping_rules])
    
    print("Final mapping rules for %s: %s" % [source_location, mapping_rules])
    
    # 2. Apply mapping rules to find target nodes
    for rule in mapping_rules:
        print("Applying rule: %s" % rule)
        var mapped_nodes = _apply_mapping_rule(rule, null, target_anatomy)
        print("Mapped nodes: %s" % mapped_nodes)
        result.target_nodes.append_array(mapped_nodes)
        
        # Calculate damage modifiers for each target
        for node in mapped_nodes:
            var target_node = target_anatomy.get_node(node)
            print("Target node %s: %s (damage_multiplier: %s)" % [node, target_node, target_node.properties.damage_multiplier if target_node else "none"])
            # For cluster targets, use the target's own modifier
            # For single mappings, apply the rule's damage modifier
            var damage_multiplier = target_node.properties.damage_multiplier
            if rule.rule.has("damage_modifier") and not target_node.parent_id.contains("cluster"):
                damage_multiplier *= rule.rule.damage_modifier
            result.damage_modifiers.append(damage_multiplier)
    
    print("Final result for %s: nodes=%s modifiers=%s" % [source_location, result.target_nodes, result.damage_modifiers])
    
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
    print("_apply_mapping_rule: rule=%s source_node=%s" % [rule, source_node])
    
    match rule.rule.get("distribution", "single"):
        "single":
            print("Finding best target for %s" % rule.target)
            var target = _find_best_target(rule.target, target_anatomy)
            print("Best target found: %s" % target)
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
    
    print("_apply_mapping_rule result: %s" % result)
    return result

func _find_best_target(target_type: String, anatomy: AnatomyBlueprint) -> String:
    print("_find_best_target: target_type=%s nodes=%s" % [target_type, anatomy.nodes.keys()])
    # First try exact id match
    if anatomy.nodes.has(target_type):
        print("Found exact match for %s" % target_type)
        return target_type
        
    # If target is "vital", look for vital nodes
    if target_type == "vital":
        print("Looking for vital nodes")
        for node_id in anatomy.nodes:
            var node = anatomy.get_node(node_id)
            if node and node.type == AnatomyBlueprint.NodeType.VITAL:
                print("Found vital node: %s" % node_id)
                return node_id
                
    print("No match found for %s" % target_type)
    return ""

func _find_multiple_targets(target_type: String, anatomy: AnatomyBlueprint, count: int) -> Array[String]:
    var result: Array[String] = []
    
    # First try exact match for cluster
    if anatomy.nodes.has(target_type):
        var target_node = anatomy.get_node(target_type)
        # If it's a cluster (has children), randomly pick one child
        if not target_node.children.is_empty():
            var random_index = randi() % target_node.children.size()
            result.append(target_node.children[random_index])
            # Generate a humorous message about the mapping
            var source_name = target_type.replace("_cluster", "").replace("_", " ")
            var target_name = target_node.children[random_index].replace("_", " ")
            SignalBus.message_sent.emit(
                "Aimed for the %s but hit the %s! Who knew they had so many arms?" % [source_name, target_name],
                Color.YELLOW
            )
            return result
    
    # Fallback to type-based search
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