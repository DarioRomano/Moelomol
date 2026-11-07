class_name KettlebridgeNotes
extends RefCounted
## The notes found in Kettlebridge (docs/design/area-kettlebridge.md, "Notes
## in Kettlebridge"): the start of story.md's stage 2, the pattern. Written
## by people who knew Millbrook had gone quiet; still, none explains
## anything (rule 3). Drafts for the lead's taste, not final writing.
##
## {id: {"title", "text", "objective"}}, as MillbrookNotes.

const NOTES: Dictionary = {
	&"market_notice": {
		"title": "Pinned over the market notice",
		"text": "Thursday market as usual.\nMillbrook stalls empty again.\nHas anyone heard from them? Ask at the Bell.",
		"objective": false,
	},
	&"travellers_diary": {
		"title": "A diary in a room at the inn",
		"text": "Road from Millbrook quiet as the grave.\nOnly company a little grey cat that kept pace\nwith the cart half the way. Gave it the end\nof my pie. Wouldn't touch it.",
		"objective": false,
	},
	&"arthurs_door": {
		"title": "On the bridge-keeper's door",
		"text": "Gone up with the eggs.\nKey's in my tin at the stall if the barge\ncomes before I'm back. - A.",
		"objective": true,
	},
	&"toll_ledger": {
		"title": "The toll ledger",
		"text": "Mon  carts 14  Millbrook 3\nTue  carts 11  Millbrook 0\nWed  carts 9   Millbrook 0\nThu  carts 6   Millbrook 0\nFri",
		"objective": false,
	},
	&"chandlers_book": {
		"title": "The chandler's order book",
		"text": "Church: 40 tallow.\nVicar wants them lit all night now.\nInn: 12 wax, the good ones.",
		"objective": false,
	},
	&"font_card": {
		"title": "A card by the font",
		"text": "ST KETTA AND THE BEAST\nThe beast came down the valley hungry,\nand the saint fed it, and it slept.\n(The carving shows a small creature\nwith many eyes.)",
		"objective": false,
	},
	&"almshouse_letter": {
		"title": "A letter on a table in the almshouses",
		"text": "Dear Nell,\nThe town is very quiet this week.\nThey say Millbrook has gone away somewhere,\nwhich is nonsense. Come for Sunday if",
		"objective": false,
	},
}
