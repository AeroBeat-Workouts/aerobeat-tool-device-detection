# AeroBeat Tool Device Detection

`aerobeat-tool-device-detection` provides a sharable Godot runtime surface for AeroBeat tool-side hardware detection.

The public entrypoint is `AeroDeviceDetection` in `/src`, designed for autoload or direct-instantiation use inside a consumer/testbed project. The API is callback-first and promise-like: each detection request returns an `AeroDeviceDetectionOperation` that supports `on_success(...)` and `on_failure(...)` chaining while immediately normalizing the payload shape for live, simulated, and rejection paths.

## Runtime contract

- **Live detection:** best-effort collection of platform, CPU, renderer, display, and screen-size information using what Godot exposes on the current host.
- **Simulation:** deterministic success bundles for tests and UI prototyping.
- **Failure simulation:** deterministic rejection payloads that exercise the same normalized error surface as runtime failures.
- **Stable shape:** every response contains the same top-level keys: `schema`, `success`, `request`, `device`, `error`, and `meta`.

### Example

```gdscript
var operation := AeroDeviceDetection.detect_live(
	{"profile": "surface_pro_8"},
	func(response: Dictionary) -> void:
		print("Detected device: ", response),
	func(error_response: Dictionary) -> void:
		push_error("Detection failed: %s" % error_response)
)

operation.on_success(func(response: Dictionary) -> void:
	print("Also available through promise-style chaining", response)
)
```

## Repo layout

- `src/` — sharable source owned by this package
- `.testbed/` — hidden workbench/test project
- `.testbed/tests/` — repo-local GUT tests for the normalized detection contract

## Testbed dependency flow

This repo follows the AeroBeat GodotEnv package pattern.

- Manifest: `.testbed/addons.jsonc`
- Installed addons: `.testbed/addons/`
- Cache: `.testbed/.addons/`
- Workbench project: `.testbed/project.godot`

Restore dependencies from the repo root:

```bash
cd .testbed
godotenv addons install
```

## Validation

Headless import:

```bash
godot --headless --path .testbed --import
```

Repo-local tests:

```bash
godot --headless --path .testbed --script addons/gut/gut_cmdln.gd \
  -gdir=res://tests \
  -ginclude_subdirs \
  -gexit
```
