# Development log

## 2026-10-30 — M0/M1 source foundation

Inspected `/workspace/CardShop`: empty unborn local branch, no files or commits. Read-only GitHub query succeeded with zero remote refs; requested main does not yet exist. User subsequently authorized creating this Unity project from scratch.

Tooling: no Unity, Unity Hub, dotnet, csc or mcs found on PATH; no Unity installation found under inspected /opt or /usr/local locations. Selected Unity 6000.0.23f1 as the bootstrap Unity 6 LTS target, not an installed-version claim.

Implemented package/assembly structure, Unity metadata, first-person Input System controller, shared raycast interaction, product definition validation, two product interactions, shop sign, HUD, inspection and pause/resume. Added deterministic editor generation of shop geometry, sample ScriptableObjects, URP, lighting and UI. Runtime UI buttons bind in Awake so callbacks survive scene serialization. Generator preserves asset GUIDs while rebuilding its owned scene. Added EditMode tests for product invariants, bindings and generation stability.

Validation: JSON manifests/assembly definitions and generated metadata checked statically. MonoBehaviour classes separated into matching filenames. Reviewed serialized references and generator paths. No Unity compilation, package resolution, scene generation, EditMode execution, Play Mode checks or Windows build occurred. No test passes are claimed. The starter scene and product assets will be materialized by the editor generator; they are not supplied as unverified handwritten scene YAML.

Remaining: install/open pinned Unity editor, resolve packages, run generator and validation, commit generated assets and package lock, run EditMode suite, complete README Play Mode checklist, then review M1. Unity API/package compatibility and actual rendering/control behavior remain unverified. Do not begin M2.

Saved environment draft `start_skill` with repository location, editor prerequisites, generation and validation steps. No install script was saved because editor installation/licensing cannot be verified here. Draft publication and new-task restoration have not occurred.
