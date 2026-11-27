class_name Autotest
extends RefCounted
## DEBUG-BUILD-ONLY end-to-end self-test used by CI on an Android emulator (and runnable on desktop).
## Trigger: a file named `autotest` in the app's private storage (user://), which only exists if a
## test harness (adb run-as) creates it; release builds (OS.is_debug_build() == false) never run this.
## Phase 1 plays level 1 with real tray taps through the real UI, checks win/reward/save, then quits.
## Phase 2 (next launch) checks that progress and coins survived the restart. Result lines start
## with "AUTOTEST" (visible in logcat) and the process exit code is 0 on success, 1 on failure.

const TRIGGER := "user://autotest"
const PHASE2 := "user://autotest_phase2"


static func should_run() -> bool:
	return OS.is_debug_build() and FileAccess.file_exists(TRIGGER)


static func run(main: Control) -> void:
	var tree := main.get_tree()
	if FileAccess.file_exists(PHASE2):
		await _phase2(main, tree)
	else:
		await _phase1(main, tree)


static func _fail(tree: SceneTree, msg: String) -> void:
	print("AUTOTEST FAIL: ", msg)
	tree.quit(1)


static func _wait(tree: SceneTree, sec: float) -> void:
	await tree.create_timer(sec).timeout


static func _close_dialogs(screen: Node) -> void:
	for c in screen.get_children():
		if c is Modal:
			c.close()  # a test harness may close even non-dismissible dialogs


static func _phase1(main: Control, tree: SceneTree) -> void:
	print("AUTOTEST phase1 start (", OS.get_name(), ", ", Engine.get_version_info()["string"], ")")
	Progress.reset_all()
	Progress.tutorial_done = true
	Progress.seen_intros[1] = true
	Progress.save()
	var coins0: int = Progress.coins
	main.open_game(1)
	await _wait(tree, 1.6)
	var screen = main.get_child(0)
	if not (screen is GameScreen):
		_fail(tree, "game screen did not open (got %s)" % screen)
		return
	_close_dialogs(screen)
	await _wait(tree, 0.3)
	var sol: Array = Levels.get_level(1)["solution"]
	for mv in sol:
		var n := 0
		while not screen.board_view.settled() and n < 300:
			await tree.process_frame
			n += 1
		screen._on_tray_tapped(mv[0])
		screen._on_tray_tapped(mv[1])
	var n2 := 0
	while screen.session.status != GameSession.Status.WON and n2 < 300:
		await tree.process_frame
		n2 += 1
	await _wait(tree, 1.5)
	if screen.session.status != GameSession.Status.WON:
		_fail(tree, "level 1 was not won after the scripted solution")
		return
	var want := coins0 + Progress.REWARD_BASE + 3 * Progress.REWARD_PER_STAR
	if Progress.coins != want or not Progress.is_completed(1) or not Progress.is_unlocked(2):
		_fail(tree, "reward/unlock wrong: coins %d (want %d)" % [Progress.coins, want])
		return
	Progress.save()
	var f := FileAccess.open(PHASE2, FileAccess.WRITE)
	f.store_string(str(want))
	f.close()
	print("AUTOTEST phase1 PASS coins=", Progress.coins)
	tree.quit(0)


static func _phase2(_main: Control, tree: SceneTree) -> void:
	var f := FileAccess.open(PHASE2, FileAccess.READ)
	var want := int(f.get_as_text())
	f.close()
	print("AUTOTEST phase2 start")
	if Progress.coins != want or not Progress.is_completed(1) or not Progress.is_unlocked(2) or Progress.stars_of(1) != 3:
		_fail(tree, "progress lost after restart: coins %d (want %d), completed %s" % [Progress.coins, want, str(Progress.completed)])
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PHASE2))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TRIGGER))
	Progress.reset_all()
	print("AUTOTEST phase2 PASS")
	tree.quit(0)
