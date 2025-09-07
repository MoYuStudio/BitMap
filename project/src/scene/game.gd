extends Control

# 信号定义
signal back_to_menu

# 游戏控制变量
var is_paused = false
var game_start_time: float
var current_cursor_position: Vector2i = Vector2i.ZERO
var current_build_mode: String = "绘制模式"
var current_road_type: String = ""

# UI引用
var position_label: Label
var build_type_label: Label
var time_label: Label
var stats_label: Label

func _ready():
	# 记录游戏开始时间
	game_start_time = Time.get_unix_time_from_system()
	
	# 获取UI引用
	position_label = $CanvasLayer/TopPanel/HBoxContainer/GameData/PositionLabel
	build_type_label = $CanvasLayer/TopPanel/HBoxContainer/GameData/BuildTypeLabel
	time_label = $CanvasLayer/TopPanel/HBoxContainer/GameData/TimeLabel
	stats_label = $CanvasLayer/TopPanel/HBoxContainer/GameData/StatsLabel
	
	# 连接返回按钮信号
	$CanvasLayer/TopPanel/HBoxContainer/BackButton.pressed.connect(_on_back_to_menu)
	
	# 连接建筑选择器信号
	var building_selector = $CanvasLayer
	if building_selector:
		building_selector.mode_changed.connect(_on_build_mode_changed)
		building_selector.road_type_changed.connect(_on_road_type_changed)

func _process(delta):
	# 更新游戏时间
	update_time_display()
	
	# 更新游戏统计
	update_stats_display()
	
	# 更新光标位置
	update_cursor_position()

func _input(event):
	# 处理ESC键返回菜单
	if event.is_action_pressed("ui_cancel"):
		# 恢复鼠标光标显示
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		back_to_menu.emit()
	
	# 处理P键暂停游戏
	if event.is_action_pressed("ui_accept") and event.keycode == KEY_P:
		toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	$GameWorld.process_mode = Node.PROCESS_MODE_WHEN_PAUSED if is_paused else Node.PROCESS_MODE_INHERIT
	print("游戏", "暂停" if is_paused else "继续")

func _on_back_to_menu():
	# 恢复鼠标光标显示
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	back_to_menu.emit()

# UI更新函数
func update_time_display():
	var current_time = Time.get_time_dict_from_system()
	var time_str = "%02d:%02d:%02d" % [current_time.hour, current_time.minute, current_time.second]
	time_label.text = "时间: " + time_str

func update_cursor_position():
	# 从光标控制器获取当前位置
	var cursor = $GameWorld/Cursor
	if cursor:
		var terrain_layer = $GameWorld/TerrainLayer
		if terrain_layer:
			var mouse_pos = get_global_mouse_position()
			var tile_pos = terrain_layer.local_to_map(terrain_layer.to_local(mouse_pos))
			current_cursor_position = tile_pos
			position_label.text = "坐标: (%d, %d)" % [tile_pos.x, tile_pos.y]

func update_stats_display():
	# 统计城市数量
	var city_count = 0
	var city_layer = $GameWorld/CityLayer
	if city_layer and city_layer.has_method("get_city_count"):
		city_count = city_layer.get_city_count()
	
	# 统计道路数量
	var road_count = 0
	var road_layer = $GameWorld/RoadLayer
	if road_layer and road_layer.has_method("get_road_count"):
		road_count = road_layer.get_road_count()
	
	stats_label.text = "城市: %d | 道路: %d" % [city_count, road_count]

func update_build_type_display():
	var build_text = "建造: " + current_build_mode
	if current_road_type != "":
		build_text += " (" + current_road_type + ")"
	build_type_label.text = build_text

# 信号处理函数
func _on_build_mode_changed(mode):
	match mode:
		0: # BuildMode.PAINT
			current_build_mode = "绘制模式"
			current_road_type = ""
		1: # BuildMode.ROAD
			current_build_mode = "道路模式"
			current_road_type = "铁路"  # 默认道路类型
	update_build_type_display()

func _on_road_type_changed(road_type):
	match road_type:
		0: # Road.RoadType.RAILWAY
			current_road_type = "铁路"
		1: # Road.RoadType.HIGHWAY
			current_road_type = "高速公路"
		2: # Road.RoadType.ROAD
			current_road_type = "公路"
	update_build_type_display()
