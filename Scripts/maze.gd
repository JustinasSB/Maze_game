extends Node3D

var wall_prefab = preload("res://Scenes/Wall.tscn")
var collectible = preload("res://Scenes/Collectible.tscn")
var pedestal = preload("res://Scenes/Pedestal.tscn")
var end_game_trigger = preload("res://Scenes/end_game_trigger.tscn")
var maze_size
var collectible_location
var collectibles_collected:int = 0
var collectibles_to_gen_end = 1

var player: CharacterBody3D #player reference

const DIRECTIONS = [
	Vector2(0, 2),   # Up
	Vector2(0, -2),  # Down
	Vector2(2, 0),   # Right
	Vector2(-2, 0)   # Left
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	maze_size = 11 #odd size to avoid missing side walls
	var result = maze_gen(false)
	var maze_array = result[0]
	collectible_location = result[1]
	draw_maze(maze_array)
	draw_pedestal(collectible_location.x,collectible_location.y, maze_array)
	#coordinates scaled to match wall scale
	#wall scaled to make corridors wider
	create_collectible(collectible_location.x*2,collectible_location.y*2)

#Create a maze from given grid
func draw_maze(maze_array):
	for i in range(0,maze_size):
		for o in range(0,maze_size):
			if maze_array[i][o] == 0:
				create_wall(i*2,o*2)

func create_wall(x,z):
	var inst:Node3D = wall_prefab.instantiate()
	self.add_child(inst)
	inst.scale.y = 5
	inst.position = Vector3(x,1,z)

func create_collectible(x,z):
	var inst:Node3D = collectible.instantiate()
	self.add_child(inst)
	inst.position = Vector3(x,2,z)
	
	#add collision detection
	var area = inst.get_node("Area3D")
	area.connect("area_entered",_on_area_3d_area_entered)
	
	print("Collectible spawned at: " , x , " " , z)

func create_end_game_trigger(location: Vector3) -> void:
	#instantiate end game trigger
	var trigger_instance = end_game_trigger.instantiate()
	#add to scene and set position to given location
	self.add_child(trigger_instance)
	trigger_instance.position = location
	var area = trigger_instance.get_node("Trigger")
	area.connect("area_entered",_on_end_game_trigger_entered)

#TODO: there are currently no areas for raycast to detect ground level
func get_ground_position(x, z):
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(Vector3(x, 10, z),Vector3(x, -10, z))
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space_state.intersect_ray(query)
	if result:
		print("detected")
		return result.position
	else:
		return Vector3(x, 0, z)

func draw_pedestal(x,z, maze):
	var inst:Node3D = pedestal.instantiate()
	self.add_child(inst)
	inst.position = get_ground_position(x*2,z*2)
	#make sure the pedestal always faces the open corridor
	if maze[x+1][z] == 1:
		inst.rotate_y(deg_to_rad(270))
	elif maze[x-1][z] == 1:
		inst.rotate_y(deg_to_rad(90))
	elif maze[x][z+1] == 1:
		inst.rotate_y(deg_to_rad(180))
	elif maze[x][z-1] == 1:
		inst.rotate_y(deg_to_rad(0))

func maze_gen(with_params, pos = Vector2(1,1), CreateExit=false):
	var maze = initialize_maze_array()
	var cur_x
	var cur_y
	#create entrance and set maze propagation point
	if !with_params:
		#break a wall to make an entrance
		maze[1][0] = 1
		maze[1][1] = 1
		cur_x = 1
		cur_y = 1 
	else:
		maze[position.x][position.y] = 1
		if CreateExit:
			maze[maze_size-2][maze_size-1] = 1
			create_end_game_trigger(Vector3((maze_size-2)*2,0,(maze_size-1)*2))
		cur_x = pos.x
		cur_y = pos.y
	
	#initialize direction enum for randomization
	var direction = DIRECTIONS.duplicate()
	
	#create history for backtracking when deadends are reached
	var history = []
	history.append(Vector2(cur_x,cur_y))
	var i:int = 1
	
	#variables to set collectible location
	var collectible_location
	var max = 0
	
	#booleans for halting logic
	var keep_searching = true
	var updated = false
	
	while keep_searching:
		direction.shuffle()
		updated = false
		#travel
		for Dir in direction:
			if valid_placement(maze,cur_x,cur_y,Dir):
				updated = true
				cur_x = cur_x + Dir.x
				cur_y = cur_y + Dir.y
				if history.size() > i:
					history[i] = Vector2(cur_x,cur_y)
				else:
					history.append(Vector2(cur_x,cur_y))
					collectible_location = Vector2(history[i].x,history[i].y)
				maze[cur_x][cur_y] = 1
				if Dir.x != 0:
					maze[cur_x-(Dir.x/2)][cur_y] = 1
				else:
					maze[cur_x][cur_y-(Dir.y/2)] = 1
				i+=1
		if updated:
			continue
		
		#backtrack
		if i>0:
			i=i-1
			cur_x = history[i].x
			cur_y = history[i].y
			continue
		
		#halt
		if i == 0:
			keep_searching = false
	
	return [maze, collectible_location]

func initialize_maze_array():
	var maze = []
	maze.resize(maze_size)
	for i in range(0,maze_size):
		maze[i] = []
		maze[i].resize(maze_size)
		for o in range(0,maze_size):
			maze[i][o] = 0
	return maze

func valid_placement(maze, cur_x, cur_y, Dir):
	if cur_x + Dir.x > 0 and cur_x + Dir.x < maze_size and cur_y + Dir.y > 0 and cur_y + Dir.y < maze_size:
		if maze[cur_x+Dir.x][cur_y+Dir.y] != 1:
			return true
	return false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

#on collectible area trigger delete and redraw maze with new parameters
func _on_area_3d_area_entered(area: Area3D) -> void:
	#progress game state
	collectibles_collected += 1
	
	#clean up previous maze
	for n in self.get_children():
		self.remove_child(n)
		n.queue_free()
	
	#play pickup sound for player
	if player and player.has_method("Pick_up"):
		player.Pick_up()
	
	#generate new maze
	var result
	if collectibles_collected > collectibles_to_gen_end:
		result = maze_gen(true, collectible_location, true)
	else:
		result = maze_gen(true, collectible_location)
	
	#update maze and collectible location
	var maze_array = result[0]
	collectible_location = result[1]
	
	draw_maze(maze_array)
	
	if collectibles_collected < collectibles_to_gen_end+1:
		draw_pedestal(collectible_location.x,collectible_location.y, maze_array)
		create_collectible(collectible_location.x*2,collectible_location.y*2)
	
	pass # Replace with function body.

func _on_end_game_trigger_entered(area: Area3D) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Scenes/gameover.tscn")

func set_player(player_node: CharacterBody3D) -> void:
	player = player_node
