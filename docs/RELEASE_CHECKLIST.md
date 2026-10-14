# Release checklist

- [ ] Upgrade to a current Godot 4.x stable + templates (Play target-API rule); re-run tests/validator.
- [ ] Choose and register the final application id; update both presets.
- [ ] Install gradle build template + full Android SDK; build a release AAB.
- [ ] Generate a **release keystore** (kept outside the repo, backed up); configure Play App Signing.
- [ ] Bump `version/code` and `version/name` (both presets) and `config/version` in `project.godot`.
- [ ] Run on ≥2 real devices (small + large, one with a display cutout, one low-end); complete `docs/TESTING.md` manual plan; check `adb logcat`.
- [ ] Listen to audio levels; playtest levels 1–10 with new players; tune move-limit slack if needed.
- [ ] Verify `aapt dump badging` shows no unexpected permissions.
- [ ] Store listing: screenshots, feature graphic, short/long description, content rating questionnaire.
- [ ] Privacy policy URL + Data Safety form (app collects no data; stores progress locally).
- [ ] Decide on ads: if adding a rewarded provider, first verify current SDK compatibility, consent (UMP) requirements, test-ad rules, privacy disclosures and Play policies; use test ids only in debug; production ids from build config, never in git.
- [ ] Tag the release commit; archive the AAB and mapping/debug symbols.
