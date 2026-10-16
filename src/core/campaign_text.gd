class_name CampaignText
extends RefCounted
## Player-facing text. Rules wording here must match docs/RULES.md and BoardState.

const STAGES := {
	1: "Basics", 2: "Tight Trays", 3: "Move Limits", 4: "Locks",
	5: "Special Trays", 6: "Ice", 7: "Mastery",
}

const REASONS := {
	BoardState.Reason.GAME_OVER: "This level is already finished.",
	BoardState.Reason.NO_MOVES_LEFT: "No moves left.",
	BoardState.Reason.SAME_TRAY: "",
	BoardState.Reason.BAD_TRAY: "That isn't a tray.",
	BoardState.Reason.EMPTY_SOURCE: "That tray is empty.",
	BoardState.Reason.LOCKED: "Locked! Clear a tray of the shape shown on the padlock to open it.",
	BoardState.Reason.FROZEN: "Frozen! It thaws after the number of moves shown.",
	BoardState.Reason.SOURCE_ONLY: "This tray only gives objects away (up-arrow tag). You can't drop into it.",
	BoardState.Reason.WRONG_TYPE_FOR_TRAY: "This tray only takes the shape shown on its tag.",
	BoardState.Reason.FULL: "That tray is full.",
	BoardState.Reason.TYPE_MISMATCH: "Objects only stack on the same shape, or in an empty tray.",
}

const INTROS := {
	"basics": ["How to play",
		"1. Tap a tray to lift its top object.\n2. Tap another tray to drop it there.\n\nObjects can land on the same shape, or in an empty tray. Fill a tray with one shape to clear it. Clear every tray to win."],
	"capacity": ["Mind the free slots",
		"Every tray has a limited number of slots. Watch the Free slots counter: when only the last slot is left, choose carefully what goes in it.\n\nMade a mistake? Undo is free."],
	"limit": ["Move limits",
		"Some levels allow only a set number of moves. The counter shows how many you have left. Undo gives moves back, so planning ahead is always allowed."],
	"lock": ["Padlocks",
		"A padlock freezes an object in place. The shape on the padlock tells you what opens it: clear a tray of that shape and the lock disappears."],
	"accepts": ["Reserved trays",
		"A tray with a shape tag on its top edge only accepts that shape. Use it to park the right objects."],
	"source": ["One-way trays",
		"A tray with an up-arrow tag only gives objects away. You can take from it but never drop into it."],
	"ice": ["Ice",
		"A frozen object can't move until enough moves have been made. The number shows how many moves remain before it thaws."],
	"mix": ["Everything together",
		"From here on, levels mix locks, ice, reserved and one-way trays. Plan the last slot before you fill it."],
}

const RULES_TEXT := "Tap a tray to lift its top object, then tap another tray to place it.\n\n• Only the top object of a tray can move.\n• An object can land on the same shape, or in an empty tray.\n• Trays have limited slots. A full tray can't take more.\n• Fill a tray with one shape and it clears.\n• Clear every tray to win.\n\nSpecial rules:\n• Padlock: clear a tray of the shown shape to open it.\n• Ice: wait for the shown number of moves.\n• Shape tag on a tray: it takes only that shape.\n• Up-arrow tag on a tray: you can only take from it.\n• Move limit: finish before the counter reaches 0."


static func reason_text(r: int) -> String:
	return REASONS.get(r, "That move isn't allowed.")
