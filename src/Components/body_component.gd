@tool
class_name BodyComponent extends Component

const DefultBodyComponentBlueprint = preload("res://src/Components/Blueprints/body_component_blueprint.gd")
const DEFAULT_BLUEPRINT = preload("res://new_assets/blueprints/body/humanoid.tres")

signal consciousness_check_failed
signal wound_applied(wound_type: int, body_part: int)
signal condition_applied(condition: int)
signal died

enum BodyPart {
    NONE,
    HEAD,
    NECK,
    CHEST,
    ABDOMEN,
    LEFT_ARM,
    RIGHT_ARM,
    LEFT_HAND,
    RIGHT_HAND,
    RIGHT_EQUIPMENT,
    LEFT_EQUIPMENT,
    LEFT_LEG,
    RIGHT_LEG
}

enum WoundType {
    LIGHT,
    MODERATE,
    SEVERE,
    CRITICAL,
    FATAL
}

var type: String = "humanoid"
var parts: Dictionary = {}
var consciousness: float = 100.0
var is_dead: bool = false
var equipment: Dictionary = {}  # Dictionary of slot -> Entity
var protection: Dictionary = {}  # Dictionary of part -> total protection
var wounds: Dictionary = {}

class Wound:
    var type: WoundType
    var treatment_level: int  # 0 = untreated, 1 = bandaged, 2 = stitched
    var part: BodyPart
    var bleeding_rate: int = 0

    func _init(severity: WoundType, part: BodyPart):
        self.type = severity
        self.part = part
        self.treatment_level = 0

func _init(blueprint: Resource = null) -> void:
    super()
    name = "BodyComponent"
    
    if not blueprint:
        blueprint = DEFAULT_BLUEPRINT
    
    if blueprint:
        if not blueprint is BodyComponentBlueprint:
            push_error("Invalid blueprint type provided to BodyComponent")
            return
            
        type = blueprint.type
        parts = blueprint.parts.duplicate()
        wounds = blueprint.wounds.duplicate()
        consciousness = blueprint.consciousness
        is_dead = blueprint.is_dead

    # Initialize parts dictionary with default humanoid parts
    parts = {
        "head": true,
        "neck": true,
        "chest": true,
        "abdomen": true,
        "left_arm": true,
        "right_arm": true,
        "left_leg": true,
        "right_leg": true
    }
    
    # Initialize wounds dictionary with empty arrays for each part
    for part in parts.keys():
        wounds[part] = []
    for part in BodyPart.values():
        equipment[part] = null
        protection[part] = 0

func _get_part_from_string(part_str: String) -> BodyPart:
    match part_str.to_lower():
        "head": return BodyPart.HEAD
        "neck": return BodyPart.NECK
        "chest": return BodyPart.CHEST
        "abdomen": return BodyPart.ABDOMEN
        "left_arm": return BodyPart.LEFT_ARM
        "right_arm": return BodyPart.RIGHT_ARM
        "left_leg": return BodyPart.LEFT_LEG
        "right_leg": return BodyPart.RIGHT_LEG
        _: return BodyPart.NONE

func setup_from_blueprint(blueprint: Resource) -> Component:
    if not blueprint or not blueprint is BodyComponentBlueprint:
        push_error("Invalid blueprint provided to BodyComponent.setup_from_blueprint")
        return self
    
    var body_blueprint = blueprint as BodyComponentBlueprint
    type = body_blueprint.type
    parts = body_blueprint.parts
    consciousness = body_blueprint.consciousness
    is_dead = body_blueprint.is_dead
    
    # Initialize wounds dictionary with empty arrays for each part
    wounds = {}
    for part in BodyPart.values():
        wounds[part] = []
    
    # Copy wounds from blueprint, converting string keys to enum values
    for part_str in body_blueprint.wounds:
        var part = _get_part_from_string(part_str)
        if part != null:
            wounds[part] = body_blueprint.wounds[part_str].duplicate()
    
    return self

