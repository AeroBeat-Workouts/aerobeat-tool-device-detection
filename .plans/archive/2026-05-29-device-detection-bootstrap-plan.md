# AeroBeat Tool Device Detection

**Date:** 2026-05-29  
**Status:** Complete  
**Last Updated:** 2026-05-29 11:52 EDT  
**Blocked Reason:** None  
**Agent:** `chip`

---

## Goal

Turn the fresh `aerobeat-tool-device-detection` template repo into a repo-local singleton tool that can detect or simulate device hardware, emit a JSON-formatted result payload, and drive a `.testbed` scene that switches between image and looping video backgrounds based on detected GPU data.

---

## Overview

This repo is currently in fresh template shape with `src/AeroToolManager.gd`, a minimal hidden `.testbed/`, and a starter `.testbed/addons.jsonc`. The implementation needs to follow the normal AeroBeat tool-polyrepo rules: sharable source remains in `/src/`, the repo self-installs into `.testbed/addons/` via the hidden `.testbed/addons.jsonc` symlink dependency, and the resulting package is intended to later load into `aerobeat-assembly-community` as an addon singleton.

The first delivery slice should establish three things together rather than separately: the renamed singleton runtime surface (`AeroDeviceDetection`), a callback-style promise-like detection/simulation API that returns structured device information or structured failure payloads, and a proving-surface scene in `.testbed/` that consumes the singleton plus the existing image/video tool repos. That scene should demonstrate both real-device detection and deterministic simulation buttons covering the top Steam-style hardware presets, this host Surface/Intel Iris Xe profile, and an explicit simulated failure path that exercises the same rejection/error-handling branch as a live detection failure.

Because the work crosses repo conventions, runtime detection limits, and testbed dependency wiring, the plan should explicitly preserve source-vs-addon ownership boundaries, pull reusable assets from the image/video tool testbeds instead of inventing new media, and validate behavior from the hidden `.testbed` Godot project rather than from mirrored addon payloads.

---

## REFERENCES

| ID | Description | Path |
| --- | --- | --- |
| `REF-01` | Owning repo root | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection` |
| `REF-02` | Current singleton template to replace | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/src/AeroToolManager.gd` |
| `REF-03` | Current hidden testbed dependency manifest | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/addons.jsonc` |
| `REF-04` | Image loader runtime facade | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-image-loader/src/AeroImageLoader.gd` |
| `REF-05` | Video player runtime facade | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-video-player/src/AeroVideoPlayerManager.gd` |
| `REF-06` | Device-detection testbed Godot project entrypoint | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/project.godot` |
| `REF-07` | Assembly community consumer repo mentioned for downstream singleton loading | `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-assembly-community` |

---

## Tasks

### Task 1: Define the singleton contract + repo wiring slice

**Bead ID:** `aerobeat-tool-device-detection-eec`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Serve the `coder` workflow role on the `primary` lane for `aerobeat-tool-device-detection-eec`. In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection`, run `bd update aerobeat-tool-device-detection-eec --status in_progress --json` when you start. Replace the fresh template singleton with `AeroDeviceDetection`, rename repo-owned entrypoints/metadata accordingly, and implement a callback-style promise-like detection API surface that can either collect best-effort live device data, return deterministic simulated hardware bundles, or trigger a deterministic rejection/failure bundle through the same normalized JSON-style response contract. Update the hidden `.testbed` dependency manifest to self-install this repo by its real package name and add the requested `aerobeat-tool-image-loader`, `aerobeat-vendor-godot-image`, `aerobeat-vendor-godot-video`, and `aerobeat-tool-video-player` dependencies without editing mirrored addon payloads. Run relevant repo-local validation, commit/push to `main` by default, and leave a precise handoff with files changed, validation evidence, and commit hash.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/src/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/src/AeroToolManager.gd` (removed/replaced)
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/src/AeroDeviceDetection.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/src/AeroDeviceDetectionOperation.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/plugin.cfg`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/README.md`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/addons.jsonc`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/project.godot`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/tests/test_device_detection_contract.gd`

**Status:** ✅ Complete

**Results:** The first coder attempt failed and was rejected after orchestrator verification showed no actual repo changes. The retry landed the runtime contract properly in commit `d274c18` (`Implement AeroDeviceDetection runtime contract`) and pushed it to `origin/main`. The implementation replaced the template singleton with `AeroDeviceDetection`, added the operation helper class, updated plugin/readme metadata, rewired the hidden `.testbed` dependency manifest for the real package name and requested tool/vendor dependencies, and replaced the starter tests with contract coverage for live callback shape, simulated success, simulated rejection, and normalized response structure. Validation passed with `godotenv addons install`, `godot --headless --path .testbed --import`, and `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` (`4/4 passed`).

---

### Task 2: Build the `.testbed` proving scene + media assets slice

**Bead ID:** `aerobeat-tool-device-detection-x3d`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Serve the `coder` workflow role on the `primary` lane for `aerobeat-tool-device-detection-x3d`. In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection`, run `bd update aerobeat-tool-device-detection-x3d --status in_progress --json` when you start. In the hidden `.testbed`, create a startup scene/controller that loads `AeroDeviceDetection`, runs the same scene logic for real detection and every preset button, prints the structured result on screen, selects an image background when the GPU indicates Intel Iris Xe, selects a looping video background otherwise, logs structured errors when detection fails, and adds seven GUI buttons total: five Steam-style approximation presets, one host Surface/Intel Iris Xe preset, and one explicit detection-failure preset that exercises the same rejection/error branch. Pull the test assets from the existing image/video tool repo `.testbed` assets into this repo’s `.testbed/assets/images/` and `.testbed/assets/videos/` folders. Run relevant repo-local validation, commit/push to `main` by default, and leave a precise handoff with files changed, validation evidence, and commit hash.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/assets/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/scenes/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/scripts/`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/tests/`

