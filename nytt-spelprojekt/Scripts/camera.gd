extends Camera2D

const WINDOW_SIZE = Vector2(1920,1080)
const MAX_ZOOM := 5.0
const MIN_ZOOM := 1.0
const MAX_ZOOM_SPEED := 1.1
const PAN_SPEED := 10.0
const MOUSE_PAN_SPEED := 0.5

var right_mouse_dragging := false
var previous_mouse_pos := Vector2.ZERO


func _input(event: InputEvent) -> void:

	# === TOUCHPAN ===
	if event is InputEventPanGesture:
		var pan: InputEventPanGesture = event
		global_position += pan.delta * PAN_SPEED
		clamp_camera_to_limits()

	# === TOUCHZOOM ===
	if event is InputEventMagnifyGesture:
		_apply_zoom(event.factor)
	

	# ======================================================
	# === MOUSE ZOOM (scroll wheel) ========================
	# ======================================================
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(1.05) # zooma in lite
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(1.0 / 1.05) # zooma ut lite

		# === Start right mouse drag ===
		if event.button_index == MOUSE_BUTTON_RIGHT:
			right_mouse_dragging = event.pressed
			previous_mouse_pos = get_viewport().get_mouse_position()


	# ======================================================
	# === MOUSE DRAG PAN (right mouse button) =============
	# ======================================================
	if event is InputEventMouseMotion and right_mouse_dragging:
		var mouse_pos = event.position
		var delta = mouse_pos - previous_mouse_pos

		# Flytta kameran motsatt draget
		global_position -= delta * MOUSE_PAN_SPEED

		previous_mouse_pos = mouse_pos
		clamp_camera_to_limits()



# ==========================================================
# === Reusable zoom function ===============================
# ==========================================================
func _apply_zoom(factor: float) -> void:

	# Begränsa hur snabbt man får zooma i ett enda event
	factor = clamp(factor, 1.0 / MAX_ZOOM_SPEED, MAX_ZOOM_SPEED)

	var new_zoom = zoom * factor

	new_zoom.x = clamp(new_zoom.x, MIN_ZOOM, MAX_ZOOM)
	new_zoom.y = clamp(new_zoom.y, MIN_ZOOM, MAX_ZOOM)

	var size_after_zoom = get_viewport_rect().size / new_zoom

	if size_after_zoom.x > WINDOW_SIZE.x or size_after_zoom.y > WINDOW_SIZE.y:
		return

	zoom = new_zoom
	clamp_camera_to_limits()



func get_camera_rect() -> Rect2:
	var size = get_viewport_rect().size / zoom
	var half = size * 0.5
	return Rect2(global_position - half, size)


func clamp_camera_to_limits():
	var rect = get_camera_rect()

	var left = limit_left
	var right = limit_right
	var top = limit_top
	var bottom = limit_bottom

	var pos = global_position

	if rect.position.x < left:
		pos.x = left + rect.size.x * 0.5
	if rect.position.x + rect.size.x > right:
		pos.x = right - rect.size.x * 0.5

	if rect.position.y < top:
		pos.y = top + rect.size.y * 0.5
	if rect.position.y + rect.size.y > bottom:
		pos.y = bottom - rect.size.y * 0.5

	global_position = pos
