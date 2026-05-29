extends Control

const IMAGE_BACKGROUND_PATH := "res://assets/images/demo_tool_landscape.png"
const VIDEO_BACKGROUND_PATH := "assets/videos/calm_blue_sea_1.ogv"
const VIDEO_SLOT := "device_detection_background"
const BACKGROUND_KIND_IMAGE := "image"
const BACKGROUND_KIND_VIDEO := "video"
const BACKGROUND_KIND_ERROR := "error"
const GodotBackendBridgeScript := preload("res://addons/aerobeat-tool-video-player/src/AeroVideoPlayerGodotBackendBridge.gd")

const PRESETS := [
	{
		"id": "steam_gtx_1060_desktop",
		"label": "Steam Approx · GTX 1060 Desktop",
		"bundle": {
			"profile": "steam_gtx_1060_desktop",
			"device_name": "Steam Approx Desktop · GTX 1060",
			"model_name": "Custom Desktop",
			"vendor_name": "NVIDIA",
			"platform": "windows",
			"os_name": "Windows",
			"os_version": "11",
			"cpu_name": "Intel Core i7-8700K",
			"gpu_name": "NVIDIA GeForce GTX 1060",
			"gpu_vendor": "NVIDIA",
			"renderer_name": "NVIDIA GeForce GTX 1060",
			"rendering_method": "forward_plus",
			"display_server": "windows",
			"screen_size": {"width": 1920, "height": 1080},
			"memory_gb": 16.0,
			"tags": ["steam_approx", "desktop", "1080p"]
		}
	},
	{
		"id": "steam_rtx_3060_desktop",
		"label": "Steam Approx · RTX 3060 Desktop",
		"bundle": {
			"profile": "steam_rtx_3060_desktop",
			"device_name": "Steam Approx Desktop · RTX 3060",
			"model_name": "Custom Desktop",
			"vendor_name": "NVIDIA",
			"platform": "windows",
			"os_name": "Windows",
			"os_version": "11",
			"cpu_name": "AMD Ryzen 5 5600X",
			"gpu_name": "NVIDIA GeForce RTX 3060",
			"gpu_vendor": "NVIDIA",
			"renderer_name": "NVIDIA GeForce RTX 3060",
			"rendering_method": "forward_plus",
			"display_server": "windows",
			"screen_size": {"width": 2560, "height": 1440},
			"memory_gb": 16.0,
			"tags": ["steam_approx", "desktop", "1440p"]
		}
	},
	{
		"id": "steam_rtx_4060_laptop",
		"label": "Steam Approx · RTX 4060 Laptop",
		"bundle": {
			"profile": "steam_rtx_4060_laptop",
			"device_name": "Steam Approx Laptop · RTX 4060",
			"model_name": "Gaming Laptop",
			"vendor_name": "NVIDIA",
			"platform": "windows",
			"os_name": "Windows",
			"os_version": "11",
			"cpu_name": "Intel Core i7-13700H",
			"gpu_name": "NVIDIA GeForce RTX 4060 Laptop GPU",
			"gpu_vendor": "NVIDIA",
			"renderer_name": "NVIDIA GeForce RTX 4060 Laptop GPU",
			"rendering_method": "forward_plus",
			"display_server": "windows",
			"screen_size": {"width": 2560, "height": 1600},
			"memory_gb": 16.0,
			"tags": ["steam_approx", "laptop", "portable"]
		}
	},
	{
		"id": "steam_deck",
		"label": "Steam Approx · Steam Deck",
		"bundle": {
			"profile": "steam_deck",
			"device_name": "Steam Deck",
			"model_name": "Steam Deck LCD",
			"vendor_name": "AMD",
			"platform": "linux",
			"os_name": "SteamOS",
			"os_version": "3",
			"cpu_name": "AMD Custom APU 0405",
			"gpu_name": "AMD Aerith",
			"gpu_vendor": "AMD",
			"renderer_name": "AMD Aerith",
			"rendering_method": "forward_plus",
			"display_server": "x11",
			"screen_size": {"width": 1280, "height": 800},
			"memory_gb": 16.0,
			"tags": ["steam_approx", "handheld", "800p"]
		}
	},
	{
		"id": "steam_radeon_780m_handheld",
		"label": "Steam Approx · Radeon 780M Handheld",
		"bundle": {
			"profile": "steam_radeon_780m_handheld",
			"device_name": "Steam Approx Handheld · Radeon 780M",
			"model_name": "Windows Handheld",
			"vendor_name": "AMD",
			"platform": "windows",
			"os_name": "Windows",
			"os_version": "11",
			"cpu_name": "AMD Ryzen Z1 Extreme",
			"gpu_name": "AMD Radeon 780M Graphics",
			"gpu_vendor": "AMD",
			"renderer_name": "AMD Radeon 780M Graphics",
			"rendering_method": "forward_plus",
			"display_server": "windows",
			"screen_size": {"width": 1920, "height": 1080},
			"memory_gb": 16.0,
			"tags": ["steam_approx", "handheld", "1080p"]
		}
	},
	{
		"id": "surface_pro_8_iris_xe",
		"label": "Host Surface · Intel Iris Xe",
		"bundle": {
			"profile": "surface_pro_8_iris_xe",
			"device_name": "Surface Pro 8",
			"model_name": "Surface Pro 8",
			"vendor_name": "Intel",
			"platform": "windows",
			"os_name": "Windows",
			"os_version": "11",
			"cpu_name": "11th Gen Intel(R) Core(TM) i7-1185G7",
			"gpu_name": "Intel Iris Xe Graphics",
			"gpu_vendor": "Intel",
			"renderer_name": "Intel Iris Xe Graphics",
			"rendering_method": "forward_plus",
			"display_server": "windows",
			"screen_size": {"width": 2880, "height": 1920},
			"memory_gb": 16.0,
			"tags": ["surface", "intel", "portable"]
		}
	},
	{
		"id": "simulate_detection_failure",
		"label": "Simulate Detection Failure",
		"failure": {
			"profile": "simulate_detection_failure",
			"code": "device_detection_probe_failed",
			"message": "Simulated device detection failure for the proving surface.",
			"detail": {
				"source": "preset_button",
				"expected_branch": "failure"
			}
		}
	}
]

