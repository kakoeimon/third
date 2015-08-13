
extends RigidBody



var max_acceleration = 0.2
var target

var velocity = Vector3()
var max_velocity = 10.0
var steering_linear = Vector3()
var steering_angular = 0
var shape #this is the 3d model or skeleton that we will rotate for aling, face etc 
var group

func _steering_fixed_process(delta):
	velocity += steering_linear
	steering_linear = Vector3()
	if velocity.length() > max_velocity:
		velocity = velocity.normalized() * max_velocity
	var y = get_linear_velocity().y	
	velocity.y = y
	set_linear_velocity(velocity)
	#set_angular_velocity(Vector3(0,steering_angular,0))

func reset_steering():
	velocity = get_linear_velocity()
	steering_angular = 0


func seek(target_pos = target.get_translation()):
	var l = (target_pos - get_translation()).normalized() * max_acceleration
	steering_linear += l
	
func flee(target_pos = target.get_translation()):
	var l = (get_translation() - target_pos).normalized() * max_acceleration
	steering_linear += l

func arrive(target_pos = target.get_translation()):
	var target_radius = 1
	var slow_radius = 4
	var time_to_target = 0.1
	var target_speed = 1
	
	var direction = target_pos - get_translation()
	var distance = direction.length()
	
	if distance < target_radius:
		return
		
	if distance > slow_radius:
		target_speed = max_velocity
	else:
		target_speed = max_velocity * distance / slow_radius
		
	var target_velocity = direction.normalized() * target_speed
	
	var l = target_velocity - get_linear_velocity()
	l /= time_to_target
	
	if l.length() > max_acceleration:
		l = l.normalized() * max_acceleration
	
	steering_linear += l


func velocity_match():
	var time_to_target = 0.1
	var linear = target.get_linear_velocity() - get_linear_velocity()
	linear /= time_to_target
	
	if linear.length() > max_acceleration:
		linear = linear.normalized() * max_acceleration
		
	steering_linear += linear

func pursue(target_pos = target.get_translation()):
	var max_prediction = 10
	var pursue_target_pos = Vector3()
	
	var direction = target_pos - get_translation()
	var distance = direction.length()
	
	var speed = target.get_linear_velocity().length()
	var prediction
	if speed <= distance / max_prediction:
		prediction = max_prediction
	else:
		prediction = distance / speed
		
	var pursue_pos = target_pos + target.get_linear_velocity() * prediction
	
	var linear = (pursue_pos - get_translation()).normalized() * max_acceleration
	steering_linear += linear

func aling(target = target.shape):
	#I was unable to find a way to interpolate with angular velocity the rigidbody. 
	#So I just rotate the graphic aka shape
	var acc = 0.1
	var q1 = Quat(shape.get_transform().basis)
	var q2 = Quat(target.get_transform().basis)
	var t = Transform(q1.slerp(q2, acc))
	shape.set_transform(t)


func face(target_pos = target.get_translation()):
	var direction = target_pos - get_translation()
	var acc = 0.1
	if direction.length() == 0:
		return
	var angle = atan2(-direction.x, direction.z)
	var q1 = Quat(shape.get_transform().basis)
	var q2 = Quat(Vector3(0,1,0),angle)
	var t = Transform(q1.slerp(q2, acc))
	shape.set_transform(t)

func look_where_you_are_going():
	var velocity = get_linear_velocity()
	var acc = 0.1
	if velocity.length() == 0:
		return 0	
	var angle = atan2(-velocity.x, velocity.z)
	var q1 = Quat(shape.get_transform().basis)
	var q2 = Quat(Vector3(0,1,0),angle)
	var t = Transform(q1.slerp(q2, acc))
	shape.set_transform(t)
	
func wander():
	var wander_offset = get_transform().basis.z

	var angle = rand_range(-PI , PI)


	wander_offset = wander_offset.rotated(Vector3(0,1,0), angle)
	var linear = wander_offset.normalized() * max_acceleration
	steering_linear += linear
	
func separation(sep_group = group):
	var threshold = 4
	var dt = threshold * threshold
	var decay_coefficient = 0.01
	var targets = get_tree().get_nodes_in_group(sep_group)
	for t in targets:
		if get_instance_ID() != t.get_instance_ID():
			var direction = get_translation() - t.get_translation()
			var dd = direction.length_squared()

			if dd < dt:
				var strength = min(decay_coefficient * dd, max_acceleration)
				strength = max_acceleration * 2
				steering_linear += direction.normalized() * strength
				
