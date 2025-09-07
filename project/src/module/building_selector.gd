extends CanvasLayer

# 建造模式枚举
enum BuildMode {
	CLICK,     # 点击模式
	PAINT,     # 绘制模式
	RAILWAY    # 铁路模式
}

# 当前选择的模式
var current_mode = BuildMode.CLICK

# UI节点引用
var ui_control: Control
var city_button: Button
var click_button: Button
var paint_button: Button
var railway_button: Button

# 城市瓦片的source_id
const CITY_SOURCE_ID = 2

# 信号
signal mode_changed(mode: BuildMode)

func _ready():
	# 获取UI节点引用
	ui_control = get_node("UI")
	city_button = get_node("UI/VBoxContainer/BuildingContainer/CityButton")
	click_button = get_node("UI/VBoxContainer/ModeContainer/ClickButton")
	paint_button = get_node("UI/VBoxContainer/ModeContainer/PaintButton")
	railway_button = get_node("UI/VBoxContainer/ModeContainer/RailwayButton")
	
	# 连接按钮信号
	connect_buttons()
	
	# 更新UI状态
	update_ui_state()

func connect_buttons():
	# 连接城市按钮（目前只有城市一种建筑）
	city_button.pressed.connect(_on_city_button_pressed)
	
	# 连接模式选择按钮
	click_button.pressed.connect(_on_mode_button_pressed.bind(BuildMode.CLICK))
	paint_button.pressed.connect(_on_mode_button_pressed.bind(BuildMode.PAINT))
	railway_button.pressed.connect(_on_mode_button_pressed.bind(BuildMode.RAILWAY))

func _on_city_button_pressed():
	print("选择建筑: 城市")

func _on_mode_button_pressed(mode: BuildMode):
	current_mode = mode
	update_ui_state()
	mode_changed.emit(mode)
	var mode_name = ""
	match mode:
		BuildMode.CLICK:
			mode_name = "点击模式"
		BuildMode.PAINT:
			mode_name = "绘制模式"
		BuildMode.RAILWAY:
			mode_name = "铁路模式"
	print("切换模式: ", mode_name)

func update_ui_state():
	# 更新模式按钮状态
	click_button.modulate = Color.WHITE if current_mode == BuildMode.CLICK else Color.GRAY
	paint_button.modulate = Color.WHITE if current_mode == BuildMode.PAINT else Color.GRAY
	railway_button.modulate = Color.WHITE if current_mode == BuildMode.RAILWAY else Color.GRAY

func get_city_source_id() -> int:
	return CITY_SOURCE_ID

func get_current_mode() -> BuildMode:
	return current_mode

func is_mouse_over_ui() -> bool:
	# 检查鼠标是否在UI区域内
	if not ui_control:
		return false
	
	# 获取鼠标位置（相对于CanvasLayer）
	var mouse_pos = get_viewport().get_mouse_position()
	var ui_rect = Rect2(ui_control.position, ui_control.size)
	return ui_rect.has_point(mouse_pos)
