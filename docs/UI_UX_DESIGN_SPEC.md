# UNJAM: THE LAST SLOT — UI / UX / Design Specification (current state)

*Version of the game described: 0.1.0 (release candidate) · Godot 4.7.1 · **revision 2 (2026-10-16): updated after the UI/UX improvement pass** (contrast tokens, tray rule tags, status pills, action-bar order, reward animation). Screens in `docs/design/` were re-rendered from the updated game.*
*Purpose: hand this file (plus the images in `docs/design/`) to a design reviewer — human or AI — and ask what should change.
Everything here describes **what exists today**, with exact values taken from the source; nothing is aspirational.
Section 13 lists weaknesses I measured or noticed, and Section 14 is a ready-to-paste review request.*

---------------------------------------------------------------------------------------------------

## 0. What is in the design pack

| File | What it is |
|------|------------|
| `docs/UI_UX_DESIGN_SPEC.md` | this document |
| `docs/design/sheets/sheet_1_menus_levelselect_tutorial.png` | contact sheet: splash, menus, settings, level select, credits, tutorial intro (screens 01–10) |
| `docs/design/sheets/sheet_2_gameplay_and_hints.png` | contact sheet: gameplay states, restart/hint dialogs (screens 11–20) |
| `docs/design/sheets/sheet_3_mechanics_dialogs_results.png` | contact sheet: mechanics levels, pause, rules, win, fail (screens 21–29) |
| `docs/design/screens/NN_*.png` | the 29 individual screens, 1080×1920 (= the 720×1280 design canvas ×1.5) |
| `docs/design/UNJAM_UI_UX_Design_Spec.pdf` | **single self-contained PDF (21 pages): this spec + all 29 screens embedded — easiest to hand to a reviewer** |
| `docs/design/UNJAM_design_pack.zip` | all of the above in one file (not tracked in git; rebuild by zipping the spec + `docs/design/{sheets,screens}`) |

All screenshots are rendered by the **real game screens** on a desktop OpenGL context (not photographed on a phone), so
fonts/antialiasing may differ slightly from a device. Regenerate with `tools/make_design_screens.gd` (instructions in §15).

## 1. Product context (for the reviewer)

* **Genre:** casual sorting / tray-capacity puzzle for Android phones, portrait, one-handed thumb play, offline, no ads, no account, no permissions.
* **Core idea:** move the top object of a tray onto the same shape or into an empty tray; fill a tray with one shape to clear it;
  clear everything to win. Trays have limited slots; the tension is **"who gets the last free slot?"** (hence the HUD chip *Free slots* → *Last slot!*).
* **Content:** 40 levels in 7 stages (Basics → Tight Trays → Move Limits → Locks → Special Trays → Ice → Mastery). Each new mechanic is introduced once by a card.
* **Meta:** stars per level (1–3), coins (earned on first clear, spent on hints), unlock-next progression, local save.
* **Audience intent:** general casual audience, calm tone, premium-feeling but minimal. No violence, text-light, shape-based.
* **Tone of voice:** short, friendly, plain sentences ("That tray is full.", "Let's go", "Not now"). No exclamation spam; one "clear!" on win.

## 2. Platform and display facts

| Property | Value |
|----------|-------|
| Engine / renderer | Godot 4.7.1, GL Compatibility (2D only) |
| Design canvas | **720 × 1280 logical px** (9:16). Stretch mode `canvas_items`, aspect `expand` |
| Taller phones (e.g. 20:9) | the canvas grows vertically (720×1560…); content is laid out with containers, the board is centred in the free space |
| Wider windows (tablet / foldable / landscape — Android 16 ignores the portrait lock ≥ 600 dp) | content is held in a **centred column** (max 780 logical px wide; 900 on level select) that re-flows on resize/rotation; side areas show the plain background |
| Orientation | portrait requested (`screenOrientation=portrait`) |
| Safe area | system-bar/cutout insets are added to the top/bottom (and sides) margins (`ColumnMargin`); the maths is unit-tested, **real device values not yet verified** |
| Min touch target | **96 logical px** (= 48 dp on a 360 dp-wide phone). Trays are tapped on their whole column cell (much larger) |
| Input | single tap only (`InputEventMouseButton`, Android touch is emulated as mouse). No drag, long-press, swipe or multi-touch gestures; no keyboard |
| Back button | closes a dismissible dialog → in-game opens Pause → Level select/Credits go back to Menu → Menu exits. Result dialogs (win/fail) ignore it |
| Scroll | Level select and Credits scroll vertically by touch-drag (dead-zone 24 px so a wobbly tap is still a tap) |
| Fonts | Godot's built-in default UI font (Open Sans family) — no custom font files. Bold = synthetic embolden (0.55) applied to text ≥ 34 px and to all buttons |

