extends TestCase
## Ad gate (reward at most once, never simulated) and audio fallbacks.

const AdServiceScript = preload("res://src/services/ad_service.gd")


class FakeProvider extends RewardedAdProvider:
	var ready := true
	var shown := 0
	func is_ready(_p: String) -> bool:
		return ready
	func show(p: String) -> void:
		shown += 1


func test_no_provider_means_no_ads_and_no_rewards() -> void:
	var ads = AdServiceScript.new()
	var granted := [0]
	ads.reward_granted.connect(func(_p): granted[0] += 1)
	check(not ads.is_available("hint"))
	check(not ads.request("hint"), "request declined without provider")
	eq(granted[0], 0)
	ads.free()


func test_reward_granted_once_per_request() -> void:
	var ads = AdServiceScript.new()
	var fp := FakeProvider.new()
	ads.set_provider(fp)
	var granted := [0]
	ads.reward_granted.connect(func(_p): granted[0] += 1)
	fp.reward_earned.emit("hint")      # unsolicited callback: ignored
	eq(granted[0], 0, "no reward without a request")
	check(ads.request("hint"))
	check(not ads.request("hint"), "second request while one is in flight is refused")
	eq(fp.shown, 1)
	fp.reward_earned.emit("hint")
	fp.reward_earned.emit("hint")      # duplicate callback
	eq(granted[0], 1, "exactly one reward")
	ads.free()


func test_failed_or_closed_ad_grants_nothing_and_allows_retry() -> void:
	var ads = AdServiceScript.new()
	var fp := FakeProvider.new()
	ads.set_provider(fp)
	var granted := [0]
	ads.reward_granted.connect(func(_p): granted[0] += 1)
	ads.request("coins")
	fp.failed.emit("coins", "no fill")
	eq(granted[0], 0)
	check(ads.request("coins"), "can retry after failure")
	fp.closed_without_reward.emit("coins")
	eq(granted[0], 0)
	fp.ready = false
	check(not ads.request("coins"), "unavailable ad is never faked")
	ads.free()


func test_audio_is_safe_with_unknown_sounds_and_disabled() -> void:
	Audio.play("does_not_exist")
	var was: bool = Audio.sound_on
	Audio.sound_on = false
	Audio.play("move")
	Audio.sound_on = was
	check(true, "no crash")