@onready var background_base: ColorRect = %BackgroundBase
@onready var background_image_surface: TextureRect = %BackgroundImageSurface
@onready var background_video_surface: Control = %BackgroundVideoSurface
@onready var status_label: Label = %StatusLabel
@onready var summary_label: Label = %SummaryLabel
@onready var background_mode_label: Label = %BackgroundModeLabel
@onready var info_label: Label = %InfoLabel
@onready var error_label: Label = %ErrorLabel
@onready var response_view: TextEdit = %ResponseView
@onready var preset_buttons: VBoxContainer = %PresetButtons

var _video_manager: AeroVideoPlayerManager
var _active_background_kind: String = BACKGROUND_KIND_ERROR
var _last_response: Dictionary = {}
var _last_failure: Dictionary = {}
var _last_request_source: String = "boot"

func _ready() -> void:
	AeroImageLoader.reset()
	AeroImageLoader.attach_slot_surface(VIDEO_SLOT, background_image_surface, true)
	_ensure_video_manager()
	_build_preset_buttons()
	status_label.text = "Booting live detection…"
	summary_label.text = "Waiting for AeroDeviceDetection to resolve the live profile."
	background_mode_label.text = "Background mode: pending"
	info_label.text = "Last request: live startup"
	error_label.text = ""
	response_view.text = "{}"
	_run_live_detection()

func _exit_tree() -> void:
	if _video_manager != null and is_instance_valid(_video_manager):
		_video_manager.unload(VIDEO_SLOT)
	AeroImageLoader.detach_slot_surface(VIDEO_SLOT)

func get_preset_button_count() -> int:
	return preset_buttons.get_child_count()

func get_active_background_kind() -> String:
	return _active_background_kind

func get_last_detection_response() -> Dictionary:
	return _last_response.duplicate(true)

func get_last_detection_failure() -> Dictionary:
	return _last_failure.duplicate(true)

func run_preset_by_id(preset_id: String) -> bool:
	for preset in PRESETS:
		if str(preset.get("id", "")) != preset_id:
			continue
		_run_preset(preset)
		return true
	return false

func rerun_live_detection() -> void:
	_run_live_detection()

func _ensure_video_manager() -> AeroVideoPlayerManager:
	if _video_manager != null and is_instance_valid(_video_manager):
		return _video_manager
	var backend_bridge := GodotBackendBridgeScript.new()
	_video_manager = backend_bridge.create_manager()
	add_child(_video_manager)
	_video_manager.attach_surface(background_video_surface, VIDEO_SLOT)
	_video_manager.set_cover_mode(AeroVideoPlayerManager.COVER_MODE_COVER, VIDEO_SLOT)
	_video_manager.set_audio_level(0.0, VIDEO_SLOT)
	return _video_manager

func _build_preset_buttons() -> void:
	for child in preset_buttons.get_children():
		child.queue_free()
	for preset in PRESETS:
		var button := Button.new()
		button.text = str(preset.get("label", preset.get("id", "Preset")))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_preset_button_pressed.bind(preset.duplicate(true)))
		preset_buttons.add_child(button)

func _on_preset_button_pressed(preset: Dictionary) -> void:
	_run_preset(preset)

func _run_live_detection() -> void:
	_last_request_source = "live_startup"
	status_label.text = "Running live detection…"
	AeroDeviceDetectionRuntime.detect_live(
		{"profile": "live_startup"},
		func(response: Dictionary) -> void:
			_apply_detection_response(response, _last_request_source),
		func(response: Dictionary) -> void:
			_apply_detection_failure(response, _last_request_source)
	)