## 3. Design principles / visual identity

1. **Calm paper-and-ink look:** warm neutral background, white cards, one coral accent, deep indigo text.
2. **Shapes before colours:** every object type has a unique **shape + colour** so the game is readable without colour vision.
3. **Tactile 2D:** rounded rectangles (radius 26–40), soft drop shadows under buttons/cards, a small specular dot and darker rim on objects, soft ellipse shadow under objects.
4. **Everything procedural:** no bitmap art in the UI — all shapes, icons, the logo and the coin/star glyphs are drawn in code (crisp at any size); audio is synthesised in code.
5. **Restraint:** at most one primary (coral) button per screen/dialog; the HUD shows only level, moves, free slots, coins and three actions.
6. **Logo idea:** a tray holding three objects (circle, square, triangle) and one **empty dashed ring** — "the last slot".

## 4. Design tokens

### 4.1 Colour (exact values from `src/ui/ui_theme.gd`)

| Token | Hex | Usage |
|-------|-----|-------|
| `BG` | `#F3F0EA` | screen background (warm off-white) |
| `BG_DARK` | `#E7E2D8` | pressed state of secondary/icon buttons |
| `PANEL` | `#FFFFFF` | cards, dialogs, chips, secondary buttons, level tiles |
| `TRAY` | `#E1DCCF` | tray body, progress-bar track |
| `TRAY_EDGE` | `#9C9482` | tray outline (2.65:1 on BG), chip/button outlines; slot guide rings use it at 42 % |
| `INK` | `#2B2F4A` | primary text, icons, dashed "last slot" ring, toast background, padlock |
| `INK_SOFT` | `#5A5E7A` | secondary text (level name, captions, stage headers, stats) — 5.57:1 on BG |
| `ACCENT` | `#D2432F` | primary button fill (white text 4.58:1), selection ring, current-level tile border, progress fill |
| `ACCENT_DARK` | `#A82F21` | primary button pressed, "THE LAST SLOT" tagline (5.97:1), warning text |
| `GOOD` | `#2FBF71` | valid-destination highlight and tray-clear flash only (never behind text) |
| `GOOD_DARK` | `#178348` | switch ON track (white label 4.80:1) |
| `SWITCH_OFF` | `#756E5D` | switch OFF track (white label 4.9:1) |
| `WARN` | `#F4B400` | hint highlight border, coin, stars, hint cost badge |
| `ICE` | `#BFE6FA` | frozen overlay (with `#7CC3E8` rim and `#4AA3D6` snowflake) |
| Danger button | `DANGER #C23A3A` / pressed `#A02E2E` | destructive confirmations ("Restart", "Erase everything"); white text 5.30:1 |
| Chip alert fills | `#FFD9D3` (≤ 3 moves left) · `#FFE9A8` (last slot) | HUD chips |
| Dim behind dialogs | `#1A1C33` @ 55 % | modal scrim |
| Locked tile | fill `#DCD6C7`, number `#7D7863` | locked level tiles (number 3.06:1) |

### 4.2 Object palette (8 types: colour + shape; each has a darker rim 36 % and light sheen)

| Type | Colour | Shape |
|------|--------|-------|
| 0 | `#EF5B5B` red | circle |
| 1 | `#2E9BE6` blue | rounded square |
| 2 | `#F5B400` amber | triangle |
| 3 | `#2FBF71` green | hexagon |
| 4 | `#8E5CF5` purple | diamond |
| 5 | `#F06BB5` pink | star (5-point) |
| 6 | `#10A9A0` teal | pentagon |
| 7 | `#F2792B` orange | plus/cross |

Levels use 2–5 types (level 1 uses 2; most later levels use 4–5), trays have capacity 3, 4 or 5, and a level has 4–7 trays.

### 4.3 Typography (logical px at the 720 canvas)

| Role | Size | Weight | Used for |
|------|------|--------|----------|
| Logo wordmark "UNJAM" | 128 | bold | menu/splash |
| Tagline "THE LAST SLOT" | 38 | bold, `ACCENT_DARK` | menu/splash |
| H1 | 44 | bold | screen/dialog titles, "Level N", Play button text |
| H2 | 34 | bold | buttons, coin balance, "+N coins" |
| Body | 28 | regular | dialog text, chips, toasts, coach text, stage headers |
| Small | 22 (24–26 for dense text) | regular | level name, captions under icons, rules text, credits |
| Micro | 16–20 | regular | switch "ON/OFF", hint-cost badge |

Line wrapping: word-smart; text is centred in dialogs, left-aligned in Credits and Level-select stage headers. No dynamic font scaling.

