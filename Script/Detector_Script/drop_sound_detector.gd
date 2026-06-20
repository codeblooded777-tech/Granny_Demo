extends Area3D

@export var drop_sound: AudioStream
@onready var audio: AudioStreamPlayer3D = AudioStreamPlayer3D.new()

func _ready() -> void:
	add_child(audio)
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node3D) -> void:
	var parent = get_parent()
	if parent.just_dropped and not parent._is_teleporting:
		_play_land()
		parent.just_dropped = false

func _play_land() -> void:
	if not audio.playing and drop_sound:
		audio.stream = drop_sound
		#audio.volume_db = 0.0 
		audio.play()
