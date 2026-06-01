class_name AeroDeviceDetectionModioMetadata
extends RefCounted

const AeroDeviceDetectionScript := preload("res://addons/aerobeat-tool-device-detection/src/AeroDeviceDetection.gd")

const DEFAULT_KEY_PREFIX := "device_"
const UNKNOWN := "unknown"
const INCLUDED_DEVICE_FIELDS := [
	"profile",
	"platform",
	"os_name",
	"os_version",
	"cpu_name",
	"gpu_vendor",
	"gpu_name",
	"rendering_method",
	"display_server",
]

static func build_metadata_kvp_pairs(device_payload: Variant, extra_metadata: Dictionary = {}, key_prefix: String = DEFAULT_KEY_PREFIX) -> Array:
	var device := _normalize_device_payload(device_payload)
	var normalized_prefix := key_prefix.strip_edges()
	var pairs: Array = []

	for field_name in INCLUDED_DEVICE_FIELDS:
		var value := _normalize_scalar(device.get(field_name, UNKNOWN))
		if value == UNKNOWN:
			continue
		pairs.append("%s%s=%s" % [normalized_prefix, field_name, value])

	var screen_size := device.get("screen_size", {}) if typeof(device.get("screen_size", {})) == TYPE_DICTIONARY else {}
	var screen_width := int(screen_size.get("width", 0))
	var screen_height := int(screen_size.get("height", 0))
	if screen_width > 0:
		pairs.append("%sscreen_width=%d" % [normalized_prefix, screen_width])
	if screen_height > 0:
		pairs.append("%sscreen_height=%d" % [normalized_prefix, screen_height])

	var memory_gb := float(device.get("memory_gb", -1.0))
	if memory_gb > 0.0:
		pairs.append("%smemory_gb=%s" % [normalized_prefix, _format_decimal(memory_gb)])

	for extra_key in extra_metadata.keys():
		var normalized_key := str(extra_key).strip_edges()
		var normalized_value := str(extra_metadata.get(extra_key, "")).strip_edges()
		if normalized_key.is_empty() or normalized_value.is_empty():
			continue
		pairs.append("%s=%s" % [normalized_key, normalized_value])

	return pairs

static func build_metadata_kvp_text(device_payload: Variant, extra_metadata: Dictionary = {}, key_prefix: String = DEFAULT_KEY_PREFIX) -> String:
	return "\n".join(PackedStringArray(build_metadata_kvp_pairs(device_payload, extra_metadata, key_prefix)))

static func _normalize_device_payload(device_payload: Variant) -> Dictionary:
	var payload := _coerce_dictionary(device_payload)
	if payload.has("device") or payload.has("request") or payload.has("success") or payload.has("error"):
		return AeroDeviceDetectionScript.normalize_response(payload).get("device", {})
	return AeroDeviceDetectionScript.normalize_device(payload)

static func _coerce_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	if value is String:
		var parsed = JSON.parse_string(str(value))
		if typeof(parsed) == TYPE_DICTIONARY:
			return parsed
	return {}

static func _normalize_scalar(value: Variant) -> String:
	var normalized := str(value).strip_edges()
	return normalized if not normalized.is_empty() else UNKNOWN

static func _format_decimal(value: float) -> String:
	if is_equal_approx(value, round(value)):
		return str(int(round(value)))
	var formatted := "%.2f" % value
	while formatted.contains(".") and (formatted.ends_with("0") or formatted.ends_with(".")):
		formatted = formatted.left(-1)
	return formatted
