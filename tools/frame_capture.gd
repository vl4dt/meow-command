extends SceneTree
## Captures a 1280×720 gameplay frame for store screenshots / marketing.
## Needs a REAL rendering context (viewport textures are empty under
## --headless), so run WITHOUT --headless — a window opens for ~5s:
##
##   godot --path . -s res://tools/frame_capture.gd
##
## Output: res://assets/store/frame_capture.png

const OUT := "res://assets/store/frame_capture.png"

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Force an exact 1280x720 borderless window so the capture has no
	# letterbox bars (the window manager may otherwise open it larger).
	root.size = Vector2i(1280, 720)
	root.borderless = true
	root.position = Vector2i(0, 0)
	await process_frame
	await process_frame

	var ps: PackedScene = load("res://scenes/main.tscn")
	if ps == null:
		push_error("FAILED TO LOAD main scene")
		quit(1)
		return
	var main = ps.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	main._begin_run(false)
	# Let rats fall into frame and the city settle...
	for i in range(300):
		await process_frame
	# A few shots for action (missiles + booms in the frame)
	for i in range(6):
		main._fire_at(Vector2(260.0 + float(i) * 140.0, 380.0 + float(i % 3) * 60.0))
		for f in range(12):
			await process_frame
	# Let the last explosions bloom
	for f in range(40):
		await process_frame

	# Re-assert the size right before capture (defence against resizes).
	root.size = Vector2i(1280, 720)
	await process_frame
	await process_frame

	var img: Image = root.get_texture().get_image()
	if img.get_width() != 1280 or img.get_height() != 720:
		push_warning("FRAME: unexpected size %dx%d (expected 1280x720)" % [img.get_width(), img.get_height()])
	if img.is_empty():
		push_error("FRAME RESULT: FAIL (empty image — run without --headless)")
		quit(1)
		return
	if not DirAccess.dir_exists_absolute("res://assets/store"):
		DirAccess.make_dir_recursive_absolute("res://assets/store")
	img.save_png(OUT)
	print("FRAME RESULT: PASS (", OUT, " ", img.get_width(), "x", img.get_height(), ")")
	quit(0)