**Files Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/src/AeroDeviceDetection.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/project.godot`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/scenes/device_detection_testbed.tscn`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/scripts/device_detection_testbed.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/tests/test_device_detection_testbed.gd`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/assets/images/demo_tool_landscape.png`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/assets/images/demo_tool_landscape.png.import`
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/assets/videos/calm_blue_sea_1.ogv`

**Status:** ✅ Complete

**Results:** Built the hidden `.testbed` proving surface and pushed it in commit `49f6445`. The controller now uses one shared runtime path for live startup detection, five Steam-style approximation presets, one Surface/Intel Iris Xe preset, and one explicit failure preset, updating both background selection and the info/payload UI from the same response flow. The Intel Iris Xe branch renders an image through `AeroImageLoader`; non-Intel presets render a looping video through `AeroVideoPlayerManager`; the failure branch updates the UI and logs structured JSON. One small source-level improvement was added to `src/AeroDeviceDetection.gd` so Linux live detection can use `lspci` when Godot reports a too-generic renderer name, allowing this Surface host to resolve as `Intel Iris Xe Graphics` through the public API. Validation passed with `godotenv addons install`, `godot --headless --path .testbed --import`, and `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` (`8/8 passed`).

---

### Task 3: Run QA on the hidden testbed behavior

**Bead ID:** `aerobeat-tool-device-detection-i2q`  
**SubAgent:** `primary` (for `qa`)  
**Role:** `qa`  
**References:** `REF-01`, `REF-03`, `REF-04`, `REF-05`, `REF-06`  
**Prompt:** Serve the `qa` workflow role on the `primary` lane for `aerobeat-tool-device-detection-i2q`. In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection`, run `bd update aerobeat-tool-device-detection-i2q --status in_progress --json` when you start. Independently verify the hidden `.testbed` can import dependencies, autoload the singleton, render the expected background branch for live detection and each preset path, and emit correct structured error behavior when the explicit failure preset is used. Use the highest-fidelity repo-local Godot checks available and verify no source edits were made under mirrored `/addons/` payloads. Add evidence and pass/fail notes to the bead.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/`

**Files Created/Deleted/Modified:**
- `.testbed/project.godot`
- `.testbed/addons.jsonc`
- `.testbed/scripts/device_detection_testbed.gd`
- `.testbed/tests/test_device_detection_testbed.gd`
- `.testbed/tests/test_device_detection_contract.gd`
- `src/AeroDeviceDetection.gd`

**Status:** ✅ Complete

**Results:** QA passed and the bead was closed. Independent verification confirmed `.testbed` dependency import and autoload behavior, `8/8` repo-local tests passing, live startup on this host resolving to `Intel Iris Xe Graphics` and the image branch, a non-Intel preset (`steam_rtx_3060_desktop`) resolving to the looping video branch, and the explicit failure preset updating the UI and logging structured JSON with `event=device_detection_failure` and `error.code=device_detection_probe_failed`. QA also verified that the same scene-update flow drives both the background selection and the device-info/payload UI, and found no tracked source edits under mirrored `.testbed/addons` / `.testbed/.addons` payloads. Pre-existing duplicate UID warnings were noted on a direct probe path but did not affect correctness.

---

### Task 4: Audit the contract, simulation presets, and proving surface

