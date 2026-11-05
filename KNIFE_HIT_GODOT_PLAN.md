# Knife Hit — Godot 4 (GDScript) Rebuild Master Plan

> **Goal:** Reverse-engineer Knife Hit 1.8.34 (Ketchapp/Estoty) from the attached APKM and rebuild it in **Godot 4.x + GDScript**, producing a result that is *higher quality than the original* (feel, visuals, performance, accessibility, features).
>
> **Source artifact:** `com.ketchapp.knifehit_1.8.34-67_2arch_7dpi_24lang_...apkm` (89 MB, versionCode 67, min API 24).
>
> **Status legend:** ✅ observed (evidence) · 🟡 inferred (needs RE confirmation) · ❓ unknown (RE must resolve)

---

## 1. Reverse-Engineering Findings (recon pass)

### 1.1 Target profile

| Item | Finding | Status |
|---|---|---|
| Package | `com.ketchapp.knifehit`, Knife Hit 1.8.34 (2026-09-15 build) | ✅ `info.json` |
| Container | APKM split bundle: `base.apk` (133 MB) + ABI/dpi/locale splits | ✅ `unzip -l` |
| Game engine (original) | **Cocos2d-x 3.14.1**, physics via **Box2D** (`Gameplayb2d`, `b2World`) | ✅ `strings libMyGame.so` |
| Game binary | `lib/arm64-v8a/libMyGame.so` — 11.9 MB, **stripped but 23,054 exported dynamic symbols** incl. full C++ RTTI | ✅ `readelf --dyn-syms` |
| Java layer | 10 dex files = ads/billing/analytics/GPGS/SDKBox glue only; **no gameplay logic** | ✅ dex strings |
| Level/config files | **None** — stage generation & difficulty are hardcoded in native code | ✅ asset inventory |
| Build origin | `/Users/dagnis/Documents/EstotyProjects/knife-hit/` | ✅ path strings |

### 1.2 Recovered class map (from RTTI/vtables/dynsyms)

**Gameplay:** `Game`, `GameScene`, `GameLayer`, `Gameplayb2d`, `Knife`, `Apple`, `Target`, `Obstacle`, `HitPart`, `FlyingObject`, `level_struct`, `Math`
**HUD/Flow:** `HudLayer`, `KnifesBar`, `LevelsBar`, `XpBar`, `MenuLayer`, `GameOverLayer`, `ContinueLayer`, `LoadingScene/LoadingLayer`, `AgeGateScene`, `ExitLayer`, `LegalScreen`, `ShareSquare`, `RatePopup`
**Meta/economy:** `ShopLayer`, `ShopManager`, `ShopDataModel`, `ShopItemPreview`, `KnifePacksCell`, `IAPManager`, `AdManager`, `GiftButton`, `SettingsCell`
**Key methods visible:** `Target::prepare(int)`, `Knife::prepare(...)`, `Apple::prepare(bool)`, `Game::getStage(int)`, `Game::setStage(int,int)`, `Game::getScore(int)`, `Game::setScore(int,int)`, `Game::addCoins(int)`, `Game::getCoins()`, `Math::EasyIn/EasyOut/PingPong/Lerp/Clamp/Gamma`, `HitPart::create/setW...`, `Obstacle::create/prepare`

### 1.3 Asset inventory (all extractable, production quality)

| Asset class | Count | Notes |
|---|---|---|
| Knife sprites (`assets/HD/knifes/knife_*.png`) | **414** | shop/collection content |
| Resolution sets | 699 files each in `HD/`, `SD/`, `HDR/` | pick HD (or HDR on high-end) |
| Sounds (`assets/MP3/`) | **286** | throw, hit, boss-hit per knife, UI, music |
| Spine animations (`.skel` + `.atlas` + `.png`) | **32** | target, confetti, sparks, coins, logo, powerups… |
| Backgrounds (`assets/HD/bg/`) | 25 | base + 6 challenge themes (jungle, pirates, monsters, kingdoms, treasures, ice age) |
| Fonts | `Dyno Bold/Regular`, `NotoSans` family | ✅ TTF |
| Physics fixtures | `assets/physics/physics.plist` (PhysicsEditor, ptm 32) | container/target collision shapes |
| Challenge UI | `assets/HD/challenges/` (numbered sets + `_f/_w/_r/_inactive` states) | 6 themed challenges |

### 1.4 RE tooling status

