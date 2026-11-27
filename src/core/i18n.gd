class_name I18n
extends RefCounted
## Localisation. Keys are the English source strings (Godot translates Label/Button text through
## TranslationServer automatically; formatted strings and draw_string text go through tr() explicitly).
## Hindi text is machine-drafted and needs native review before release (docs/LOCALISATION.md).
## Player language: "auto" (device language if supported, else English), "en" or "hi".

const LANGUAGES := ["auto", "en", "hi"]
const SUPPORTED := ["en", "hi"]

static var _installed := false

const HI := {
	# --- menu / settings
	"Play": "खेलें",
	"Levels": "स्तर",
	"Settings": "सेटिंग",
	"Privacy & credits": "गोपनीयता और क्रेडिट",
	"Continue · Level %d": "जारी रखें · स्तर %d",
	"%d / %d levels cleared   ·   %d stars": "%d / %d स्तर पूरे   ·   %d सितारे",
	"Your save file could not be read. %s": "आपकी सेव फ़ाइल पढ़ी नहीं जा सकी। %s",
	"A backup was restored.": "बैकअप बहाल किया गया।",
	"Starting fresh.": "नई शुरुआत की गई।",
	"Reset all progress": "सारी प्रगति मिटाएँ",
	"Done": "हो गया",
	"Reset progress?": "प्रगति मिटाएँ?",
	"This erases completed levels, coins and settings on this device. It can't be undone.": "इससे इस डिवाइस पर पूरे किए स्तर, सिक्के और सेटिंग मिट जाएँगी। इसे वापस नहीं किया जा सकता।",
	"Erase everything": "सब कुछ मिटाएँ",
	"Cancel": "रद्द करें",
	"Sound effects": "ध्वनि प्रभाव",
	"Music": "संगीत",
	"Reduce motion": "कम हलचल",
	"Colour-blind colours": "रंग-अंधता के अनुकूल रंग",
	"Language": "भाषा",
	"Automatic": "स्वचालित",
	"English": "English",
	"Hindi": "हिन्दी",
	"ON": "चालू",
	"OFF": "बंद",
	"Loading…": "लोड हो रहा है…",
	"Could not load levels:\n": "स्तर लोड नहीं हो सके:\n",
	# --- level select
	"Stage %d · %s": "चरण %d · %s",
	"Clear level %d to unlock this one.": "इसे खोलने के लिए स्तर %d पूरा करें।",
	# --- game
	"Level %d": "स्तर %d",
	"Undo": "पूर्ववत",
	"Hint": "संकेत",
	"Restart": "फिर शुरू",
	"Moves left: %d": "बची चालें: %d",
	"Moves: %d": "चालें: %d",
	"Last slot!": "आख़िरी जगह!",
	"Free slots: %d": "खाली जगह: %d",
	"Level %d clear!": "स्तर %d पूरा!",
	"Solved in %d moves (par %d)": "%d चालों में हल किया (लक्ष्य %d)",
	"+%d coins": "+%d सिक्के",
	"Replay: no new coins": "दोबारा खेलने पर नए सिक्के नहीं मिलते",
	"Next level": "अगला स्तर",
	"You finished every level. Thanks for playing!": "आपने सारे स्तर पूरे कर लिए। खेलने के लिए धन्यवाद!",
	"Play again": "फिर खेलें",
	"Level select": "स्तर चुनें",
	"Out of moves": "चालें खत्म",
	"No moves left": "कोई चाल नहीं बची",
	"Every slot is blocked or the move limit is reached. Undo to try a different plan.": "हर जगह बंद है या चाल की सीमा पूरी हो गई। पूर्ववत करके दूसरी योजना आज़माएँ।",
	"You ran out of moves. Undo to try a different plan, or restart the level.": "आपकी चालें खत्म हो गईं। पूर्ववत करके दूसरी योजना आज़माएँ, या स्तर फिर शुरू करें।",
	"Undo last move": "आख़िरी चाल पूर्ववत करें",
	"Restart level": "स्तर फिर शुरू करें",
	"Restart level?": "स्तर फिर शुरू करें?",
	"Your progress in this level will be lost.": "इस स्तर की आपकी प्रगति मिट जाएगी।",
	"Keep playing": "खेलते रहें",
	"Not enough coins": "सिक्के पर्याप्त नहीं हैं",
	"A hint costs %d coins and you have %d. Complete levels to earn more.": "एक संकेत की कीमत %d सिक्के है और आपके पास %d हैं। और कमाने के लिए स्तर पूरे करें।",
	"OK": "ठीक है",
	"Need a hint?": "संकेत चाहिए?",
	"Show a good next move for %d coins? You have %d.": "%d सिक्कों में अगली अच्छी चाल दिखाएँ? आपके पास %d हैं।",
	"Show hint (%d)": "संकेत दिखाएँ (%d)",
	"Not now": "अभी नहीं",
	"This can't be finished": "यह स्तर पूरा नहीं हो सकता",
	"\n\nNo coins were charged.": "\n\nकोई सिक्का नहीं कटा।",
	"Close": "बंद करें",
	"No hint right now": "अभी कोई संकेत नहीं",
	"That hint is no longer valid. You weren't charged.": "वह संकेत अब मान्य नहीं है। आपके सिक्के नहीं कटे।",
	"Not enough coins.": "सिक्के पर्याप्त नहीं हैं।",
	"This arrangement can't be finished any more. Undo a few moves or restart.": "यह व्यवस्था अब पूरी नहीं हो सकती। कुछ चालें पूर्ववत करें या फिर शुरू करें।",
	"No reliable hint is available for this position. Try Undo or Restart. You weren't charged.": "इस स्थिति के लिए भरोसेमंद संकेत उपलब्ध नहीं है। पूर्ववत या फिर शुरू आज़माएँ। आपके सिक्के नहीं कटे।",
	"Paused": "रुका हुआ",
	"Resume": "जारी रखें",
	"How to play": "कैसे खेलें",
	"Got it": "समझ गया",
	"Let's go": "चलिए शुरू करें",
	"Tap the glowing tray to lift its top object.": "चमकती ट्रे को छूकर उसकी ऊपरी वस्तु उठाएँ।",
	"Now tap the highlighted tray to drop it there.": "अब चिह्नित ट्रे को छूकर वस्तु वहाँ रखें।",
	"Tap the lifted tray again to put it back, then try the glowing one.": "उठाई हुई ट्रे को फिर छूकर वस्तु वापस रखें, फिर चमकती ट्रे आज़माएँ।",
	# --- stages
	"Basics": "बुनियादी बातें",
	"Tight Trays": "तंग ट्रे",
	"Move Limits": "चाल की सीमा",
	"Locks": "ताले",
	"Special Trays": "विशेष ट्रे",
	"Ice": "बर्फ़",
	"Mastery": "महारत",
	"Veteran": "अनुभवी",
	"Expert": "विशेषज्ञ",
	"Grandmaster": "ग्रैंडमास्टर",
	# --- rule reasons
	"This level is already finished.": "यह स्तर पहले ही पूरा हो चुका है।",
	"No moves left.": "कोई चाल नहीं बची।",
	"That isn't a tray.": "वह ट्रे नहीं है।",
	"That tray is empty.": "वह ट्रे खाली है।",
	"Locked! Clear a tray of the shape shown on the padlock to open it.": "बंद है! ताले पर दिखे आकार की एक ट्रे पूरी करें तो यह खुल जाएगा।",
	"Frozen! It thaws after the number of moves shown.": "जमा हुआ है! दिखाई गई चालों के बाद यह पिघलेगा।",
	"This tray only gives objects away (up-arrow tag). You can't drop into it.": "यह ट्रे सिर्फ़ वस्तुएँ देती है (ऊपर-तीर का टैग)। इसमें कुछ रखा नहीं जा सकता।",
	"This tray only takes the shape shown on its tag.": "यह ट्रे सिर्फ़ अपने टैग पर दिखा आकार लेती है।",
	"That tray is full.": "वह ट्रे भरी हुई है।",
	"Objects only stack on the same shape, or in an empty tray.": "वस्तुएँ केवल उसी आकार पर या खाली ट्रे में रखी जा सकती हैं।",
	"That move isn't allowed.": "यह चाल मान्य नहीं है।",
	# --- tutorial cards
	"Mind the free slots": "खाली जगह का ध्यान रखें",
	"Move limits": "चाल की सीमा",
	"Padlocks": "ताले",
	"Reserved trays": "आरक्षित ट्रे",
	"One-way trays": "एकतरफ़ा ट्रे",
	"Everything together": "सब कुछ एक साथ",
	"1. Tap a tray to lift its top object.\n2. Tap another tray to drop it there.\n\nObjects can land on the same shape, or in an empty tray. Fill a tray with one shape to clear it. Clear every tray to win.": "1. किसी ट्रे को छूकर उसकी ऊपरी वस्तु उठाएँ।\n2. दूसरी ट्रे को छूकर उसे वहाँ रखें।\n\nवस्तु उसी आकार पर या खाली ट्रे में रखी जा सकती है। एक ट्रे को एक ही आकार से भरें तो वह साफ़ हो जाती है। सारी ट्रे साफ़ करें और जीतें।",
	"Every tray has a limited number of slots. Watch the Free slots counter: when only the last slot is left, choose carefully what goes in it.\n\nMade a mistake? Undo is free.": "हर ट्रे में सीमित जगह होती है। \"खाली जगह\" गिनती पर नज़र रखें: जब सिर्फ़ आख़िरी जगह बचे, तो सोच-समझकर चुनें कि उसमें क्या जाए।\n\nगलती हो गई? पूर्ववत मुफ़्त है।",
	"Some levels allow only a set number of moves. The counter shows how many you have left. Undo gives moves back, so planning ahead is always allowed.": "कुछ स्तरों में चालों की सीमा होती है। गिनती दिखाती है कि कितनी चालें बची हैं। पूर्ववत चालें लौटा देता है, इसलिए पहले से योजना बनाना हमेशा ठीक है।",
	"A padlock freezes an object in place. The shape on the padlock tells you what opens it: clear a tray of that shape and the lock disappears.": "ताला किसी वस्तु को अपनी जगह रोक देता है। ताले पर बना आकार बताता है कि वह कैसे खुलेगा: उस आकार की एक ट्रे पूरी करें और ताला हट जाएगा।",
	"A tray with a shape tag on its top edge only accepts that shape. Use it to park the right objects.": "जिस ट्रे के ऊपरी किनारे पर आकार का टैग हो, वह सिर्फ़ वही आकार लेती है। सही वस्तुएँ रखने के लिए इसका उपयोग करें।",
	"A tray with an up-arrow tag only gives objects away. You can take from it but never drop into it.": "ऊपर-तीर वाले टैग की ट्रे सिर्फ़ वस्तुएँ देती है। आप उससे ले सकते हैं, पर उसमें कभी रख नहीं सकते।",
	"A frozen object can't move until enough moves have been made. The number shows how many moves remain before it thaws.": "जमी हुई वस्तु तब तक नहीं हिलती जब तक पर्याप्त चालें न चल ली जाएँ। संख्या बताती है कि पिघलने में कितनी चालें बाकी हैं।",
	"From here on, levels mix locks, ice, reserved and one-way trays. Plan the last slot before you fill it.": "यहाँ से स्तरों में ताले, बर्फ़, आरक्षित और एकतरफ़ा ट्रे मिले-जुले आते हैं। आख़िरी जगह भरने से पहले उसकी योजना बनाएँ।",
	"Tap a tray to lift its top object, then tap another tray to place it.\n\n• Only the top object of a tray can move.\n• An object can land on the same shape, or in an empty tray.\n• Trays have limited slots. A full tray can't take more.\n• Fill a tray with one shape and it clears.\n• Clear every tray to win.\n\nSpecial rules:\n• Padlock: clear a tray of the shown shape to open it.\n• Ice: wait for the shown number of moves.\n• Shape tag on a tray: it takes only that shape.\n• Up-arrow tag on a tray: you can only take from it.\n• Move limit: finish before the counter reaches 0.": "किसी ट्रे को छूकर उसकी ऊपरी वस्तु उठाएँ, फिर दूसरी ट्रे को छूकर उसे रखें।\n\n• ट्रे की सिर्फ़ ऊपरी वस्तु हिल सकती है।\n• वस्तु उसी आकार पर या खाली ट्रे में रखी जा सकती है।\n• ट्रे में सीमित जगह होती है। भरी ट्रे में और कुछ नहीं आता।\n• एक ट्रे को एक ही आकार से भरें तो वह साफ़ हो जाती है।\n• जीतने के लिए सारी ट्रे साफ़ करें।\n\nविशेष नियम:\n• ताला: दिखे आकार की ट्रे पूरी करें तो खुल जाता है।\n• बर्फ़: दिखाई गई चालों तक रुकें।\n• ट्रे पर आकार का टैग: वह सिर्फ़ वही आकार लेती है।\n• ट्रे पर ऊपर-तीर का टैग: उससे सिर्फ़ लिया जा सकता है।\n• चाल की सीमा: गिनती 0 होने से पहले पूरा करें।",
}


## Registers the Hindi table with the TranslationServer (once).
static func install() -> void:
	if _installed:
		return
	_installed = true
	var t := Translation.new()
	t.locale = "hi"
	for k in HI:
		t.add_message(k, HI[k])
	TranslationServer.add_translation(t)


## Resolves the effective locale for a language setting.
static func resolve(lang: String) -> String:
	if lang == "en" or lang == "hi":
		return lang
	var dev := OS.get_locale_language()
	return dev if dev in SUPPORTED else "en"


static func apply(lang: String) -> void:
	install()
	TranslationServer.set_locale(resolve(lang))


## Native name of a language option (shown untranslated so users can always find their own).
static func option_label(lang: String) -> String:
	match lang:
		"en":
			return "English"
		"hi":
			return "हिन्दी"
	return "Auto"
