extends Camera3D

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Hello from camera!")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventMouseMotion:
		var x_rad = -deg_to_rad(event.relative.x)
		var y_rad = -deg_to_rad(event.relative.y)
		rotate(
			Vector3(0.0, 1.0, 0.0),
			x_rad)
