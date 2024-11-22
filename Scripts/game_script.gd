extends Node3D

#List containing all cameras and current cam index
@onready var cameras = [$"Main Camera", $"Top Camera", $"Front camera", $"Resource Camera" ]

#variable to contain main GridMap
@onready var grid_map = $GridMap

#variables holding buttons inside build ui
@onready var tetris_button = $"Control/Walls build button"
@onready var tower_button = $"Control/Tower build button"
@onready var build_ui_button = $"Control/Build UI button"
@onready var resource_button = $"Control/Resource build button"

#variable to contain raycast to detect clicks in build mode
@onready var raycast = $"Top Camera/RayCast3D"

#variable to contain Enemy Path Spawner
@onready var enemy_path = $"Enemy Spawner"

var NormalTowerScene = preload("res://Scenes/normal_tower_lvl_1.tscn")
var Lumbermill = preload("res://Scenes/lumbermill.tscn")

var build_ui = false
var tower_build = false
var tetris_build_mode = false
var resource_build = false

var current_cam_index = 0
var coordinates_check_mode = false
var hover = [null, null, null, null] #array that holds blocks for hover. 4 couse very tetris block size = 4
var short_path = [] #array that holds shortest path converted to local
var tower_hover_holder:MeshInstance3D = null
var resource_hover_holder:MeshInstance3D = null


@onready var label = $"Control/Resource count label"
@onready var lumbermill = $"Resource Holder"/resource_hover_holder
#resource counter:
var wood=0

#Disables all camera except one with current cam index
func set_camera():
	for i in range (cameras.size()):
			cameras[i].current = (i == current_cam_index)

func _input(event: InputEvent) -> void:
	if tetris_build_mode and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			place_block_on_click()
	if tetris_build_mode and event is InputEventKey:
		if event.keycode == KEY_Q and event.is_pressed():
			grid_map.rotate_block_backwards()
	if tetris_build_mode and event is InputEventKey:
		if event.keycode == KEY_E and event.is_pressed():
			grid_map.rotate_block_forward()
	if coordinates_check_mode and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			check_coordinates()
	if tower_build and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			place_tower_on_click()
	if resource_build and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
			place_resource_on_click()
			
func get_collision_point(): #returns raycast collision point with map
	#variable to hold mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	
	#setting raycast start point (mouse position), length and direction -> Vector3
	var from = cameras[current_cam_index].project_ray_origin(mouse_pos)
	var to = from + cameras[current_cam_index].project_ray_normal(mouse_pos) * 100
	
	#gets space, creates raycast(from, to) and cointains result
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result.size() > 0:
		#print("Collision point: ", result)
		return result.position  # Return collision point
	else:
		return null  #No collison

#function places block on raycast position
func place_block_on_click():
	var collision_point = get_collision_point()
	#checking if raycast detected any block if so place block on gridmap
	if collision_point != null:
		var grid_pos = grid_map.local_to_map(collision_point)
		grid_map.place_tetris_block(grid_pos, grid_map.current_shape)
		update_hover_mesh()
		convert_path_to_local()
		enemy_path.set_path(short_path)
		
#function places tower on raycast position
func place_tower_on_click():
	tower_hover_holder.free()
	var collision_point = get_collision_point()
	#checking if raycast detected any block if so place block on gridmap
	if collision_point != null and grid_map.can_place_tower(collision_point):
		var tower = NormalTowerScene.instantiate()
		var grid_pos = grid_map.local_to_map(collision_point)
		var place_pos = grid_map.map_to_local(grid_pos)
		place_pos.y+=1
		tower.position=place_pos
		tower.get_node("MobDetector").visible=false
		grid_map.place_tower_in_tilemap(collision_point)
		get_node("Tower Holder").add_child(tower)
		print("Added tower in position: ",grid_pos)
		tower_hover_holder=null

#function that hover towers over the map showing where it can be placed and its range
func hover_tower():
	var collision_point = get_collision_point()
	if tower_hover_holder==null:
		tower_hover_holder = NormalTowerScene.instantiate()
		get_node("Tower Holder").add_child(tower_hover_holder)
	tower_hover_holder.can_shoot=false
	if collision_point != null:
		tower_hover_holder.visible=true
		var grid_pos = grid_map.local_to_map(collision_point)
		var place_pos = grid_map.map_to_local(grid_pos)
		place_pos.y=5
		tower_hover_holder.position=place_pos
		#if not grid_map.can_place_tower(collision_point):
		#	print("no")
		#else:
		#	print("yes")
	else:
		tower_hover_holder.visible=false
	
#function creates block hover on raycast position
func update_hover_cursor():
	var collision_point = get_collision_point()
	if collision_point != null and tetris_build_mode:
		var grid_pos = grid_map.local_to_map(collision_point)
		var grid_pos_f = Vector3(grid_pos.x, grid_pos.y, grid_pos.z)
		for i in range(grid_map.current_shape.size()):
			pass
			var block_pos = grid_pos_f + grid_map.current_shape[i]
			var world_pos = grid_map.map_to_local(block_pos)
			world_pos.y += 0.5
			hover[i].global_transform.origin = world_pos
			hover[i].visible = true  # We make sure that hover is visible
	else:
		for h in hover:
			h.visible = false  #Hides hover if it doesnt collide with grid

#prints in output coordinates of clicked point	
func check_coordinates():
	var collision_point = get_collision_point()
	if collision_point != null:
		var grid_pos = grid_map.local_to_map(collision_point)	
		print(grid_pos)
		
func wood_timers():
	for i in get_node("Resource Holder").get_child_count():
		if get_node("Resource Holder").get_child(i).generates_wood==true:
			get_node("Resource Holder").get_child(i).get_node("Timer").start()
			get_node("Resource Holder").get_child(i).generates_wood=false
			wood = wood + 1
			#print("Timer ", i)

