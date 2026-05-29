## Public runtime entrypoint for AeroBeat device detection.
##
## The facade returns callback-friendly operations for both live best-effort
## detection and deterministic simulation bundles while preserving the same
## normalized response/device/error contract for success and failure payloads.
extends Node

const OperationScript := preload("res://addons/aerobeat-tool-device-detection/src/AeroDeviceDetectionOperation.gd")
const VERSION := "0.1.0"
const DEFAULT_PROFILE := "live_best_effort"
const UNKNOWN := "unknown"
const RESPONSE_SCHEMA := "aerobeat.device_detection.v1"

signal detection_started(request: Dictionary)
signal detection_succeeded(response: Dictionary)
signal detection_failed(response: Dictionary)

var _last_response: Dictionary = {}
var _last_error: Dictionary = {}

func detect(options: Dictionary = {}, on_success: Callable = Callable(), on_failure: Callable = Callable()):
	return detect_live(options, on_success, on_failure)

func detect_live(options: Dictionary = {}, on_success: Callable = Callable(), on_failure: Callable = Callable()):
	var normalized_options := _normalize_options(options)
	var request := _build_request("live", normalized_options)
	detection_started.emit(request.duplicate(true))
	var operation: RefCounted = OperationScript.new()
	if on_success.is_valid():
		operation.call("on_success", on_success)
	if on_failure.is_valid():
		operation.call("on_failure", on_failure)

	var force_failure := bool(normalized_options.get("force_failure", false))
	if force_failure:
		return _settle_failure(
			operation,
			request,
			"device_detection_forced_failure",
			"Live device detection was forced to fail for validation.",
			{
				"reason": str(normalized_options.get("failure_reason", "forced")),
				"profile": str(normalized_options.get("profile", DEFAULT_PROFILE)),
			}
		)

	var device := _collect_live_device(normalized_options)
	var response := _build_success_response(request, device, {
		"detection_path": "live",
		"best_effort": true,
		"profile": str(normalized_options.get("profile", DEFAULT_PROFILE)),
	})
	return _settle_success(operation, response)

func simulate_bundle(bundle: Dictionary, on_success: Callable = Callable(), on_failure: Callable = Callable()):
	var normalized_options := _normalize_options(bundle)
	var request := _build_request("simulation", normalized_options)
	detection_started.emit(request.duplicate(true))
	var operation: RefCounted = OperationScript.new()
	if on_success.is_valid():
		operation.call("on_success", on_success)
	if on_failure.is_valid():
		operation.call("on_failure", on_failure)
	var device := normalize_device(bundle)
	var response := _build_success_response(request, device, {
		"detection_path": "simulation",
		"best_effort": false,
		"profile": str(normalized_options.get("profile", _resolve_device_profile(device))),
	})
	return _settle_success(operation, response)

func simulate_failure(failure: Dictionary = {}, on_failure: Callable = Callable()):
	var normalized_failure := failure.duplicate(true)
	var request := _build_request("simulation", _normalize_options(normalized_failure))
	detection_started.emit(request.duplicate(true))
	var operation: RefCounted = OperationScript.new()
	if on_failure.is_valid():
		operation.call("on_failure", on_failure)
	var code := str(normalized_failure.get("code", "device_detection_rejected")).strip_edges()
	if code.is_empty():
		code = "device_detection_rejected"
	var message := str(normalized_failure.get("message", "Device detection was rejected.")).strip_edges()
	if message.is_empty():
		message = "Device detection was rejected."
	var detail := normalized_failure.get("detail", {}) if typeof(normalized_failure.get("detail", {})) == TYPE_DICTIONARY else {}
	return _settle_failure(operation, request, code, message, detail)

func get_last_response() -> Dictionary:
	return _last_response.duplicate(true)

func get_last_error() -> Dictionary:
	return _last_error.duplicate(true)

func get_capabilities() -> Dictionary:
	return {
		"service": "device_detection",
		"schema": RESPONSE_SCHEMA,
		"supports_live_detection": true,
		"supports_simulation": true,
		"supports_failure_simulation": true,
		"promise_style_callbacks": true,
	}

func normalize_response_payload(raw_response: Dictionary = {}) -> Dictionary:
	return normalize_response(raw_response)

func normalize_device_payload(raw_device: Dictionary = {}) -> Dictionary:
	return normalize_device(raw_device)

