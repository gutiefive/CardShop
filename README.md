# Card Shop Empire — Godot

An offline, first-person fictional baseball card shop prototype. **Godot 4.6.3 standard edition**, typed GDScript, Compatibility renderer. No external packages, services or credentials required.

This replaces the Unity scaffold at the user's request. The original Unity source is preserved in Git commit `828924b`; the active project is entirely Godot.

## Open and play

1. Install Godot 4.6.3 **standard** edition; .NET is not required.
2. Clone this repository or pull its latest `main`.
3. In Godot Project Manager, click **Import**, choose `Game/project.godot`, then **Import & Edit**.
4. Press **F6** with `scenes/starter_shop.tscn` open, or **F5** to run the project. The starter scene is already committed; no generation step is needed to play.
5. Use **WASD** to move, mouse to look, **Left Shift** to sprint, **E** to interact, **C** for collection, and **Escape** to close panels or toggle pause. Close/Resume buttons also work. Click into the game window if needed for keyboard focus.

Approach the blue pack or red box. The crosshair turns yellow and a prompt shows its name. E displays authored description and wholesale/retail prices. The counter sign is a second interaction: it toggles OPEN/CLOSED. Cash starts at $500 and increases through customer checkout. Three free starter packs can now be opened through booster inspection; backroom purchasing is not implemented.

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

**Validated here on Godot 4.6.3:** editor import, scene generation, main-scene headless startup and **145 automated checks, zero failures**. Tests exercise authored product validation, integer-cent price formatting, input bindings, repeated hierarchy generation, packed reference wiring, actual CharacterBody floor/movement/sprint/wall collision, camera ray focus/range/occlusion, E inspection, pause blocking physics, Close/Resume signal wiring, sign toggle and look calculations.

These are engine-backed headless tests. Button signals and input handlers are invoked programmatically; physical clicks, mouse capture and visual rendering have not been checked. No Windows export was built. The user subsequently reported the desktop M1 smoke test passed, showed the M2 inspection working, authorized M3, and then confirmed its nine-card collection/zero-pack state and Escape-to-walking on desktop. M4 physical button/input/layout checks are pending. Desktop editor-menu regeneration and Windows export remain unverified.

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

M4 session retail loop is implemented; desktop M4 acceptance is pending. M5 remains gated on review. See DEVELOPMENT_PLAN.md and DEVELOPMENT_LOG.md.

## M2 fictional card database

`data/cards/rookie_catalog.tres` registers eight fictional players, one 2026 Rookie Series set, three rarities (Common, Uncommon, Rare), and eight numbered cards. Player Resources contain identity, fictional team, position, handedness and biography. Cards reference their player, set and rarity, with a stable ID and an authored base value in cents. These values are placeholders, not a simulated market. The M3 rules and session-owned collection reference these definitions; season simulation and dynamic market pricing remain future work.

In Godot's FileSystem panel, open `data/cards/rookie_catalog.tres` to inspect the registered definitions. Expand a player or card reference to inspect/edit it. Both shop products reference the same set; in-game inspection now shows its name and checklist size. The database is authored data, not a new card browser screen.

To validate and print the full checklist:

```sh
godot --headless --path Game --script tools/list_catalog.gd
```

Runtime queries: `CardCatalog.find_card(stable_id)`, `cards_for_set(set_id)` (sorted by printed number), and `cards_for_player(player_id)`. Unknown IDs return null or an empty array. `validation_errors()` rejects missing/null/duplicate definitions, invalid prices/metadata, unregistered references, duplicate printed numbers, out-of-range numbers and incomplete checklists. IDs are globally unique across definition types; do not change shipped IDs when renaming a player or moving an asset. When adding cards, register their Resource and dependencies in the catalog and update the set checklist size. Commit the Resources and run tests before review.

## M3: opening packs and collecting cards

Each new play session starts with **three free starter packs**, each containing **three cards**. Personal packs never deduct cash or retail inventory. Shelf products now represent finite M4 retail stock; the two glass-case examples remain for personal inspection/opening. Hobby boxes can be inspected but cannot be opened in M3.

1. Run F5, approach a **blue Rookie Series Booster Pack**, and press **E**.
2. Click **Open free starter pack (3 left)**.
3. Read the first card's player/team, rarity, biography and base value. The reveal shows **NEW!** or **DUPLICATE** and your copy count.
4. Click **Next card** through the three cards. **Finish · View collection** opens the full checklist.
5. View owned quantities, missing cards, unique progress and total copies. **Back to shop** or **Escape** returns to gameplay.
6. Press **C** any time in the shop, or **View collection** in the pause menu, to reopen the collection.
7. After opening all three starter packs, opening is disabled. Nine copies were awarded; fewer than eight unique cards is normal.

