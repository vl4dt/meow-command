extends SceneTree
## Headless smoke test: load the main scene, tick a few frames, assert it survives.
## Run: godot --headless --path . -s res://tools/smoke_test.gd

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var targets := ["res://scenes/main.tscn"]
	var errors := 0
	for path in targets:
		var ps: PackedScene = load(path)
		if ps == null:
			push_error("FAILED TO LOAD: " + path)
			errors += 1
			continue
		var node := ps.instantiate()
		root.add_child(node)
		await process_frame
		await process_frame
		await process_frame
		if not is_instance_valid(node):
			push_error("SCENE DIED: " + path)
			errors += 1
		else:
			node.queue_free()
			await process_frame
	print("SMOKE RESULT: ", "FAIL" if errors > 0 else "PASS")
	quit(1 if errors > 0 else 0)
