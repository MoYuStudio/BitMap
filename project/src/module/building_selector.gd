extends CanvasLayer

# 建造模式枚举
enum BuildMode {
	PAINT,     # 绘制模式
	ROAD,      # 道路模式
	DELETE     # 删除模式
}

# 当前选择的模式
var current_mode = BuildMode.PAINT

# UI节点引用
var ui_control: Control
var city_button: Button
var railway_button: Button
var highway_button: Button
var road_button: Button
var paint_button: Button
var road_mode_button: Button
var delete_button: Button

# 城市瓦片的source_id
const CITY_SOURCE_ID = 2

# 当前选择的道路类型
var current_road_type: Road.RoadType = Road.RoadType.RAILWAY

# 信号
signal mode_changed(mode: BuildMode)
signal road_type_changed(road_type: Road.RoadType)

func _ready():
	# 获取UI节点引用
	ui_control = get_node("Selector")
	city_button = get_node("Selector/VBoxContainer/BuildingContainer/CityButton")
	railway_button = get_node("Selector/VBoxContainer/BuildingContainer/RailwayButton")
	highway_button = get_node("Selector/VBoxContainer/BuildingContainer/HighwayButton")
	road_button = get_node("Selector/VBoxContainer/BuildingContainer/RoadButton")
	paint_button = get_node("Selector/VBoxContainer/ModeContainer/PaintButton")
	road_mode_button = get_node("Selector/VBoxContainer/ModeContainer/RoadButton")
	delete_button = get_node("Selector/VBoxContainer/ModeContainer/DeleteButton")
	
	# 连接按钮信号
	connect_buttons()
	
	# 更新UI状态
	update_ui_state()

func connect_buttons():
	# 连接建筑类型按钮
	city_button.pressed.connect(_on_city_button_pressed)
	railway_button.pressed.connect(_on_railway_button_pressed)
	highway_button.pressed.connect(_on_highway_button_pressed)
	road_button.pressed.connect(_on_road_button_pressed)
	
	# 连接模式选择按钮
	paint_button.pressed.connect(_on_mode_button_pressed.bind(BuildMode.PAINT))
	road_mode_button.pressed.connect(_on_mode_button_pressed.bind(BuildMode.ROAD))
	delete_button.pressed.connect(_on_mode_button_pressed.bind(BuildMode.DELETE))

func _on_city_button_pressed():
	print("选择建筑: 城市")

func _on_railway_button_pressed():
	current_road_type = Road.RoadType.RAILWAY
	update_road_type_ui()
	road_type_changed.emit(current_road_type)
	print("选择道路类型: 铁路")

func _on_highway_button_pressed():
	current_road_type = Road.RoadType.HIGHWAY
	update_road_type_ui()
	road_type_changed.emit(current_road_type)
	print("选择道路类型: 高速公路")

func _on_road_button_pressed():
	current_road_type = Road.RoadType.ROAD
	update_road_type_ui()
	road_type_changed.emit(current_road_type)
	print("选择道路类型: 公路")

func _on_mode_button_pressed(mode: BuildMode):
	current_mode = mode
	update_ui_state()
	mode_changed.emit(mode)
	var mode_name = ""
	match mode:
		BuildMode.PAINT:
			mode_name = "绘制模式"
		BuildMode.ROAD:
			mode_name = "道路模式"
		BuildMode.DELETE:
			mode_name = "删除模式"
	print("切换模式: ", mode_name)
	print("发送信号 mode_changed: ", mode)

func update_ui_state():
	# 更新模式按钮状态
	paint_button.modulate = Color.WHITE if current_mode == BuildMode.PAINT else Color.GRAY
	road_mode_button.modulate = Color.WHITE if current_mode == BuildMode.ROAD else Color.GRAY
	delete_button.modulate = Color.WHITE if current_mode == BuildMode.DELETE else Color.GRAY
	
	# 根据模式显示/隐藏建筑类型按钮
	match current_mode:
		BuildMode.PAINT:
			# 绘制模式：只显示城市按钮
			city_button.visible = true
			railway_button.visible = false
			highway_button.visible = false
			road_button.visible = false
		BuildMode.ROAD:
			# 道路模式：显示铁路、高速公路和公路按钮
			city_button.visible = false
			railway_button.visible = true
			highway_button.visible = true
			road_button.visible = true
			update_road_type_ui()
		BuildMode.DELETE:
			# 删除模式：隐藏所有建筑类型按钮
			city_button.visible = false
			railway_button.visible = false
			highway_button.visible = false
			road_button.visible = false

func update_road_type_ui():
	"""更新道路类型按钮状态"""
	railway_button.modulate = Color.WHITE if current_road_type == Road.RoadType.RAILWAY else Color.GRAY
	highway_button.modulate = Color.WHITE if current_road_type == Road.RoadType.HIGHWAY else Color.GRAY
	road_button.modulate = Color.WHITE if current_road_type == Road.RoadType.ROAD else Color.GRAY

func get_city_source_id() -> int:
	return CITY_SOURCE_ID

func get_current_mode() -> BuildMode:
	return current_mode

func get_current_road_type() -> Road.RoadType:
	return current_road_type

func is_mouse_over_ui() -> bool:
	# 检查鼠标是否在UI区域内
	if not ui_control:
		return false
	
	# 获取鼠标位置（相对于CanvasLayer）
	var mouse_pos = get_viewport().get_mouse_position()
	
	# 检查Selector区域
	var selector_rect = Rect2(ui_control.position, ui_control.size)
	if selector_rect.has_point(mouse_pos):
		return true
	
	# 检查TopPanel区域
	var top_panel = get_node("TopPanel")
	if top_panel:
		var top_panel_rect = Rect2(top_panel.position, top_panel.size)
		if top_panel_rect.has_point(mouse_pos):
			return true
	
	return false