### 4.4 Shape, spacing, elevation

| Element | Radius | Border | Shadow |
|---------|--------|--------|--------|
| Buttons (primary/danger/secondary) | 30 | secondary: 2 px `TRAY_EDGE` | soft: 10 px blur, +5 px y, ink @ 18 % (ghost buttons: none) |
| Dialog card | 40 | none | soft (same) |
| Tray | 0.34 × slot size | 3 px `TRAY_EDGE` | none |
| Chips (moves/free slots/coins) | 28–30 | 2 px `TRAY_EDGE` | none |
| Toast | 28 | none | none |
| Level tile | 30 | 2 px `TRAY_EDGE` (current: 5 px `ACCENT`) | soft when unlocked |
| Switch track | 26 | none | none |

Spacing (logical px): screen margins 20 (game) / 24–40 (other screens) plus safe-area insets; VBox gaps 12–18; dialog padding 36 horizontal × 34 vertical, 18 between blocks, 14 between buttons; HUD button gap 18; level-grid gap 14.

### 4.5 Iconography (all drawn in code, 3–4 px strokes, rounded caps)

Pause (two bars) · Back (chevron) · Undo (counter-clockwise arrow) · Restart (clockwise arrow) · Hint (light bulb) · Coin (gold disc with inner ring) ·
Star (filled gold / empty `#D8D2C4`) · Padlock (with the **key shape inside**) · Snowflake (ice) · Sound/Music (+ crossed variants, currently unused in UI).

### 4.6 Motion (all durations in seconds; **Reduce motion** setting makes everything instant, no shake, no pulse, no screen fade)

| Event | Animation |
|-------|-----------|
| Select object | lifts 0.45 × slot above its slot, 0.10 s ease-out; white disc + coral ring behind it |
| Move | 3 stages: rise to above the source tray (0.09) → glide above the destination (0.13, ease-in-out) → drop with a small bounce (0.10) ≈ 0.32 s total; **all input locked meanwhile** |
| Tray complete | objects pop to 1.35× and fade (0.16 / 0.20, delayed 0.12) while the tray flashes green (0.40) |
| Invalid move | tray (and its top object) shakes ±8 → ±5 px, 5 × 0.04 s, + toast |
| Board (re)build after undo/restart | objects scale 0.4→1 with back-out + fade-in (0.18 / 0.14) |
| Hint | source object pulses 1.0↔1.15 (0.4 s each, looping) until the next tap; both trays get a yellow outline |
| Dialog open | card scales 0.92→1 (back-out 0.16) with fade 0.12 |
| Screen change | cross-fade through the background colour, 0.14 s out + 0.14 s in |
| Toast | appears instantly, holds 1.2 s + 0.05 s per character (min 1.9 s, max 4.5 s), fades 0.3 s |

### 4.7 Audio (all synthesised in code; SFX at −6 dB, music at −16 dB; toggles for each)

| Cue | Sound design |
|-----|--------------|
| tap (buttons) | very short blip, 660→560 Hz, 50 ms |
| select | rising soft tone 520→780 Hz, 90 ms |
| move | soft falling "thud" 400→300 Hz + 300→260 Hz, ~160 ms |
| invalid | low soft buzz 200→150 Hz, 140 ms |
| undo | falling tone 500→330 Hz, 110 ms |
| clear (tray) | three-note rising arpeggio C5-E5-G5 |
| coin | two quick high notes 988 / 1319 Hz |
| win | C5-E5-G5-C6 fanfare |
| fail | descending 330 → 262 → 196 Hz |
| music | 8-second loop, A-minor / F / C / G arpeggio (sine), very quiet |

## 5. Component specifications

