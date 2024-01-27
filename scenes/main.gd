extends Node2D

# Tilemap node
@onready var tilemap = $tilemap
# Sound node for obstacles
@onready var obstacle_sound = $obstacle_sound
# Sound node for search
@onready var search_sound = $search_sound
# Label node for displaying messages
@onready var label = $label
# Label node for displaying finished messages
@onready var finished_label = $finished_label
# Start button node
@onready var start = $start
# Input field for start x coordinate
@onready var start_x_value = $cord_legend/start_x_value
# Input field for start y coordinate
@onready var start_y_value = $cord_legend/start_y_value
# Input field for finish x coordinate
@onready var finish_x_value = $cord_legend/finish_x_value
# Input field for finish y coordinate
@onready var finish_y_value = $cord_legend/finish_y_value
# Input field for obstacle percentage
@onready var obstacle_value = $obstacle_legend/obstacle_value

# 2D array representing the grid
var grid = []
# Width of the grid
var grid_width = 10
# Height of the grid
var grid_height = 10
# List of nodes to be searched by the grassfire algorithm
var grassfire_search = []
# List of nodes that have been searched
var searched_nodes = []

# Start and finish positions, and percentage of obstacles, with export_range for input validation in the editor
@export_range(0, 9) var start_position_x = 1
@export_range(-9, 0) var start_position_y = -1
@export_range(0, 9) var finish_position_x = 8
@export_range(-9, 0) var finish_position_y = -8
@export_range(0, 70) var percentage_obstacles = 15

# Vector2i values representing different types of cubes
var empty_cube = Vector2i(0,0)
var obstacle_cube = Vector2i(1,0)
var path_cube = Vector2i(2,0)
var start_cube = Vector2i(3,0)
var finish_cube = Vector2i(4,0)
var search_cube = Vector2i(5,0)

# Called when the node enters the scene tree for the first time
func _ready():
	# Initialize the grid and the start and finish positions
	initialize_grid()
	initialize_start_position()
	initialize_finish_position()

# Initialize the grid with 0s
func initialize_grid():
	for i in grid_width:
		grid.append([])
		for j in grid_height:
			grid[i].append(0)

# Set the start position on the tilemap and in the grid
func initialize_start_position():
	tilemap.set_cell(0, Vector2i(start_position_x, start_position_y), 0, start_cube)
	grid[start_position_x][-start_position_y] = -1

# Initialize the finish position on the tilemap and in the grid
func initialize_finish_position():
	tilemap.set_cell(0, Vector2i(finish_position_x, finish_position_y), 0, finish_cube)
	grid[finish_position_x][-finish_position_y] = -2

# Event handler for start button press
func _on_start_pressed():
	if (start_position_x == finish_position_x and start_position_y == finish_position_y):
		label.text = "Change Start or Finish"
	else:
		set_ui(true)
		search_sound.pitch_scale = 1
		clear_grid()
		create_obstacles()
		grassfire_search_algo()

# Function to create obstacles in the grid
func create_obstacles():
	var numberOfObstacles = percentage_obstacles
	var obstaclesPlaced = 0

	while obstaclesPlaced < numberOfObstacles:
		var randomX = randi_range(0, 9)
		var randomY = randi_range(-9, 0)

		if grid[randomX][-randomY] == 0:
			grid[randomX][-randomY] = -3
			tilemap.set_cell(0, Vector2i(randomX, randomY), 0, obstacle_cube)
			# Decrease timeout as more obstacles are placed
			var timeout = max(0.05, 0.15 - (0.10 * obstaclesPlaced / numberOfObstacles))
			await get_tree().create_timer(timeout).timeout
			obstacle_sound.play()
			obstaclesPlaced += 1
			label.text = "Obstacles Placed: " + str(obstaclesPlaced) + "/" + str(numberOfObstacles)

# Clears the grid in the frontend and the back
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
	var numberOfObstacles = percentage_obstacles
	# Wait for obstacles to be created
	await get_tree().create_timer((numberOfObstacles / 2.0 * (0.15 + 0.05)) + 1).timeout
	# Add the start position to the grassfire search list
	grassfire_search.append(Vector2i(start_position_x, start_position_y))

	# Initialize the searched nodes list and the total number of nodes
	searched_nodes = []
	var totalNodes = grid_width * grid_height
	var nodesProcessed = 0

	# Define the directions for the grassfire search
	var directions = [Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0)]

	# While there are still nodes to search
	while grassfire_search.size() > 0:
		# Get the current node and calculate the next value
		var current_node = grassfire_search.pop_front()
		var next_current_value = 0
		if (current_node.x == start_position_x and current_node.y == start_position_y):
			next_current_value = 1
		else:
			next_current_value = grid[current_node.x][-current_node.y] + 1

		# For each direction, calculate the new node and check if it's the finish
		for direction in directions:
			var new_node = current_node + direction
			if (new_node.x == finish_position_x and new_node.y == finish_position_y):
				# Found the finish
				grid[new_node.x][-new_node.y] = -4
				finished_label.visible = true

			# If the new node is valid, add it to the grid and the grassfire search list
			if is_valid(new_node.x, new_node.y):
				grid[new_node.x][-new_node.y] = next_current_value
				grassfire_search.push_back(new_node)
				tilemap.set_cell(0, new_node, 0, search_cube)
				add_to_set(new_node)

		# Wait for a short time and play the search sound
		await get_tree().create_timer(0.04).timeout
		search_sound.play()
		# Update the label with the number of nodes processed
		label.text = "Nodes Processed: " + str(searched_nodes.size()) + "/" + str(totalNodes)

	# Wait for a short time and hide the finished label
	await get_tree().create_timer(1).timeout
	finished_label.visible = false

	# If the finish was found, show the path, otherwise show a message that no path was found
	if (grid[finish_position_x][-finish_position_y] == -4):
		show_path()
	else:
		label.text = "No Path Found!"
		set_ui(false)

