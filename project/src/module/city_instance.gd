extends Node2D

# 城市数据
var city_name: String = ""
var city_position: Vector2i
var city_level: int = 0
var city_data: Dictionary = {}

# UI引用
var city_label: Label
var city_sprite: Sprite2D

func _ready():
	# 获取子节点引用
	city_sprite = get_node("Sprite2D")
	city_label = get_node("Label")
	
	# 设置点击检测
	set_process_input(true)

func set_city_data(city_name_param: String, pos: Vector2i, data: Dictionary = {}):
	city_name = city_name_param
	city_position = pos
	city_data = data
	
	# 更新标签显示
	if city_label:
		city_label.text = city_name

func _input(event):
	# 检测鼠标点击
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 检查点击是否在城市范围内
			var mouse_pos = get_global_mouse_position()
			# 使用城市精灵的实际大小进行点击检测
			var city_sprite_size = city_sprite.texture.get_size() if city_sprite and city_sprite.texture else Vector2(32, 32)
			var city_rect = Rect2(global_position - city_sprite_size / 2, city_sprite_size)
			
			if city_rect.has_point(mouse_pos):
				on_city_clicked()

func on_city_clicked():
	print("点击了城市: ", city_name, " 位置: ", city_position)
	# 可以在这里添加更多城市交互逻辑
	# 比如显示城市信息面板、编辑城市名称等

func get_city_info() -> Dictionary:
	return {
		"name": city_name,
		"position": city_position,
		"level": city_level,
		"data": city_data
	}

func update_city_display():
	# 更新城市显示（根据等级调整外观）
	if city_label:
		city_label.text = city_name + " (Lv." + str(city_level) + ")"
	
	# 根据等级调整城市精灵的缩放
	if city_sprite:
		var scale_factor = 1.0 + (city_level * 0.1)  # 每级增加10%大小
		city_sprite.scale = Vector2(scale_factor, scale_factor)
