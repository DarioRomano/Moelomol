class_name MillbrookNotes
extends RefCounted
## The notes found in Millbrook (docs/design/area-millbrook.md, "Notes in
## Millbrook"): stage 1 of story.md, ordinary loss. Each is written by someone
## from before, about their own life, short enough for one screen; none
## explains anything. Drafts for the lead's taste, not final writing.
##
## {id: {"title", "text", "objective"}}: `objective` notes carry the satchel's
## loose-thread mark until Millbrook's objective is done (Q37).

const NOTES: Dictionary = {
	&"lost_pet_poster": {
		"title": "A poster on a fence post",
		"text": "MISSING\nPip, our tabby. Grey stripes, white paws, very friendly.\nHasn't come home since Tuesday. Please check sheds.\nReward. Ask at the schoolhouse.",
		"objective": false,
	},
	&"my_family": {
		"title": "A drawing on the schoolroom wall",
		"text": "MY FAMILY\nby Rosie, age 6\n\nMum. Dad. Me. Pip.\n(Pip is the cat. He is the best one.)",
		"objective": false,
	},
	&"schoolroom_board": {
		"title": "The schoolroom board",
		"text": "Tuesday\nThe Water Cycle\nThe sun warms the pond. The water goes up as\nvapour. It makes clouds. The clouds",
		"objective": false,
	},
	&"kitchen_table": {
		"title": "On a kitchen table",
		"text": "Gone to help Ted with the last of the wheat.\nSoup's on the stove. Back by dark.",
		"objective": false,
	},
	&"chapel_notices": {
		"title": "The chapel notice board",
		"text": "HARVEST SUPPER\nnext Sunday, after the service.\nBring a dish. Bring a chair.\n\nFlowers this month: Mrs Abbott, then the Hales.",
		"objective": false,
	},
	&"cider_tally": {
		"title": "Chalk on the cider shed door",
		"text": "Pressed: 14 barrels\nNorth rows: Thursday\nDon't let the boys near the press again.",
		"objective": false,
	},
	&"hive_log": {
		"title": "The beekeeper's log",
		"text": "Bees restless three days running.\nNo reason I can see. Took the honey early.\nThey'll settle.",
		"objective": false,
	},
	&"sluice_note": {
		"title": "Pinned by the sluice wheel",
		"text": "Took the crank home again. The Abbott boys keep\nwinding the gate for fun and the meadow floods.\nPond's high, mind the low road.\nCrank's on the hook by my door if you need it.\n- T.",
		"objective": true,
	},
	&"miller_calendar": {
		"title": "A calendar by the miller's door",
		"text": "Mon - mill\nTue - mill. Sacks to Ted.\nWed - mill\nThu -\nFri -",
		"objective": false,
	},
	&"grist_apples": {
		"title": "Chalked inside the miller's door",
		"text": "Grist is NOT to have apples from the orchard again.\nHe gets ideas and he gets out.\nFence is mended. - T.",
		"objective": false,
	},
}
