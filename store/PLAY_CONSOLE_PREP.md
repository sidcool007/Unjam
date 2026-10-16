# Google Play Console preparation (drafts + owner decisions)

Nothing in this file has been submitted. No Play Console app exists yet as far as the project knows; it was **not**
possible to check (play.google.com is blocked in the build environment and requires the owner's login).
Requirements below that I could not verify from an official page in this environment are marked **[CONFIRM]**.

## 1. Application identity (OWNER DECISION — irreversible once published)
The package name is permanent after the first upload. Current value is a placeholder: `com.unjam.thelastslot`.
First check Play Console (and your own domains) that it is unused. Proposals, in order of preference:
1. `io.github.sidcool007.unjam` — tied to the GitHub account `sidcool007` the repository lives under (no domain purchase needed).
2. `com.<your-owned-domain>.unjam` — if you own a domain (best long-term).
3. Keep `com.unjam.thelastslot` only if you are certain you will never need a different brand/domain.
Do **not** change it in `export_presets.cfg` (both presets) until you approve; then run the test-suite (`test_release_config`).
Display name: *Unjam: The Last Slot* (title ≤ 30 chars ✔ 21).

## 2. Version
Proposed first release: **versionName `1.0.0`, versionCode `1`**. Every later upload needs a strictly higher versionCode
(e.g. 2, 3…), edited in **both** presets and `project.godot config/version`. Current repo value is `0.1.0 / 1` (candidate).

## 3. Store listing (draft)
* **Short description (≤80):** "A calm sorting puzzle about who gets the last free slot." (57)
* **Full description (≤4000):**
  Sort shapes into trays — but space is limited, and only the top object can move. Unjam is a relaxing-to-tricky puzzle
  built around one question: who gets the last slot?
  • 40 handcrafted levels, each solved and checked to guarantee a solution exists
  • Easy to learn: tap a tray to lift, tap another to drop
  • New ideas arrive one at a time: tight trays, move limits, padlocks, reserved and one-way trays, ice, and mixes
  • Undo any move for free, restart any time, and use hints when you're stuck
  • Plays completely offline • No ads • No account • No permissions • Your progress stays on your device
  • Colour-blind friendly: every object has its own shape as well as its colour; reduce-motion option included
* **Category:** Games → Puzzle. **Tags:** puzzle, casual, offline.
* **Graphics (ready, in `store/`):** `icon_512.png` (512×512), `feature_graphic_1024x500.png`,
  `screenshots/01…06_*.png` (1080×1920 portrait phone; rendered by the real game on a desktop GL context, **not** captured on a device — replace with device captures if preferred).
* **Support contact:** email **[OWNER]** (required), website optional, **privacy policy URL [OWNER — see §6]**.

## 4. Declarations (drafts; answers must match the final AAB)
| Form | Draft answer | Basis |
|------|--------------|-------|
| App access | All functionality available without login or special access | No accounts |
| Ads | **No** ads | No ad SDK; `RewardedAdProvider` is an unused interface |
| In-app purchases / paid app | None / Free | None implemented |
| Data safety — collection | **No data collected**; **No data shared** | Nothing transmitted; verified: no INTERNET permission, no network code, no SDKs |
| Data safety — security | Data not transmitted (n/a); deletion: user can reset in-app or uninstall | Local file only |
| Permissions | None | 0 `uses-permission` in manifest |
| Advertising ID declaration | Does **not** use advertising ID | No ads/analytics |
| Content rating (IARC questionnaire inputs) | No violence, blood, sexual content, profanity, drugs, gambling, user-generated content, user interaction, location sharing, digital purchases | Abstract shape puzzle. Expected result: lowest rating tier — the questionnaire decides, not me |
| Target audience & content | **OWNER DECISION.** Recommended: 13+ / general audience, *not* primarily directed to children, to avoid the Families policy obligations; if you choose "under 13 included", Families-policy requirements apply [CONFIRM] | Game is suitable for all ages but the declaration has policy consequences |
| News / government / health / financial / COVID | No | – |
| Target API | App targets Android 16 (API 36) — meets the 31 Aug 2026 rule (official page read 2026-10-16) | `docs/ANDROID.md` |

## 5. Owner decisions still open
1. Final application ID (§1) · 2. Developer/legal name shown on the listing · 3. Support email (+ optional website)
4. Privacy-policy hosting URL (§6) · 5. Target age group (§4) · 6. Whether to use Play App Signing upload key (recommended, `docs/SIGNING.md`)
7. Countries/regions · 8. Developer account type (personal vs organisation — drives §7) · 9. Pricing (free) · 10. Approve screenshots/graphics.

## 6. Privacy-policy URL
Policy text: `store/PRIVACY_POLICY.md` (needs owner fields). A stable public URL is mandatory. Free option: enable GitHub Pages on the
repository and publish the policy at e.g. `https://sidcool007.github.io/unjam/privacy` — **not done** (requires owner action/repo settings;
repository `sidcool007/unjam` visibility and Pages settings are the owner's). Link the same URL in Play Console and, if desired, in-app.
The app already has a Privacy & credits screen (offline text).

## 7. Closed testing / production access (account-specific) **[CONFIRM in Play Console]**
Per the brief (not verifiable here): *personal* developer accounts created after 13 Nov 2023 must run a closed test with
**≥12 testers opted in continuously for ≥14 days** before applying for production access; organisation accounts are exempt.
Check **Play Console → Dashboard → "Test and release" requirements** for your account; do not rely on this note.
If it applies:
1. Upload the signed AAB to a **Closed testing** track; create a tester list (email list or Google Group) of ≥12 real people (aim for 15–20 to absorb drop-outs).
2. Send each tester the opt-in link; they must **opt in and stay opted in**, install, and use the app; ask for feedback (crashes, confusion, difficulty).
3. Keep the track live ≥14 consecutive days; fix issues with new builds (higher versionCode) without removing the tester group.
4. Then use the console's production-access application (answer: testing process, feedback gathered, changes made, readiness).
5. Review/approval is Google's decision; no date can be promised.
Status: **not started** (needs a signed AAB, owner's account, and testers).
