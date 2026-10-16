# Release checklist (status as of 2026-10-16)

Legend: [x] verified · [ ] open · [!] blocked (what blocks it)

## Technical
- [x] Target API 36 build (APK manifest `targetSdkVersion:'36'`) — Godot 4.7.1
- [x] Automated tests 78/78, level validator 40/40 (0 errors/warnings)
- [x] Manifest: 0 permissions, portrait, backup off; APK has no ad/analytics/network libraries
- [x] Launcher icon fits the adaptive-icon safe zone (0 px outside); 512 px store icon generated
- [x] Release config guard test (identity/version consistent, no secrets tracked)
- [!] Run `docs/DEVICE_TEST_PLAN.md` on ≥2 real devices (incl. cutout + low-end) — no device available to the assistant
- [!] Install gradle template + Android SDK platform 36 / build-tools 36.1.0 — `dl.google.com` denied by egress policy
- [!] Create upload keystore (`docs/SIGNING.md`) — owner action; never commit it
- [!] Export + verify signed release AAB — needs the two items above
- [ ] Listen to audio; run human playtest (`docs/PLAYTEST_PLAN.md`) — recruit testers
- [ ] Bump `version/code` (both presets) before every upload; set `1.0.0` for first release

## Play Console (owner)
- [ ] Decide & approve final application ID (not registered/published as far as known; check console) — `store/PLAY_CONSOLE_PREP.md` §1
- [ ] Create app in Play Console (**owner's authorisation/terms**); enrol in Play App Signing
- [ ] Host privacy policy at a stable public URL; fill owner/contact placeholders — `store/PRIVACY_POLICY.md`
- [ ] Data safety, content rating, target audience, ads/IAP declarations — drafts in `store/PLAY_CONSOLE_PREP.md` §4
- [ ] Listing text, icon, feature graphic, screenshots (ready in `store/`), support email
- [ ] Confirm whether closed testing (12 testers × 14 days) applies to the account; run it if so — §7
- [ ] Re-verify every declaration against the final AAB before submitting
- [ ] Production access application, then staged rollout (Google decides; no date promised)

## Explicitly out of scope for this release
Live ads, in-app purchases, backend, accounts.
