extends RigidBody3D
class_name Item
# Hey guys, CodeBlooded here!
# https://www.youtube.com/@codeblooded-v4e - My Youtube Channel
# Please like, share and subscribe - Please subscribe it really helps me make more tutorials. Thanks!
# https://sketchfab.com/alpez791 - My Sketchfab Voxel Model only
# If you have any questions, feel free to message me.
# GMAIL: codeblooded777@gmail.com
#_________              .___      __________ .__                       .___           .___ 
#\_   ___ \   ____    __| _/ ____ \______   \|  |    ____    ____    __| _/ ____    __| _/ 
#/    \  \/  /  _ \  / __ |_/ __ \ |    |  _/|  |   /  _ \  /  _ \  / __ |_/ __ \  / __ |  
#\     \____(  <_> )/ /_/ |\  ___/ |    |   \|  |__(  <_> )(  <_> )/ /_/ |\  ___/ / /_/ |  
# \______  / \____/ \____ | \___  >|______  /|____/ \____/  \____/ \____ | \___  >\____ |  
		#\/              \/     \/        \/                            \/     \/      \/  
#
#   ________             .___        __                          ____  .__                  
# /  _____/   ____    __| _/ ____ _/  |_       ____    ____    / ___\ |__|  ____    ____   
#/   \  ___  /  _ \  / __ | /  _ \\   __\    _/ __ \  /    \  / /_/  >|  | /    \ _/ __ \  
#\    \_\  \(  <_> )/ /_/ |(  <_> )|  |      \  ___/ |   |  \ \___  / |  ||   |  \\  ___/  
# \______  / \____/ \____ | \____/ |__|       \___  >|___|  //_____/  |__||___|  / \___  > 
#        \/              \/                       \/      \/                   \/      \/ 
# 

signal item_out_of_bounds
var _is_teleporting := false
var hold_point: Marker3D
@export var body: CollisionShape3D
@export var fall_limit: float = -50.0
@export var item_name: String = "Item"
var just_dropped := false

func _ready():
	_set_mesh_layer(true, false)
	freeze = true

func _physics_process(_delta):
	if global_position.y < fall_limit:
		_teleport_to_bedroom()

func _process(_delta: float) -> void:
	if hold_point:
		global_transform = hold_point.global_transform

func _teleport_to_bedroom() -> void:
	if _is_teleporting:
		return
	_is_teleporting = true
	var spawn = get_tree().get_first_node_in_group("bedroom_spawn")
	if spawn:
		global_position = spawn.global_position
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	await get_tree().create_timer(0.5).timeout
	_is_teleporting = false
	item_out_of_bounds.emit()

func _set_mesh_layer(layer_1: bool, layer_20: bool) -> void:
	for child in find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, layer_1)
		child.set_layer_mask_value(20, layer_20)

func _pick(point: Marker3D) -> void:
	hold_point = point
	freeze = true
	body.disabled = true
	_set_mesh_layer(false, true)
	just_dropped = false
	# look for a RemoteTransform3D that is currently linked to this drawer
	for node in get_tree().get_nodes_in_group("drawer_remote"):
		var absolute_remote = node.get_node_or_null(node.remote_path)
		
		# if this remote is pointing here, clear its path
		if absolute_remote == self:
			node.remote_path = NodePath("")
			break

	var area = get_node_or_null("drop_sound_detector")
	if area:
		area.monitoring = false

func drop(direction: Vector3) -> void:
	hold_point = null
	freeze = false
	body.disabled = false
	apply_impulse(direction)
	_set_mesh_layer(true, false)
	just_dropped = true
	var area = get_node_or_null("drop_sound_detector")
	if area:
		area.monitoring = true
