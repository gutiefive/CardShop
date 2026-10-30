# Card Shop Empire conventions

Scope is M0 and M1 only. Do not begin M2 until M1 has been reviewed.
Use the existing checkout; cloud tasks are isolated. Do not create worktrees unless requested.

Unity project lives in Game/. Target Unity 6 LTS, C#, URP, Input System and Unity Test Framework. The bootstrap editor pin is 6000.0.23f1 because no editor was installed during scaffolding. Verify package resolution in that editor before accepting M1. Use feature folders, readable C#, explicit serialized references, ScriptableObjects for authored products, and stable IDs. Separate data validation from presentation. Never use object names or Find() to wire gameplay. Editor-only validation may enumerate scene objects.

Keep generated content separate from final art. StarterShopBuilder owns its generated scene, sample definitions and materials: regeneration replaces these outputs, preserving their asset GUIDs. Do not regenerate over manually edited starter content without preserving it. Commit Unity .meta files with assets. Never commit Library, credentials, or build outputs. No third-party assets, trademarks, paid APIs, online infrastructure, purchasing, pack opening, or later milestone systems in M1.

Acceptance requires actual editor compilation, successful EditMode tests, Play Mode movement/look/collision, both interactions, inspection dismissal, pause/resume, URP rendering, and duplicate-free regeneration. Record exact tested editor version and results. Never describe static checks as compilation or a scene as tested without running Unity. Report limitations honestly.
