extends Node2D

@onready var tilemap = $grid

var grid = []
var grid_width = 10
var grid_height = 10

@export_range(0, 9) var start_position_x = 0
@export_range(-9, 0) var start_position_y = 0
@export_range(0, 9) var finish_position_x = 9
@export_range(-9, 0) var finish_position_y = -9
@export_range(0, 80, 5) var percentage_obstacles: float

var start_cube = Vector2i(3,0)
var finish_cube = Vector2i(4,0)

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
	create_obstacles()

func create_obstacles():
	pass
