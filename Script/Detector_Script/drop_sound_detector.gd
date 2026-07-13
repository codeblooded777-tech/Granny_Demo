extends Area3D
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
