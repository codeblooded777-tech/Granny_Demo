extends RigidBody3D
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
