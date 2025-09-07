extends Control

# 当前场景
var current_scene: Control

func _ready():
	# 设置场景控制器为全屏
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 显示菜单场景
	show_menu()

func load_and_show_scene(scene_path: String):
	# 清除当前场景
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	
	# 加载新场景
	var scene_resource = load(scene_path)
	var new_scene = scene_resource.instantiate()
	
	# 设置场景为全屏
	new_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 添加到场景树
	add_child(new_scene)
	current_scene = new_scene
	
	# 连接信号
	connect_scene_signals(new_scene)
	
	print("加载并显示场景: ", scene_path)

func connect_scene_signals(scene: Control):
	# 根据场景类型连接不同的信号
	if scene.name == "MenuScene":
		scene.start_game.connect(_on_start_game)
		scene.open_settings.connect(_on_open_settings)
		scene.open_about.connect(_on_open_about)
		scene.quit_game.connect(_on_quit_game)
	elif scene.name == "SettingsScene":
		scene.back_to_menu.connect(_on_back_to_menu)
	elif scene.name == "GameScene":
		scene.back_to_menu.connect(_on_back_to_menu)
	elif scene.name == "AboutScene":
		scene.back_to_menu.connect(_on_back_to_menu)

func show_menu():
	load_and_show_scene("res://src/scene/menu.tscn")

func show_settings():
	load_and_show_scene("res://src/scene/settings.tscn")

func show_game():
	load_and_show_scene("res://src/scene/game.tscn")

func show_about():
	load_and_show_scene("res://src/scene/about.tscn")

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
