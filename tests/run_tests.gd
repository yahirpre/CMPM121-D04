## Headless test runner: deno task test
## Godot exits 0 on script errors, so this runner fails loudly instead:
## an unloadable test file or zero tests run both count as failure.
extends SceneTree


func _initialize() -> void:
	var failed := 0
	var passed := 0
	for file in DirAccess.get_files_at("res://tests"):
		if not file.ends_with("_test.gd"):
			continue
		var script: GDScript = load("res://tests/" + file)
		if script == null or not script.can_instantiate():
			failed += 1
			print("  FAIL %s: could not load (see errors above)" % file)
			continue
		for method in script.get_script_method_list():
			if not method.name.begins_with("test_"):
				continue
			var suite = script.new()
			suite.call(method.name)
			if suite.failures.is_empty():
				passed += 1
				print("  ok   %s :: %s" % [file, method.name])
			else:
				failed += 1
				print("  FAIL %s :: %s: %s" % [file, method.name, ", ".join(suite.failures)])
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 or passed == 0 else 0)