func normalize_error_payload(raw_error: Dictionary = {}) -> Dictionary:
	return normalize_error(raw_error)

static func normalize_device(raw_device: Dictionary = {}) -> Dictionary:
	var normalized := {
		"profile": UNKNOWN,
		"device_name": UNKNOWN,
		"vendor_name": UNKNOWN,
		"vendor_id": UNKNOWN,
		"model_name": UNKNOWN,
		"platform": UNKNOWN,
		"os_name": UNKNOWN,
		"os_version": UNKNOWN,
		"cpu_name": UNKNOWN,
		"gpu_name": UNKNOWN,
		"gpu_vendor": UNKNOWN,
		"renderer_name": UNKNOWN,
		"rendering_method": UNKNOWN,
		"display_server": UNKNOWN,
		"screen_size": {
			"width": 0,
			"height": 0,
		},
		"memory_gb": -1.0,
		"tags": [],
		"metadata": {},
	}
	for key in raw_device.keys():
		normalized[key] = raw_device[key]
	normalized["profile"] = _normalize_string(normalized.get("profile", UNKNOWN))
	normalized["device_name"] = _normalize_string(normalized.get("device_name", normalized.get("model_name", UNKNOWN)))
	normalized["vendor_name"] = _normalize_string(normalized.get("vendor_name", normalized.get("gpu_vendor", UNKNOWN)))
	normalized["vendor_id"] = _normalize_string(normalized.get("vendor_id", UNKNOWN))
	normalized["model_name"] = _normalize_string(normalized.get("model_name", normalized.get("device_name", UNKNOWN)))
	normalized["platform"] = _normalize_string(normalized.get("platform", UNKNOWN))
	normalized["os_name"] = _normalize_string(normalized.get("os_name", normalized.get("platform", UNKNOWN)))
	normalized["os_version"] = _normalize_string(normalized.get("os_version", UNKNOWN))
	normalized["cpu_name"] = _normalize_string(normalized.get("cpu_name", UNKNOWN))
	normalized["gpu_name"] = _normalize_string(normalized.get("gpu_name", UNKNOWN))
	normalized["gpu_vendor"] = _normalize_string(normalized.get("gpu_vendor", normalized.get("vendor_name", UNKNOWN)))
	normalized["renderer_name"] = _normalize_string(normalized.get("renderer_name", UNKNOWN))
	normalized["rendering_method"] = _normalize_string(normalized.get("rendering_method", UNKNOWN))
	normalized["display_server"] = _normalize_string(normalized.get("display_server", UNKNOWN))
	normalized["screen_size"] = _normalize_screen_size(normalized.get("screen_size", {}))
	normalized["memory_gb"] = float(normalized.get("memory_gb", -1.0))
	normalized["tags"] = _normalize_tags(normalized.get("tags", []))
	if typeof(normalized.get("metadata", {})) != TYPE_DICTIONARY:
		normalized["metadata"] = {}
	return normalized

static func normalize_error(raw_error: Dictionary = {}) -> Dictionary:
	var normalized := {
		"code": UNKNOWN,
		"message": UNKNOWN,
		"detail": {},
		"retryable": false,
	}
	for key in raw_error.keys():
		normalized[key] = raw_error[key]
	var code := _normalize_string(normalized.get("code", UNKNOWN))
	normalized["code"] = code if code != UNKNOWN else "unknown_error"
	var message := _normalize_string(normalized.get("message", UNKNOWN))
	normalized["message"] = message if message != UNKNOWN else "Unknown device detection error."
	if typeof(normalized.get("detail", {})) != TYPE_DICTIONARY:
		normalized["detail"] = {}
	normalized["retryable"] = bool(normalized.get("retryable", false))
	return normalized