| Tool | State | Use |
|---|---|---|
| Hopper 6.6.1 (`/opt/hopper`) | ✅ healthy, private display works | primary native RE of `libMyGame.so` |
| REA (`npx rea-agents@6.8.0`) | ✅ CLI works; ❌ MCP not registered for OpenCode (needs `rea setup --client opencode` + restart) | orchestration, evidence, paging |
| Ghidra | ❌ not installed (needs portable JDK + release zip, no sudo) | headless second opinion / decompile |
| jadx | ❌ not installed (needs JDK) | dex decompile (save keys, IAP catalog, ad triggers) |

---

## 2. Recovered Game Design (build contract)

> Numbers marked `TBD-RE` are filled during Phase 2 decompilation; each maps to a symbol to crack.

### 2.1 Core loop (observed gameplay + asset/symbol evidence)

1. Stage starts: `Target` shows a rotating log/disc with `N` slots; `N` knives waiting in `KnifesBar`.
2. Player **taps anywhere** → current knife launches upward with fixed velocity.
3. Knife embeds at impact angle (relative to target) → sticks (becomes child of rotating target).
4. **Fail:** thrown knife hits an already-stuck knife → bounce-off + game over (`AFTER MISSING THE KNIFE`, `ev_knife_hit_` sounds).
5. **Win:** all `N` knives embedded → stage clear → next stage (`Game::getStage/setStage`).
6. Every `TBD-RE` stages → **boss target** (HP bar, `BOSS: %s`, `boss_hit/ev_hit_*.mp3`, `DEFEAT BOSS`, `BOSS DEFEATED`).
7. **Apples** embedded in the target = currency (`APPLES`, `apple_angles`, `ev_apple_hit_`, `apple_coin` Spine) → spent in `ShopLayer` on knives (`KNIFE PACKS`, 414 sprites).
8. Game over → `ContinueLayer` (extra life / apples / rewarded video) → otherwise `GameOverLayer` (score, `gpgsSubmitHighstage`).
9. Meta: XP/levels (`XpBar`, `add_xp`, `DEFEAT BOSSES TO GAIN XP`), daily gift, missions, 6 **challenge themes**, VIP subscription + ads (all optional/strip-able).

### 2.2 Target rotation

- Per-stage angular velocity curve with **direction flips** mid-stage. Easing helpers exist in binary: `Math::EasyIn/EasyOut/PingPong/Gamma` → speed ramps and ping-pong oscillation are used. 🟡
- Parameters per stage: `base_speed`, `flip_intervals[]`, `pattern_id` → all `TBD-RE` from `Target::prepare(int)` + `level_struct`.

### 2.3 Knife throw & collision

- Fixed forward velocity, no aiming (tap-only). Impact = ray/segment vs target circle(s). 🟡
- Stick rule: angular gap between new knife and nearest stuck knife `< min_gap` (radians, scales with target radius) → collision → game over. Fixture data in `physics.plist` (container polygon) confirms shape-based contact in original. 🟡
- Apple rule: knife passing within `apple_angles` window collects apple (separate sensor). 🟡

### 2.4 Scoring / economy

- Score = stage reached (`Game::getScore(int)/setScore(int,int)`), highscore local + GPGS (`gpgsSubmitHighstage`).
- Currency: apples → knives; coins (`Game::addCoins/getCoins`) → continues/powerups. Exact rates `TBD-RE`.

---

## 3. Godot Project Architecture

### 3.1 Project settings (Godot 4.3+)

```
Window: viewport 1080x1920 (portrait), stretch mode=canvas_items, aspect=expand
Renderer: gl_compatibility (max device coverage) / mobile on Android
Physics tick: 60 Hz (throw simulation fixed-step for determinism)
Rendering: texture_filter = Nearest? -> No: Linear (art is HD) ; msaa_2d=2x
Audio: bus layout Master / SFX / Music
Input: single virtual action "throw" (touch + mouse + space)
```

### 3.2 Folder layout

