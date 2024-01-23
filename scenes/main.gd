extends Node2D

@onready var tilemap = $tilemap
@onready var obstacle_sound = $obstacle_sound
@onready var search_sound = $search_sound
@onready var label = $label
@onready var finished_label = $finished_label
@onready var start = $start

var grid = []
var grid_width = 10
var grid_height = 10
var grassfire_search = []
var searched_nodes = []

@export_range(0, 9) var start_position_x = 0
@export_range(-9, 0) var start_position_y = 0
@export_range(0, 9) var finish_position_x = 9
@export_range(-9, 0) var finish_position_y = -9
@export_range(0, 25, 0.5) var percentage_obstacles: float = 10

var empty_cube = Vector2i(0,0)
var obstacle_cube = Vector2i(1,0)
var path_cube = Vector2i(2,0)
var start_cube = Vector2i(3,0)
var finish_cube = Vector2i(4,0)
var search_cube = Vector2i(5,0)

func _ready():
	initialize_grid()
	initialize_start_position()
	initialize_finish_position()

func initialize_grid():
	for i in grid_width:
		grid.append([])
		for j in grid_height:
			grid[i].append(0)

func initialize_start_position():
	tilemap.set_cell(0, Vector2i(start_position_x, start_position_y), 0, start_cube)
	grid[start_position_x][-start_position_y] = -1

func initialize_finish_position():
	tilemap.set_cell(0, Vector2i(finish_position_x, finish_position_y), 0, finish_cube)
	grid[finish_position_x][-finish_position_y] = -2

func _on_start_pressed():
	start.set_disabled(true)
	search_sound.pitch_scale = 1
	clear_grid()
	create_obstacles()
	grassfire_search_algo()

func create_obstacles():
	var numberOfObstacles = int(percentage_obstacles + 0.5)
	var obstaclesPlaced = 0

	while obstaclesPlaced < numberOfObstacles:
		var randomX = randi_range(0, 9)
		var randomY = randi_range(-9, 0)

		if grid[randomX][-randomY] == 0:
			grid[randomX][-randomY] = -3
			tilemap.set_cell(0, Vector2i(randomX, randomY), 0, obstacle_cube)
			var timeout = max(0.05, 0.15 - (0.10 * obstaclesPlaced / numberOfObstacles))  # Decrease timeout as more obstacles are placed
			await get_tree().create_timer(timeout).timeout
			obstacle_sound.play()
			obstaclesPlaced += 1
			label.text = "Obstacles Placed: " + str(obstaclesPlaced) + "/" + str(numberOfObstacles)

func clear_grid():
	for i in grid_width:
		for j in grid_height:
			grid[i][j] = 0
	
	for i in range(10):
		for j in range(-9, 1):
			tilemap.set_cell(0, Vector2i(i, j), 0, empty_cube)

	grid[start_position_x][-start_position_y] = -1
	grid[finish_position_x][-finish_position_y] = -2
	tilemap.set_cell(0, Vector2i(start_position_x, start_position_y), 0, start_cube)
	tilemap.set_cell(0, Vector2i(finish_position_x, finish_position_y), 0, finish_cube)

func is_valid(x, y):
	return 0 <= x and x <= 9 and -9 <= y and y <= 0 and grid[x][-y] == 0

func grassfire_search_algo():
	var numberOfObstacles = int(percentage_obstacles + 0.5)
	await get_tree().create_timer((numberOfObstacles / 2.0 * (0.15 + 0.05)) + 1).timeout # wait for obstacles to be created
	grassfire_search.append(Vector2i(start_position_x, start_position_y))

	searched_nodes = []
	var totalNodes = grid_width * grid_height
	var nodesProcessed = 0

	var directions = [Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0)]

	while grassfire_search.size() > 0:
		var current_node = grassfire_search.pop_front()
		var next_current_value = 0
		if (current_node.x == start_position_x and current_node.y == start_position_y):
			next_current_value = 1
		else:
			next_current_value = grid[current_node.x][-current_node.y] + 1

		for direction in directions:
			var new_node = current_node + direction
			if (new_node.x == finish_position_x and new_node.y == finish_position_y):
				# Found the finish
				grid[new_node.x][-new_node.y] = -4
				finished_label.visible = true

			if is_valid(new_node.x, new_node.y):
				grid[new_node.x][-new_node.y] = next_current_value
				grassfire_search.push_back(new_node)
				tilemap.set_cell(0, new_node, 0, search_cube)
				add_to_set(new_node)

		await get_tree().create_timer(0.04).timeout
		search_sound.play()
		label.text = "Nodes Processed: " + str(searched_nodes.size()) + "/" + str(totalNodes)
	
	
	await get_tree().create_timer(1).timeout
	finished_label.visible = false
	
	if (grid[finish_position_x][-finish_position_y] == -4):
		show_path()
	else:
		label.text = "No Path Found!"

var shortest_path = []

func is_valid_path(x, y):
	return 0 <= x and x <= 9 and -9 <= y and y <= 0 and grid[x][-y] > 0

func show_path():
	# Clears the tilemap of searched nodes
	for node in searched_nodes:
		tilemap.set_cell(0, node, 0, empty_cube)
	label.text = "Path Length: " + str(shortest_path.size())
	search_sound.pitch_scale = 1.5

	var final_path = []

	# Find the shortest path using the grid

	var finished_node = Vector2i(finish_position_x, finish_position_y)
	var directions = [Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0)]

	var finished = true
	while(finished):
		var min_value = 999999
		var min_x = 0
		var min_y = 0
		for direction in directions:
			var new_node = finished_node + direction
			#New node is something like (0,3)
			if is_valid_path(new_node.x, new_node.y):
				if grid[new_node.x][-new_node.y] < min_value:
					min_value = grid[new_node.x][-new_node.y]
					min_x = new_node.x
					min_y = new_node.y
					#Start found
			if (new_node.x == start_position_x and new_node.y == start_position_y):
				finished = false
				break
		if (finished == true):
			final_path.append(Vector2i(min_x, min_y))
			finished_node = final_path[-1]

	var path_length = 1
	for i in range(final_path.size() - 1, -1, -1):
		await get_tree().create_timer(0.25).timeout
		search_sound.play()
		tilemap.set_cell(0, final_path[i], 0, path_cube)
		label.text = "Path Length: " + str(path_length)
		path_length += 1
	await get_tree().create_timer(0.5).timeout
	search_sound.pitch_scale = 2
	search_sound.play()
	await get_tree().create_timer(0.15).timeout
	search_sound.pitch_scale = 2.5
	search_sound.play()
	await get_tree().create_timer(0.15).timeout
	search_sound.pitch_scale = 4
	search_sound.play()
	start.set_disabled(false)

func add_to_set(element):
	if element not in searched_nodes:
		searched_nodes.append(element)