func _run_preset(preset: Dictionary) -> void:
	_last_request_source = str(preset.get("id", "preset"))
	status_label.text = "Running preset %s…" % _last_request_source
	if preset.has("failure"):
		AeroDeviceDetectionRuntime.simulate_failure(
			preset.get("failure", {}).duplicate(true),
			func(response: Dictionary) -> void:
				_apply_detection_failure(response, _last_request_source)
		)
		return
	AeroDeviceDetectionRuntime.simulate_bundle(
		preset.get("bundle", {}).duplicate(true),
		func(response: Dictionary) -> void:
			_apply_detection_response(response, _last_request_source),
		func(response: Dictionary) -> void:
			_apply_detection_failure(response, _last_request_source)
	)

func _apply_detection_response(response: Dictionary, request_source: String) -> void:
	_last_response = response.duplicate(true)
	_last_failure = {}
	error_label.text = ""
	var device: Dictionary = response.get("device", {})
	var background_kind := BACKGROUND_KIND_IMAGE if _uses_image_background(device) else BACKGROUND_KIND_VIDEO
	_apply_background_for_success(background_kind, request_source)
	var device_name := str(device.get("device_name", "unknown device"))
	var gpu_name := str(device.get("gpu_name", "unknown GPU"))
	status_label.text = "Resolved %s via %s." % [device_name, request_source]
	summary_label.text = "GPU: %s | Background: %s" % [gpu_name, background_kind]
	background_mode_label.text = "Background mode: %s" % background_kind
	info_label.text = "Profile: %s | Platform: %s | Vendor: %s | Renderer: %s" % [
		str(device.get("profile", "unknown")),
		str(device.get("platform", "unknown")),
		str(device.get("gpu_vendor", "unknown")),
		str(device.get("renderer_name", "unknown")),
	]
	response_view.text = JSON.stringify(response, "\t")

func _apply_detection_failure(response: Dictionary, request_source: String) -> void:
	_last_response = response.duplicate(true)
	_last_failure = response.duplicate(true)
	_apply_background_for_failure()
	var error_info: Dictionary = response.get("error", {})
	status_label.text = "Detection failed via %s." % request_source
	summary_label.text = "Failure code: %s" % str(error_info.get("code", "unknown_error"))
	background_mode_label.text = "Background mode: %s" % BACKGROUND_KIND_ERROR
	info_label.text = "Profile: %s | Message: %s" % [
		str(response.get("request", {}).get("profile", "unknown")),
		str(error_info.get("message", "Unknown device detection error.")),
	]
	error_label.text = "Failure: %s" % str(error_info.get("message", "Unknown device detection error."))
	response_view.text = JSON.stringify(response, "\t")
	_log_detection_failure(response, request_source)

func _apply_background_for_success(background_kind: String, request_source: String) -> void:
	_active_background_kind = background_kind
	background_base.color = Color("#101820")
	background_image_surface.visible = background_kind == BACKGROUND_KIND_IMAGE
	background_video_surface.visible = background_kind == BACKGROUND_KIND_VIDEO
	if background_kind == BACKGROUND_KIND_IMAGE:
		var manager := _ensure_video_manager()
		manager.unload(VIDEO_SLOT)
		AeroImageLoader.load_image({
			"path": IMAGE_BACKGROUND_PATH,
			"slot": VIDEO_SLOT,
			"maintain_aspect_ratio": true,
			"metadata": {
				"source": "device_detection_testbed",
				"request_source": request_source,
			},
		})
		return
	var video_manager := _ensure_video_manager()
	video_manager.load({
		"path": VIDEO_BACKGROUND_PATH,
		"slot": VIDEO_SLOT,
		"loop": true,
		"autoplay": false,
		"cover_mode": AeroVideoPlayerManager.COVER_MODE_COVER,
		"audio_level": 0.0,
		"metadata": {
			"source": "device_detection_testbed",
			"request_source": request_source,
		},
	}, VIDEO_SLOT)
	video_manager.play(VIDEO_SLOT)

func _apply_background_for_failure() -> void:
	_active_background_kind = BACKGROUND_KIND_ERROR
	background_base.color = Color("#3a1116")
	background_image_surface.visible = false
	background_video_surface.visible = false
	if _video_manager != null and is_instance_valid(_video_manager):
		_video_manager.unload(VIDEO_SLOT)

func _uses_image_background(device: Dictionary) -> bool:
	var gpu_name := str(device.get("gpu_name", "")).to_lower()
	var renderer_name := str(device.get("renderer_name", "")).to_lower()
	return gpu_name.contains("intel iris xe") or renderer_name.contains("intel iris xe")

func _log_detection_failure(response: Dictionary, request_source: String) -> void:
	var payload := {
		"event": "device_detection_failure",
		"request_source": request_source,
		"response": response.duplicate(true),
	}
	printerr(JSON.stringify(payload, "\t"))
