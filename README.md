# Card Shop Empire

An offline, first-person fictional baseball card shop prototype for Windows PC. Active scope: M0 + M1. No purchasing, pack opening, customers, persistence, or baseball simulation yet.

## Tooling and current status

Open `Game/` with **Unity 6000.0.23f1 (Unity 6 LTS)**, with Windows Build Support if making a Windows build. No Unity editor or C# compiler was installed in the cloud machine, so this is a source scaffold with editor generation tooling, not an editor-verified playable build. The editor pin is a selected bootstrap target, not a detected installed editor. Package versions are explicit in `Game/Packages/manifest.json`; Unity must resolve them and produce its package lock on first import. Do not ignore or discard that generated lockfile.

Required: package resolution, compilation, scene generation, EditMode tests and manual Play Mode acceptance. Optional: Windows standalone build. No credentials, external services, or paid APIs are needed. Initial package resolution needs Unity's package registry (`packages.unity.com`) and its download hosts; this has not been exercised here.

## First launch

1. Install the pinned editor through Unity Hub and open `Game/`. Allow package import to finish. Confirm Active Input Handling is **Input System Package (New)**; accept a restart if Unity requests one.
2. Select **Card Shop Empire > Generate Starter Shop**. This creates `Scenes/StarterShop.unity`, two product ScriptableObjects, materials, a URP renderer/pipeline, a UI EventSystem, and the build scene entry. The generator sets URP and player settings. Generated assets live below `Assets/_CardShopEmpire/`.
3. Select **Card Shop Empire > Validate Starter Shop**. Resolve any console exceptions before entering Play Mode. The validator checks scene references and product ID uniqueness.
4. Enter Play Mode. Use WASD, mouse, Left Shift and E. A yellow crosshair and text indicate an interactable in range. Inspect a shelf/display product, close with the button or Escape. Toggle the counter sign to see a different interaction. Escape opens the pause menu; Resume or Escape returns to control. Pause blocks all gameplay controls; no simulation systems exist yet and global time scale is intentionally unchanged.
5. Run **Window > General > Test Runner > EditMode > Run All**. The generator test replaces the active scene: save other work first. Tests cover invalid/nonfinite product values, stable IDs, input bindings, scene references and regeneration counts/GUID stability.
6. Generate a second time and verify one player/HUD/shop and no duplicates. Generator-owned content is rebuilt rather than merged. Duplicate or rename the generated scene before hand editing it; sample assets/materials are generator-owned too.

## Acceptance checklist (not yet run)

- [ ] Pinned editor opens project and resolves packages without errors
- [ ] Compilation and all EditMode tests pass; record counts
- [ ] URP materials and lighting render; no missing/pink materials
- [ ] WASD/mouse/sprint work; pitch clamps; diagonal movement is normalized
- [ ] Player collides with walls, shelves, counter, floor and display; cannot leave porch
- [ ] Product prompt only in range and line of sight; inspection shows correct definition
- [ ] Close button and Escape dismiss inspection and restore cursor capture
- [ ] Counter sign toggles, with transient confirmation
- [ ] Pause blocks movement/look/interactions; menu mouse works; resume captures cursor
- [ ] Regeneration preserves asset GUIDs and produces no duplicate objects
- [ ] Optional: Windows standalone build and smoke test

## Automated editor commands

Set `UNITY_EDITOR` to your installed editor executable. Run from the repository root, sequentially, with no other editor instance opening Game. Batch use requires an appropriately licensed editor.

```sh
"$UNITY_EDITOR" -batchmode -nographics -quit -projectPath "$PWD/Game" -executeMethod CardShopEmpire.Editor.StarterShopBuilder.Build -logFile /tmp/cardshop-generate.log
"$UNITY_EDITOR" -batchmode -nographics -projectPath "$PWD/Game" -runTests -testPlatform EditMode -testResults /tmp/cardshop-editmode.xml -logFile /tmp/cardshop-tests.log
```

Check process exit status, current logs and XML test counts/failures. Do not add `-quit` to the test command; let the runner finish. These commands are documented but unexecuted in this cloud environment. Preserve generated Unity asset/meta files after a successful run.

## Architecture

`Scripts/Player` owns Input System actions and CharacterController movement. `Scripts/Interaction` owns `IInteractable`, the shared camera raycast, product inspection and sign toggle. `Scripts/Shop` holds authored product definitions and pure validation rules. `Scripts/UI` displays focus, inspection, notices, pause and placeholder cash. No gameplay wiring depends on scene object names. Product IDs `rookie-series-pack` and `rookie-series-box` are stable; prices are authoring floats for this prototype, not a full economy implementation.

The opaque pale blue display top is a glass-style placeholder. Focus feedback uses a yellow crosshair plus prompt, without material mutation. The scene generator uses primitives and replaceable materials. All art and fictional product descriptions are original placeholders. See DEVELOPMENT_PLAN.md and DEVELOPMENT_LOG.md for scope and evidence.
