extends Node

# 场景引用
var menu_scene: Control
var settings_scene: Control
var game_scene: Control
var about_scene: Control

# 当前场景
var current_scene: Control

func _ready():
	# 加载所有场景
	load_scenes()
	
	# 显示菜单场景
	show_menu()

func load_scenes():
	# 加载场景资源
	var menu_scene_resource = preload("res://src/scene/menu.tscn")
	var settings_scene_resource = preload("res://src/scene/settings.tscn")
	var game_scene_resource = preload("res://src/scene/game.tscn")
	var about_scene_resource = preload("res://src/scene/about.tscn")
	
	# 实例化场景
	menu_scene = menu_scene_resource.instantiate()
	settings_scene = settings_scene_resource.instantiate()
	game_scene = game_scene_resource.instantiate()
	about_scene = about_scene_resource.instantiate()
	
	# 添加到场景树
	add_child(menu_scene)
	add_child(settings_scene)
	add_child(game_scene)
	add_child(about_scene)
	
	# 连接信号
	connect_scene_signals()
	
	# 隐藏所有场景
	hide_all_scenes()

func connect_scene_signals():
	# 连接菜单场景信号
	menu_scene.start_game.connect(_on_start_game)
	menu_scene.open_settings.connect(_on_open_settings)
	menu_scene.open_about.connect(_on_open_about)
	menu_scene.quit_game.connect(_on_quit_game)
	
	# 连接设置场景信号
	settings_scene.back_to_menu.connect(_on_back_to_menu)
	
	# 连接游戏场景信号
	game_scene.back_to_menu.connect(_on_back_to_menu)
	
	# 连接关于场景信号
	about_scene.back_to_menu.connect(_on_back_to_menu)

func hide_all_scenes():
	menu_scene.visible = false
	settings_scene.visible = false
	game_scene.visible = false
	about_scene.visible = false

func show_scene(scene: Control):
	hide_all_scenes()
	scene.visible = true
	current_scene = scene

func show_menu():
	show_scene(menu_scene)

func show_settings():
	show_scene(settings_scene)

func show_game():
	show_scene(game_scene)

func show_about():
	show_scene(about_scene)

# 信号处理函数
func _on_start_game():
	show_game()

func _on_open_settings():
	show_settings()

func _on_open_about():
	show_about()

func _on_quit_game():
	get_tree().quit()

func _on_back_to_menu():
	show_menu()
