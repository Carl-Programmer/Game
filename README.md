# 🥔 POTATO GAME — GAME DESIGN DOCUMENT (v2 — Finalized)

**Genre:** Farming / Foraging / Collection / Economy / PvP
**Platform:** Roblox
**Players per Server:** 10-15
**Core Fantasy:** Forage, grow, discover, collect, trade, cook, and battle with unique potatoes.

> **v2 changelog:** Combat redesigned around a multi-potato loadout with infinite throws and post-match decay (replaces single-potato + M1 melee). Foraging (hoe + mob risk) is now the primary potato source; farming is the safe backup. Everything else carries over from v1.

---

# 1. GAME OVERVIEW

Players collect potatoes with randomized characteristics and decide what to do with them.

A potato can be:

* 🪓 Foraged from the world (primary)
* 🌱 Grown on the player's farm (backup, safe & slower)
* 💰 Sold or traded
* ⚔️ Used in PvP
* 🍳 Cooked into food
* 📖 Added to a collection

### Core fantasy

> **Forage a potato. Find a crazy one. Decide what to do with it. Then fight someone with it.**

---

# 2. CORE GAME LOOP

```text
        🪓 FORAGE (primary)      🌱 FARM (backup)
                    \                /
                     v              v
                  🥔 POTATO ROLLED
              (rarity, effect, weight, quality)
                          ↓
              INVENTORY + COLLECTION BOOK
                          ↓
        ┌─────────────────┼─────────────────┐
        ↓                 ↓                 ↓
   ⚔️ PvP LOADOUT      🍳 Cook          💰 Sell/Trade
        ↓                 ↓                 ↓
  Infinite throws,     Food buff         Spuds
  decay after match   (separate slot)
        └─────────────────┼─────────────────┘
                          ↓
                   💰 Spuds earned
                          ↓
              Upgrade Hoe / Farm / Zones
                          ↓
                Find Better Potatoes
                          ↓
                       REPEAT

        🧑‍🌾 Rare Merchant Event — feeds seeds/hoe upgrades
        into either path, unpredictably
```

The game should always give the player a reason to seek a better potato.

---

# 3. WORLD STRUCTURE

The game should **NOT use a massive open-world lobby**.

Each server contains:

* 🏠 Personal player farms
* 🌲 Several small forageable zones (see Section 6)
* 🏪 Central hub
* ⚔️ PvP Arena (separate place — see Section 22)
* 🍳 Cooking/Restaurant area
* 🧑‍🌾 Merchant spawn point

Recommended server size: **10–15 players**, compact and performance-friendly.

Map Structure Idea:
<br>
<img width="759" height="466" alt="image" src="https://github.com/user-attachments/assets/e78a86a2-3a80-4e49-af8a-4a8e53185e0d" />

---

# 4. PLAYER FARM (BACKUP LOOP)

Every player receives a personal farm plot. Farming is the **safe, reliable, slower** way to get potatoes — it exists so players always have a fallback that requires no risk.

```text
Buy/obtain seed → Plant → Wait for growth → Harvest → Inventory
```

### Farm upgrades
* Number of plots
* Growth speed
* Potato quality chance
* Mutation chance
* Farming efficiency

---

# 5. POTATO FORAGING (PRIMARY LOOP)

Foraging is the primary **active** way of finding potatoes. Players take their hoe into the world and dig at suspicious soil spots.

```text
Find Suspicious Soil → Dig with hoe → Random result
```

Possible outcomes: nothing / common–rare potato / special item / **mob encounter**.

---

# 6. FORAGING ZONES

| Zone | Possible Rarities | Risk |
|---|---|---|
| 🌳 Forest | Common, Uncommon, Rare | Low |
| 🏜️ Drylands | Uncommon, Rare, Epic | Medium |
| ❄️ Frozen Fields | Rare, Epic, Legendary | High |
| 🌋 Volcano | Epic, Legendary, Mythic | Very High |

Higher-tier zones require better hoes to access (see Section 8) and carry greater mob risk.

---

# 7. MOB RISK

Some forage spots trigger mobs. This makes valuable potatoes cost something beyond time.

* Getting overwhelmed should have a real stake — e.g. dropping foraged potatoes on defeat, or being sent back to town empty-handed.
* Mobs stay simple; no complicated RPG combat system needed.
* Players carry a basic combat tool for mobs — **the hoe is a foraging tool first, not a combat weapon.**
* Late hoe upgrades can reduce ambush risk, not just increase speed.

