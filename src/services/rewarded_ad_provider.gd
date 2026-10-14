class_name RewardedAdProvider
extends RefCounted
## Provider-agnostic interface for a FUTURE rewarded-ad SDK. Nothing in the
## gameplay code knows about any ad network. A real provider subclasses this,
## lives in its own file, and is registered via Ads.set_provider().
##
## Contract:
##  - is_ready(placement) is true only if an ad can really be shown now.
##  - show(placement) must emit exactly one of reward_earned / closed_without_reward /
##    failed, and reward_earned ONLY after the SDK confirms the ad was completed.
##  - Never emit reward_earned for a simulated/skipped/failed ad.
## Production ad-unit ids must come from build config, never from source control.

signal reward_earned(placement: String)
signal closed_without_reward(placement: String)
signal failed(placement: String, reason: String)

func is_ready(_placement: String) -> bool:
	return false


func show(placement: String) -> void:
	failed.emit(placement, "no provider")
