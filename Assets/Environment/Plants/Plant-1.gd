extends Node2D


# Declare member variables here. Examples:
# var a = 2
export(float) var pitch = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Wiggle.pitch_scale = pitch


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Area2D_body_entered(body):
	if "Player" in body.name:
		$AnimationPlayer.play("Wiggle")
		$Wiggle.play()
		Input.start_joy_vibration(0, .1, .1, .2)
	if "Mushroom-Enemy" in body.name:
		$AnimationPlayer.play("Wiggle")
		$Wiggle.play()