---

# 8. HOE PROGRESSION

The hoe is the player's primary foraging progression system.

| Hoe | Dig Speed | Extra Stat | Zone Access |
|---|---|---|---|
| Wooden | Base | — | Forest |
| Iron | Faster | Better detection | Drylands |
| Golden | Faster | Better rare-potato chance | Frozen Fields |
| Crystal | Fastest | High luck | Volcano |

Keep the hoe simple in v1: dig speed, luck, detection range, zone access. No more stats than that.

---

# 9. POTATO SYSTEM

Every harvested/foraged potato receives four **independent** randomized rolls:

**⭐ Rarity** — Common · Uncommon · Rare · Epic · Legendary · Mythic
**⚡ Effect** — Speed, Shield, Lifesteal, Dash, Knockback, Explosion, Ice, etc.
**⚖️ Weight** —  Kg value, e.g. 0.1kg–4kg+ (affects throw arc & knockback)
**✨ Quality** — Rotten · Poor · Normal · Good · Perfect (affects effect potency)
**🧬 Mutation** (optional) — Rainbow, Charged, Crystal, Burnt, Shadow, Sun-Kissed

`The effect pool absorbs mutations`

`Instead of a separate Mutation roll, former "mutation" concepts become entries in the same Effect pool — this turns every mutation into a genuine gameplay variant instead of a purely cosmetic layer, and gives you more potato varieties without adding a whole extra stat:`

|Category|Example effects  |
|--|--|
| Combat |Speed, Shield, Lifesteal, Dash, Knockback, Explosion, Ice  |
| Mutations | Rainbow (small all-round buff), Charged (chain/shock damage), Crystal (bonus defense), Burnt (damage-over-time), Shadow (brief invisibility on dash), Sun-Kissed (regen)


### Suggested rarity odds (base rates, tune via playtest)

| Rarity | Odds |
|---|---|
| Common | ~50% |
| Uncommon | ~25% |
| Rare | ~15% |
| Epic | ~7% |
| Legendary | ~2.5% |
| Mythic | ~0.5% |

Zone, weather, and hoe upgrades shift these slightly — but Mythic should stay rare (≤2–3%) even at max progression, or the "holy grail" feeling dies.

---

# 10. POTATO DESIGN PHILOSOPHY

A potato is never simply "Legendary = better than Rare." Two potatoes of the same rarity can serve completely different builds:

* **Legendary — 3.8kg, Explosion, Perfect** → slow, extremely powerful combat style
* **Legendary — 0.4kg, Speed, Good** → fast, mobility-focused build

The goal is desirable **god-roll combinations**, not a single power ranking.

**Example Player Market UI:**
<br>
<img width="647" height="302" alt="Untitled-2026-02-19-1449 excalidraw" src="https://github.com/user-attachments/assets/966fc3d7-a943-4d2b-a6f5-00d7d2d7dda5" />

---

# 11. POTATO FRESHNESS / CONDITION

Potatoes never permanently disappear from inactivity. Condition only changes through **match usage**, not passive time decay (see Section 21) — a player is never punished for a potato just sitting in inventory.

* 🟢 **Fresh** — full effectiveness
* 🟡 **Stale** — reduced effectiveness
* 🔴 **Rotten** — cannot be used in PvP; still sellable for a small amount or cookable

Optional future feature: 🧊 Refrigerator — further slows any residual decay.

---

# 12. POTATO ECONOMY

Currency: **💰 Spuds**

**Earned via:** selling potatoes, selling cooked food, PvP rewards, other activities
**Spent on:** farm upgrades, hoe upgrades, seeds, cooking, repairs, other progression

---

# 13. POTATO SELLING

NPCs offer a guaranteed but low floor price (e.g. Rare Potato → 500 Spuds). Players can earn far more through the player market — the NPC never sets true value.

---

# 14. PLAYER MARKET

Players list potatoes for other players. Player demand — not rarity alone — determines real value. A well-rolled PvP combination can be worth far more than another potato of identical rarity.

---

# 15. POTATO MERCHANT

The merchant is **not permanently available** — he appears periodically as a world event ("THE POTATO MERCHANT HAS ARRIVED! He will leave in 10 minutes.") and sells special seeds, rare ingredients, hoe upgrades, and limited items. This should feel like an event, not a shop tab.