static func normalize_response(raw_response: Dictionary = {}) -> Dictionary:
	var normalized := {
		"schema": RESPONSE_SCHEMA,
		"success": false,
		"request": {
			"kind": UNKNOWN,
			"profile": UNKNOWN,
			"simulated": false,
			"requested_at_unix": 0,
		},
		"device": normalize_device(),
		"error": normalize_error(),
		"meta": {},
	}
	for key in raw_response.keys():
		normalized[key] = raw_response[key]
	normalized["schema"] = RESPONSE_SCHEMA
	normalized["success"] = bool(normalized.get("success", false))
	if typeof(normalized.get("request", {})) != TYPE_DICTIONARY:
		normalized["request"] = {}
	var request := {
		"kind": _normalize_string(normalized.get("request", {}).get("kind", UNKNOWN)),
		"profile": _normalize_string(normalized.get("request", {}).get("profile", UNKNOWN)),
		"simulated": bool(normalized.get("request", {}).get("simulated", false)),
		"requested_at_unix": int(normalized.get("request", {}).get("requested_at_unix", 0)),
	}
	normalized["request"] = request
	normalized["device"] = normalize_device(normalized.get("device", {}))
	normalized["error"] = normalize_error(normalized.get("error", {}))
	if typeof(normalized.get("meta", {})) != TYPE_DICTIONARY:
		normalized["meta"] = {}
	return normalized

func _collect_live_device(options: Dictionary) -> Dictionary:
	var screen_size := _resolve_screen_size()
	var renderer_name := _resolve_renderer_name()
	var gpu_name := renderer_name
	var gpu_vendor := _infer_gpu_vendor(renderer_name)
	var profile := str(options.get("profile", DEFAULT_PROFILE))
	var memory_gb := -1.0
	if options.has("memory_gb_hint"):
		memory_gb = float(options.get("memory_gb_hint", -1.0))
	var platform := _map_platform_name(OS.get_name())
	return normalize_device({
		"profile": profile,
		"device_name": _resolve_device_name(platform, gpu_name),
		"vendor_name": gpu_vendor,
		"model_name": _resolve_device_name(platform, gpu_name),
		"platform": platform,
		"os_name": OS.get_name(),
		"os_version": OS.get_version(),
		"cpu_name": _normalize_string(OS.get_processor_name()),
		"gpu_name": gpu_name,
		"gpu_vendor": gpu_vendor,
		"renderer_name": renderer_name,
		"rendering_method": _resolve_rendering_method(),
		"display_server": _normalize_string(DisplayServer.get_name()),
		"screen_size": screen_size,
		"memory_gb": memory_gb,
		"tags": _build_live_tags(platform, gpu_vendor, screen_size),
		"metadata": {
			"engine": Engine.get_version_info(),
			"feature_tags": OS.get_cmdline_user_args(),
			"best_effort": true,
		},
	})

func _build_success_response(request: Dictionary, device: Dictionary, meta_overrides: Dictionary = {}) -> Dictionary:
	var response := normalize_response({
		"success": true,
		"request": request.duplicate(true),
		"device": device.duplicate(true),
		"error": normalize_error({
			"code": "none",
			"message": "",
			"detail": {},
			"retryable": false,
		}),
		"meta": {
			"detected_at_unix": Time.get_unix_time_from_system(),
		},
	})
	for key in meta_overrides.keys():
		response["meta"][key] = meta_overrides[key]
	return response

func _settle_success(operation, response: Dictionary):
	_last_response = normalize_response(response)
	_last_error = {}
	detection_succeeded.emit(_last_response.duplicate(true))
	operation.settle_success(_last_response.duplicate(true))
	return operation

func _settle_failure(operation, request: Dictionary, code: String, message: String, detail: Dictionary = {}):
	var response := normalize_response({
		"success": false,
		"request": request.duplicate(true),
		"device": normalize_device({
			"profile": str(request.get("profile", UNKNOWN)),
			"platform": _map_platform_name(OS.get_name()),
		}),
		"error": normalize_error({
			"code": code,
			"message": message,
			"detail": detail.duplicate(true),
			"retryable": false,
		}),
		"meta": {
			"detected_at_unix": Time.get_unix_time_from_system(),
			"detection_path": str(request.get("kind", UNKNOWN)),
		},
	})
	_last_response = response.duplicate(true)
	_last_error = response.duplicate(true)
	detection_failed.emit(response.duplicate(true))
	operation.settle_failure(response.duplicate(true))
	return operation

func _build_request(kind: String, options: Dictionary) -> Dictionary:
	return {
		"kind": kind,
		"profile": str(options.get("profile", DEFAULT_PROFILE)),
		"simulated": kind != "live",
		"requested_at_unix": Time.get_unix_time_from_system(),
	}

