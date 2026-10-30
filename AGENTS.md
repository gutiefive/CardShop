# Card Shop Empire conventions

Active engine: Godot 4.6.3 standard edition, typed GDScript, Compatibility renderer. Project lives in Game/. Unity was superseded at the user's request; its original scaffold remains in commit 828924b. Do not restore Unity dependencies or introduce C# tooling without a new requirement.

Use the existing checkout. Cloud tasks are isolated; do not create worktrees unless requested. Keep the active milestone at M0/M1; M2 requires M1 review. No pack opening, buying, customer AI, save system, online services, paid APIs or unrelated systems yet.

Use feature folders, explicit exported NodePaths and typed references. Never wire gameplay by searching scene object names. Interactable defines the shared contract; InteractionController owns ray/range/occlusion logic. Authored products are Resources with stable IDs; prices are integer cents. Keep data validation independent of presentation. Commit .gd.uid files and .tres/.tscn sources, never .godot or build outputs.

ShopBuilder owns scenes/starter_shop.tscn. Generation replaces that file, not arbitrary user scenes. Preserve custom edits in a separate scene before regeneration. Editor-menu generation requires confirmation. Do not duplicate gameplay logic in generator or interactable subclasses. Use primitive, original placeholder art.

Validation: run Godot editor import, tools/generate_shop.gd when generator changes, tests/run_tests.gd and a main-scene smoke run. Tests must exit nonzero on failure; inspect stderr too, since engine parser/runtime errors can occur with zero exit status. Document exact engine, counts and limits. Headless physics/UI-state tests do not prove desktop rendering, physical mouse capture, real button clicks or Windows exports. Full M1 acceptance remains gated on the desktop checklist in README.
