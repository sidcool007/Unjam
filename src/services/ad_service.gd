extends Node
## Autoload "Ads": thin gate between gameplay and an optional rewarded-ad
## provider. The first release ships with NO provider, so every request is
## declined and the UI simply never offers an ad. Rewards are granted at most
## once per request id.

signal reward_granted(placement: String)

const PLACEMENT_HINT := "hint"
const PLACEMENT_EXTRA_MOVE := "extra_move"
const PLACEMENT_COINS := "coins"

var provider: RewardedAdProvider = null
var _pending := {}  # placement -> true while a request is in flight


func set_provider(p: RewardedAdProvider) -> void:
	provider = p
	if p != null:
		p.reward_earned.connect(_on_reward)
		p.closed_without_reward.connect(func(pl): _pending.erase(pl))
		p.failed.connect(func(pl, _r): _pending.erase(pl))


func is_available(placement: String) -> bool:
	return provider != null and not _pending.has(placement) and provider.is_ready(placement)


## Returns false immediately when no ad can be shown (caller offers an alternative).
func request(placement: String) -> bool:
	if not is_available(placement):
		return false
	_pending[placement] = true
	provider.show(placement)
	return true


func _on_reward(placement: String) -> void:
	if not _pending.has(placement):
		return  # unsolicited or duplicate callback: never grant twice
	_pending.erase(placement)
	reward_granted.emit(placement)
