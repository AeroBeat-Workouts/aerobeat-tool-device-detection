extends GutTest

const TestbedScene := preload("res://scenes/device_detection_testbed.tscn")

func test_startup_live_detection_builds_seven_preset_buttons() -> void:
	var scene := TestbedScene.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_eq(scene.get_preset_button_count(), 7, "The proving surface should expose exactly seven preset buttons")
	assert_true(scene.get_last_detection_response().get("success", false), "Boot should run the live detection success path")
	assert_true(
		[scene.BACKGROUND_KIND_IMAGE, scene.BACKGROUND_KIND_VIDEO].has(scene.get_active_background_kind()),
		"Live detection should resolve into either the image or video background branch"
	)
	assert_true(_find_text_edit(scene, "ResponseView").text.contains("\"schema\""), "The info panel should render the structured response payload")

func test_surface_preset_routes_to_image_background() -> void:
	var scene := TestbedScene.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_true(scene.run_preset_by_id("surface_pro_8_iris_xe"), "Surface preset should exist")
	assert_eq(scene.get_active_background_kind(), scene.BACKGROUND_KIND_IMAGE, "Intel Iris Xe should select the image loader background")
	assert_eq(String(AeroImageLoader.get_last_result().get("detail", {}).get("path", "")), scene.IMAGE_BACKGROUND_PATH, "Image branch should load the copied shared image asset")
	assert_true(_find_label(scene, "BackgroundModeLabel").text.contains("image"), "GUI should report the image background mode")

func test_non_intel_preset_routes_to_video_background() -> void:
	var scene := TestbedScene.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_true(scene.run_preset_by_id("steam_rtx_3060_desktop"), "Steam RTX 3060 preset should exist")
	assert_eq(scene.get_active_background_kind(), scene.BACKGROUND_KIND_VIDEO, "Non-Intel presets should use the looping video background")
	assert_true(_find_label(scene, "SummaryLabel").text.contains("video"), "GUI summary should mention the video branch")
	assert_true(_find_text_edit(scene, "ResponseView").text.contains("steam_rtx_3060_desktop"), "GUI payload should update to the selected preset profile")

func test_failure_preset_updates_error_branch_and_failure_payload() -> void:
	var scene := TestbedScene.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_true(scene.run_preset_by_id("simulate_detection_failure"), "Failure preset should exist")
	assert_eq(scene.get_active_background_kind(), scene.BACKGROUND_KIND_ERROR, "Failure preset should clear to the error background branch")
	assert_eq(String(scene.get_last_detection_failure().get("error", {}).get("code", "")), "device_detection_probe_failed", "Failure payload should be preserved for UI + logging")
	assert_true(_find_label(scene, "ErrorLabel").text.contains("Simulated device detection failure"), "GUI should surface the failure message")

func _find_label(scene: Node, name: String) -> Label:
	return scene.find_child(name, true, false) as Label

func _find_text_edit(scene: Node, name: String) -> TextEdit:
	return scene.find_child(name, true, false) as TextEdit
