extends MeshInstance3D

var cam_pos_prev := Vector3()
var cam_rot_prev := Quaternion()

func _ready():
	var cam = get_parent()
	if cam is Camera3D:
		cam_pos_prev = cam.global_transform.origin
		cam_rot_prev = Quaternion(cam.global_transform.basis)

func _process(delta):
	if delta <= 0:
		return
		
	var delta_clamped = clamp(delta, 1.0/120.0, 1.0/30.0)
	var mat = mesh.surface_get_material(0) as ShaderMaterial
	if !mat:
		return
		
	var cam = get_parent()
	if !(cam is Camera3D):
		return
	
	# Linear velocity (delta-based)
	var new_pos = cam.global_transform.origin
	var velocity = (new_pos - cam_pos_prev) / delta
	
	# Angular velocity
	var new_rot = Quaternion(cam.global_transform.basis)
	var rot_diff = new_rot * cam_rot_prev.inverse()
	
	# Convert difference quaternion to axis-angle
	var angle = 2 * acos(rot_diff.w)
	var axis = Vector3(rot_diff.x, rot_diff.y, rot_diff.z).normalized()
	var ang_vel = axis * (angle / delta)
	
	mat.set_shader_parameter("linear_velocity", velocity / delta_clamped)
	mat.set_shader_parameter("angular_velocity", ang_vel / delta_clamped)
		
	cam_pos_prev = new_pos
	cam_rot_prev = new_rot
