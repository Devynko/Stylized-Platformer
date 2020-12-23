extends KinematicBody2D

export (float) var health = 5
export (int) var speed = 80
export (int) var jump_speed = -170
export (int) var gravity = 800
var jumpCount = 2
var secondJump = false
var dir = null

var velocity = Vector2.ZERO

export (float, 0, 1.0) var friction = 0.2
export (float, 0, 1.0) var acceleration = 0.15

var state = null
var jump = false
var moveLeft = false
var moveRight = false
var attack = false
var falling = false
var jumping = false
var attackCount = 0
# Retrieve state machine controller
onready var playback = $AnimationTree.get("parameters/playback")

enum {
	MOVE,
	JUMPING,
	ATTACK,
	HURT,
	KNOCKBACK
}



func _ready():
	dir = 0
	state = MOVE

func getInput():
	# JUMP INPUT
	if Input.is_action_just_pressed("jump"):
		jump = true
	if Input.is_action_just_released("jump"):
		jump = false
	# MOVE INPUT
	if Input.is_action_pressed("ui_right"):
		moveRight = true
	if Input.is_action_pressed("ui_left"):
		moveLeft = true
	if Input.is_action_just_released("ui_right"):
		moveRight = false
	if Input.is_action_just_released("ui_left"):
		moveLeft = false




#-------------------
# Callable Functions
#-------------------
#    Attack Functions
func disableHitbox():
	$LeftHitBox/CollisionShape2D.disabled = true
	$RightHitBox/CollisionShape2D.disabled = true
func enableHitbox():
	if dir == -1:
		$LeftHitBox/CollisionShape2D.disabled = false
	elif dir == 1:
		$RightHitBox/CollisionShape2D.disabled = false
func endAttack():
	$LeftHitBox/CollisionShape2D.disabled = true
	$RightHitBox/CollisionShape2D.disabled = true
	state = MOVE
func playWooshSound():
	if not $Woosh.is_playing() and is_on_floor():
		$Woosh.play()
func AttackCount1():
	attackCount = 1
func AttackCount2():
	attackCount = 2
		
func activateHurtState():
	state = HURT
	
# State Functions
func moveState(delta):
	if state == MOVE:
		if moveRight:
			get_node( "Sprite" ).set_flip_h( false )
			playback.travel('Run')
			# PLAY FOOTSTEP AUDIO
			if not $Footstep.is_playing() and is_on_floor():
				$Footstep.play()
			dir = 1
		elif moveLeft:
			get_node( "Sprite" ).set_flip_h( true )
			playback.travel('Run')
			# PLAY FOOTSTEP AUDIO
			if not $Footstep.is_playing() and is_on_floor():
				$Footstep.play()
			dir = -1
		# IF NOT MOVING SET DIRECTION TO NONE
		if !moveLeft and !moveRight:
			#dir = 0
			pass
		if moveLeft or moveRight and !attack and state != 2:
			velocity.x = lerp(velocity.x, dir * speed, acceleration)
		else:
			velocity.x = lerp(velocity.x, 0, friction)
			playback.travel('Idle')

		# IF NOT ON FLOOR, IF FALLING PLAY FALL ANIMATION
		if !is_on_floor():
			if velocity.y < 0:
				jumping = true
			if velocity.y > 20:
				jumping = true
				playback.travel('Fall')

		if is_on_floor():
			jumpCount = 2


		if Input.is_action_just_pressed("jump"):
			if jumpCount == 2:
				playback.travel('Jump')
			elif jumpCount == 1:
				playback.travel('Double Jump')
			state = JUMPING
			
		if Input.is_action_just_pressed("Attack") and is_on_floor() and !attack:
			if attackCount == 0:
				state = ATTACK
			if attackCount == 1:
				velocity.x = 0
				velocity.x = dir * 1500
				state = ATTACK
			elif attackCount == 2:
				velocity.x = 0
				velocity.x = dir * 1000
				state = ATTACK
			elif attackCount == 3:
				attackCount = 0
				velocity.x = 0
				velocity.x = lerp(velocity.x, 0, friction)
				state = MOVE
			

			
		velocity.y += gravity * delta
		velocity = move_and_slide(velocity, Vector2.UP)


func jumpState(delta):
	if jumpCount == 2:
		jumpCount -= 1
		$Jump.play()
		velocity.y = jump_speed
		state = MOVE
	elif jumpCount == 1:
		$Woosh.play()
		jumpCount -= 1
		velocity.y = jump_speed
		state = MOVE
	else:
		state = MOVE
			
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector2(0,-1))
	
func attackState(delta):
	
	if attackCount == 0:
		velocity.x = 0
		$AttackTimer.start()
		attack = true
		
		playback.travel('Attack 1')
	elif attackCount == 1:
		velocity.x = 0
		$AttackTimer.start()
		attack = true
		playback.travel('Attack 2')
		
	elif attackCount == 2:
		velocity.x = 0
		$AttackTimer.start()
		attack = true
		playback.travel('Attack 3')
		
	else: 
		velocity.x = 0
		
	velocity.y += gravity * delta
	
	


func hurt(delta):
	if health > 0:
		health -= 1
		Input.start_joy_vibration(0, 1, 1, .5)
		$HealthBar/Progress.value = health
		#playback.travel('Hurt')
		$Timers/KnockBackTimer.start()
		state = MOVE
		#state = KNOCKBACK
	else:
		pass
	
	
func knockBack(delta):
#	if player.dir == 1:
#		get_node( "Sprite" ).set_flip_h( true )
#		knockBackDir = 1
#	if player.dir == -1:
#		get_node( "Sprite" ).set_flip_h( false )
#		knockBackDir = -1
	pass

#	velocity.x = lerp(velocity.x, knockBackDir * speed, acceleration)
#	velocity.y += gravity * delta
#	velocity = move_and_slide(velocity, Vector2.UP)
		
		
func _physics_process(delta):
	getInput()
	match state:
		MOVE:
			moveState(delta)
		JUMPING:
			jumpState(delta)
		ATTACK:
			attackState(delta)
		HURT:
			hurt(delta)
	print ($AttackTimer.time_left)
	if attack and state == 0:
		if attackCount == 0:
			attackCount = 1
			attack = false
		elif attackCount == 1:
			attackCount = 2
			attack = false
		elif attackCount == 2:
			attackCount = 3
			attack = false
		elif attackCount == 3:
			attackCount = 0
			attack = false
#--------
# Signals
#--------

# When You attack something on the Left
func _on_LeftHitBox_area_entered(area):
	if "Enemy-Hitbox" in area.name:
		# This changes the enemy's state to HURT
		area.get_parent().state = 4
		Input.start_joy_vibration(0, 1, 1, .5)

# When You attack something on the Right
func _on_RightHitBox_area_entered(area):
	if "Enemy-Hitbox" in area.name:
		# This changes the enemy's state to HURT
		area.get_parent().state = 4
		Input.start_joy_vibration(0, 1, 1, .5)


func _on_BattleMusicTimer_timeout():
	print ("TIMER TIME OUT")
	if $BattleMusic.is_playing():
		$BattleMusic.stop()
		$Music.play()


func _on_AttackTimer_timeout():
	attackCount = 0
	velocity.x = 0
	attack = false