| Component | Spec |
|-----------|------|
| **Primary button** | coral `ACCENT`, white bold 34 px text (44 px for the main *Play/Continue*), min height 96 (112 for Play), radius 30, side padding 28, soft shadow; pressed `ACCENT_DARK`; disabled 35 % alpha |
| **Secondary button** | white, ink bold text, 2 px `TRAY_EDGE` outline, soft shadow; pressed `BG_DARK` |
| **Ghost button** | transparent, ink bold text, no shadow; pressed 6 % black — used for tertiary actions ("Settings", "Privacy & credits", "Level select", "Reset all progress", "Close") |
| **Danger button** | red `#D94A4A`, white text — only on irreversible confirms |
| **Icon button (HUD)** | 150 × 112 white card, radius 30, 2 px outline + shadow; vector icon centred at 38 % height, 22 px caption at 86 %; disabled = 35 % alpha content; optional corner **badge** (hint cost "15" on a gold pill) |
| **Square icon button** | 96 × 96 (pause, back) |
| **Chip** | pill 250 × 56 min, white, 2 px outline, 28 px ink text; alert fills coral-tint (≤ 3 moves left) or yellow-tint (*Last slot!*) |
| **Coin chip** | pill ≥150 × 96: gold coin icon + balance (34 px bold) |
| **Switch row** | 96-high rounded row on `BG`, label 28 px left, track 96 × 52: ON green with right knob and "ON", OFF grey `#C9C3B4` with left knob and "OFF" — whole row is the touch target |
| **Dialog (Modal)** | scrim + centred white card, min width 600, radius 40, title 44 px bold, optional body (28 px, centred), then a stack of full-width buttons (primary on top, then secondary, then ghost). Tapping the scrim dismisses dismissible dialogs; result dialogs (win/fail) are not dismissible |
| **Toast** | dark-ink pill, white 28 px text, bottom-anchored just above the action bar (game) / list bottom (level select) |
| **Level tile** | 150 × 146, number 44 px, three small stars under it (gold = earned); **current** level has a 5 px coral border; **locked** tile is a darker beige with a padlock instead of stars and a grey number |
| **Tray** | vertical rounded container: width = 1.3 × slot, height = capacity × slot + 0.3 × slot; one faint **slot ring** per capacity slot (a non-colour capacity cue); objects stack bottom-up; tap area = the full column cell |
| **Object** | circle/shape of radius 0.40 × slot with rim, sheen dot and ground shadow, always drawn at ≥ 72 % opacity so its shape stays recognisable; **locked** = 72 % opacity + a white **status pill** under it (padlock glyph + the *shape that opens it*); **frozen** = pale-blue ring + a pale-blue status pill (snowflake + moves left); **selected** = white disc + 5-px coral ring |
| **Tray rule tag** | white 0.31 × slot badge with ink ring straddling the tray's top edge: shows the single **shape** a reserved tray accepts, or an **up-arrow** for a one-way tray. Replaces the earlier faint ghost shape / tiny triangle |
| **Slot size** | computed to fit: `clamp(min(height-fit, width-fit), 36, 112)` logical px (row gap 40 px so tags never touch the tray above; the board sits at 58 % of the free height, slightly low, nearer the thumb); the tray grid is 1 row for ≤ 4 trays (level 1), 3 columns × 2 rows for 5–6 trays, 4 columns × 2 rows for 7 trays (the largest shipped level) |

## 6. Information architecture and navigation

```
Splash ──(≈1.4 s auto)──► Main menu ──► Play/Continue ──► Game (level N)
                           │   ├─► Levels ──► Game (any unlocked level)
                           │   ├─► Settings (dialog) ─► How to play (dialog) / Reset progress (confirm)
                           │   └─► Privacy & credits
Game ─► Pause (dialog: sound, music, reduce motion, Resume, How to play, Level select)
     ─► Restart (confirm if moves > 0) · Undo · Hint (confirm) · result dialogs (Win: Next / Play again / Level select · Fail: Undo / Restart / Level select)
```
Depth is never more than 3 taps from any state; there is no bottom tab bar and no account/profile area.

## 7. Screen-by-screen specification

(Image names refer to `docs/design/screens/`.)

### 7.1 Splash — `01_splash.png`
Background `BG`; the logo (tray with circle/square/triangle + dashed ring, "UNJAM", "THE LAST SLOT") centred and fading in over 0.35 s; small grey "Loading…" near the bottom.
Holds ≈ 0.5 s after the fade, then goes to the menu. If the level file cannot load, the text changes to an error message in `ACCENT_DARK` (never expected in release).

### 7.2 Main menu — `02_menu_new_player.png`, `03_menu_with_progress.png`
Top-right: coin chip. Then: logo (≈470 px tall), progress text ("14 / 40 levels cleared · 38 stars", 24 px soft), progress bar (18 px, coral fill on tray track),
**primary button** — *Play* for a new player or *Continue · Level N* (112 px tall, 44 px text), secondary *Levels*, then two ghost buttons side by side: *Settings*, *Privacy & credits*.
The lower third of tall phones is empty background. If the save file was damaged and a backup restored (or reset), a one-line warning in red appears under the buttons.

### 7.3 Settings dialog — `04_settings_dialog.png`
Title *Settings*; three switch rows (Sound effects · Music · Reduce motion); secondary *How to play* (opens the rules dialog); ghost *Reset all progress* (opens a confirmation); primary *Done*.

### 7.4 Reset confirmation — `05_reset_progress_confirm.png`
*Reset progress?* — "This erases completed levels, coins and settings on this device. It can't be undone." Danger button *Erase everything*, secondary *Cancel*.

