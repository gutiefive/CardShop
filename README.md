# Card Shop Empire — Godot

An offline, first-person fictional baseball card shop prototype. **Godot 4.6.3 standard edition**, typed GDScript, Compatibility renderer. No external packages, services or credentials required.

This replaces the Unity scaffold at the user's request. The original Unity source is preserved in Git commit `828924b`; the active project is entirely Godot.

## Open and play

1. Install Godot 4.6.3 **standard** edition; .NET is not required.
2. Clone this repository or pull its latest `main`.
3. In Godot Project Manager, click **Import**, choose `Game/project.godot`, then **Import & Edit**.
4. Press **F6** with `scenes/starter_shop.tscn` open, or **F5** to run the project. The starter scene is already committed; no generation step is needed to play.
5. Use **WASD** to move, mouse to look, **Left Shift** to sprint, **E** to interact, **C** for collection, **B** for the shop office, and **Escape** to close panels or toggle pause. Close/Resume buttons also work. Click into the game window if needed for keyboard focus.

Approach the blue pack or red box. The crosshair turns yellow and a prompt shows its name. E displays authored description and wholesale/retail prices. The counter sign is a second interaction: it toggles OPEN/CLOSED. Cash starts at $500 and increases through customer checkout. Three free starter packs can now be opened through booster inspection; more stock can be ordered in the shop office.

## Included scene

Warm primitive shop with floor, ceiling, walls, entrance/closed porch, counter, three shelf units, a transparent glass-style card case, lights, player and functional HUD. Twenty-nine product instances use two authored Resources: Rookie Series Booster Pack and Rookie Series Hobby Box. Glass blocks player movement but inspection rays can reach products through it. Solid walls and furniture block inspection rays.

`tools/shop_builder.gd` is the single generation path. In the editor select **Project > Tools > Regenerate Card Shop** (plugin enabled in project settings). Confirm replacement, then reopen the starter scene from disk. Save customized layouts as a separate scene first; regeneration replaces the generated starter scene. It preserves external product Resources and their stable IDs. Repeated generation produces the same layout and hierarchy without accumulating nodes.

## Checks

From repository root, with `godot` on PATH (or substitute your Godot executable):

```sh
godot --headless --path Game --editor --import --quit
godot --headless --path Game --script tests/run_tests.gd
godot --headless --path Game --quit-after 90 -- --no-save
```

To regenerate from the command line, after initial editor import:

```sh
godot --headless --path Game --script tools/generate_shop.gd
```

Cloud sandbox only: set `XDG_CONFIG_HOME=/tmp/cardshop-godot/config`, `XDG_DATA_HOME=/tmp/cardshop-godot/data`, and `XDG_CACHE_HOME=/tmp/cardshop-godot/cache`, creating those directories first. Godot editor import also opens a local debug socket, which may need the execution tool's supported sandbox escalation. Normal desktop use needs no such override.

**Validated here on Godot 4.6.3:** editor import, scene generation, main-scene headless startup and **199 automated checks, zero failures**. Tests exercise authored product validation, integer-cent price formatting, input bindings, repeated hierarchy generation, packed reference wiring, actual CharacterBody floor/movement/sprint/wall collision, camera ray focus/range/occlusion, E inspection, pause blocking physics, Close/Resume signal wiring, sign toggle and look calculations.

These are engine-backed headless tests. Button signals and input handlers are invoked programmatically; physical clicks, mouse capture and visual rendering have not been checked. No Windows export was built. The user subsequently reported the desktop M1 smoke test passed, showed the M2 inspection working, authorized M3, and then confirmed its nine-card collection/zero-pack state and Escape-to-walking on desktop. The user also reported stocking, customer pickup/queue and checkout working in M4. M5 ordering, upgrade, and restart checks on desktop are pending. Desktop editor-menu regeneration and Windows export remain unverified.

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

M5 ordering, progression and local save/load are implemented; desktop M5 acceptance is pending. M6 remains gated on review. See DEVELOPMENT_PLAN.md and DEVELOPMENT_LOG.md.

## M2 fictional card database

