extends GutTest
const Main = preload("res://scenes/main.gd")
var _main = null;
	
func before_each():
	_main = Main.new();

func after_each():
	_main.free();

func test_check_valid_grid_dimension():
	assert_eq(_main.grid_height, 10);
	assert_eq(_main.grid_width, 10);