**Bead ID:** `aerobeat-tool-device-detection-2g2`  
**SubAgent:** `primary` (for `auditor`)  
**Role:** `auditor`  
**References:** `REF-01`, `REF-02`, `REF-03`, `REF-04`, `REF-05`, `REF-06`, `REF-07`  
**Prompt:** Serve the `auditor` workflow role on the `primary` lane for `aerobeat-tool-device-detection-2g2`. In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection`, run `bd update aerobeat-tool-device-detection-2g2 --status in_progress --json` when you start. Independently truth-check the singleton/API naming, normalized response contract, testbed dependency wiring, simulation-preset intent, explicit failure-preset behavior, and background-selection logic against the approved plan and changed files. Confirm the repo is ready for downstream consumption by `aerobeat-assembly-community` as an addon singleton. Add evidence and final pass/fail notes to the bead.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/`

**Files Created/Deleted/Modified:**
- Whatever prior tasks changed; audit should cite exact files in its evidence.

**Status:** ✅ Complete

**Results:** The first audit pass correctly caught a narrow singleton/autoload naming mismatch between the documented downstream API name and the hidden `.testbed` autoload proof. After the focused follow-up fix in commit `9990476` (`Align device detection singleton naming`), the audit retry passed and closed the bead. Independent audit confirmed that `README.md`, `.testbed/project.godot`, `.testbed/scripts/device_detection_testbed.gd`, and `.testbed/tests/test_device_detection_contract.gd` now all align on the same downstream singleton name: `AeroDeviceDetection`. The auditor also revalidated the rest of the already-passing surface: normalized response contract intact, callback operation shape intact, dependency wiring correct, proving surface/presets/failure path present, and no improper mirrored-addon edits. Validation passed with `godot --headless --path .testbed --import` and `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` (`9/9 passed`). Non-blocking duplicate UID warnings remain, but they are not an audit blocker.

---

### Task 5: Align singleton/autoload naming with the documented AeroDeviceDetection API

**Bead ID:** `aerobeat-tool-device-detection-6rt`  
**SubAgent:** `primary` (for `coder`)  
**Role:** `coder`  
**References:** `REF-01`, `REF-02`, `REF-06`, `REF-07`  
**Prompt:** Serve the `coder` workflow role on the `primary` lane for `aerobeat-tool-device-detection-6rt`. In `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection`, run `bd update aerobeat-tool-device-detection-6rt --status in_progress --json` when you start. Fix the narrow audit gap by aligning the documented singleton/API name with the autoload/proven runtime surface for downstream addon use. Make the repo prove the same name it documents, keep the normalized response contract intact, update any affected tests/project wiring/docs, run relevant validation, commit/push to `main`, and leave a precise handoff for audit retry.

**Folders Created/Deleted/Modified:**
- `/home/derrick/.openclaw/workspace/projects/aerobeat/aerobeat-tool-device-detection/.testbed/`

**Files Created/Deleted/Modified:**
- `.testbed/project.godot`
- `.testbed/scripts/device_detection_testbed.gd`
- `.testbed/tests/test_device_detection_contract.gd`
- `README.md`

**Status:** ✅ Complete

**Results:** Landed the narrow naming-alignment fix in commit `9990476` (`Align device detection singleton naming`) and pushed it to `origin/main`. The hidden `.testbed` now proves the documented singleton name by autoloading `src/AeroDeviceDetection.gd` as `AeroDeviceDetection`, the proving-surface script calls were updated to that public name, the contract test suite now explicitly verifies that the documented autoload exists and the legacy autoload name does not, and the README now states the exact singleton registration shape downstream consumers should use. A brief experiment with adding `class_name AeroDeviceDetection` to the script was correctly rejected and reverted because Godot conflicts when an autoload singleton shares that same global class name. Validation passed with `godot --headless --path .testbed --import` and `godot --headless --path .testbed --script addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit` (`9/9 passed`).

---

## Final Results

**Status:** ✅ Complete

**What We Built:** `aerobeat-tool-device-detection` is now a working AeroBeat tool polyrepo with a callback-style `AeroDeviceDetection` singleton contract, best-effort live detection, simulated success/failure paths, hidden `.testbed` proving surface, copied media assets, seven preset buttons, Intel Iris Xe image branching, non-Intel looping-video branching, structured failure logging, repo-local tests, QA verification, and a final naming alignment so the documented downstream singleton name matches the autoload proof.

**Reference Check:** `REF-01` through `REF-07` were satisfied across implementation, proving surface, QA, and audit. The only temporary deviation was the singleton/autoload naming mismatch caught by audit, which was fixed before final completion in commit `9990476`.

**Commits:**
- `d274c18` - Implement AeroDeviceDetection runtime contract
- `49f6445` - Build device detection testbed proving surface
- `9990476` - Align device detection singleton naming

**Lessons Learned:** The strongest failure in this slice was not runtime behavior but proof coherence: for addon-singleton repos, the documented public name, the autoload proof, and the test contract all need to match exactly or audit should fail even if behavior is otherwise green. Best-effort Linux GPU detection also benefited from a narrow `lspci` fallback when Godot exposed only a generic renderer label.

---

*Completed on 2026-05-29*
