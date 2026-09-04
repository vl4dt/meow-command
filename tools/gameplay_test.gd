extends SceneTree
## Headless gameplay simulation: no input devices needed.
## Verifies title start, spawning, shooting, kills, armored shells,
## turret damage, wave progression, game over, restart.
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

	# --- 0) Scene starts at TITLE; begin a run
	if main.state != main.State.TITLE:
		push_error("FAIL: scene should start at TITLE (state=%d)" % main.state)
		errors += 1
	main._begin_run(false)
	await process_frame

	# --- 1) Wave 1 is active and rats start falling
	var spawned := await _wait_until(func(): return main.rats.size() > 0, 5000, "first rat to spawn")
	if not spawned:
		errors += 1

	# --- 2) Park a rat and shoot it: missile + explosion must kill it
	main._spawn_rat()
	await process_frame
	var rat = main.rats[main.rats.size() - 1]
	rat.speed = 0.0  # park it so the shot is fair
	main._fire_at(rat.position)
	# Look up by name (not object) so the lambda never captures a freed node.
	var rat_name: String = rat.name
	var killed := await _wait_until(
		func(): return main.rats.filter(func(d): return d.name == rat_name).is_empty(),
		6000, "shot rat to be killed")
	if not killed:
		errors += 1
	if main.score < 10:
		push_error("FAIL: no score awarded for rat kill (score=%d)" % main.score)
		errors += 1

	# --- 3) Armored shell needs exactly two hits
	var shell = RatMissile.new()
	shell.setup(RatMissile.Kind.SHELL, Vector2(640.0, 100.0), Vector2(640.0, 664.0), 30.0, false)
	shell.spawn_grace = 0.0
	main.world.add_child(shell)
	main.rats.append(shell)
	shell.take_hit()
	if shell.dead:
		push_error("FAIL: shell died on the first hit")
		errors += 1
	shell.take_hit()
	if not shell.dead:
		push_error("FAIL: shell survived two hits")
		errors += 1
	await process_frame  # let the reconciler clean it up

	# --- 4) A landed rat damages the nearest turret
	var turret = main.turrets[0]
	var hp_before: int = turret.hp
	var lander = RatMissile.new()
	lander.setup(RatMissile.Kind.NORMAL, Vector2(turret.position.x, -30.0), turret.position, 500.0, false)
	main.world.add_child(lander)
	main.rats.append(lander)
	var damaged := await _wait_until(
		func(): return turret.hp < hp_before or not turret.alive,
		4000, "turret to take landing damage")
	if not damaged:
		push_error("FAIL: landed rat did not damage a turret (hp=%d)" % turret.hp)
		errors += 1

	# --- 5) Clear the sky -> wave break -> wave 2
	main.rats_to_spawn = 0
	for d in main.rats.duplicate():
		d.dead = true
	var broke := await _wait_until(func(): return main.state == main.State.WAVE_BREAK, 5000, "wave break")
	if not broke:
		errors += 1
	var advanced := await _wait_until(func(): return main.wave == 2, 8000, "wave 2 to start")
	if not advanced:
		errors += 1

	# --- 6) Raze the whole city -> game over
	for c in main.cities:
		for b in c.buildings:
			b["hp"] = 0
	main._check_game_over()
	if main.state != main.State.GAME_OVER:
		push_error("FAIL: no game over with the city destroyed (state=%d)" % main.state)
		errors += 1

	# --- 7) Restart resets the world
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
	var alive_t := 0
	for t in main.turrets:
		if t.alive:
			alive_t += 1
	if main.turrets.size() != 4 or alive_t != 4:
		push_error("FAIL: turrets not rebuilt on restart (turrets=%d alive=%d)" % [main.turrets.size(), alive_t])
		errors += 1

	print("GAMEPLAY RESULT: ", "FAIL" if errors > 0 else "PASS")
	quit(1 if errors > 0 else 0)
