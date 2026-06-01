extends GutTest

const AeroDeviceDetectionScript := preload("res://addons/aerobeat-tool-device-detection/src/AeroDeviceDetection.gd")
const AeroDeviceDetectionModioMetadataScript := preload("res://addons/aerobeat-tool-device-detection/src/AeroDeviceDetectionModioMetadata.gd")
const AeroDeviceDetectionScriptPath := "res://addons/aerobeat-tool-device-detection/src/AeroDeviceDetection.gd"

func test_documented_autoload_name_matches_runtime_surface() -> void:
	var singleton = get_tree().root.get_node_or_null("AeroDeviceDetection")
	assert_not_null(singleton, "testbed should expose the documented AeroDeviceDetection autoload")
	assert_null(get_tree().root.get_node_or_null("AeroDeviceDetectionRuntime"), "legacy AeroDeviceDetectionRuntime autoload name should be removed")
	assert_true(singleton.has_method("detect_live"), "documented autoload should expose detect_live")
	assert_eq(singleton.get_script().resource_path, AeroDeviceDetectionScriptPath, "documented autoload should point at the shared source script")

func test_live_detection_callback_shape() -> void:
	var detector = AeroDeviceDetectionScript.new()
	add_child_autofree(detector)
	var seen: Array = []
	var operation = detector.detect_live(
		{"profile": "live_test"},
		func(response: Dictionary) -> void:
			seen.append(response)
	)
	assert_not_null(operation, "detect_live should return an operation object")
	assert_true(operation.has_method("on_success"), "operation should expose promise-like chaining")
	assert_true(operation.has_method("is_settled"), "operation should expose lifecycle helpers")
	assert_true(operation.is_settled(), "live detection should settle immediately for the contract slice")
	assert_true(operation.did_succeed(), "live detection should succeed in best-effort mode")
	assert_eq(seen.size(), 1, "live detection should invoke the success callback once")
	_assert_success_shape(seen[0], "live", false, "live_test")
	assert_eq(detector.get_last_response().get("request", {}).get("kind", ""), "live", "detector should store last live response")

func test_simulated_bundle_success_callback_shape() -> void:
	var detector = AeroDeviceDetectionScript.new()
	add_child_autofree(detector)
	var seen: Array = []
	var operation = detector.simulate_bundle(
		{
			"profile": "surface_pro_8",
			"device_name": "Surface Pro 8",
			"model_name": "Surface Pro 8",
			"platform": "windows",
			"os_name": "Windows",
			"os_version": "11",
			"cpu_name": "11th Gen Intel(R) Core(TM) i7-1185G7",
			"gpu_name": "Intel Iris Xe Graphics",
			"gpu_vendor": "Intel",
			"renderer_name": "forward_plus",
			"rendering_method": "forward_plus",
			"display_server": "windows",
			"screen_size": {"width": 2880, "height": 1920},
			"memory_gb": 16.0,
			"tags": ["surface", "intel", "portable"],
		},
		func(response: Dictionary) -> void:
			seen.append(response)
	)
	assert_not_null(operation, "simulate_bundle should return an operation object")
	assert_true(operation.did_succeed(), "simulate_bundle should succeed")
	assert_eq(seen.size(), 1, "simulate_bundle should invoke its success callback")
	_assert_success_shape(seen[0], "simulation", true, "surface_pro_8")
	assert_eq(seen[0].get("device", {}).get("gpu_name", ""), "Intel Iris Xe Graphics", "simulated payload should preserve GPU name")
	assert_eq(seen[0].get("device", {}).get("screen_size", {}).get("width", 0), 2880, "simulated payload should preserve screen width")

func test_simulated_failure_rejection_callback_shape() -> void:
	var detector = AeroDeviceDetectionScript.new()
	add_child_autofree(detector)
	var seen: Array = []
	var operation = detector.simulate_failure(
		{
			"profile": "failure_case",
			"code": "device_permission_denied",
			"message": "Camera permission denied.",
			"detail": {
				"source": "user_settings",
				"retryable": false,
			},
		},
		func(response: Dictionary) -> void:
			seen.append(response)
	)
	assert_not_null(operation, "simulate_failure should return an operation object")
	assert_true(operation.is_settled(), "simulate_failure should settle immediately")
	assert_false(operation.did_succeed(), "simulate_failure should reject")
	assert_eq(seen.size(), 1, "simulate_failure should invoke the failure callback once")
	_assert_failure_shape(seen[0], "simulation", true, "failure_case", "device_permission_denied")
	assert_eq(detector.get_last_error().get("error", {}).get("code", ""), "device_permission_denied", "detector should store last error response")

func test_normalized_response_device_error_structure() -> void:
	var response = AeroDeviceDetectionScript.normalize_response({
		"success": false,
		"request": {
			"kind": "simulation",
			"profile": "normalized_test",
			"simulated": true,
			"requested_at_unix": 123,
		},
		"device": {
			"gpu_name": "",
			"screen_size": Vector2i(1920, 1080),
			"tags": ["intel", "intel", ""],
			"metadata": "bad",
		},
		"error": {
			"code": "",
			"message": "",
			"detail": "bad",
		},
		"meta": "bad",
	})
	assert_false(response.get("success", true), "normalized response should preserve success=false")
	assert_eq(response.get("schema", ""), AeroDeviceDetectionScript.RESPONSE_SCHEMA, "normalized response should stamp the schema")
	assert_eq(response.get("device", {}).get("gpu_name", ""), AeroDeviceDetectionScript.UNKNOWN, "blank GPU names should normalize to unknown")
	assert_eq(response.get("device", {}).get("screen_size", {}).get("height", 0), 1080, "Vector2i screen size should normalize into a dictionary")
	assert_eq(response.get("device", {}).get("tags", []).size(), 1, "tags should be deduplicated and blanks removed")
	assert_typeof(response.get("device", {}).get("metadata", {}), TYPE_DICTIONARY, "device metadata should normalize to a dictionary")
	assert_eq(response.get("error", {}).get("code", ""), "unknown_error", "blank error codes should normalize to unknown_error")
	assert_typeof(response.get("error", {}).get("detail", {}), TYPE_DICTIONARY, "error detail should normalize to a dictionary")
	assert_typeof(response.get("meta", {}), TYPE_DICTIONARY, "meta should normalize to a dictionary")

