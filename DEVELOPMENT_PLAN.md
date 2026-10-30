# Development plan — Godot restart

The active implementation uses Godot 4.6.3/GDScript. The previous Unity scaffold is historical.

- [x] M0: project configuration, Resources, architecture, conventions and documentation
- [x] M0: Godot import and headless execution verified
- [x] M1: first-person shop, collision, interaction, two products, HUD and pause
- [x] M1: committed starter scene and repeatable editor/CLI generation
- [x] M1: 36 automated checks pass
- [x] M1: user-reported desktop gameplay smoke test and review
- [ ] M1 follow-up: desktop editor-menu regeneration (headless regeneration passed)
- [x] M2: fictional baseball player/set/card database, product set references and validation
- [x] M2: 59 automated checks across database and M1 gameplay
- [x] M2: user reviewed updated inspection and authorized M3
- [x] M3: weighted pack rules, finite free starter packs and card reveals
- [x] M3: owned copy counts and collection checklist
- [x] M3: 105 combined automated checks pass
- [x] M3: user screenshots show nine copies/zero packs; user confirmed Escape restores walking
- [ ] M3 follow-up: remaining edge cases in README (restart, mid-reveal skip, exhausted-button check)
- [x] M4: finite backroom-to-shelf stocking and visible stock
- [x] M4: customer aisle routes, browsing, reservations, queue and exit
- [x] M4: checkout cash/sales and 145 combined automated checks
- [x] M4: user confirmed finite shelf stocking, customer pickup/queue and register checkout
- [ ] M4 follow-up: desktop pause/closing/empty-stock edge cases
- [x] M5: wholesale orders, cash/revenue/expenses and capacity limits
- [x] M5: sale-based levels and paid backroom upgrade
- [x] M5: local autosave/manual save, backup recovery, archived reset
- [x] M5: persistent collection/packs and backroom personal-pack opening
- [x] M5: 199 combined automated checks pass
- [ ] M5: desktop ordering/progression/restart acceptance and user review
- [ ] M6: grading, autographs, parallels and negotiations
- [ ] M7: fictional seasons and dynamic markets
- [ ] M8: polish, performance, demo and Steam readiness

The user approved continuing after the M1 desktop smoke test. M5 is authorized and implemented; do not start M6 until M5 has been reviewed and further work authorized. Optional Windows export follows desktop validation; no export templates or build are assumed installed.
