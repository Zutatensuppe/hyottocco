extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (PackedScene) var arrow
export (NodePath) var animationtree

onready var _anim_tree = get_node(animationtree)

var direction = Vector3.FORWARD
var gravity = 20
var movement_speed = 10
var jump = 10

var gravity_vec = Vector3()

var angular_accel = 7
var fov_accel = 20

var need_release = false

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("players")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func shoot_arrow(timeLeft):
	var shoot_origin = $shootFrom.global_transform.origin
	var mouse_position = get_tree().root.get_mouse_position()
	var ray_from = $Camroot/h/v/Camera.project_ray_origin(mouse_position)
	var ray_dir = $Camroot/h/v/Camera.project_ray_normal(mouse_position)
	
	var shoot_target
	var collision = get_world().direct_space_state.intersect_ray(ray_from, ray_from + ray_dir * 1000, [self], 0b11)
	if collision.empty():
		shoot_target = ray_from + ray_dir * 1000
	else:
		shoot_target = collision.position

	var shoot_dir = (shoot_target - shoot_origin).normalized()
	
	var b = arrow.instance()
	
	var max_time_left = 0.5
	var MIN_VELOCITY = 50
	var MAX_VELOCITY = 110
	var velocity = MIN_VELOCITY + (max_time_left - timeLeft) * 2 * (MAX_VELOCITY - MIN_VELOCITY)
	
	b.muzzle_velocity = velocity
	
	owner.add_child(b)
	b.global_transform.origin = shoot_origin
	b.look_at(shoot_origin + shoot_dir, Vector3.UP)
	b.global_transform.origin.move_toward(shoot_origin + shoot_dir, 1)
	b.velocity = -b.transform.basis.z * b.muzzle_velocity
	
	need_release = true
	$ShootTimer.start(.3)

func start_aiming(delta):
	if $AimTimer.is_stopped():
		$AimTimer.start(.5)
		
	$TextureProgress.value = (0.5 - $AimTimer.time_left) / 0.5 * 100
	Engine.time_scale = 0.2
	$Camroot/h/v/Camera.fov = lerp(
		$Camroot/h/v/Camera.fov,
		30,
		delta * fov_accel * 2
	)

func stop_aiming(delta):
	if not $AimTimer.is_stopped():
		$AimTimer.stop()
	$TextureProgress.value = 0
	Engine.time_scale = 1.0
	$Camroot/h/v/Camera.fov = lerp(
		$Camroot/h/v/Camera.fov,
		70,
		delta * fov_accel
	)

func _physics_process(delta):
	var aiming = false
	var jumping = false 
	var running = false 
	if $ShootTimer.time_left == 0 and not need_release:
		# may shoot	
		if Input.is_action_pressed("shoot"):
			start_aiming(delta)
			aiming = true
		elif Input.is_action_just_released("shoot"):
			shoot_arrow($AimTimer.time_left)
	else:
		# may not shoot
		stop_aiming(delta)
	
	if need_release and not Input.is_action_pressed("shoot"):
		need_release = false
	
	if (Input.is_action_pressed("move_right") ||
		Input.is_action_pressed("move_left") || 
		Input.is_action_pressed("move_forward") || 
		Input.is_action_pressed("move_backward")):
		running = true
		var h_rot = $Camroot/h.global_transform.basis.get_euler().y
		
		direction = Vector3(
			Input.get_action_raw_strength("move_right") - Input.get_action_raw_strength("move_left"),
			0,
			Input.get_action_raw_strength("move_backward") - Input.get_action_raw_strength("move_forward")
		).rotated(Vector3.UP, h_rot).normalized()
		
		$archer.rotation.y = lerp_angle($archer.rotation.y, atan2(direction.x, direction.z), delta * angular_accel)
	else:
		direction = Vector3()
	
	if not is_on_floor():
		gravity_vec += Vector3.DOWN * gravity * delta
		jumping = true
	else:
		gravity_vec = -get_floor_normal() * gravity
		
		if Input.is_action_just_pressed("jump") and is_on_floor():
			gravity_vec = Vector3.UP * jump
			jumping = true
	
	var movement = direction * movement_speed
	movement.y = gravity_vec.y
	
	move_and_slide(movement, Vector3.UP)
	
	if aiming:
		_anim_tree["parameters/playback"].travel("aim")
	elif jumping:
		_anim_tree["parameters/playback"].travel("jump")
	elif running:
		_anim_tree["parameters/playback"].travel("run")
	else:
		_anim_tree["parameters/playback"].travel("idle")

func _on_AimTimer_timeout():
	shoot_arrow(0)


func _on_ShootTimer_timeout():
	$ShootTimer.stop()