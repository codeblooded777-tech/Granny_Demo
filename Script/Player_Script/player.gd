extends CharacterBody3D
# Hey guys, CodeBlooded here!
# https://www.youtube.com/@codeblooded-v4e - My Youtube Channel
# Please like, share and subscribe - Please subscribe it really helps me make more tutorials. Thanks!
# https://sketchfab.com/alpez791 - My Sketchfab Voxel Model only
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
# Feel free to use/learn from this, just give credit. Thanks!

# Camera
@onready var cam: Camera3D = %Camera3D
@onready var subviewport_camera = get_node("%Subviewport_Camera")
# Movement - Look
@export var look_sensitivity : float = 0.006
# Movement - Walk/Ground Speed
@export var walk_speed := 3.0
#@export var sprint_speed := 8.5
@export var ground_accel := 14.0
@export var ground_decel := 10.0
@export var ground_friction := 3.0
# Movement - Air Movement
@export var air_cap := 0.85
@export var air_accel := 800.0
@export var air_move_speed := 500.0
@export var climb_speed := 2.0
# Headbob Effect
const HEADBOB_MOVE_AMOUNT = 0.06
const HEADBOB_FREQUENCY = 2.4
var headbob_time := 0.0
# Stairs / Crouch Step Height
const MAX_STEP_HEIGHT = 0.4
const  CROUCH_TRANSLATE = 1.1
const CROUCH_JUMP_ADD = CROUCH_TRANSLATE * 0.9
# Movement Direction
var wish_dir := Vector3.ZERO
var cam_aligned_wish_dir := Vector3.ZERO
# Noclip
var noclip_speed_mult := 3.0
var noclip := false
# Floor State
var _snapped_to_stairs_last_frame := false
var _last_frame_was_on_floor = -INF
# Crouch State
var is_crouched := false

# Flashlight Variable
@onready var flashlight = %flashlight
var flash_light_rotation_smooth := 15.0
var flash_light_position_smooth := 15.0

# Pick/Drop Var
var hold_item: Item
@onready var hold_point = %hold_point
# UI
@onready var mainsight1 = %MainSight
@onready var mainsight2 = %MainSight2
@onready var drop_text = %DropMessage

# Item Idle Var
@onready var weapon_holder : Node3D = $HeadOriginalPosition/Head/CameraSmooth/Camera3D/ItemHolder
var sway_amount := 0.02
var sway_speed := 6.0

# Message Label
@onready var message_label: Label = %Message_label
# Item Name Label
@onready var item_name_label: Label = %ItemNameLabel
# Bear Trap Var
@onready var hold_to_remove = %Hold_To_Remove
@onready var bear_trap_progress = %BearTrapProgressBar
var is_trapped: bool = false
var current_trap: Node = null
var is_untrapping := false
var untrap_timer := 0.0
const UNTRAP_DURATION := 3.0
# Blood Screen Var
@onready var blood_screen = %BloodScreen
var blood_tween: Tween

func get_move_speed() -> float:
	if is_crouched:
		return walk_speed * 0.8
	return walk_speed

