extends CharacterBody3D

@onready var Head = get_node("%Head")
@onready var Footstep = $Audio/Footstep
@onready var Pickup =  $Audio/Pick_up
var collectible = preload("res://Collectible.tscn")


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var cameraRotation = Vector2(0,0)
var mouseSensitivity = 0.01

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event is InputEventMouseMotion:
		camera_look(event.relative*mouseSensitivity) #handle mouse input

func camera_look(vector: Vector2):
	cameraRotation += vector
	#set angle limit
	cameraRotation.y = clamp(cameraRotation.y, deg_to_rad(-80), deg_to_rad(80))
	
	transform.basis = Basis()
	Head.transform.basis = Basis()
	rotate_object_local(Vector3(0,1,0), -cameraRotation.x) #rotate horizontally
	Head.rotation.x = -cameraRotation.y #rotate vertically

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		if is_on_floor():
			movement_sounds()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func movement_sounds():
	var Sound_Playback = false
	if Footstep.is_playing():
		Sound_Playback = true
	else:
		Sound_Playback = false
	
	if !Sound_Playback:
		Footstep.play()

func Pick_up():
	print("Playing pickup sound")
	Pickup.play()
	
