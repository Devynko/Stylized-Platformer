extends KinematicBody2D


# Declare member variables here.
export var debug = false

export (float) var health = 4.0
export (int) var speed = 1200
export (int) var gravity = 800
export (float, 0, 1.0) var friction = 0.2
export (float, 0, 1.0) var acceleration = 0.25

var dir = -1
var knockBackDir = 1
var moveLeft = false
var moveRight = false
var velocity = Vector2.ZERO
var isKnockBack = false
var dead = false
var playerHit = false
var followLeft = false
var followRight = false
var allowedToAttack = true
var attackReady = false


onready var playback = $AnimationTree.get("parameters/playback")
onready var player = get_tree().get_root().get_node("Game/Player")
onready var music = get_tree().get_root().get_node("Game/Player/Music")
onready var BattleMusic = get_tree().get_root().get_node("Game/Player/BattleMusic")


# STATES
var state = WONDER
enum {
	WONDER,
	FOLLOW,
	READYATTACK,
	ATTACK,
	HURT,
	KNOCKBACK,
	DEAD
}


func setStateWonder():
	state = WONDER
func setStateAttack():
	state = ATTACK
func queueFree():
	queue_free()
	
#    Attack Functions
func disableHitbox():
	$LeftAttackBox/CollisionShape2D.disabled = true
	$RightAttackBox/CollisionShape2D.disabled = true
func enableHitbox():
	if dir == -1:
		$LeftAttackBox/CollisionShape2D.disabled = false
	elif dir == 1:
		$RightAttackBox/CollisionShape2D.disabled = false
func disableAttack():
	allowedToAttack = false

# Called when the node enters the scene tree for the first time.
func _ready():
	moveLeft = true
	
func wonder(delta):
	
	attackReady = false
	if moveLeft or moveRight:
		playback.travel('Walk')
		velocity.x = lerp(velocity.x, dir * speed, acceleration)
	else:
		velocity.x = lerp(velocity.x, 0, friction)
	
	if moveLeft:
		get_node( "Sprite" ).set_flip_h( true )
	if moveRight:
		get_node( "Sprite" ).set_flip_h( false )
	
	if not $RayCastLeft.is_colliding():
		dir = 1
		get_node( "Sprite" ).set_flip_h( false )
		moveRight = true
		moveLeft = false
	if not $RayCastRight.is_colliding():
		dir = -1
		get_node( "Sprite" ).set_flip_h( true )
		moveRight = false
		moveLeft = true
	
	if $RayCastWallLeft.is_colliding():
		dir = 1
		get_node( "Sprite" ).set_flip_h( false )
		moveRight = true
		moveLeft = false
	if $RayCastWallRight.is_colliding():
		dir = -1
		get_node( "Sprite" ).set_flip_h( true )
		moveRight = false
		moveLeft = true
	if isKnockBack:
		if knockBackDir == -1:
			dir = 1
			get_node( "Sprite" ).set_flip_h( false )
			moveRight = true
			moveLeft = false
			isKnockBack = false
		if knockBackDir == 1:
			dir = -1
			get_node( "Sprite" ).set_flip_h( true )
			moveRight = false
			moveLeft = true
			isKnockBack = false

	
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	
func follow(delta):
	if moveLeft or moveRight:
		playback.travel('Walk')
		velocity.x = lerp(velocity.x, dir * speed, acceleration)
	else:
		velocity.x = lerp(velocity.x, 0, friction)
	
	if moveLeft:
		get_node( "Sprite" ).set_flip_h( true )
	if moveRight:
		get_node( "Sprite" ).set_flip_h( false )
	
	if not $RayCastLeft.is_colliding():
		dir = 1
		get_node( "Sprite" ).set_flip_h( false )
		moveRight = true
		moveLeft = false
	if not $RayCastRight.is_colliding():
		dir = -1
		get_node( "Sprite" ).set_flip_h( true )
		moveRight = false
		moveLeft = true
	
	if $RayCastWallLeft.is_colliding():
		dir = 1
		get_node( "Sprite" ).set_flip_h( false )
		moveRight = true
		moveLeft = false
	if $RayCastWallRight.is_colliding():
		dir = -1
		get_node( "Sprite" ).set_flip_h( true )
		moveRight = false
		moveLeft = true
	if isKnockBack:
		if knockBackDir == -1:
			dir = 1
			get_node( "Sprite" ).set_flip_h( false )
			moveRight = true
			moveLeft = false
			isKnockBack = false
		if knockBackDir == 1:
			dir = -1
			get_node( "Sprite" ).set_flip_h( true )
			moveRight = false
			moveLeft = true
			isKnockBack = false
	if followLeft:
			dir = -1
			get_node( "Sprite" ).set_flip_h( true )
			moveRight = false
			moveLeft = true
			isKnockBack = false
	if followRight:
			dir = 1
			get_node( "Sprite" ).set_flip_h( false )
			moveRight = true
			moveLeft = false
			isKnockBack = false
	if not followLeft and not followRight:
		state = WONDER

	
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)	
	

