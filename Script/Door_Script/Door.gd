extends StaticBody3D
class_name Door
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

enum State { CLOSED, OPEN, LOCKED }

# Animation setup
@export_group("Animation Setup")
@export var anim_player: AnimationPlayer
@export var anim_open: String = "open"
@export var anim_close: String = "close"
@export var anim_lock: String = "lock"

# Audio setup
@export_group("Audio Setup")
@export var audio_player: AudioStreamPlayer3D
@export var sound_open: AudioStream
@export var sound_close: AudioStream
@export var sound_locked: AudioStream

# Lock configuration 
@export_group("Lock Configuration")
@export var required_key: String = ""
@export var locked_message: String = ""
@export var locked_by_default: bool = false

@export_group("Drawer Configuration") # Keep this for now. We'll add something here in the next tutorial.

# Runtime state
var state: State = State.CLOSED  # door current state
var _is_animating: bool = false  # Prevents interactions while the door is animating

# Shared lock for AnimationPlayers
# Prevents doors that share the same AnimationPlayer from
# interrupting each other's animations
# This static dictionary tracks which AnimationPlayers are busy
static var _busy_anim_players: Dictionary = {} # Maps AnimationPlayer

# Wait until this AnimationPlayer is free
static func _acquire(anim_play: AnimationPlayer) -> void:
	if anim_play == null:
		return
	while _busy_anim_players.get(anim_play, false):
		await anim_play.animation_finished
	_busy_anim_players[anim_play] = true

# Release the AnimationPlayer lock
static func _release(anim_play: AnimationPlayer) -> void:
	if anim_play == null:
		return
	_busy_anim_players[anim_play] = false

# Called when the node enters the scene tree
func _ready() -> void:
	if locked_by_default:
		state = State.LOCKED

# Handle player interaction
func interact() -> void:
	match state:
		State.CLOSED:
			open()
		State.OPEN:
			close()
		State.LOCKED:
			_on_locked()

# Try unlocking with an item
func try_unlock_with_item(item: Item) -> String:
	if required_key == "":
		return ""
	if item.item_name != required_key:
		_play_sound(sound_locked)
		_play(anim_lock)
		return locked_message
	
	unlock()
	open()
	return ""

# Open the door
func open() -> void:
	if state == State.LOCKED or _is_animating:
		return
	state = State.OPEN
	_is_animating = true
	set_collision_layer_value(7, false)
	
	await _acquire(anim_player)
	
	_play_sound(sound_open)
	_play(anim_open)
	if anim_player:
		await anim_player.animation_finished
		
	_release(anim_player)
	_is_animating = false
	set_collision_layer_value(7, true)

# Close the door
func close() -> void:
	if state == State.LOCKED or _is_animating:
		return
	state = State.CLOSED
	_is_animating = true
	set_collision_layer_value(7, false)
	
	await _acquire(anim_player)
	_play_sound(sound_close)
	_play(anim_close)
	
	if anim_player:
		await anim_player.animation_finished
	set_collision_layer_value(7, true)
	
	_release(anim_player)
	_is_animating = false

# Lock the door
func lock() -> void:
	state = State.LOCKED
	_busy_anim_players[anim_player] = true
	_is_animating = false
	_play(anim_lock)
	if anim_player and anim_lock != "":
		await anim_player.animation_finished
	_release(anim_player)

# Unlocks the door 
func unlock() -> void:
	state = State.CLOSED

# Check if the door is locked
func is_locked() -> bool:
	return state == State.LOCKED

#  Helper function for playing animation
func _play(anim_name: String) -> void:
	if anim_player == null:
		push_error("Door: no AnimationPlayer assigned on " + name)
		return
	if anim_name == "":
		return
	if not anim_player.has_animation(anim_name):
		push_error("Door: animation '" + anim_name + "' not found on " + name)
		return
	anim_player.play(anim_name)

# Helper function for playing sounds
func _play_sound(stream: AudioStream) -> void:
	if audio_player == null:
		push_error("Door: no AudioStreamPlayer3D assigned on " + name)
		return
	if stream == null:
		return
	audio_player.stop()
	audio_player.stream = stream
	audio_player.play()

# Handle locked interaction.
func _on_locked() -> void:
	if _is_animating:
		return
	_is_animating = true
	_play_sound(sound_locked)
	_play(anim_lock)
	if anim_player and anim_lock != "" and anim_player.has_animation(anim_lock):
		await anim_player.animation_finished
	_is_animating = false
