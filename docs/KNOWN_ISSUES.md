# Known issues, limitations and unverified items (2026-10-16)

## Blocking a store release
1. **No device/emulator testing has ever been performed** → `docs/DEVICE_TEST_PLAN.md` (all rows NOT RUN).
2. **No release AAB, no release keystore** → network denial for `dl.google.com` + owner-created upload key (`docs/ANDROID.md`, `docs/SIGNING.md`).
3. **Application ID is a placeholder**; Play Console registration unknown → owner decision (`store/PLAY_CONSOLE_PREP.md`).
4. **Privacy-policy URL does not exist yet**; owner/contact fields are blank placeholders (`store/PRIVACY_POLICY.md`).
5. **Play account type / closed-testing obligation unknown**; official support pages unreachable here → confirm in Play Console.

## Not verified by humans
* Audio levels/quality never listened to. · Level difficulty and move-limit fairness (par + max(spec slack, 45 %)) never playtested
  → `docs/PLAYTEST_PLAN.md` (not run; testers must be recruited).
* Touch feel, safe-area/cutout values from a real OS, low-end performance, tablet/foldable behaviour — only simulated.

## Engine/platform limits
* **TalkBack/screen-reader support is unavailable:** Godot 4.7.1 stable contains no Android accessibility server
  (it first appears in Godot master/4.8 dev: `platform/android` has no accessibility code at tags 4.6/4.7.1). Mitigations in place:
  unique shape per object type, slot guides, locks show their key shape, ice shows a number, reduce-motion option, 48 dp targets.
* Android 16 ignores the portrait lock on ≥600 dp screens; handled by a centred column, unverified on hardware.

## Design limitations
* Dead-end positions (moves exist but the level can't be won) are announced only when the player taps Hint (free).
* A hint is a good next move, not necessarily the shortest plan; search is capped (40 000 nodes) with fallback to the authored solution.
* **No haptics, by decision:** vibration requires the `VIBRATE` permission; the app currently requests none.
* UI items still open after two improvement passes are listed in `docs/UI_UX_DESIGN_SPEC.md` §13: tray fill vs page 1.20:1 (outline carries the boundary), amber fill 1.46:1 (carried by its 5.1:1 rim), no symbol legend, Pause reach (provisional — evaluated, not changed, needs real-device use).
* Replays pay no coins (finite economy ≈ 1 200 coins + 30 start).
* Debug APK ≈57 MB (debug template, two ABIs); a release AAB will be smaller per device.