func place_resource_on_click():
	resource_hover_holder.free()
	var collision_point = get_collision_point()
	
	#checking if raycast detected any block if so place block on gridmap
	if collision_point != null:
		var grid_pos = grid_map.local_to_map(collision_point)
		if grid_map.can_place_resource(grid_pos, grid_map.lumber_shape):
			var lumbermill = Lumbermill.instantiate()
			
			var place_pos = grid_map.map_to_local(grid_pos)
			place_pos.y=2.5
			place_pos.x+=1.5
			place_pos.z+=1.5
			lumbermill.position=place_pos
			grid_map.place_resource_in_tilemap(collision_point)
			get_node("Resource Holder").add_child(lumbermill)
			print("Added lumbermill in position: ",grid_pos)
			resource_hover_holder=null
	
func hover_resource():
	var collision_point = get_collision_point()
	
	if resource_hover_holder == null:
		resource_hover_holder = Lumbermill.instantiate()
		resource_hover_holder.game_script = self
		get_node("Resource Holder").add_child(resource_hover_holder)
	resource_hover_holder.generates_wood = false
	if collision_point != null:
		
		
		#print(collision_point)
		resource_hover_holder.visible = true
		var grid_pos = grid_map.local_to_map(collision_point)
		var place_pos = grid_map.map_to_local(grid_pos)
		#print(grid_pos)
		place_pos.y=2.5
		place_pos.x+=1.5
		place_pos.z+=1.5
		resource_hover_holder.position=place_pos
	else:
		#print("nie dziala raycast")
		resource_hover_holder.visible = false
	
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.game_script = self
	set_camera()
	var mesh_lib = grid_map.mesh_library
	for i in range(hover.size()):
		hover[i] = MeshInstance3D.new()
		if mesh_lib:
			hover[i].mesh = mesh_lib.get_item_mesh(grid_map.block_type)
			add_child(hover[i])
			hover[i].visible = false
	
	convert_path_to_local()
	enemy_path.set_path(short_path)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	wood_timers()
	if Input.is_action_just_pressed("Camera_F1"):
		if current_cam_index >0 :
			current_cam_index -= 1
		current_cam_index = current_cam_index%3
		set_camera()
		coordinates_check_mode = false	
	elif Input.is_action_just_pressed("Camera_F2"):
		current_cam_index += 1
		current_cam_index = current_cam_index%3
		set_camera()
		coordinates_check_mode = false	
	elif Input.is_action_just_pressed("Camera_F9"):
		current_cam_index = 1
		set_camera()
		coordinates_check_mode = true
		tetris_build_mode = false
	if tetris_build_mode:
		coordinates_check_mode = false	
		update_hover_cursor()
	if tower_build:
		coordinates_check_mode = false
		hover_tower()
	if resource_build:
		coordinates_check_mode = false
		hover_resource()


#Signal to enter build mode
func _on_tetris_build_button_pressed() -> void:
	if not tetris_build_mode:
		tetris_build_mode = true
		build_ui_button.disabled = true
		tower_button.disabled = true
		resource_button.disabled = true
	else:
		tetris_build_mode = false
		build_ui_button.disabled = false
		tower_button.disabled = false
		resource_button.disabled = false

#called in _progress updates mesh that is hover for block placement
func update_hover_mesh() -> void:
	var mesh_lib = grid_map.mesh_library
	if not mesh_lib:
		return  # Upewnij się, że mesh_library istnieje
	for i in range(hover.size()):
		if hover[i]:
			hover[i].mesh = mesh_lib.get_item_mesh(grid_map.block_type)


#transforms shortest_path from gridmap placement to local 
func convert_path_to_local()-> void:
	#delete path previous path
	if not short_path.is_empty():
		short_path = []
		
	#add start_end points to path (to be discussed)
	var path_start = grid_map.start_point
	path_start.x +=1
	var path_end = grid_map.end_point
	path_end.x -=1
	short_path.append(grid_map.map_to_local(path_start))
	
	#we add grid_map.shortest_path to short_path changing it to local needs 
	for vect in grid_map.shortest_path:
			vect.y += 1
			short_path.append(grid_map.map_to_local(vect))
	short_path.append(grid_map.map_to_local(path_end))

#build ui button enables other buttons used to buy and place walls and towers
func _on_build_ui_button_pressed() -> void:
	if not build_ui:
		current_cam_index = 1
		tetris_button.visible = true
		tetris_button.disabled = false
		tower_button.visible = true
		tower_button.disabled = false
		resource_button.visible = true
		resource_button.disabled = false
		build_ui = true
	else:
		current_cam_index = 0
		tetris_button.visible = false
		tetris_button.disabled = true
		tower_button.visible = false
		tower_button.disabled = true
		resource_button.visible = false
		resource_button.disabled = true
		build_ui = false
	set_camera()

func _on_tower_build_button_pressed() -> void:
	if not tower_build:
		tower_build = true
		build_ui_button.disabled = true
		tetris_button.disabled = true
		resource_button.disabled = true
	else:
		tower_build = false
		build_ui_button.disabled = false
		tetris_button.disabled = false
		resource_button.disabled = false

func _on_resource_build_button_pressed() -> void:
	if not resource_build:
		current_cam_index = 3
		resource_build = true
		build_ui_button.disabled = true
		tetris_button.disabled = true
		tower_button.disabled = true
	else:
		current_cam_index = 1
		resource_build = false
		build_ui_button.disabled = false
		tetris_button.disabled = false
		tower_button.disabled = false
	set_camera()