### 7.5 Level select — `06_level_select_top.png`, `07_level_select_locked_toast.png`
Header: square back button · "Levels" · total stars "★ 38". Scrolling list grouped by stage: grey header "Stage 4 · Locks" then a 4-column grid of tiles (see §5).
Opens scrolled so the current level is in view. Tapping a locked tile plays the invalid sound and shows the toast "Clear level N to unlock this one." where N is the highest level currently unlocked (the one still to be cleared); the tile itself does not move.
Completed levels show their stars; there is no separate "completed" tick.

### 7.6 Privacy & credits — `08_privacy_and_credits.png`
Back button + title; one white card with left-aligned 24 px text in four blocks: PRIVACY, CREDITS, OPEN SOURCE (Godot MIT notice), VERSION. Scrolls.

### 7.7 Game HUD (all gameplay screens) — see `10_…` onward
Top bar (left→right): **Pause** (96 sq) · centre title column ("Level 15" 44 px bold over the level name 22 px soft) · **coin chip**.
Below it two centred chips: **Moves: N** (or **Moves left: N** on limited levels; turns coral-tinted at ≤ 3) and **Free slots: N** (reads **Last slot!** with a yellow tint when exactly 1).
Optional **coach line** (28 px, centred) only during the level-1 tutorial.
The **board** fills the remaining space (see §5/§8). **Bottom bar:** **Restart, Undo, Hint (15)** icon buttons (Restart is deliberately far from Hint). A toast appears just above the bottom bar.

### 7.8 Tutorial — `09_intro_card_how_to_play.png`, `10_game_level1_initial_with_coach.png`, `11_…`
On the very first level: a **How to play** card ("1. Tap a tray to lift its top object. 2. Tap another tray to drop it there. …") with *Let's go*.
Then a **coach line** under the chips that changes with state: "Tap the glowing tray to lift its top object." → (after lifting) "Now tap the highlighted tray to drop it there." The source tray glows yellow, the target tray gets a yellow outline.
The coach disappears after level 1 is cleared. Later mechanics get a one-time **intro card** on their first level (§10): `19_level11_move_limit_intro.png`.

### 7.9 Gameplay states
| State | Image | What the player sees |
|-------|-------|----------------------|
| Idle | `10_…` | all objects on slots; Undo disabled until a move exists |
| Selected | `11_…` | lifted object with coral ring; **valid** destination trays get a green outline + light green fill; invalid trays unchanged |
| Invalid drop | `12_…` | tray shakes, toast with the reason, selection stays |
| Moving | `13_…` | object in flight; all buttons and trays inert; destination highlights already cleared |
| After move | `14_…` | counters updated, Undo enabled |
| Tray cleared | `27_…` | objects pop, tray flashes green, objects removed |
| Restart confirm | `15_…` | only when ≥ 1 move has been made |

### 7.10 Hint flow — `16`, `17`, `18`
Tap **Hint** → the game computes a real winning move silently → dialog *Need a hint?* "Show a good next move for 15 coins? You have 85." (*Show hint (15)* / *Not now*) → source object pulses and both trays get a yellow outline until the next tap; coins −15.
If coins < 15: *Not enough coins* — "A hint costs 15 coins and you have N. Complete levels to earn more." (*OK*).
If the position can never be finished: *This can't be finished* + explanation (free) with *Undo last move* / *Restart level* / *Close*. If no hint exists: *No hint right now* (free).

### 7.11 Mechanic levels — `20_level15_padlocks`, `21_level21_reserved_trays`, `22_level24_one_way_tray`, `23_level29_ice_frozen_objects`, `24_level40_dense_mastery`
* **Padlock:** the locked object stays visible (72 % opacity) with a white pill beneath it: padlock glyph + the **shape that opens it**; clearing a tray of that shape removes the lock.
* **Reserved tray:** a white tag badge on the tray's top edge showing the only shape it accepts.
* **One-way tray:** a slightly darker tray with an up-arrow tag on its top edge; objects can be taken but never dropped in.
* **Ice:** pale-blue ring around the object and a pale-blue pill (snowflake + the number of moves left until it thaws); the shape underneath stays fully visible.
* **Move limit:** chip switches to "Moves left: N".

### 7.12 Pause — `25_pause_menu.png`
*Paused*: three switches, primary *Resume*, secondary *How to play*, ghost *Level select*. Also opened by the Android back button during play.

### 7.13 How to play (rules) — `26_how_to_play_rules_dialog.png`
Verbatim rules text (see §10.3) with *Got it*.