```
knife-hit-godot/
├── project.godot
├── docs/SPEC.md                  # RE'd constants table (filled by Phase 2)
├── assets/
│   ├── art/knifes/  art/bg/  art/ui/  art/challenges/
│   ├── spine/                     # .skel/.atlas/png (+ Spine-Godot module, see §6)
│   ├── audio/sfx/  audio/music/
│   └── fonts/
├── data/
│   ├── stages.json               # generated stage tables (TBD-RE filled)
│   ├── knives.json               # 414 knife defs: id, name, price, sprite
│   └── balance.json              # all TBD-RE constants in ONE file
├── scenes/
│   ├── boot/Boot.tscn            # loading + age gate
│   ├── menu/Menu.tscn
│   ├── game/Game.tscn
│   ├── shop/Shop.tscn
│   └── ui/ (GameOver, Continue, Pause, Settings, ChallengeSelect)
├── scripts/
│   ├── autoload/  Game.gd  Save.gd  AudioManager.gd  EventBus.gd  AdsStub.gd
│   ├── game/      GameDirector.gd  Target.gd  Knife.gd  ThrowController.gd
│   │              StageGenerator.gd  Apple.gd  Boss.gd  HitFX.gd
│   ├── ui/        Hud.gd  KnifesBar.gd  GameOverView.gd  ContinueView.gd …
│   └── meta/      ShopManager.gd  Progression.gd  ChallengeManager.gd
└── tools/extract_apkm.sh  re/ (RE notes, evidence IDs)
```

### 3.3 Scene tree — `Game.tscn`

```
Game (Node2D)                     [GameDirector.gd]
├── Background (Sprite2D + ParallaxBackground)
├── World (Node2D)
│   ├── Target (Node2D)           [Target.gd]
│   │   ├── Sprite (Sprite2D)             # log / boss body
│   │   ├── StuckKnives (Node2D)          # children rotate with target
│   │   ├── Apples (Node2D)
│   │   └── Shape (CircleShape2D/StaticBody2D)   # from physics.plist
│   ├── Knife (Node2D)            [Knife.gd] — in-flight knife (kinematic, manual integration)
│   └── FX (Node2D)               # sparks, confetti, shake camera host
├── Camera2D (shake via offset)
├── HUD (CanvasLayer)
│   ├── KnifesBar (HBoxContainer) # remaining knives
│   ├── StageLabel / ScoreLabel / BossHP (ProgressBar)
│   └── ApplesCounter
└── Overlays (CanvasLayer): Pause, ContinueView, GameOverView, ChallengeHUD
```