**Session only:** stopping/restarting the game resets collection and starter inventory. Save/load belongs to M5. All three cards are granted at the start of an opening; Escape skips the remaining reveals without losing or duplicating them. Opening twice from queued clicks is guarded.

`data/cards/rookie_pack_rules.tres` defines three independent draws with **70% Common / 25% Uncommon / 5% Rare per card**. Cards within the chosen rarity are selected uniformly, with replacement. Duplicates are expected, and no rarity is guaranteed per pack. A valid seeded RNG produces reproducible tests; normal play randomizes its seed. Rules reject invalid/nonfinite/nonpositive weights and empty rarity pools. `CardCollection` tracks integer counts by stable card ID, and validates a whole batch before granting it.

### M3 desktop review (pending)

- [ ] Fetch/pull the update, open project and run without errors
- [ ] Open a blue booster, verify each reveal fits and its rarity/new/duplicate text is readable
- [ ] Advance to collection; total copies increases by exactly three per pack
- [ ] Escape during reveal keeps all three cards and returns control
- [x] User confirmed Escape from collection resumes movement
- [ ] Desktop C/pause-menu collection button edge cases
- [x] User screenshot confirms nine copies and zero packs
- [ ] Desktop exhausted-pack button check
- [ ] Hobby boxes offer personal inspection only; personal pack opening does not change cash
- [ ] Restart resets starter packs/collection as disclosed

### Updating through GitHub Desktop

Stop the game and close Godot, then select the CardShop repository on main in GitHub Desktop. Click **Fetch origin**, then **Pull origin** when offered. Reopen the same cloned `Game/project.godot` and press F5. No ZIP download is required. Keep using the cloned copy rather than an older extracted ZIP.

## M4: stock shelves, serve customers, checkout

Start with **$500**, **12 booster packs** and **3 hobby boxes** in the backroom. Shelves start empty. These are free starter supplies; ordering more stock and a broader economy come in M5. All cash, stock, customers and collection reset when stopping/restarting the game.

1. Walk to the three shelves along the back wall. Aim at each **blue stock board above the shelf**, then press **E**. One press transfers as many units as fit from the backroom. The left/right shelves hold boosters; the middle holds hobby boxes. Each capacity is nine. Stock appears visually, and boards show live quantities.
2. Aim at the red **CLOSED** sign on the counter and press **E** to open. The HUD shows OPEN, active customers, queue count, sales and remaining backroom supply.
3. Capsule customers arrive about every seven seconds while open, up to three active customers. They walk to an available shelf, browse briefly, take one unit and walk to checkout. Empty shelves do not create purchases.
4. At the front of the counter, aim at the **blue CHECKOUT register** and press **E** when the prompt offers a sale. One press serves the first ready customer at the product's retail price: **$4 booster / $65 hobby box**. Stock was removed at pickup; cash is credited only at checkout.
5. Customers advance through the queue and leave after being served. Close the sign to stop new arrivals; existing customers can finish browsing and checkout while closed. Pause, inspection and collection screens stop customer simulation.
6. Continue until stock is exhausted. There is no infinite stock refill or reordering yet. The M3 personal starter packs/collection remain separate from retail stock and customer purchases.

Stock and sales use integer counts/cents. Reservations prevent two buyers taking one unit, and an order can only be paid once. Internal cancellation returns a reserved item to its shelf, or backroom if the shelf was refilled. No customer patience/abandonment, baskets with multiple items, manual price changes or save/load in this milestone.

Customers are original colored capsule placeholders with status labels. They follow authored waypoints through the generated aisles, collide with shop geometry, and are nonblocking to the player/other customers. This is a layout-specific prototype, not general navigation for arbitrary remodeled shops. Moving furniture requires updating/testing waypoints. The suite physically exercises all three shelf routes, queue advancement and exits.

For faster deterministic automated checks:

```sh
godot --headless --fixed-fps 60 --path Game --script tests/run_tests.gd
```

### M4 desktop review (pending)

- [ ] Fetch/pull update and run F5 without errors
- [ ] Aim at stock boards and E: backroom decreases, shelf models/counts appear
- [ ] Open sign: customers visibly enter, browse and queue without crossing furniture
- [ ] E at register serves only a ready front customer and updates cash once
- [ ] Queue advances and served customers leave
- [ ] Close sign stops new admission; existing orders remain serviceable
- [ ] Pause/inspection/collection freeze customer movement and resume normally
- [ ] Retail sales leave personal starter packs/collection unchanged
- [ ] Empty/full shelf and depleted-backroom prompts are readable

M4 needs a desktop review of the new stock boards, register, customer visuals and HUD; automated results do not substitute for that review.
