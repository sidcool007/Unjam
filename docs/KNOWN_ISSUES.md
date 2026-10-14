# Known issues and limitations

**Release blockers / unverified**
1. **Never run on a device or emulator.** See TESTING.md for the manual plan.
2. **Target API:** Godot 4.3 templates target API 34; Play Store needs a newer target →
   upgrade Godot first. No AAB was built; no release signing key exists (by design).
3. Application id `com.unjam.thelastslot` is a placeholder.
4. Audio unverified by ear; levels unverified by human playtesters (difficulty and the
   45 % move-limit slack are judgement calls backed by solver numbers only).

**Design limitations**
* Dead-end positions (legal moves exist but the level can't be won) are not announced
  automatically; the Hint button detects them (free) and offers Undo/Restart.
* A hint is a *good next move*, not necessarily the shortest plan.
* Hint search is capped (40 000 nodes); on very slow phones it may pause the UI for a
  moment (desktop worst case 82 ms). If the cap is hit it falls back to the authored
  solution while the player is still on it, otherwise reports "no hint" without charging.
* No TalkBack/screen-reader support or system font scaling. Non-colour cues exist (each
  type has a unique shape; capacity is drawn as slots; locks show the key shape; ice shows
  a number), plus a reduce-motion setting.
* Portrait phones only; tablets/landscape are letterboxed/untested.
* Replays pay no coins, so coins are finite (≈ 40 levels × ≤30 + 30 start ≈ 1 200 total).
* Rewarded ads are an interface only; no provider exists.
* Debug APK is large (~48 MB) because it embeds the debug engine template.
