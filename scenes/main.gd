extends Node2D

var grid = []
var grid_width = 10
var grid_height = 10
var start_position_x = 0
var start_position_y = 0
var end_position_x = 9	
var end_position_y = -9


# MAKE THE START AND END TILE BE PLACED BASED ON THE START AND END POSITIONS ABOVE

func _ready():
	initialize_grid()
	initialize_start_position()
	initialize_end_position()
	print(grid)
	
func initialize_grid():
	for i in grid_width:
		grid.append([])
		for j in grid_height:
			grid[i].append(0)

func initialize_start_position():
	grid[start_position_x][start_position_y] = -1

func initialize_end_position():
	grid[end_position_x][end_position_y] = -2
