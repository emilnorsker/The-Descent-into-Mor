@tool
class_name AnatomyBlueprint extends Resource

enum NodeType {
    VITAL,      # Critical body parts (head, heart)
    STRUCTURAL, # Supporting parts (spine, trunk)
    APPENDAGE,  # Limbs and extremities
    ORGAN,      # Internal organs
    ARMOR,      # Protective parts (shell, scales)
}

# Basic node structure for anatomy
class AnatomyNode:
    var id: String
    var type: NodeType
    var parent_id: String
    var children: Array[String] = []  # Initialize empty typed array
    var properties: Dictionary = {
        "vital": false,
        "symmetrical": false,
        "count": 1,
        "damage_multiplier": 1.0
    }
    
    func _init() -> void:
        children = []  # Ensure it's initialized

# The actual anatomy data
@export var anatomy_type: String = ""  # "humanoid", "serpentine", "insectoid", etc.
@export var nodes: Dictionary = {}  # id -> AnatomyNode
@export var root_node: String = ""  # Starting point of the anatomy

# Mapping rules for this anatomy
@export var mapping_rules: Array[Dictionary] = []  # Array of mapping rules to other anatomies

func _init() -> void:
    if Engine.is_editor_hint():
        if nodes.is_empty():
            # Create default root node
            var root = AnatomyNode.new()
            root.id = "core"
            root.type = NodeType.STRUCTURAL
            nodes["core"] = root
            root_node = "core"

func add_node(id: String, type: NodeType, parent_id: String = "") -> void:
    var node = AnatomyNode.new()
    node.id = id
    node.type = type
    node.parent_id = parent_id
    nodes[id] = node
    
    if parent_id:
        nodes[parent_id].children.append(id)
    elif root_node.is_empty():
        root_node = id

func add_mapping_rule(source_type: String, target_type: String, rule: Dictionary) -> void:
    mapping_rules.append({
        "source": source_type,
        "target": target_type,
        "rule": rule
    })

func get_node(id: String) -> AnatomyNode:
    var node_data = nodes.get(id)
    if not node_data:
        return null
        
    var node = AnatomyNode.new()
    node.id = node_data.id
    node.type = node_data.type
    node.parent_id = node_data.parent_id
    # Convert raw array to Array[String]
    for child in node_data.children:
        node.children.append(child as String)
    node.properties = node_data.properties
    return node

func get_parent(node_id: String) -> AnatomyNode:
    var node = get_node(node_id)
    if node and node.parent_id:
        return get_node(node.parent_id)
    return null

func get_children(node_id: String) -> Array[AnatomyNode]:
    var node = get_node(node_id)
    if not node:
        return []
    
    var result: Array[AnatomyNode] = []
    for child_id in node.children:
        var child = get_node(child_id)
        if child:
            result.append(child)
    return result

func get_mapping_rules_for(source: String) -> Array:
    # First try exact location match
    var location_rules = mapping_rules.filter(func(rule): return rule.source == source)
    if not location_rules.is_empty():
        return location_rules
        
    # Then try partial location match (e.g. "hand" matches "left_hand")
    var base_location = source.split("_")[-1]  # Get last part after underscore
    location_rules = mapping_rules.filter(func(rule): return rule.source == base_location)
    if not location_rules.is_empty():
        return location_rules
        
    # Finally try type match
    return mapping_rules.filter(func(rule): return rule.source == source) 