### 7.14 Level complete — `28_level_complete_dialog.png`
Non-dismissible dialog: "Level N clear!", three big stars (earned = gold, others grey; middle one larger), "Solved in 8 moves (par 8)", "+30 coins" (first completion) or "Replay: no new coins",
buttons *Next level* (primary; replaced by a "You finished every level" line on level 40), *Play again*, *Level select*. Stars pop in one after another (0.28 s each, 0.2 s apart) and "+N coins" counts up over 0.55 s while the coin sound plays; with **Reduce motion** the final values show immediately.

### 7.15 Level failed — `29_level_failed_dialog.png`
Non-dismissible dialog: "Out of moves" (move limit) or "No moves left" (deadlock) with one explanatory sentence, *Undo last move* (primary; shown only if undo is possible), *Restart level*, *Level select*.

## 8. Interaction model

**Two-tap move:** tap tray A (lifts its top object) → tap tray B (drops it). Tap A again to cancel. There is no drag-and-drop.

| Situation | Result |
|-----------|--------|
| Tap an empty tray as source | shake + toast "That tray is empty." (reason `EMPTY_SOURCE`, §10.4) |
| Tap a tray whose top object is locked/frozen | shake + toast explaining lock/ice |
| Tap a destination that refuses the object | shake on that tray + toast with the reason; the source stays selected |
| Tap during an animation / while a dialog is open | ignored |
| Undo | free, unlimited (up to 400 moves), restores moves, trays, unlocked state, ice countdown; allowed after a failure |
| Restart | confirm dialog if moves > 0, else immediate |
| Win | evaluated only from game state; reward processed exactly once |
| Fail | out of moves or no legal move; Undo recovers |

**State machine:** `Idle ⇄ Selected → Animating → (Idle | WinDialog | FailDialog)`; dialogs sit on top of Idle. `Animating` and any open dialog lock all game input and disable Hint/Undo/Restart.

**Feedback matrix**
| Event | Visual | Audio | Text |
|-------|--------|-------|------|
| Select | lift + ring + green targets | select | coach (tutorial only) |
| Valid move | 3-stage glide + bounce | move | counters update |
| Tray cleared | pop + green flash | clear | — |
| Invalid move | shake | invalid | toast with reason |
| Undo | board rebuilds with pop-in | undo | — |
| Hint paid | pulse + yellow outlines | coin | — |
| Win | dialog | win (+coin) | stars, moves, coins |
| Fail | dialog | fail | explanation |
| Button press | pressed colour | tap | — |
| No haptics anywhere | | | |

## 9. Progress, economy and number display

* Start balance 30 coins; hint 15; first clear pays 15 + 5 × stars (20–30); replays pay 0 (they can only improve stars).
* Stars: ≤ 125 % of par → 3; ≤ 175 % → 2; otherwise 1 (par = proven shortest solution length). Level select shows best stars.
* Move limits (23 of the 40 levels have them: 11–14, 17–20, 23, 25, 26, 29–40) are par + max(spec slack, 45 % of par). Undo refunds moves.
* Level unlock: clearing level N unlocks N+1; locked tiles are visibly different; "Continue" opens the current/next unlocked level.

## 10. Copy deck (verbatim, generated from the code)

### 10.1 Stage names
| Stage | Name |
|------:|------|
| 1 | Basics |
| 2 | Tight Trays |
| 3 | Move Limits |
| 4 | Locks |
| 5 | Special Trays |
| 6 | Ice |
| 7 | Mastery |

### 10.2 One-time intro cards (`CampaignText.INTROS`)
| Key | Title | Body |
|-----|-------|------|
| `accepts` | Reserved trays | A tray with a shape tag on its top edge only accepts that shape. Use it to park the right objects. |
| `basics` | How to play | 1. Tap a tray to lift its top object.<br>2. Tap another tray to drop it there.<br><br>Objects can land on the same shape, or in an empty tray. Fill a tray with one shape to clear it. Clear every tray to win. |
| `capacity` | Mind the free slots | Every tray has a limited number of slots. Watch the Free slots counter: when only the last slot is left, choose carefully what goes in it.<br><br>Made a mistake? Undo is free. |
| `ice` | Ice | A frozen object can't move until enough moves have been made. The number shows how many moves remain before it thaws. |
| `limit` | Move limits | Some levels allow only a set number of moves. The counter shows how many you have left. Undo gives moves back, so planning ahead is always allowed. |
| `lock` | Padlocks | A padlock freezes an object in place. The shape on the padlock tells you what opens it: clear a tray of that shape and the lock disappears. |
| `mix` | Everything together | From here on, levels mix locks, ice, reserved and one-way trays. Plan the last slot before you fill it. |
| `source` | One-way trays | A tray with an up-arrow tag only gives objects away. You can take from it but never drop into it. |