func _normalize_options(options: Dictionary) -> Dictionary:
	var normalized := {
		"profile": DEFAULT_PROFILE,
		"force_failure": false,
		"failure_reason": "",
	}
	for key in options.keys():
		normalized[key] = options[key]
	normalized["profile"] = _normalize_string(normalized.get("profile", DEFAULT_PROFILE))
	if normalized["profile"] == UNKNOWN:
		normalized["profile"] = DEFAULT_PROFILE
	normalized["force_failure"] = bool(normalized.get("force_failure", false))
	normalized["failure_reason"] = str(normalized.get("failure_reason", "")).strip_edges()
	return normalized

func _resolve_screen_size() -> Dictionary:
	var size := Vector2i.ZERO
	if DisplayServer.get_name() != "headless":
		var screen_size := DisplayServer.screen_get_size()
		if screen_size.x > 0 and screen_size.y > 0:
			size = screen_size
	if size == Vector2i.ZERO and get_tree() != null and get_tree().root != null:
		var rect_size := get_tree().root.get_visible_rect().size
		if rect_size.x > 0 and rect_size.y > 0:
			size = Vector2i(int(rect_size.x), int(rect_size.y))
	return _normalize_screen_size(size)

func _resolve_renderer_name() -> String:
	if RenderingServer.has_method("get_current_rendering_method"):
		var current_method := str(RenderingServer.get_current_rendering_method()).strip_edges()
		if not current_method.is_empty():
			return current_method
	return _resolve_rendering_method()

func _resolve_rendering_method() -> String:
	if ProjectSettings.has_setting("rendering/renderer/rendering_method"):
		return _normalize_string(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	return UNKNOWN

func _resolve_device_name(platform: String, gpu_name: String) -> String:
	var cpu_name := _normalize_string(OS.get_processor_name())
	if cpu_name != UNKNOWN:
		return "%s / %s" % [platform, cpu_name]
	if gpu_name != UNKNOWN:
		return "%s / %s" % [platform, gpu_name]
	return platform

func _build_live_tags(platform: String, gpu_vendor: String, screen_size: Dictionary) -> Array:
	var tags: Array = [platform]
	if gpu_vendor != UNKNOWN:
		tags.append(gpu_vendor.to_lower().replace(" ", "_"))
	var height := int(screen_size.get("height", 0))
	if height >= 2160:
		tags.append("4k")
	elif height >= 1440:
		tags.append("1440p")
	elif height >= 1080:
		tags.append("1080p")
	else:
		tags.append("sub_1080p")
	return _normalize_tags(tags)

static func _normalize_string(value: Variant) -> String:
	var normalized := str(value).strip_edges()
	return normalized if not normalized.is_empty() else UNKNOWN

static func _normalize_screen_size(value: Variant) -> Dictionary:
	if value is Vector2i:
		var vector: Vector2i = value
		return {"width": max(0, vector.x), "height": max(0, vector.y)}
	var dict := value if typeof(value) == TYPE_DICTIONARY else {}
	return {
		"width": max(0, int(dict.get("width", 0))),
		"height": max(0, int(dict.get("height", 0))),
	}

static func _normalize_tags(value: Variant) -> Array:
	var tags: Array = []
	var source: Array = value if typeof(value) == TYPE_ARRAY else []
	for entry in source:
		var normalized := str(entry).strip_edges()
		if normalized.is_empty():
			continue
		if not tags.has(normalized):
			tags.append(normalized)
	return tags

static func _map_platform_name(raw_name: String) -> String:
	match raw_name:
		"Linux", "FreeBSD", "NetBSD", "OpenBSD":
			return "linux"
		"Windows":
			return "windows"
		"macOS":
			return "macos"
		"Android":
			return "android"
		"iOS":
			return "ios"
		"Web":
			return "web"
		_:
			return raw_name.to_lower().replace(" ", "_")

static func _infer_gpu_vendor(renderer_name: String) -> String:
	var lowered := renderer_name.to_lower()
	if lowered.contains("intel"):
		return "Intel"
	if lowered.contains("nvidia"):
		return "NVIDIA"
	if lowered.contains("amd") or lowered.contains("radeon"):
		return "AMD"
	if lowered.contains("apple"):
		return "Apple"
	return UNKNOWN

static func _resolve_device_profile(device: Dictionary) -> String:
	var profile := _normalize_string(device.get("profile", UNKNOWN))
	return profile if profile != UNKNOWN else DEFAULT_PROFILE
