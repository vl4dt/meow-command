extends SceneTree
## Headless gameplay simulation: no input devices needed.
## Verifies spawning, shooting, kills, wave progression, game over, restart.
## NOTE: waits are real-time based — headless frame pacing is not 60fps.
## Run: godot --headless --path . -s res://tools/gameplay_test.gd

func _init() -> void:
	call_deferred("_run")


func _wait_until(cond: Callable, timeout_ms: int, what: String) -> bool:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < timeout_ms:
		if cond.call():
			return true
		await process_frame
	var ok: bool = cond.call()
	if not ok:
		push_error("TIMEOUT waiting for: %s" % what)
	return ok


func _run() -> void:
	var errors := 0
	var ps: PackedScene = load("res://scenes/main.tscn")
	if ps == null:
		push_error("FAILED TO LOAD main scene")
		quit(1)
		return
	var main = ps.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	# --- 1) Wave 1 is active and dogs start falling
	var spawned := await _wait_until(func(): return main.dogs.size() > 0, 5000, "first dog to spawn")
	if not spawned:
		errors += 1

	# --- 2) Park a dog and shoot it: missile + explosion must kill it
	main._spawn_dog()
	await process_frame
	var dog = main.dogs[main.dogs.size() - 1]
	dog.velocity = Vector2.ZERO  # park it so the shot is fair
	var turret = main.turrets[0]
	turret.cooldown = 0.0
	main._fire_at(dog.position)
	var killed := await _wait_until(func(): return not main.dogs.has(dog), 6000, "shot dog to be killed")
	if not killed:
		errors += 1
	if main.score < 10:
		push_error("FAIL: no score awarded for dog kill (score=%d)" % main.score)
		errors += 1

	# --- 3) Clear the sky -> wave break -> wave 2
	main.dogs_to_spawn = 0
	for d in main.dogs.duplicate():
		d.dead = true
	var broke := await _wait_until(func(): return main.state == main.State.WAVE_BREAK, 5000, "wave break")
	if not broke:
		errors += 1
	var advanced := await _wait_until(func(): return main.wave == 2, 8000, "wave 2 to start")
	if not advanced:
		errors += 1

	# --- 4) Raze the whole city -> game over (even mid-break)
	for c in main.cities:
		for b in c.buildings:
			b["hp"] = 0
	main._check_game_over()
	if main.state != main.State.GAME_OVER:
		push_error("FAIL: no game over with the city destroyed (state=%d)" % main.state)
		errors += 1

	# --- 5) Restart resets the world
	main._restart()
	await process_frame
	await process_frame
	if main.state != main.State.PLAYING or main.wave != 1 or main.score != 0:
		push_error("FAIL: restart did not reset state (state=%d wave=%d score=%d)" % [main.state, main.wave, main.score])
		errors += 1
	var all_hp := 0
	for c in main.cities:
		all_hp += c.alive_count()
	if main.cities.size() != 3 or all_hp != 9:
		push_error("FAIL: cities not rebuilt on restart (cities=%d buildings=%d)" % [main.cities.size(), all_hp])
		errors += 1

	print("GAMEPLAY RESULT: ", "FAIL" if errors > 0 else "PASS")
	quit(1 if errors > 0 else 0)