### 10.3 Rules text ("How to play")
> Tap a tray to lift its top object, then tap another tray to place it.
> 
> • Only the top object of a tray can move.
> • An object can land on the same shape, or in an empty tray.
> • Trays have limited slots. A full tray can't take more.
> • Fill a tray with one shape and it clears.
> • Clear every tray to win.
> 
> Special rules:
> • Padlock: clear a tray of the shown shape to open it.
> • Ice: wait for the shown number of moves.
> • Shape tag on a tray: it takes only that shape.
> • Up-arrow tag on a tray: you can only take from it.
> • Move limit: finish before the counter reaches 0.

### 10.4 Refusal reasons shown as toasts
| Reason code | Text |
|-------------|------|
| `BAD_TRAY` | That isn't a tray. |
| `EMPTY_SOURCE` | That tray is empty. |
| `FROZEN` | Frozen! It thaws after the number of moves shown. |
| `FULL` | That tray is full. |
| `GAME_OVER` | This level is already finished. |
| `LOCKED` | Locked! Clear a tray of the shape shown on the padlock to open it. |
| `NO_MOVES_LEFT` | No moves left. |
| `SAME_TRAY` | *(silent — tapping the selected tray just deselects)* |
| `SOURCE_ONLY` | This tray only gives objects away (up-arrow tag). You can't drop into it. |
| `TYPE_MISMATCH` | Objects only stack on the same shape, or in an empty tray. |
| `WRONG_TYPE_FOR_TRAY` | This tray only takes the shape shown on its tag. |

### 10.5 Other fixed strings
Menu: *Play* · *Continue · Level N* · *Levels* · *Settings* · *Privacy & credits* · "N / 40 levels cleared · N stars".
HUD: *Level N* · *Moves: N* · *Moves left: N* · *Free slots: N* · *Last slot!* · *Undo* · *Hint* · *Restart*.
Dialogs: *Restart level?* "Your progress in this level will be lost." (*Restart* / *Keep playing*) · *Need a hint?* · *Not enough coins* · *This can't be finished* · *No hint right now* · *Paused* · *Settings* · *Reset progress?* ·
*Level N clear!* · *Out of moves* / *No moves left* · *Next level* · *Play again* · *Level select* · *Undo last move* · *Restart level* · *Let's go* · *Got it* · *OK* · *Done*.
Toasts: "Clear level N to unlock this one." (level select) · "That hint is no longer valid. You weren't charged." · "Not enough coins."
Tutorial coach: "Tap the glowing tray to lift its top object." · "Now tap the highlighted tray to drop it there." · "Tap the lifted tray again to put it back, then try the glowing one."
Credits/privacy text is in `src/ui/credits_screen.gd`.

## 11. Accessibility status

**Provided:** unique shape per object type (colour is never the only cue) · capacity drawn as slot rings · locks show their key shape · ice shows a number · "Last slot!" has text, not just a colour ·
Reduce-motion setting · 48 dp touch targets · no time pressure, no hidden gestures, no flashing > 3 Hz · sound and music optional and the game is fully playable muted · text sizes 22–44 px on a 720 px canvas (≈ 11–22 sp on a 360 dp phone).

**Measured contrast (WCAG 2.x ratio; thresholds: 4.5 normal text, 3.0 large text/graphics; enforced by `tests/test_contrast.gd`):**

| Pair | Before | Now | Verdict |
|------|-------:|----:|---------|
| Ink text on background / on white | 11.48 / 13.06 | 11.48 / 13.06 | pass |
| Soft grey text on background / white | 4.33 / 4.92 | **5.57 / 6.33** | pass (was failing on BG) |
| White on primary coral button | 2.80 | **4.58** | pass (was failing) |
| White on pressed coral | 3.87 | **6.79** | pass |
| White on danger button | 4.18 | **5.30** | pass |
| Tagline on background | 3.40 | **5.97** | pass |
| "ON"/"OFF" label on switch | 2.38 | **4.80 / 5.07** | pass |
| Coral graphics (ring, current tile, progress) on background | 2.5 | **4.03** | pass (≥ 3) |
| Tray outline on background | 1.47 | **2.65** | improved; still below 3.0 (tray fill vs BG is 1.20) — outline is 3 px |
| Locked-tile number on locked tile | 2.09 | 3.06 | disabled state, now ≈3 |
| Object rims vs tray (36 % darker) | amber fill 1.34 | rims 3.14–6.00 | every shape has a ≥ 2.0 outline; unique shapes remain the primary cue |
| Ink on alert chips | 10.0 / 10.9 | same | pass |

**Not provided:** screen-reader/TalkBack support (the engine version used has no Android accessibility server), system font-size scaling, high-contrast mode, haptics, dyslexia-friendly font option, left-handed layout variant (the bottom bar is centred).

