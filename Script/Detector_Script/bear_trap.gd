extends RigidBody3D

signal trap_triggered(position: Vector3)
@onready var anim_tree: AnimationTree = %AnimationTree
@onready var step_sound: AudioStreamPlayer3D = %step_sound
@onready var escape_sound : AudioStreamPlayer3D = %escape_sound
var is_triggered := false

func _ready() -> void:
	add_to_group("traps")
	anim_tree.set("parameters/conditions/BearTrapActivate", false)

func _on_bear_trap_detector_body_entered(body: Node3D) -> void:
	if is_triggered:
		return
	if body.is_in_group("players") or body.is_in_group("items"):
		is_triggered = true
		anim_tree.set("parameters/conditions/BearTrapActivate", true)
		if step_sound:
			step_sound.play()
		# Freeze Player
		if body.has_method("set_trapped"):
			body.set_trapped(true, self)
		# Emit signal
		emit_signal("trap_triggered", global_position)

func reset_trap() -> void:
	is_triggered = false
	anim_tree.set("parameters/conditions/BearTrapActivate", false)
	anim_tree.set("parameters/conditions/BearTrapDeactivate", true)
	# Play escape sound
	if escape_sound:
		escape_sound.play()
	await get_tree().create_timer(0.2).timeout
	anim_tree.set("parameters/conditions/BearTrapDeactivate", false)
