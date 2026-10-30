# Card Shop Empire — Godot

An offline, first-person fictional baseball card shop prototype. **Godot 4.6.3 standard edition**, typed GDScript, Compatibility renderer. No external packages, services or credentials required.

This replaces the Unity scaffold at the user's request. The original Unity source is preserved in Git commit `828924b`; the active project is entirely Godot.

## Open and play

1. Install Godot 4.6.3 **standard** edition; .NET is not required.
2. Clone this repository or pull its latest `main`.
3. In Godot Project Manager, click **Import**, choose `Game/project.godot`, then **Import & Edit**.
4. Press **F6** with `scenes/starter_shop.tscn` open, or **F5** to run the project. The starter scene is already committed; no generation step is needed to play.
5. Use **WASD** to move, mouse to look, **Left Shift** to sprint, **E** to interact, and **Escape** to close inspection or toggle pause. Close/Resume buttons also work. Click into the game window if needed for keyboard focus.

Approach the blue pack or red box. The crosshair turns yellow and a prompt shows its name. E displays authored description and wholesale/retail prices. The counter sign is a second interaction: it toggles OPEN/CLOSED. Cash is a fixed $500 placeholder. No actual purchasing or pack opening is implemented.

## Included scene

Warm primitive shop with floor, ceiling, walls, entrance/closed porch, counter, three shelf units, a transparent glass-style card case, lights, player and functional HUD. Twenty-nine product instances use two authored Resources: Rookie Series Booster Pack and Rookie Series Hobby Box. Glass blocks player movement but inspection rays can reach products through it. Solid walls and furniture block inspection rays.

`tools/shop_builder.gd` is the single generation path. In the editor select **Project > Tools > Regenerate Card Shop** (plugin enabled in project settings). Confirm replacement, then reopen the starter scene from disk. Save customized layouts as a separate scene first; regeneration replaces the generated starter scene. It preserves external product Resources and their stable IDs. Repeated generation produces the same layout and hierarchy without accumulating nodes.

## Checks

From repository root, with `godot` on PATH (or substitute your Godot executable):

```sh
godot --headless --path Game --editor --import --quit
godot --headless --path Game --script tests/run_tests.gd
godot --headless --path Game --quit-after 90
```

To regenerate from the command line, after initial editor import:

```sh
godot --headless --path Game --script tools/generate_shop.gd
```

Cloud sandbox only: set `XDG_CONFIG_HOME=/tmp/cardshop-godot/config`, `XDG_DATA_HOME=/tmp/cardshop-godot/data`, and `XDG_CACHE_HOME=/tmp/cardshop-godot/cache`, creating those directories first. Godot editor import also opens a local debug socket, which may need the execution tool's supported sandbox escalation. Normal desktop use needs no such override.

**Validated here on Godot 4.6.3:** editor import, scene generation, main-scene headless startup and **59 automated checks, zero failures**. Tests exercise authored product validation, integer-cent price formatting, input bindings, repeated hierarchy generation, packed reference wiring, actual CharacterBody floor/movement/sprint/wall collision, camera ray focus/range/occlusion, E inspection, pause blocking physics, Close/Resume signal wiring, sign toggle and look calculations.

These are engine-backed headless tests. Button signals and input handlers are invoked programmatically; physical clicks, mouse capture and visual rendering have not been checked. No Windows export was built. The user subsequently reported the desktop gameplay smoke test passed and authorized M2. Desktop editor-menu regeneration and Windows export remain unverified.

## Desktop acceptance record

User-reported smoke checks are marked below. Detailed edge cases and export remain follow-up checks.

- [x] User opened the project and ran the desktop gameplay smoke test
- [ ] Verify lighting, materials, readable labels, glass and HUD at desktop resolution
- [ ] WASD, diagonal movement, sprint, physical mouse-look/capture and pitch limit
- [ ] Floor/wall/furniture/porch collision; no escaping the shop
- [ ] Product focus within range; walls block focus; glass allows inspection
- [ ] Both products show correct name, description and prices
- [ ] Physical Close button and Escape dismiss inspection; cursor recaptures
- [x] User-reported sign interaction smoke test
- [x] User-reported pause/resume smoke test
- [ ] Editor regeneration confirmation/reopening works without duplicates
- [ ] Optional: Windows export with installed Godot export templates and smoke test

## Architecture

- `scripts/player/`: CharacterBody3D movement and mouse-look.
- `scripts/interaction/`: shared Interactable contract, camera ray controller, product and sign behaviors.
- `scripts/shop/` and `data/`: typed authored product Resources, stable IDs and validation; prices use integer cents.
- `scripts/ui/`: HUD, inspection, notifications, tree pause and cursor modes.
- `scenes/`: committed generated starter scene with explicit serialized references.
- `tools/`, `addons/shop_tools/`: shared builder, CLI entry point and editor menu.
- `tests/`: dependency-free headless test runner.

M2 database is implemented; M3 remains gated on review. See DEVELOPMENT_PLAN.md and DEVELOPMENT_LOG.md.

## M2 fictional card database

`data/cards/rookie_catalog.tres` registers eight fictional players, one 2026 Rookie Series set, three rarities (Common, Uncommon, Rare), and eight numbered cards. Player Resources contain identity, fictional team, position, handedness and biography. Cards reference their player, set and rarity, with a stable ID and an authored base value in cents. These values are placeholders, not a simulated market. There are no pack odds, owned copies, collection, packs to open, or season simulation yet.

In Godot's FileSystem panel, open `data/cards/rookie_catalog.tres` to inspect the registered definitions. Expand a player or card reference to inspect/edit it. Both shop products reference the same set; in-game inspection now shows its name and checklist size. The database is authored data, not a new card browser screen.

To validate and print the full checklist:

```sh
godot --headless --path Game --script tools/list_catalog.gd
```

Runtime queries: `CardCatalog.find_card(stable_id)`, `cards_for_set(set_id)` (sorted by printed number), and `cards_for_player(player_id)`. Unknown IDs return null or an empty array. `validation_errors()` rejects missing/null/duplicate definitions, invalid prices/metadata, unregistered references, duplicate printed numbers, out-of-range numbers and incomplete checklists. IDs are globally unique across definition types; do not change shipped IDs when renaming a player or moving an asset. When adding cards, register their Resource and dependencies in the catalog and update the set checklist size. Commit the Resources and run tests before review.
