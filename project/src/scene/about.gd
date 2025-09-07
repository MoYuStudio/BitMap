extends Control

# 信号定义
signal back_to_menu

func _ready():
	# 连接按钮信号
	$CanvasLayer/VBoxContainer/BackButton.pressed.connect(_on_back_button_pressed)
	
	# 设置版本信息
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/VersionLabel.text = "版本: v3.0.0"
	$CanvasLayer/VBoxContainer/ScrollContainer/VBoxContainer/UpdateLabel.text = "更新时间: 2025年9月"

func _on_back_button_pressed():
	back_to_menu.emit()