# Initialize the shortest path list
var shortest_path = []

# Function to show the path
func show_path():
	# Clears the tilemap of searched nodes
	for node in searched_nodes:
		tilemap.set_cell(0, node, 0, empty_cube)
	label.text = "Path Length: " + str(shortest_path.size())
	search_sound.pitch_scale = 1.5

	# Initialize the final path and the finished node
	var final_path = []
	var finished_node = Vector2i(finish_position_x, finish_position_y)
	var directions = [Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0)]

	# While the path is not finished
	var finished = true
	while(finished):
		# Initialize the minimum value and the minimum x and y
		var min_value = 999999
		var min_x = 0
		var min_y = 0
		# For each direction, calculate the new node and check if it's the start
		for direction in directions:
			var new_node = finished_node + direction
			if is_valid_path(new_node.x, new_node.y):
				if grid[new_node.x][-new_node.y] < min_value:
					min_value = grid[new_node.x][-new_node.y]
					min_x = new_node.x
					min_y = new_node.y
			if (new_node.x == start_position_x and new_node.y == start_position_y):
				finished = false
				break
		# If the path is not finished, add the node with the minimum value to the final path
		if (finished == true):
			final_path.append(Vector2i(min_x, min_y))
			finished_node = final_path[-1]

	# Initialize the path length
	var path_length = 1
	# For each node in the final path, wait for a short time, play the search sound, and update the path length
	for i in range(final_path.size() - 1, -1, -1):
		await get_tree().create_timer(0.25).timeout
		search_sound.play()
		tilemap.set_cell(0, final_path[i], 0, path_cube)
		label.text = "Path Length: " + str(path_length)
		path_length += 1
	# Play the success sound and disable the UI
	play_success_sound()
	set_ui(false)

# Scuffed way of playing the success sound
func play_success_sound():
	await get_tree().create_timer(0.5).timeout
	search_sound.pitch_scale = 2
	search_sound.play()
	await get_tree().create_timer(0.15).timeout
	search_sound.pitch_scale = 2.5
	search_sound.play()
	await get_tree().create_timer(0.15).timeout
	search_sound.pitch_scale = 4
	search_sound.play()

# Validates if the coordinates are valid
func is_valid_path(x, y):
	return 0 <= x and x <= 9 and -9 <= y and y <= 0 and grid[x][-y] > 0

func add_to_set(element):
	if element not in searched_nodes:
		searched_nodes.append(element)

# This function is triggered when the start x value is changed. It clears the grid, updates the start position x value and sets the cell at the new start position with the start cube.
func _on_start_x_value_value_changed(value):
	clear_grid()
	label.text = ""
	tilemap.set_cell(0, Vector2i(start_position_x, start_position_y), 0, empty_cube)
	start_position_x = int(value)
	tilemap.set_cell(0, Vector2i(start_position_x, start_position_y), 0, start_cube)

# This function is triggered when the start y value is changed. It clears the grid, updates the start position y value and sets the cell at the new start position with the start cube.
func _on_start_y_value_value_changed(value):
	clear_grid()
	label.text = ""
	tilemap.set_cell(0, Vector2i(start_position_x, start_position_y), 0, empty_cube)
	start_position_y = int(value)
	tilemap.set_cell(0, Vector2i(start_position_x, start_position_y), 0, start_cube)

# This function is triggered when the finish x value is changed. It clears the grid, updates the finish position x value and sets the cell at the new finish position with the finish cube.
func _on_finish_x_value_value_changed(value):
	clear_grid()
	label.text = ""
	tilemap.set_cell(0, Vector2i(finish_position_x, finish_position_y), 0, empty_cube)
	finish_position_x = int(value)
	tilemap.set_cell(0, Vector2i(finish_position_x, finish_position_y), 0, finish_cube)

# This function is triggered when the finish y value is changed. It clears the grid, updates the finish position y value and sets the cell at the new finish position with the finish cube.
func _on_finish_y_value_value_changed(value):
	clear_grid()
	label.text = ""
	tilemap.set_cell(0, Vector2i(finish_position_x, finish_position_y), 0, empty_cube)
	finish_position_y = int(value)
	tilemap.set_cell(0, Vector2i(finish_position_x, finish_position_y), 0, finish_cube)

# This function is triggered when the obstacle value is changed. It updates the percentage of obstacles.
func _on_obstacle_value_value_changed(value):
	percentage_obstacles = int(value)

# This function sets the UI elements to be disabled or editable based on the passed value.
func set_ui(value):
	start.set_disabled(value)
	start_x_value.set_editable(!value)
	start_y_value.set_editable(!value)
	finish_x_value.set_editable(!value)
	finish_y_value.set_editable(!value)
	obstacle_value.set_editable(!value)
