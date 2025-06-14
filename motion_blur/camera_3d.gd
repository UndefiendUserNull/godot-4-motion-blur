extends Camera3D


@export var senstivvity : float  = 2.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * senstivvity)) 
		rotate_x(deg_to_rad(-event.relative.y * senstivvity))
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