func _assert_success_shape(response: Dictionary, expected_kind: String, expected_simulated: bool, expected_profile: String) -> void:
	assert_true(response.get("success", false), "response should be successful")
	assert_eq(response.get("schema", ""), AeroDeviceDetectionScript.RESPONSE_SCHEMA, "response should expose the device detection schema")
	assert_eq(response.get("request", {}).get("kind", ""), expected_kind, "request kind should match")
	assert_eq(response.get("request", {}).get("simulated", not expected_simulated), expected_simulated, "simulated flag should match")
	assert_eq(response.get("request", {}).get("profile", ""), expected_profile, "profile should match")
	assert_typeof(response.get("device", {}), TYPE_DICTIONARY, "response should always include a device dictionary")
	assert_typeof(response.get("error", {}), TYPE_DICTIONARY, "response should always include an error dictionary")
	assert_typeof(response.get("meta", {}), TYPE_DICTIONARY, "response should always include a meta dictionary")

func test_modio_metadata_helper_builds_stable_upload_testing_pairs() -> void:
	var metadata_pairs := AeroDeviceDetectionModioMetadataScript.build_metadata_kvp_pairs({
		"success": true,
		"request": {
			"kind": "simulation",
			"profile": "surface_pro_8_upload_fixture",
			"simulated": true,
			"requested_at_unix": 123,
		},
		"device": {
			"profile": "surface_pro_8_upload_fixture",
			"device_name": "Surface Pro 8",
			"vendor_id": "SERIAL-123",
			"model_name": "Surface Pro 8",
			"platform": "windows",
			"os_name": "Windows",
			"os_version": "11",
			"cpu_name": "11th Gen Intel(R) Core(TM) i7-1185G7",
			"gpu_name": "Intel Iris Xe Graphics",
			"gpu_vendor": "Intel",
			"renderer_name": "forward_plus",
			"rendering_method": "forward_plus",
			"display_server": "windows",
			"screen_size": {"width": 2880, "height": 1920},
			"memory_gb": 16.0,
			"tags": ["surface", "intel", "portable"],
			"metadata": {
				"engine": {"major": 4},
				"feature_tags": ["debug"],
			},
		},
		"meta": {"detected_at_unix": 456},
	}, {"aerobeat_version": "1.0.0"})

	assert_eq(metadata_pairs, [
		"device_profile=surface_pro_8_upload_fixture",
		"device_platform=windows",
		"device_os_name=Windows",
		"device_os_version=11",
		"device_cpu_name=11th Gen Intel(R) Core(TM) i7-1185G7",
		"device_gpu_vendor=Intel",
		"device_gpu_name=Intel Iris Xe Graphics",
		"device_rendering_method=forward_plus",
		"device_display_server=windows",
		"device_screen_width=2880",
		"device_screen_height=1920",
		"device_memory_gb=16",
		"aerobeat_version=1.0.0",
	], "helper should keep only stable/useful hardware fields plus explicit extra metadata")
	assert_false(metadata_pairs.has("device_vendor_id=SERIAL-123"), "privacy-heavy identifiers should stay out of upload metadata")
	assert_false(metadata_pairs.any(func(entry): return str(entry).contains("detected_at_unix")), "ephemeral timestamps should stay out of upload metadata")
	assert_false(metadata_pairs.any(func(entry): return str(entry).contains("feature_tags")), "noisy runtime metadata should stay out of upload metadata")

func test_modio_metadata_helper_accepts_json_string_payloads() -> void:
	var metadata_text := AeroDeviceDetectionModioMetadataScript.build_metadata_kvp_text('{"device":{"profile":"steam_rtx_3060_desktop","platform":"windows","os_name":"Windows","os_version":"11","gpu_vendor":"NVIDIA","gpu_name":"GeForce RTX 3060","rendering_method":"forward_plus","display_server":"windows","screen_size":{"width":1920,"height":1080},"memory_gb":32}}', {"aerobeat_version": "1.0.0"})
	assert_string_contains(metadata_text, "device_profile=steam_rtx_3060_desktop")
	assert_string_contains(metadata_text, "device_gpu_name=GeForce RTX 3060")
	assert_string_contains(metadata_text, "aerobeat_version=1.0.0")

func _assert_failure_shape(response: Dictionary, expected_kind: String, expected_simulated: bool, expected_profile: String, expected_code: String) -> void:
	assert_false(response.get("success", true), "response should be a failure payload")
	assert_eq(response.get("schema", ""), AeroDeviceDetectionScript.RESPONSE_SCHEMA, "failure payload should keep the same schema")
	assert_eq(response.get("request", {}).get("kind", ""), expected_kind, "failure request kind should match")
	assert_eq(response.get("request", {}).get("simulated", not expected_simulated), expected_simulated, "failure simulated flag should match")
	assert_eq(response.get("request", {}).get("profile", ""), expected_profile, "failure profile should match")
	assert_eq(response.get("error", {}).get("code", ""), expected_code, "failure error code should match")
	assert_typeof(response.get("device", {}), TYPE_DICTIONARY, "failure payload should still include a normalized device dictionary")
	assert_typeof(response.get("meta", {}), TYPE_DICTIONARY, "failure payload should still include meta")
