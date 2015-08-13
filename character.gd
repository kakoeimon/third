
extends RigidBody


var max_walk_vel = 10
var max_aim_vel = 5
var move_forward_force = 1
var move_backward_force = -1
var accel = 1.1
var on_floor = false
var jump_speed = 10
var double_jump = false

func _ready():
	# Initialization here
	Input.set_mouse_mode(2)
	get_node("jump_ray").add_exception(self)
	set_process_input(true)
	set_fixed_process(true)
	pass

func _fixed_process(delta):
	get_node("InterpolatedCamera/Label").set_text(var2str(OS.get_frames_per_second()))
	var max_vel = 0
	var aiming = false
	if Input.is_action_pressed("aim"):
		var aim_node = get_node("BakedLightSampler/shape/Spatial/metarig/Skeleton/BoneAttachment/aim_target")
		#aim_node.set_rotation(get_node("yaw/pitch").get_rotation())
		get_node("InterpolatedCamera").set_target(aim_node)
		aiming = true
		max_vel = max_aim_vel
	else:
		aiming = false
		get_node("InterpolatedCamera").set_target(get_node("yaw/pitch/walk_target"))
		max_vel = max_walk_vel
	var velocity = get_linear_velocity() * 0.9
	#get_node("yaw/camera/Label").set_text("fps: " + var2str(OS.get_frames_per_second()))
	var direction = Vector3()
	var aim = get_node("yaw").get_global_transform().basis
	if Input.is_action_pressed("forward"):
		direction += aim[2]
	if Input.is_action_pressed("backward"):
		direction -= aim[2]
	if Input.is_action_pressed("right"):
		direction -= aim[0]
	if Input.is_action_pressed("left"):
		direction += aim[0]
	
	
	direction = direction.normalized() * accel
	velocity.y = 0

	velocity += direction
	var hspeed = velocity.length()
	if velocity.length() > max_vel:
		velocity = velocity.normalized() * max_vel
	
	
	velocity.y = get_linear_velocity().y
	set_linear_velocity(velocity)	
	
	if get_node("jump_ray").is_colliding():
		on_floor = true
		double_jump = true
	else:
		on_floor = false
	
	var anim = get_node("AnimationTreePlayer")
	if on_floor:
		#anim.transition_node_set_xfade_time("transition", 0.2)
		anim.transition_node_set_current("transition",0)
		anim.blend2_node_set_amount("run", hspeed / max_walk_vel)
		var p = get_node("yaw/pitch").get_rotation()
		if aiming:
			anim.blend2_node_set_amount("aim_blend", 1.0)
			print(p.x)
			if p.x >= 2.3 and p.x > 0:
				var amount = 1 + (PI - p.x) / PI * 4
				
				anim.timeseek_node_seek("aim_seek" , min(amount, 2.0))
			if p.x <= -2.3 and p.x <= 0:
				var amount = 1 - (PI + p.x) / PI * 4
				print(amount)
				anim.timeseek_node_seek("aim_seek" , max(amount, 0.0))

		else:
			anim.blend2_node_set_amount("aim_blend", 0.0)
	else:
		var vy = get_linear_velocity().y
		#anim.transition_node_set_xfade_time("transition", 0.5)
		if vy > 3:
			anim.transition_node_set_current("transition", 1)
			
		else:
			anim.transition_node_set_current("transition", 2)
			


func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		var ms = Input.get_mouse_speed()
		var dx = get_node("yaw").get_transform().rotated(Vector3(0,1,0), deg2rad(ms.x) / 1000)
		var dy = get_node("yaw/pitch").get_transform().rotated(Vector3(1,0,0), deg2rad(ms.y) / 1000)

		get_node("yaw").set_transform(dx)
		get_node("yaw/pitch").set_transform(dy)
		var p = get_node("yaw/pitch").get_rotation()
		if p.x < 2.3 and p.x > 0:
			p.x = 2.3
		if p.x > -2.3 and p.x < 0:
			p.x = -2.3	
		get_node("yaw/pitch").set_rotation(p)
		var shape = get_node("BakedLightSampler/shape")
		shape.set_transform(get_node("yaw").get_transform())
		

		
	if event.is_action("jump") and event.is_pressed() and !event.is_echo():
		if on_floor:
			var v1 = get_linear_velocity()
			v1.y = jump_speed
			set_linear_velocity(v1)
		elif double_jump:
			var v1 = get_linear_velocity()
			v1.y = jump_speed
			set_linear_velocity(v1)	
			double_jump = false
	