---

# 16. COOKING

Secondary system: `🥔 Potato → Choose Recipe → 🍳 Cook → 🍟 Food`. Food gives temporary effects (e.g. Speed Potato → Speed Fries).

---

# 17. FOOD SLOT

Separate from the PvP potato loadout (Section 20): **1 Food Slot** for a passive temporary buff (e.g. +10% movement speed). This does not consume or interact with the PvP loadout slots — it's a parallel, always-on buff layer.

---

# 18. RESTAURANT

Keep v1 simple: `Potato → Recipe → Food → Sell`. No NPC customer AI, seating, waiters, or minigames yet.

---

# 19. PVP OVERVIEW

PvP is one of the game's main features but stays separate from the farming/foraging world (its own arena place).

> **Philosophy: Potatoes determine your playstyle. Skill determines the winner.**

---

# 20. COMBAT SYSTEM — POTATO LOADOUT (v2 REDESIGN)

**Combat tool: Potato Launcher**, not traditional melee weapons or a single equipped stat-stick.

* Before a match, players build a **loadout of 2–3 potato slots** from their inventory.
* During the match, players **switch between equipped potatoes** via hotkey (1/2/3) and throw **infinitely** — no ammo tracking mid-fight.
* **Weight** affects throw arc and knockback; **Quality** affects effect potency; **Freshness** affects damage falloff.
* A universal **Dash** (Q) is available to everyone regardless of loadout, so movement tech isn't gated behind potato choice.
* An empty/no-ammo state doesn't exist — the launcher always has a weak fallback bonk so nobody is fully helpless.
* This is where **builds/playstyles emerge**: e.g. Speed + Dash for hit-and-run, Heavy + Shield for a tank build.

### Post-match decay
* When the match ends, only the **potatoes actually thrown** during the match take a durability hit — unused loadout slots stay fresh.
* **Losses decay more than wins**, adding stakes to which potatoes you risk in a match.
* This replaces per-throw ammo consumption, keeping combat fast while preserving an ongoing reason to keep foraging/farming/trading.

Loadout Selection:
<br>
<img width="758" height="367" alt="image" src="https://github.com/user-attachments/assets/574ccf35-f713-4e59-98eb-294f67d21ea6" />

PVP HUD:
<br>
<img width="838" height="318" alt="image" src="https://github.com/user-attachments/assets/d44066c7-ee8f-42ed-bc07-ba585e2ea41d" />

---

# 21. PVP CONTROLS

| Input | Action |
|---|---|
| M1 / Throw | Launch equipped potato |
| 1 / 2 / 3 | Switch loadout slot |
| Q | Universal dash |
| Space | Jump |

---

# 22. CASUAL PVP

Casual PvP uses **the player's actual loadout** — this is the "how strong is my potato build?" mode.

### Launch mode: 🥔 Potato Duel (1v1)

```text
Equip loadout → Matchmaking lobby → Solo queue or Invite friend
   → Mode assigned → Teleport to arena place → Combat (infinite throws)
   → Result → Post-match decay applied → Return to lobby
```

This flow is intentionally mode-agnostic: adding FFA, 2v2, or team battles later only means adding a new "mode assigned" branch — matchmaking, teleport, and decay logic never change.

Later modes: 2v2, FFA, team battles, special events.

---

# 23. RANKED PVP

Ranked focuses on **player skill**, not potato wealth — "how good am I?" Players compete using **standardized/balanced loadouts** rather than their own inventory, so farming progress never buys competitive advantage.

Ranks: Bronze → Silver → Gold → Platinum → Diamond → Master, with seasonal rewards, titles, and cosmetics (never stronger potatoes).

*Open decision:* should ranked give a fully fixed 2–3 potato loadout, or let players build from a small curated pool of balanced options? Fixed is simpler to implement/balance; a curated pool preserves a sliver of build choice without letting wealth matter.

---

# 24. CASUAL VS RANKED

| | Casual | Ranked |
|---|---|---|
| Question | "How strong is my potato build?" | "How good am I?" |
| Loadout | Player's own foraged/farmed potatoes | Standardized/balanced |
| Goal | Economy-driven fun | Competitive progression |

---

# 25. PVP REWARDS

Battle Tokens, titles, kill effects, emotes, cosmetics — never a direct advantage in the farming economy.

