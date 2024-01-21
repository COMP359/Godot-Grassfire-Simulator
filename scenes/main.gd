extends Node2D

@onready var tilemap = $tilemap
@onready var obstacle_sound = $obstacle_sound
@onready var search_sound = $search_sound
@onready var label = $label

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
	grid[start_position_x][start_position_y] = -1

func initialize_finish_position():
	tilemap.set_cell(0, Vector2i(finish_position_x, finish_position_y), 0, finish_cube)
	grid[finish_position_x][finish_position_y] = -2

func _on_start_pressed():
	clear_grid()
	create_obstacles()
	grassfire_search_algo()

func create_obstacles():
	var numberOfObstacles = int(percentage_obstacles + 0.5)
	var obstaclesPlaced = 0

	while obstaclesPlaced < numberOfObstacles:
		var randomX = randi_range(0, 9)
		var randomY = randi_range(-9, 0)

		if grid[randomX][randomY] == 0:
			grid[randomX][randomY] = -3
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

	grid[start_position_x][start_position_y] = -1
	grid[finish_position_x][finish_position_y] = -2
	tilemap.set_cell(0, Vector2i(start_position_x, start_position_y), 0, start_cube)
	tilemap.set_cell(0, Vector2i(finish_position_x, finish_position_y), 0, finish_cube)

func is_valid(x, y):
	return 0 <= x and x <= 9 and -9 <= y and y <= 0 and grid[x][y] == 0

func grassfire_search_algo():
	var numberOfObstacles = int(percentage_obstacles + 0.5)
	await get_tree().create_timer((numberOfObstacles / 2.0 * (0.15 + 0.05)) + 1).timeout # wait for obstacles to be created
	grassfire_search.append(Vector2i(start_position_x, start_position_y))

	searched_nodes = []
	var totalNodes = grid_width * grid_height
	var nodesProcessed = 0

	while grassfire_search.size() > 0:
		var current_node = grassfire_search.pop_front()
		var next_current_value = grid[current_node.x][current_node.y] + 1
	
		# DOWN TO RIGHT
		if is_valid(current_node.x + 1, current_node.y):
			grid[current_node.x + 1][current_node.y] = next_current_value
			grassfire_search.push_back(Vector2i(current_node.x + 1, current_node.y))
			tilemap.set_cell(0, Vector2i(current_node.x + 1, current_node.y), 0, search_cube)
			add_to_set(Vector2i(current_node.x + 1, current_node.y))
	
		#UP TO RIGHT
		if is_valid(current_node.x, current_node.y - 1):
			grid[current_node.x][current_node.y - 1] = next_current_value
			grassfire_search.push_back(Vector2i(current_node.x, current_node.y - 1))
			tilemap.set_cell(0, Vector2i(current_node.x, current_node.y - 1), 0, search_cube)
			add_to_set(Vector2i(current_node.x, current_node.y - 1))
	
		#DOWN TO LEFT
		if is_valid(current_node.x, current_node.y + 1):
			grid[current_node.x][current_node.y + 1] = next_current_value
			grassfire_search.push_back(Vector2i(current_node.x, current_node.y + 1))
			tilemap.set_cell(0, Vector2i(current_node.x, current_node.y + 1), 0, search_cube)
			add_to_set(Vector2i(current_node.x, current_node.y + 1))
	
		#UP TO LEFT
		if is_valid(current_node.x - 1, current_node.y):
			grid[current_node.x - 1][current_node.y] = next_current_value
			grassfire_search.push_back(Vector2i(current_node.x - 1, current_node.y))
			tilemap.set_cell(0, Vector2i(current_node.x - 1, current_node.y), 0, search_cube)
			add_to_set(Vector2i(current_node.x - 1, current_node.y))
	
		await get_tree().create_timer(0.04).timeout
		search_sound.play()
		label.text = "Nodes Processed: " + str(searched_nodes.size()) + "/" + str(totalNodes)

func add_to_set(element):
	if element not in searched_nodes:
		searched_nodes.append(element)