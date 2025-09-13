extends Control

signal back_to_menu

# 游戏场景引用
var game_scene: Node2D
var is_game_loaded = false

func _ready():
	# 连接游戏选择界面的按钮信号
	$GameSelection/VBoxContainer/NewGameButton.pressed.connect(_on_new_game_button_pressed)
	$GameSelection/VBoxContainer/LoadGameButton.pressed.connect(_on_load_game_button_pressed)
	$GameSelection/VBoxContainer/BackButton.pressed.connect(_on_back_to_menu_pressed)
	
	# 连接游戏控制界面的按钮信号
	$GameControls/Control/TopPanel/HBoxContainer/PauseButton.pressed.connect(_on_pause_button_pressed)
	$GameControls/Control/TopPanel/HBoxContainer/SaveGameButton.pressed.connect(_on_save_game_button_pressed)
	$GameControls/Control/TopPanel/HBoxContainer/BackButton.pressed.connect(_on_back_to_selection_pressed)
	
	# 初始显示游戏选择界面
	show_game_selection()

func _on_back_to_menu_pressed():
	# 返回主菜单
	back_to_menu.emit()

func _on_back_to_selection_pressed():
	# 返回游戏选择界面
	show_game_selection()

func _on_new_game_button_pressed():
	# 开始新游戏
	load_game_scene()

func _on_load_game_button_pressed():
	# 加载游戏
	load_saved_game()

func _on_save_game_button_pressed():
	# 保存游戏
	save_game()

func _on_pause_button_pressed():
	# 暂停/继续游戏
	toggle_pause()

func show_game_selection():
	# 显示游戏选择界面
	$GameSelection.visible = true
	$GameControls.visible = false
	if game_scene:
		game_scene.visible = false
	is_game_loaded = false

func show_game_controls():
	# 显示游戏控制界面
	$GameSelection.visible = false
	$GameControls.visible = true

func load_game_scene():
	# 加载游戏场景
	if not game_scene:
		var main_scene_resource = preload("res://src/main.tscn")
		game_scene = main_scene_resource.instantiate()
		add_child(game_scene)
		# 将游戏场景移到最底层
		move_child(game_scene, 0)
	
	game_scene.visible = true
	show_game_controls()
	is_game_loaded = true

func load_saved_game():
	# 这里实现加载保存的游戏逻辑
	print("加载游戏功能待实现")
	# 暂时直接加载新游戏
	load_game_scene()

func save_game():
	# 这里实现保存游戏逻辑
	print("保存游戏功能待实现")

func toggle_pause():
	# 暂停/继续游戏
	if game_scene:
		game_scene.process_mode = Node.PROCESS_MODE_WHEN_PAUSED if not game_scene.process_mode == Node.PROCESS_MODE_WHEN_PAUSED else Node.PROCESS_MODE_INHERIT