func hurt(delta):
	if health > 0:
		$Healthbar.visible = true
		health -= 1
		$Healthbar/Progress.value = health
		playback.travel('Hurt')
		$KnockBackTimer.start()
		$Hurt.play()
		$SwordHit.play()
		state = KNOCKBACK
	
	
func knockBack(delta):
	if player.dir == 1:
		get_node( "Sprite" ).set_flip_h( true )
		knockBackDir = 1
	if player.dir == -1:
		get_node( "Sprite" ).set_flip_h( false )
		knockBackDir = -1
#	if dir == 1:
#		knockBackDir = -1
#	if dir == -1:
#		knockBackDir = 1

	velocity.x = lerp(velocity.x, knockBackDir * speed, acceleration)
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2.UP)
	
func readyAttack():
	attackReady = true
	playback.travel('Ready Attack')
	velocity.x = 0
	
	
func attack():
	$AttackTimer.start()
	playback.travel('Attack')
	
func dead():
	if not $Die.is_playing() and !dead:
		$Die.play()
	dead = true
	playback.travel('Die')
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	match state:
		WONDER:
			wonder(delta)
			if dir == -1:
				get_node( "Sprite" ).set_flip_h( true )
			if dir == 1:
				get_node( "Sprite" ).set_flip_h( false )
		HURT:
			hurt(delta)
			#print ("HURT")
		KNOCKBACK:
			knockBack(delta)
			#print ("KNOCK BACK")
		READYATTACK:
			readyAttack()
		ATTACK:
			attack()
		DEAD:
			dead()
		FOLLOW:
			follow(delta)
			if dir == -1:
				get_node( "Sprite" ).set_flip_h( true )
			if dir == 1:
				get_node( "Sprite" ).set_flip_h( false )
	if debug:
		print (dir)
		

	# Kills Mushroom Enemy
	if health == 0:
		state = DEAD
		



func _on_KnockBackTimer_timeout():
	print ("Timer stopped")
	velocity.x = 0
	isKnockBack = true
	state = WONDER

# SEES PLAYER ON THE LEFT AND FOLLOWS
func _on_PlayerDetectionLeft_body_entered(body):
	if "Player" in body.name:
		get_tree().get_root().get_node("Game/Player/BattleMusic/BattleMusicTimer").start()
		if not BattleMusic.is_playing() and !dead:
			music.stop()
			BattleMusic.play()
		if !attackReady:
			followLeft = true
			state = FOLLOW

# SEES PLAYER ON THE RIGHT AND FOLLOWS
func _on_PlayerDetectionRight_body_entered(body):
	if "Player" in body.name:
		get_tree().get_root().get_node("Game/Player/BattleMusic/BattleMusicTimer").start()
		if not BattleMusic.is_playing() and !dead:
			music.stop()
			BattleMusic.play()
		if !attackReady:
			followRight = true
			state = FOLLOW

		

func _on_PlayerDetectionLeft_body_exited(body):
	followLeft = false


func _on_PlayerDetectionRight_body_exited(body):
	followRight = false

# ATTACK READY SIGNALS
func _on_AttackReadyLeft_body_entered(body):
	if "Player" in body.name and allowedToAttack and not attackReady:
		dir = -1
		get_node( "Sprite" ).set_flip_h( true )
		state = READYATTACK
func _on_AttackReadyRight_body_entered(body):
	if "Player" in body.name and allowedToAttack and not attackReady:
		dir = 1
		get_node( "Sprite" ).set_flip_h( false )
		state = READYATTACK


func _on_LeftAttackBox_body_entered(body):
	playerHit = true
	if "Player" in body.name and dir == -1:
		body.activateHurtState()


func _on_RightAttackBox_body_entered(body):
	
	if "Player" in body.name and dir == 1:
		body.activateHurtState()


func _on_LeftAttackBox_body_exited(body):
	playerHit = false


func _on_RightAttackBox_body_exited(body):
	playerHit = false




func _on_AttackTimer_timeout():
	allowedToAttack = true