func setup_from_dict(data: Dictionary) -> Component:
    if data.has("parts"):
        parts = data.parts if data.parts is Dictionary else {}
    if data.has("wounds"):
        var wound_data = data.wounds if data.wounds is Dictionary else {}
        for part_name in wound_data:
            var part = _get_part_from_string(part_name)
            if part != BodyPart.NONE:
                wounds[part] = wound_data[part_name]
    if data.has("consciousness"):
        consciousness = data.consciousness
    if data.has("equipment"):
        equipment = data.equipment if data.equipment is Dictionary else {}
    if data.has("protection"):
        protection = data.protection if data.protection is Dictionary else {}
    return self

func apply_wound(type: WoundType, part: BodyPart = BodyPart.NONE) -> void:
    if is_dead:
        return
        
    if part == BodyPart.NONE:
        part = randi_range(BodyPart.HEAD, BodyPart.RIGHT_LEG)
    var wound = Wound.new(type, part)
    
    # Ensure the part exists in the wounds dictionary
    if not wounds.has(part):
        wounds[part] = []
    
    wounds[part].append(wound)
    
    var consciousness_loss = (type+2) * 3  # (0-5 +2) * 3 = 6-24
    match part:
        BodyPart.HEAD:
            consciousness_loss *= 5
        BodyPart.NECK:
            consciousness_loss *= 4
        BodyPart.CHEST:
            consciousness_loss *= 1.5
    
    consciousness -= consciousness_loss #  ranges from 6-120
    emit_signal("wound_applied", type, part)
    
    # Check for instant death conditions
    if type == WoundType.FATAL and (part == BodyPart.HEAD or part == BodyPart.NECK):
        die()
    check_consciousness()

func add_consciousness(amount: int) -> void:
    consciousness += amount
    check_consciousness()

func check_consciousness() -> void:
    if consciousness <= 30:
        var roll = get_parent().roll(1, [-wounds.size() ])
        print("consciousness check: ", roll)
        if not roll:  # Need 4+ to stay conscious
            emit_signal("consciousness_check_failed")
            print("consciousness check failed, will die")
            die() # TODO: Implement unconsciousness state here
            if consciousness <= -50:
                pass
                # Implement actual death here

func treat_wound(body_part: int, wound_index: int, treatment_level: int) -> void:
    if wound_index < wounds[body_part].size():
        var wound = wounds[body_part][wound_index]
        wound.treatment_level = treatment_level
        
func is_limb_impaired(body_part: int) -> bool:
    # Check if body_part is a valid BodyPart value
    if not body_part in BodyPart.values():
        push_warning("Invalid body part %d passed to is_limb_impaired" % body_part)
        return false
        
    return false

func die() -> void:
    is_dead = true
    emit_signal("died")

func get_wounds(part = null) -> Array:
    if part != null:
        if not wounds.has(part):
            wounds[part] = []
        return wounds[part]
    else:
        var all_wounds = []
        for part_wounds in wounds.values():
            all_wounds.append_array(part_wounds)
        return all_wounds

func get_wound_severity(damage: int, part: BodyPart) -> WoundType:
    damage -= get_bodypart_protection(part)
    if damage < 10:
        return WoundType.LIGHT
    elif damage < 20:
        return WoundType.MODERATE
    elif damage < 30:
        return WoundType.SEVERE
    else:
        return WoundType.CRITICAL

func equip_to_slot(item: Entity, body_part = null) -> void:
    var parent = get_parent() as Entity
    if not parent or not parent.equipment: return
    
    # If no body part specified or invalid (-1), use default right hand
    var slot = BodyPart.RIGHT_EQUIPMENT
    if body_part != BodyPart.NONE and body_part in BodyPart.values():
        slot = body_part
    
    if is_limb_impaired(slot):
        SignalBus.message_sent.emit(parent.entity_name + " is unable to equip the %s." % item.entity_name, Color.RED)
        return
    
    parent.equipment.equip(item, slot)

func process_recovery() -> void:
    # Natural consciousness recovery
    if consciousness > 0:
        consciousness = max(0, consciousness - 1)
        
    # Process wound recovery
    for part in wounds.keys():
        for wound in wounds[part]:
            if wound.treatment_level > 0:
                # Treated wounds can improve
                if wound.type > 1 and randf() < 0.1:  # 10% chance per turn
                    wound.type -= 1
                    if wound.type == 0:
                        wounds[part].erase(wound) 

func get_bodypart_protection(part: BodyPart) -> int:
    return 0