extends Node3D

@onready var anim_player = %Bell_AnimationPlayer
@onready var audio_player = %Bell_AudioStreamPlayer3D
@onready var area = %Bell_Area3D

func _ready():
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("players"):
		anim_player.stop()
		anim_player.play("bell_rang")
		audio_player.play()
