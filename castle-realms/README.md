# Castle Realms — shared design reference

## Collaboration
Claude and ChatGPT must read this document and inspect current code before changes. Work one step at a time. User approves design decisions. Do not treat proposed balancing values as approved. Record changes and keep this reference current. Keep design documentation off the deployed main website; this document lives on castle-realms-dev. Coordinate merges and preserve existing World Jar and Castle Realms prototypes.

## Direction
Mobile browser medieval strategy game; single player first, multiplayer later. Realistic 3D city is the goal; existing canvas prototype is pseudo-3D. City first, world map later. Fixed camera tilt and angle, no rotation, one-finger pan, pinch zoom, tap buildings, Castle home button, boundaries and gentle momentum. Buildings rearrange within fixed plots.

## Confirmed buildings
- Castle: central progression; no building may exceed Castle level. Upgrade requires City Wall at current Castle level, another specified building, resources and time. Gold required for upgrades to 25+.
- Barracks: all troop types including infantry, ranged, cavalry and siege; no separate training buildings. Level controls tier unlocks, batch capacity and training speed. One independent training queue; choose type, tier and quantity; offline training.
- Academy: independent research tree separate from Lord Tree, military/economic/development research; level gates research; one independent research queue.
- Smithy: craft and upgrade Lord equipment for military and kingdom bonuses; level gates functionality.
- Hospital: level controls wounded capacity and healing speed; one independent healing queue, choose troops and quantity; costs resources and time, cheaper than training; offline healing and speedups.
- Rally Hall: allied coordinated attacks; level controls combined rally capacity.
- Embassy: incoming allied reinforcement capacity; level controls alliance help count and time reduction per help. Free alliance help for construction and research.
- Watchtower: level progressively reveals arrival time, troop count, types/tiers, military bonuses and solo/rally status.
- Market: alliance resource transfers; level increases capacity and reduces taxes.
- City Wall: level increases durability, defensive bonuses, trap capacity and trap type unlocks; trap production and repairs handled by wall, no separate Trap Workshop.
- Warehouse: unlimited accumulated resources; level controls protected amount; excess can be plundered.
- Treasury: unlock Castle 24; produces gold; level increases production; gold exclusively for Castle upgrades to 25+, not premium currency.
- Housing districts: independently upgradeable, increase total troop capacity; maximum five, additional district at Castle 10. Later district thresholds not finalized.
- No Hero Hall for now.

## Lord
Player has Lord, earns Lord XP, each level grants talent points to spend in Lord Tree. Separate from Academy. No building required. Branches, XP curves, points per level and reset rules not finalized.

## Economy
Food and wood available at Castle 1; Quarry/stone at 6; Iron Mine/iron at 11; Treasury/gold production at 24; gold required for Castle upgrades to 25+. Iron used for advanced construction, troop training and research.
20 interchangeable resource plots outside City Wall. Available counts by Castle level: 1:4, 5:6, 10:8, 15:12, 20:16, 25:20. Start with one Farmland, one Woodcutter, two empty plots. Players choose any unlocked resource building per plot; independently upgradeable. Demolish without refund; replacement starts level 1.
Resource buildings produce continuously including offline until individual collection capacity reached. Level increases hourly production and collection capacity. Collect All button. Uncollected resources lost on successful attack; collected resources protected according to Warehouse level, excess vulnerable.
Troops consume food continuously; larger armies and higher tiers consume more. New food prioritizes upkeep. No starvation deaths; zero food gives troop stat debuff, removed when food returns. Exact debuff and upkeep values deferred; mechanic provisional for now.

## Combat
Attacking casualties split into dead and wounded; player can improve ratio through research, Lord talents and equipment. Defending casualties all wounded. Both use Hospital; overflow dies permanently. Ratios and caps not decided.

## Queues and monetization
One free permanent construction queue; second permanent queue unlockable with Rubies or purchased package; maximum two. Rubies premium currency separate from gold. Speedups earned or purchased; Rubies can instantly finish construction. Research, training and healing queues independent, one each. Cancel construction/research/training/healing for 50% original resources; used speedups not refunded.

## Deferred decisions
Exact building unlocks except confirmed thresholds; castle maximum, costs, timers, prerequisite schedule, troop tiers and stats, research tree, equipment details, Lord Tree, casualty ratios, starvation debuff values, speedup durations and Ruby prices, multiplayer implementation. Do not invent final values. Initial city originally Castle, Farmland, Woodcutter, Barracks, Warehouse; expanded layout includes wall and housing, exact starting availability of other city buildings remains to be settled.

## Prototype status
V0.3 standalone camera prototype was committed to main at castle-realms/dev-v03.html. V0.4 expanded layout was requested; verify actual repository and deployment before claiming completion. Visual preview is not a fully implemented economy/combat system.