## 12. Responsive behaviour (renders inspected)

| Window | Logical canvas | Result |
|--------|---------------|--------|
| 720 × 1280 (16:9) | 720 × 1280 | reference layout |
| 720 × 1560 (19.5:9, cutout phones) | 720 × 1560 | content spreads vertically; board centred; empty space above/below board on easy levels |
| 540 × 960 (small phone) | 720 × 1280 (scaled 0.75) | identical layout, smaller physical size |
| 1200 × 1920 (tablet portrait) | 800 × 1280 | centred 780-px column with 10 px side margins |
| 1280 × 720 (landscape/tablet/foldable) | 2275 × 1280 | centred 780-px phone-style column; large empty side areas |

## 13. Status of the review findings (revision 2)

**Resolved in this revision (verified by tests/renders):**
1. Contrast failures — primary button text, soft captions, switch labels, tagline, coral graphics, tray outline (partially) → §11, `tests/test_contrast.gd`.
2. Reserved-tray ghost shape and one-way arrow were easy to miss → clear **tag badges** on the tray's top edge (§5, `22_…`, `21_…`), wording updated everywhere (intro cards, rules text, refusal toasts).
3. Padlock key shape was tiny and ice hid the object → **status pills** (§5); the shape underneath stays visible.
4. Long refusal toasts vanished too fast → duration scales with text length (1.9–4.5 s).
5. Restart sat next to Hint → order is now Restart · Undo · Hint.
6. Dead space under the HUD → board sits slightly low (58 % of free height); menu block is vertically balanced with spacers.
7. Reward moment flat → stars pop in sequentially, coins count up (respects Reduce motion).
8. Splash logo mis-positioned and Settings dialog taller than the screen (fixed earlier in this pack).

**Still open — for the next reviewer / playtests:**
* Amber triangle on the tray fill is still the weakest object (rim ≥ 2.0:1 but the fill is 1.34:1). Consider a darker tray fill or a thicker rim.
* Tray fill vs page background is 1.20:1; the 3-px outline carries the boundary.
* Thumb reach: Pause is top-left (hardest reach); consider a bottom or top-right placement after testing on real devices.
* No haptics — **deliberate**: vibration needs the `VIBRATE` permission and the "no permissions at all" property is a selling point; reconsider only if playtests show the need.
* TalkBack/screen reader: impossible with Godot 4.7.1 (no Android accessibility server); documented limitation.
* No persistent legend for the symbols (long-press help); the rules dialog and intro cards are the references.
* Hint flow is two taps plus a dialog; the highlight has no "hint used" marker.
* Level select lacks an explicit "completed" tick and stage progress summary.
* Single default font with synthetic bold; no brand typeface.
* Landscape/tablet is a centred phone column, not a tailored layout.
* Audio and difficulty fairness have never been checked by humans (`docs/PLAYTEST_PLAN.md`, not run).

## 14. Ready-to-paste review request

> You are a senior mobile game UI/UX and visual designer. Attached: a design specification for a finished Android puzzle game ("Unjam: The Last Slot"), three contact sheets and 29 individual screens.
> Please (1) review the visual design, information hierarchy, interaction model, copy and accessibility against current mobile-game best practice and WCAG 2.2 / Material touch-target guidance;
> (2) challenge each open item in section 13 — agree, disagree or reprioritise; (3) list additional problems you see in the screenshots;
> (4) propose **specific, minimal, implementable changes** (hex values, sizes, copy, animation timings) ranked by impact vs. effort, marking which are *must-fix before launch*, *should-fix*, and *nice-to-have*;
> (5) say what you would test with real players. Constraints: portrait phone game, Godot 2D with procedurally drawn graphics (no image assets), offline, no ads, no custom font files, small team. Do not suggest adding new game mechanics or monetisation.

## 15. Appendix

**Where the UI lives (source):** `src/ui/ui_theme.gd` (tokens + button/label factories) · `shapes.gd` (object shapes + icons) · `object_view.gd`, `tray_view.gd`, `board_view.gd` (board + animation) ·
`modal.gd`, `icon_button.gd`, `toggle_row.gd`, `settings_panel.gd`, `logo.gd`, `column_margin.gd` · screens: `splash_screen.gd`, `menu_screen.gd`, `level_select_screen.gd`, `game_screen.gd`, `credits_screen.gd` · navigation `main.gd` · text `src/core/campaign_text.gd`.
**Regenerate the screenshots:** `xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1080x1920 --script res://tools/make_design_screens.gd` (outputs to `docs/design/screens/`).
**Rules and economy:** `docs/RULES.md` · **Project status:** `SSOT.md`.