**Autoloads:** `EventBus` (signal hub) · `Game` (run state: stage, score, knives, economy) · `Save` (JSON user://) · `AudioManager` · `AdsStub` (rewarded-video interface → no-op offline; real SDK only if packaging Android).

---

## 4. System Specs (GDScript design)

### 4.1 GameDirector (state machine)

```gdscript
enum State { MENU, STAGE_INTRO, PLAYING, BOSS, STAGE_CLEAR, GAME_OVER, CONTINUE, PAUSED }
# transitions:
#   STAGE_INTRO -> PLAYING (0.6s banner) -> STAGE_CLEAR -> STAGE_INTRO
#   PLAYING -> GAME_OVER on knife-knife hit
#   GAME_OVER -> CONTINUE (player choice) -> PLAYING (resume same stage) or MENU
```

- Owns difficulty lookup: `var cfg := StageGenerator.config_for(Game.stage)`.
- Emits `EventBus.stage_started / stage_cleared / game_over(stage, score)`.

### 4.2 Target (rotation)

```gdscript
@export var base_speed: float          # rad/s, from balance.json
var pattern: Array                     # [{t: 0.0, speed: 1.4, dir: +1}, ...]  (TBD-RE)
var elapsed := 0.0

func _physics_process(delta: float) -> void:
    elapsed += delta
    speed = evaluate_pattern(pattern, elapsed)   # EasyIn/EasyOut/PingPong curves
    rotation += speed * dir * delta
```

- `pattern` comes from `StageGenerator` → data-driven, tunable without code edits.
- Boss mode: rotation patterns per boss phase; `HitPart` weak points → `Boss.gd` HP.

### 4.3 ThrowController + Knife (flight & impact)

```gdscript
const FLY_SPEED := 1400.0              # px/s — TBD-RE (match original feel)
const MIN_GAP := deg_to_rad(9.0)       # TBD-RE from RE

func throw_knife() -> void:
    if state != State.PLAYING or knives_left == 0: return
    knife.launch(Vector2.UP * FLY_SPEED)   # world-space, target keeps rotating

# Knife.gd — fixed-step integration in _physics_process:
func _physics_process(delta):
    position += velocity * delta
    var hit := ray_to_target(position, position + velocity * delta)
    if hit: _resolve_impact(hit)
```

`_resolve_impact(hit)` (deterministic, no physics engine needed for the check):
1. Convert contact point → angle `θ` relative to target center **in target-local space**.
2. If `θ` within apple window → collect apple (`EventBus.apple_collected`).
3. For each stuck knife angle `φ`: if `angular_dist(θ, φ) < MIN_GAP` → **game over** (knife bounces: short reverse velocity + spin + `ev_knife_hit` sfx, camera shake, slow-mo 0.25s).
4. Else → **stick**: reparent to `StuckKnives` at `θ`, thud SFX with pitch jitter, tiny hit-spark, `knives_left -= 1`.
5. `knives_left == 0` → `STAGE_CLEAR` (confetti Spine anim, next stage).

> Using manual math instead of RigidBody2D gives frame-rate-independent, testable outcomes — a deliberate improvement over the original's Box2D contact solver (reproducibility for the verification suite, §7).

### 4.4 StageGenerator + difficulty curve

```gdscript
func config_for(stage: int) -> StageConfig:
    return StageConfig.new(
        knives_for(stage),           # grows + pattern repeats (TBD-RE)
        pattern_for(stage),           # cycles through ~8 handcrafted patterns
        has_apples(stage), apple_windows(stage),
        is_boss(stage)               # every BOSS_INTERVAL stages (TBD-RE)
    )
```

- **Data-driven:** `data/stages.json` generated once from RE'd constants; runtime reads only JSON → rebalancing never touches code.
- Seeded RNG per stage (`hash(stage_id)`) → deterministic for tests + daily challenges.

### 4.5 Economy, shop, progression (meta)

- `ShopManager`: 414 knives → `knives.json` `{id, name, price, sprite, pack}` (names/strings recoverable from `.so` + `assets/HD/knifes`).
- `Progression`: XP from stage clears/bosses (`add_xp`, `+200% BOSS XP!`), level rewards, daily gift timers (`idle_bonus_apples` strings suggest idle accrual 🟡).
- `Save.gd`: single JSON (`user://save.json`) — score, stage, apples, coins, owned knives, settings, missions. Versioned + migration hook.
- **Ads/IAP/subscription removed** by default (`AdsStub`, no-ads VIP perks folded into normal rewards). Optional Android packaging can re-add a rewarded-video stub behind a feature flag.

### 4.6 Audio

- `AudioManager` with random pitch ±4% on SFX (throw, thud, miss, UI), separate bus for music ducking during boss intro.
- Per-knife boss hit sounds: `boss_hit/ev_hit_1_<boss>.mp3` selected by boss id.

### 4.7 Juice / game-feel layer (part of "beat the original")

| Effect | Implementation |
|---|---|
| Screen shake | `Camera2D.offset` trauma curve on miss/boss hit |
| Hit sparks / confetti | extracted Spine anims (or CPUParticles2D fallback) |
| Slow-mo on game-over miss | `Engine.time_scale = 0.25` for 0.3 s, restore on tween |
| Knife anticipation | 1-frame squash on tap before launch |
| Haptics | `Input.vibrate_handheld()` on hit/miss (mobile) |
| Stage banner | spring-in label + knife-whoosh |
| Background | parallax layers + subtle vignette pulse on boss |

### 4.8 Improvements over the original (acceptance bar)

1. **120 fps** support + fixed-step throw sim (no physics tunneling).
2. **Deterministic, data-driven stages** → testable, rebalancable, seeded daily challenge mode.
3. **Accessibility:** left-hand mode, UI scale, colorblind-safe boss HP, reduced-motion toggle (original has a LEFT-HAND string 🟡 — parity, then extend).
4. **Zero ads/IAP/subscription** — all content earnable by play.
5. **Feel upgrades:** slow-mo, trauma shake, pitch-jittered audio, hit-stop on last knife of a stage.
6. **Offline-first save** with export/import (JSON).
7. Performance: single draw-call atlases per theme, texture streaming off, < 50 MB install from extracted HD art.

---

## 5. Phase Plan & Milestones

### Phase 0 — Toolchain (once, ~half day)
1. `rea setup --client opencode --dry-run` → show exact paths/backups → apply with approval → **restart client** (REA MCP tools appear). Fallback: REA CLI (`npx rea-agents@6.8.0`) with no restart.
2. Portable JDK (Temurin tarball) → **jadx** (dex) + **Ghidra 12.1.x** (headless native) in-workspace; Hopper as interactive engine.
3. Create Godot project skeleton (§3.2) + `godot` binary (official tarball, no sudo).

### Phase 1 — Extraction (half day)
4. Unpack `.apkm` → `base.apk` + splits; SHA-256 inventory (evidence record).
5. Extract art/audio/fonts/Spine/`physics.plist` into `assets/`; auto-generate `knives.json` from file list.
6. jadx decompile dex → record save-prefs keys, IAP catalog, ad trigger points in `docs/RE-dex.md` (to strip/replace).

### Phase 2 — Native RE of `libMyGame.so` (2–3 days, the critical path)
7. Open in Hopper (primary) + Ghidra headless (cross-check); RTTI/vtable graph already mapped (§1.2).
8. Decompile, in priority order, each feeding a `balance.json`/`stages.json` field:

| # | Symbol(s) | Extract | Consumed by |
|---|---|---|---|
| 1 | `Target::prepare(int)`, `level_struct` | rotation patterns, speeds, flip timing | §4.2 |
| 2 | stage gen path around `Game::getStage/setStage` | knives per stage, apple windows, boss interval | §4.4 |
| 3 | `Knife::prepare` + throw handler | fly speed, spawn offset, min-gap constant | §4.3 |
| 4 | `Gameplayb2d` + `physics.plist` | collision shapes, contact radii | §4.3 |
| 5 | `Game::getScore/setScore/addCoins/getCoins` | scoring & economy rates | §4.5 |
| 6 | boss path (`HitPart`, `BOSS` strings, `boss_hit` ids) | boss HP, phases, patterns | Boss.gd |
| 7 | `Math::EasyIn/EasyOut/PingPong/Gamma` call sites | exact curve shapes | §4.2 |
| 8 | `ShopManager`/`ShopDataModel` | knife prices, pack grouping | §4.5 |

9. Fill `data/balance.json` + `data/stages.json`; every constant carries `{value, symbol, evidence_id, confidence}`.
10. Write `docs/SPEC.md` (observed vs inferred vs unknown — no silent guesses).

### Phase 3 — Build milestones (Godot)

| Milestone | Scope | Acceptance |
|---|---|---|
| **M1 Core loop** | Target rotation, tap throw, stick, miss→game over, stage clear, score | Playable 10 stages; feel matches original video recordings |
| **M2 Stages+Boss** | StageGenerator JSON, 8 patterns, boss interval + HP boss | 50 stages playable; boss phases work; constants from SPEC |
| **M3 Meta** | Menu, shop (414 knives), apples/coins, continues, save/load | Full loop: die → continue/shop → progress persists |
| **M4 Content** | 6 challenge themes, XP/missions, audio pass, Spine FX | All 6 challenges playable; every SFX wired |
| **M5 Polish** | Juice (§4.7), accessibility (§4.8), performance pass | 120 fps on test device; checklist signed off |
| **M6 Ship** | Export: web (itch.io) + Android APK (Capacitor-like via Godot export) | Install size, cold start, no crashes in 1 h soak test |

### Phase 4 — Verification
11. **Differential tests (headless Godot):** simulate throws against recorded stage patterns; assert stick/miss outcomes equal SPEC predictions (deterministic by design).
12. **Side-by-side:** play original APK (emulator) vs build on same stages — rotation feel, speed, gap tolerance judged on video, tuned to match within tolerance.
13. Regression suite: save migration, shop prices, boss HP, challenge seeds.
14. Soak/perf: frame graph, draw calls, memory over 30 min.

---

## 6. Risks & Open Decisions

| Risk | Mitigation |
|---|---|
| Spine animations need the **Spine runtime** (license) for `Spine-Godot` | Options: (a) use official Spine-Godot runtime if you hold/will-buy a Spine license; (b) render `.skel` offline to sprite strips with Spine Essential (free) and use `AnimatedSprite2D`; (c) re-keyFX in Godot `AnimationPlayer`. Decide at M4 — start with (c) fallback so nothing blocks |
| Stripped binary → some logic only inferable | Cross-check Hopper vs Ghidra; mark ❓ unknowns explicitly; gameplay is also well-known publicly, use as sanity check |
| RE constants wrong → "feels off" | Side-by-side video tuning loop (§4.12); all values in `balance.json` for fast iteration |
| Using extracted assets = Ketchapp/Ubisoft copyright | Fine for learning/personal builds; **do not publish commercially** with original art — swap to original assets (or buy asset-pack replacements) before any store release |
| Ghidra/JDK download size (~1 GB) | Optional — Hopper alone can carry Phase 2; Ghidra is a cross-check, not a blocker |

## 7. Definition of Done

- [ ] `docs/SPEC.md` complete: every gameplay constant traced to a symbol or marked unknown
- [ ] Godot project plays the full loop: menu → stages → boss → shop → continue → save
- [ ] 414 knives + 6 challenge themes + 286 sounds wired
- [ ] Beats original on: frame pacing (120 fps), feel (juice list), accessibility, no ads, offline save
- [ ] Headless differential tests green + 1 h soak with zero errors
- [ ] Web + Android exports built