---

# 26. COLLECTION SYSTEM

A Potato Collection/Book tracks discovered types and combinations (e.g. "Legendary: 1/10"). Gives players a reason to chase rare potatoes even without a PvP use for them.
<br>

<img width="868" height="439" alt="image" src="https://github.com/user-attachments/assets/b9c30d82-e6a1-464e-8802-3e8831afde6f" />

---

# 27. MUTATIONS

Long-term collection depth: 🌈 Rainbow, ⚡ Charged, 💎 Crystal, 🔥 Burnt, 🌑 Shadow, ☀️ Sun-Kissed. Alters appearance and potentially grants special properties.

---

# 28. BREEDING — FUTURE FEATURE

`Potato A + Potato B → Offspring` (inherits/combines traits, chance of rare mutation). Should carry a significant Spud cost as an economic sink.

---

# 29. ECONOMY CONTROL

Sinks: farm upgrades, hoe upgrades/repairs, breeding fees, cooking ingredients, tournament fees, zone unlocks, potato condition decay. **Remove excess currency — never delete valuable player possessions.**

---

# 30. WEATHER (FUTURE)

Server-wide, simple modifiers only:

* ☀️ Sunny — +growth speed
* 🌧️ Rain — +quality chance
* ⛈️ Storm — +mutation chance
* 🌙 Special Night — special potatoes can appear

---

# 31. SERVER EVENTS

"A MYSTERIOUS POTATO HAS APPEARED!", "THE POTATO MERCHANT HAS ARRIVED!", "A POTATO STORM IS APPROACHING!" — pull players out of their farms/forage runs into shared moments.

---

# 32. PLAYER PROGRESSION

```text
Start → Basic Hoe → Forage Forest → Get Potatoes → (Farm as backup)
   → Earn Spuds → Upgrade Hoe → Unlock Better Zones → Find Better Potatoes
   → Improve PvP Loadout / Cooking / Collection → Repeat
```

Multiple progression paths; players never need to touch every system.

---

# 33. MVP — FIRST PLAYABLE VERSION

### 🪓 Foraging (primary)
One small zone, basic hoe, dig spots, basic potato drops, simple mob risk

### 🌱 Farming (backup)
Personal farm, plant, grow, harvest

### 🥔 Potato
Rarity, one or two effects, weight, quality

### 💰 Economy
Spuds, sell potatoes, basic upgrades

### ⚔️ PvP
1v1 Casual, one arena, potato launcher, dash, **2–3 slot loadout with infinite throws**, post-match decay, health/death/respawn

### 💾 Data
Inventory, potatoes, Spuds, farm progress, hoe progression

---

# 34. DEVELOPMENT ORDER

**Phase 1 — Core:** Inventory → Potato data → Farming → Foraging → Potato generation
**Phase 2 — Combat:** Basic launcher throw → Loadout system → Dash → PvP arena → 1v1 matchmaking → Post-match decay
**Phase 3 — Economy:** Spuds → Selling → Hoe upgrades → Farm upgrades
**Phase 4 — Depth:** More rarities/effects → Quality → Mutations → Collection
**Phase 5 — Secondary:** Cooking → Food effects → Restaurant → Player market → Merchant events
**Phase 6 — Competitive:** Ranked PvP → Seasonal ranks → Additional modes

---

# 35. DESIGN PRINCIPLES

1. **Potatoes are the star.** Every major system interacts with potatoes.
2. **Skill should matter.** Powerful potatoes help but never guarantee a win.
3. **Don't punish players for quitting.** Decay only happens from active match usage, never from being offline.
4. **Keep systems simple.** Every feature should be easy to understand before adding complexity.
5. **Build vertically before horizontally.** One complete loop fun before adding zones/modes/recipes.
6. **Player economy > NPC economy.** NPCs provide a floor; players set true value.
7. **Risk creates excitement.** Rare potatoes cost effort/danger, not just price.

---

# 36. CORE IDENTITY

> A Roblox potato collecting game where every potato can become valuable for a different reason.

🪓 Forage one. 🌱 Grow another. 💰 Sell one. 🍳 Cook one. ⚔️ Build a loadout and fight with them. 📖 Collect one.

And occasionally: **find an absolutely insane potato and have no idea whether you should sell it, use it, or cook it.** That decision is the heart of the game.