`data/cards/rookie_catalog.tres` registers eight fictional players, one 2026 Rookie Series set, three rarities (Common, Uncommon, Rare), and eight numbered cards. Player Resources contain identity, fictional team, position, handedness and biography. Cards reference their player, set and rarity, with a stable ID and an authored base value in cents. These values are placeholders, not a simulated market. The pack rules and player-owned collection reference these definitions; season simulation and dynamic market pricing remain future work.

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
7. After opening all three starter packs, nine copies were awarded; fewer than eight unique cards is normal. Further openings consume one booster from backroom stock. Order more in the office (B).

**Persistent in M5:** collection and remaining starter packs are autosaved. Stopping/restarting no longer resets them. After free starter packs are exhausted, opening consumes one booster from the backroom. All three cards are granted at the start of an opening; Escape skips the remaining reveals without losing or duplicating them. Opening twice from queued clicks is guarded.

`data/cards/rookie_pack_rules.tres` defines three independent draws with **70% Common / 25% Uncommon / 5% Rare per card**. Cards within the chosen rarity are selected uniformly, with replacement. Duplicates are expected, and no rarity is guaranteed per pack. A valid seeded RNG produces reproducible tests; normal play randomizes its seed. Rules reject invalid/nonfinite/nonpositive weights and empty rarity pools. `CardCollection` tracks integer counts by stable card ID, and validates a whole batch before granting it.

### M3 desktop review (pending)

- [ ] Fetch/pull the update, open project and run without errors
- [ ] Open a blue booster, verify each reveal fits and its rarity/new/duplicate text is readable
- [ ] Advance to collection; total copies increases by exactly three per pack
- [ ] Escape during reveal keeps all three cards and returns control
- [x] User confirmed Escape from collection resumes movement
- [ ] Desktop C/pause-menu collection button edge cases
- [x] User screenshot confirms nine copies and zero packs
- [ ] Desktop free-pack exhaustion switches to backroom opening
- [ ] Hobby boxes offer personal inspection only; personal pack opening does not change cash
- [ ] M5 restart restores starter packs/collection

### Updating through GitHub Desktop

Stop the game and close Godot, then select the CardShop repository on main in GitHub Desktop. Click **Fetch origin**, then **Pull origin** when offered. Reopen the same cloned `Game/project.godot` and press F5. No ZIP download is required. Keep using the cloned copy rather than an older extracted ZIP.

## M4: stock shelves, serve customers, checkout

Start with **$500**, **12 booster packs** and **3 hobby boxes** in the backroom. Shelves start empty. These are free starter supplies. M5 orders can replenish them; cash, stock and collection now persist. Transient customers reset and the shop starts closed on load.

1. Walk to the three shelves along the back wall. Aim at each **blue stock board above the shelf**, then press **E**. One press transfers as many units as fit from the backroom. The left/right shelves hold boosters; the middle holds hobby boxes. Each capacity is nine. Stock appears visually, and boards show live quantities.
2. Aim at the red **CLOSED** sign on the counter and press **E** to open. The HUD shows OPEN, active customers, queue count, sales and remaining backroom supply.
3. Capsule customers arrive about every seven seconds while open, up to three active customers. They walk to an available shelf, browse briefly, take one unit and walk to checkout. Empty shelves do not create purchases.
4. At the front of the counter, aim at the **blue CHECKOUT register** and press **E** when the prompt offers a sale. One press serves the first ready customer at the product's retail price: **$4 booster / $65 hobby box**. Stock was removed at pickup; cash is credited only at checkout.
5. Customers advance through the queue and leave after being served. Close the sign to stop new arrivals; existing customers can finish browsing and checkout while closed. Pause, inspection and collection screens stop customer simulation.
6. Continue until stock is exhausted. Use the office (B) to order finite replacements at wholesale cost; no infinite free restock. The M3 personal starter packs/collection remain separate from retail stock and customer purchases.

Stock and sales use integer counts/cents. Reservations prevent two buyers taking one unit, and an order can only be paid once. Internal cancellation returns a reserved item to its shelf, or backroom if the shelf was refilled. No customer patience/abandonment, baskets with multiple items, manual price changes. M5 now adds local save/load.

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

The user reported M4 shelf stocking and customer checkout working. Remaining detailed edge cases are listed above.

## M5: orders, progression and local saves

Press **B** in the shop, or use **Shop office · Orders / Save** in the pause menu. Office freezes customer movement while you manage the shop.

