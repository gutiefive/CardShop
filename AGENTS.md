# Card Shop Empire conventions

Active engine: Godot 4.6.3 standard edition, typed GDScript, Compatibility renderer. Project lives in Game/. Unity was superseded at the user's request; its original scaffold remains in commit 828924b. Do not restore Unity dependencies or introduce C# tooling without a new requirement.

Use the existing checkout. Cloud tasks are isolated; do not create worktrees unless requested. The user reviewed the desktop M1 smoke test and authorized M2. Active scope is the fictional baseball card database; do not start M3 without review. No pack opening, buying, customer AI, save system, online services, paid APIs or unrelated systems yet.

Use feature folders, explicit exported NodePaths and typed references. Never wire gameplay by searching scene object names. Interactable defines the shared contract; InteractionController owns ray/range/occlusion logic. Authored products, players, sets, rarities and cards are Resources with globally unique stable IDs; prices are integer cents. CardCatalog validates complete set checklists and registered references. Definitions are authored data, never owned card instances. Keep data validation independent of presentation. Commit .gd.uid files and .tres/.tscn sources, never .godot or build outputs.

ShopBuilder owns scenes/starter_shop.tscn. Generation replaces that file, not arbitrary user scenes. Preserve custom edits in a separate scene before regeneration. Editor-menu generation requires confirmation. Do not duplicate gameplay logic in generator or interactable subclasses. Use primitive, original placeholder art.

Validation: run Godot editor import, tools/generate_shop.gd when generator changes, tests/run_tests.gd and a main-scene smoke run. Tests must exit nonzero on failure; inspect stderr too, since engine parser/runtime errors can occur with zero exit status. Document exact engine, counts and limits. Headless physics/UI-state tests do not prove desktop rendering, physical mouse capture, real button clicks or Windows exports. The user reported the desktop M1 smoke test passed. Editor-menu regeneration and Windows export remain separately unverified.