func _ready() -> void:
	flashlight.visible = false
	
	for child in %Mesh.find_children("*", "VisualInstance3D"):
		child.set_layer_mask_value(1, false)
		child.set_layer_mask_value(2, true)
	
	_connect_item_signals()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("toggle_mouse"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * look_sensitivity)
			%Camera3D.rotate_x(-event.relative.y * look_sensitivity)
			%Camera3D.rotation.x = clamp(%Camera3D.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	if event is  InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			noclip_speed_mult = min(100.0, noclip_speed_mult * 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			noclip_speed_mult = max(0.1, noclip_speed_mult * 0.9)

func _input(_event: InputEvent) -> void:
	pass

func _headbob_effect(delta):
	headbob_time += delta * self.velocity.length()
	%Camera3D.transform.origin = Vector3(
		cos(headbob_time * HEADBOB_FREQUENCY * 0.5) * HEADBOB_MOVE_AMOUNT,
		sin(headbob_time * HEADBOB_FREQUENCY) * HEADBOB_MOVE_AMOUNT,
		0
	)

func _process(_delta: float) -> void:
	subviewport_camera.set_global_transform(cam.get_global_transform())
	
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = not flashlight.visible
		
	item_bob(_delta)

var _saved_camera_global_pos = null
func _save_camera_pos_for_smoothing():
	if _saved_camera_global_pos == null:
		_saved_camera_global_pos = %CameraSmooth.global_position
		
func _slide_camera_smooth_back_to_origin(delta):
	if _saved_camera_global_pos == null: return
	%CameraSmooth.global_position.y = _saved_camera_global_pos.y
	%CameraSmooth.position.y = clampf(%CameraSmooth.position.y, -0.7, 0.7)
	var move_amount = max(self.velocity.length() * delta, walk_speed/2 * delta)
	%CameraSmooth.position.y = move_toward(%CameraSmooth.position.y, 0.0, move_amount)
	_saved_camera_global_pos = %CameraSmooth.global_position
	if %CameraSmooth.position.y == 0:
		_saved_camera_global_pos = null
	
func _snap_down_to_stairs_check() -> void:
	var did_snap := false
	var floor_below : bool = %StairsBelowRayCast3D.is_colliding() and not is_surface_too_steep(%StairsBelowRayCast3D.get_collision_normal())
	var was_on_floor_last_frame = Engine.get_physics_frames() - _last_frame_was_on_floor == 1
	if not is_on_floor() and velocity.y <= 0 and (was_on_floor_last_frame or _snapped_to_stairs_last_frame) and floor_below:
		var body_test_result = PhysicsTestMotionResult3D.new()
		if _run_body_test_motion(self.global_transform, Vector3(0, -MAX_STEP_HEIGHT, 0), body_test_result):
			_save_camera_pos_for_smoothing()
			var translate_y = body_test_result.get_travel().y
			self.position.y += translate_y
			apply_floor_snap()
			did_snap = true
	_snapped_to_stairs_last_frame = did_snap
	
func _snap_up_stairs_check(delta) -> bool:
	if not is_on_floor() and not _snapped_to_stairs_last_frame: return false
	var expected_move_motion = self.velocity * Vector3(1,0,1) * delta
	var step_pos_with_clearance = self.global_transform.translated(expected_move_motion + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	var down_check_result = PhysicsTestMotionResult3D.new()
	if (_run_body_test_motion(step_pos_with_clearance, Vector3(0, -MAX_STEP_HEIGHT * 2, 0), down_check_result)
	and (down_check_result.get_collider().is_class("StaticBody3D") or down_check_result.get_collider().is_class("CSGShape3D"))):
		var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - self.global_position).y
		if step_height > MAX_STEP_HEIGHT or step_height <= 0.01 or (down_check_result.get_collision_point() - self.global_position).y > MAX_STEP_HEIGHT: return false
		%StairsAheadRayCast3D.global_position = down_check_result.get_collision_point() + Vector3(0, MAX_STEP_HEIGHT, 0) + expected_move_motion.normalized() * 0.1
		%StairsAheadRayCast3D.force_raycast_update()
		if %StairsAheadRayCast3D.is_colliding() and not is_surface_too_steep(%StairsAheadRayCast3D.get_collision_normal()):
			_save_camera_pos_for_smoothing()
			self.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
			apply_floor_snap()
			_snapped_to_stairs_last_frame = true
			return true
	return false
	
var _cur_ladder_climbing : Area3D = null
func _handle_ladder_physics(_delta) -> bool:
	var was_climbing_ladder := _cur_ladder_climbing and _cur_ladder_climbing.overlaps_body(self)
	if not was_climbing_ladder:
		_cur_ladder_climbing = null
		for ladders in get_tree().get_nodes_in_group("ladder_area3d"):
			if ladders.overlaps_body(self):
				_cur_ladder_climbing = ladders
				break
	if _cur_ladder_climbing == null:
		return false
	var ladder_gtransform : Transform3D = _cur_ladder_climbing.global_transform
	var pos_rel_to_ladder := ladder_gtransform.affine_inverse() * self.global_position
	
	var forward_move := Input.get_action_strength("up") - Input.get_action_strength("down")
	var side_move := Input.get_action_strength("right") - Input.get_action_strength("left")
	var ladder_forward_move = ladder_gtransform.affine_inverse().basis * %Camera3D.global_transform.basis * Vector3(0, 0, -forward_move)
	var ladder_side_move = ladder_gtransform.affine_inverse().basis * %Camera3D.global_transform.basis * Vector3(side_move, 0, 0)
	var ladder_strafe_vel : float = climb_speed * (ladder_side_move.x + ladder_forward_move.x)
	var ladder_climb_vel : float = climb_speed * -ladder_side_move.z
	var cam_forward_amount : float = %Camera3D.basis.z.dot(_cur_ladder_climbing.basis.z)
	var up_wish := Vector3.UP.rotated(Vector3(1,0,0), deg_to_rad(-45 * cam_forward_amount)).dot(ladder_forward_move)
	ladder_climb_vel += climb_speed * up_wish
	self.velocity = ladder_gtransform.basis * Vector3(ladder_strafe_vel, ladder_climb_vel, 0)
	pos_rel_to_ladder.z = 0
	self.global_position = ladder_gtransform * pos_rel_to_ladder
	move_and_slide()
	return true

@onready var _original_capsule_height = $CollisionShape3D.shape.height
func _handle_crouch(delta) -> void:
	var was_crouched_last_frame = is_crouched
	if Input.is_action_pressed("crouch"):
		is_crouched = true
	elif  is_crouched and not self.test_move(self.transform, Vector3(0, CROUCH_TRANSLATE, 0)):
		is_crouched = false
	var translate_y_if_possible := 0.0
	if was_crouched_last_frame != is_crouched and not is_on_floor() and not _snapped_to_stairs_last_frame:
		translate_y_if_possible = CROUCH_JUMP_ADD if is_crouched else -CROUCH_JUMP_ADD
	
	if translate_y_if_possible != 0.0:
		var result = KinematicCollision3D.new()
		self.test_move(self.transform, Vector3(0, translate_y_if_possible, 0), result)
		self.position.y += result.get_travel().y
		%Head.position.y -= result.get_travel().y
		%Head.position.y = clampf(%Head.position.y, -CROUCH_TRANSLATE, 0)
	%Head.position.y = move_toward(%Head.position.y, -CROUCH_TRANSLATE if is_crouched else 0, 7.0 * delta)
	$CollisionShape3D.shape.height = _original_capsule_height - CROUCH_TRANSLATE if is_crouched else _original_capsule_height
	$CollisionShape3D.position.y = $CollisionShape3D.shape.height / 2
	
func _handle_noclip(delta) -> bool:
	if Input.is_action_just_pressed("_noclip") and OS.has_feature("debug"):
		noclip = !noclip
		noclip_speed_mult = 3.0
	$CollisionShape3D.disabled = noclip
	if not noclip:
		return false
	var speed = get_move_speed() * noclip_speed_mult
	if Input.is_action_pressed("sprint"):
		speed *= 3.0
	self.velocity = cam_aligned_wish_dir * speed
	global_position += self.velocity * delta
	return true
	
func clip_velocity(normal: Vector3, overbounce : float, _delta : float) -> void:
	var backoff := self.velocity.dot(normal) * overbounce
	if backoff >= 0: return
	var change := normal * backoff
	self.velocity -= change
	var adjust := self.velocity.dot(normal)
	if adjust < 0.0:
		self.velocity -= normal * adjust
		
func is_surface_too_steep(normal : Vector3) -> bool:
	var max_slope_ang_dot = Vector3(0,1,0).rotated(Vector3(1.0,0,0), self.floor_max_angle).dot(Vector3(0,1,0))
	if normal.dot(Vector3(0,1,0)) < max_slope_ang_dot:
		return true
	return false
	
func _run_body_test_motion(from : Transform3D, motion : Vector3, result = null) -> bool:
	if not result: result = PhysicsTestMotionResult3D.new()
	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(self.get_rid(), params, result)
	
func _handle_air_physic(delta) -> void:
	self.velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	var cur_speed_wish_dir = self.velocity.dot(wish_dir)
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	var add_speed_till_cap = capped_speed - cur_speed_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
		
	if is_on_wall():
		if is_surface_too_steep(get_wall_normal()):
			self.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			self.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		clip_velocity(get_wall_normal(), 1, delta)
	
func _handle_ground_physics(delta) -> void:
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_till_cap = get_move_speed() - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * get_move_speed()
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length()- drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed
	_headbob_effect(delta)
	
func _physics_process(delta: float) -> void:
	# Bear Trap
	if _handle_bear_trap(delta):
		return
	
	if is_on_floor(): _last_frame_was_on_floor = Engine.get_physics_frames()
	
	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	cam_aligned_wish_dir = %Camera3D.global_transform.basis * Vector3(input_dir.x, 0., input_dir.y)
	
	_handle_crouch(delta)
	
	if not _handle_noclip(delta) and not _handle_ladder_physics(delta):
		if is_on_floor() or _snapped_to_stairs_last_frame:
			_handle_ground_physics(delta)
		else:
			_handle_air_physic(delta)
		if not _snap_up_stairs_check(delta):
			move_and_slide()
			_snap_down_to_stairs_check()
			
	_slide_camera_smooth_back_to_origin(delta)
	# Pick and Drop Func
	_pick_drop(delta)
	
func _flashlight(delta: float) -> void:
	flashlight.global_transform = Transform3D(
		flashlight.global_transform.basis.slerp(cam.global_transform.basis, delta * flash_light_rotation_smooth),
		flashlight.global_transform.basis.slerp(cam.global_transform.basis, delta * flash_light_position_smooth)
	)

func _drop_item(distance: float, force: float):
	var space_state = get_world_3d().direct_space_state
	var forward = -cam.global_transform.basis.z.normalized()
	var drop_pos = cam.global_transform.origin + forward * distance
	var drop_query = PhysicsRayQueryParameters3D.create(
		cam.global_transform.origin, drop_pos
	)
	drop_query.exclude = [self, hold_item]
	var drop_hit = space_state.intersect_ray(drop_query)
	if drop_hit:
		drop_pos = drop_hit.position + drop_hit.normal * 0.3
	hold_item.global_transform.origin = drop_pos
	hold_item.drop(forward * force)
	hold_item = null

func _pick_drop(_delta):
	var space_state = get_world_3d().direct_space_state
	var from = cam.global_transform.origin
	var to = from + -cam.global_transform.basis.z * 3.0 # raycast length
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 128 + 64 + 16 + 8 + 4
	var result = space_state.intersect_ray(query)
	# Pick
	if Input.is_action_just_pressed("pick"):
		if result and result.collider is Item:
			if hold_item:
				_drop_item(0.5, 4)
			# Pick New Item
			result.collider._pick(hold_point)
			hold_item = result.collider
	# Drop
	if hold_item and Input.is_action_just_pressed("drop"):
		_drop_item(1.0, 2)
	# Ui
	# default crosshair
	mainsight1.visible = true
	mainsight2.visible = false
	item_name_label.text = ""
	# if looking at Item
	if result and result.collider is Item:
		mainsight1.visible = false
		mainsight2.visible = true
		item_name_label.text = result.collider.item_name
	# Show drop text
	drop_text.visible = hold_item != null

func item_bob(delta):
	if weapon_holder:
		var mouse_vel = Input.get_last_mouse_velocity()
		weapon_holder.rotation_degrees.y = lerp(
			weapon_holder.rotation_degrees.y,
			mouse_vel.x * sway_amount,
			sway_speed * delta
		)
		weapon_holder.rotation_degrees.x = lerp(
			weapon_holder.rotation_degrees.x,
			mouse_vel.y * sway_amount,
			sway_speed * delta
		)

func _flash_blood_screen() -> void:
	if blood_tween:
		blood_tween.kill()
	blood_screen.visible = true
	blood_screen.modulate.a = 1.0
	blood_tween = create_tween()
	blood_tween.tween_property(blood_screen, "modulate:a", 0.0, 8.0)\
		.set_trans(Tween.TRANS_EXPO)\
		.set_ease(Tween.EASE_OUT)

func set_trapped(value: bool, trap_ref = null):
	is_trapped = value
	current_trap = trap_ref if value else null
	if value:
		_flash_blood_screen()

func _is_looking_at_trap() -> bool:
	var space_state = get_world_3d().direct_space_state
	var from = cam.global_transform.origin
	var to = from + -cam.global_transform.basis.z * 5.0 # raycast length
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return false
	var hit_collider = result.get("collider")
	return hit_collider != null and hit_collider.is_in_group("traps") and hit_collider == current_trap

func _handle_bear_trap(delta: float) -> bool:
	if not is_trapped:
		return false
	velocity = Vector3.ZERO
	move_and_slide()
	
	var looking := _is_looking_at_trap()
	
	if Input.is_action_just_pressed("interact") and looking and not is_untrapping:
		is_untrapping = true
		untrap_timer = UNTRAP_DURATION
		hold_to_remove.visible = true
		
	if not is_untrapping:
		hold_to_remove.visible = looking
		
	if Input.is_action_pressed("interact") and current_trap and looking:
		if is_untrapping:
			untrap_timer -= delta
			bear_trap_progress.visible = true
			bear_trap_progress.value = (UNTRAP_DURATION - untrap_timer) / UNTRAP_DURATION * 100.0
			
			if untrap_timer <= 0:
				if current_trap:
					current_trap.reset_trap()
				is_trapped = false
				is_untrapping = false
				current_trap = null
				bear_trap_progress.visible = false
				hold_to_remove.visible = false
	else:
		if is_untrapping:
			is_untrapping = false
			untrap_timer = 0.0
			bear_trap_progress.visible = false
	return true

func _connect_item_signals() -> void:
	for item in get_tree().get_nodes_in_group("items"):
		if item is Item:
			item.item_out_of_bounds.connect(_on_item_out_of_bounds)
			
func _on_item_out_of_bounds() -> void:
	show_message("Item fell out of bounds. It has been teleported in a bedroom")
	
func show_message(text: String, duration := 3.0) -> void:
	message_label.text = text
	message_label.visible = true
	await get_tree().create_timer(duration).timeout
	message_label.visible = false