- **Order 6 boosters · $12** buys six units at $2 wholesale each.
- **Order 1 hobby box · $40** buys one unit at wholesale.
- Deliveries arrive immediately in the **backroom**. Use E at shelf boards afterward to move them to shelves. Orders are rejected whole if cash or backroom space is insufficient; no partial charges or partial deliveries.
- Starting backroom capacity is **24 boosters / 6 boxes**, separate from shelf capacity.
- **Level 1 — Neighborhood Shop:** 0–4 completed sales. **Level 2 — Local Favorite:** 5–14 sales. **Level 3 — Card Destination:** 15+ sales. Progression counts paid checkouts, not browsing/reservations.
- At Level 2, **Expand backroom · $100** is unlocked. Buying once doubles capacity to **48 boosters / 12 boxes**. This is a storage upgrade; it does not change shop geometry or customer routes. Level 3 is a title milestone for now.
- Cash starts at $500 and reconciles as starting cash + revenue − expenses. Expenses include wholesale orders and the backroom upgrade. Fixed retail prices remain $4/$65; no rents, wages, debt, custom pricing or delivery delays in this prototype.
- Once the three free starter packs are used, inspect a blue booster and use **Open backroom pack**. This removes one backroom booster and adds three cards to your collection. Shelf stock and queued customer baskets are not available for personal opening. No extra cash is charged when opening stock you already own.

### Save behavior

The game automatically loads on startup and autosaves after stock transfers, orders, upgrades, customer item reservations/checkout/cancellation and personal pack openings. **Save shop now** in the office provides a manual checkpoint. Normal window close attempts a save too; action autosaves cover Godot's external Stop button, which can terminate the game without a close callback.

Saved data: cash, sales/revenue/expenses, backroom inventory, shelf counts, upgrade, remaining starter packs, collected copy counts, and exact pack RNG state. Player position, panel/reveal position and live customers are transient. Every load starts at the normal spawn with the shop **closed** and customers reset. Items held by customers in a checkpoint are returned to their shelf (or backroom if the shelf is full); cash is credited only for completed sales. Snapshotting does not duplicate or cancel live reservations. In the rare case a returned unit exceeds backroom capacity, it is retained and further orders are blocked until space is available.

Saves use stable IDs and versioned validated JSON at `user://shop_save_v1.json`, outside the Git repository. On Windows the usual location is:

```text
%APPDATA%\Godot\app_userdata\Card Shop Empire\shop_save_v1.json
```

A temporary write is flushed before replacing the checkpoint, and `.bak` retains the previous valid save. If the primary is invalid, a valid backup can be loaded with a recovery notice. If both are invalid/unsupported, files are protected from overwrite; the office shows an error. It does not silently discard the previous shop. **New shop** asks for confirmation, archives the primary/backup locally with unique suffixes, and reloads a fresh shop. Archives are not deleted automatically. Save write failures are shown; avoid assuming unsaved changes survived if the office reports an error.

M4 and earlier had no persistent save to migrate: the first M5 launch starts a fresh $500 shop with starter supplies. Subsequent Git pulls do not replace local user saves. The schema is version 1; unsupported versions and missing/unknown IDs are rejected instead of partially restored.

Tests disable normal persistence and use uniquely isolated temporary save folders. To run a smoke test without touching your shop save:

```sh
godot --headless --path Game --quit-after 90 -- --no-save
```

### M5 desktop review (pending)

1. Fetch/pull with Godot closed, reopen and press F5.
2. Press B. Order six boosters: cash should decrease **$12**, backroom should increase **6**. Stock them with E at a shelf board.
3. Serve five customers. Office should show Level 2 and enable the **$100 backroom expansion** when affordable. Buy it and verify 48/12 capacity.
4. Open a personal pack, note collection/cash/stock, then click **Save shop now**.
5. Stop/restart. Confirm those values persist, shop is closed, customers are gone, and you can reopen it normally.
6. Once free packs are gone, test a backroom opening: one booster removed, three owned cards added, no second cash charge.
7. Optionally test confirmed New shop only when ready to reset; the old save files are archived locally.

Automated results cover schema validation, wholesale/upgrade transactions, exact RNG/collection round trips, held-inventory reconciliation, backup recovery, corrupt-save protection, manual save, real scene restart and confirmed reset. Desktop physical input, office layout and Windows filesystem behavior remain for user review.
