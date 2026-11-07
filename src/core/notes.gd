class_name Notes
extends RefCounted
## Every note in the game, wherever it was found (one satchel for the whole
## game, Q37): each place's book of notes, looked up by id.

## Place id -> that place's notes ({id: {"title", "text", "objective"}}).
const BOOKS: Dictionary = {
	&"millbrook": MillbrookNotes.NOTES,
	&"kettlebridge": KettlebridgeNotes.NOTES,
	&"farm": FarmNotes.NOTES,
}


## The note with `note_id`, or an empty dictionary.
static func find(note_id: StringName) -> Dictionary:
	for place: StringName in BOOKS:
		var book: Dictionary = BOOKS[place]
		if book.has(note_id):
			return book[note_id]
	return {}


static func place_of(note_id: StringName) -> StringName:
	for place: StringName in BOOKS:
		if (BOOKS[place] as Dictionary).has(note_id):
			return place
	return &""


## True if the note carries the satchel's loose-thread mark: about its
## place's objective, which is not done yet (Q37). `live` is the area being
## played, if any (its objective may be newer than what the game stored).
static func loose_thread(note_id: StringName, state: GameState, live: Area = null) -> bool:
	var note: Dictionary = find(note_id)
	if note.is_empty() or not bool(note.get("objective", false)):
		return false
	var place: StringName = place_of(note_id)
	if live != null and live.id == place:
		return not live.objective_done
	var stored: Dictionary = state.area_states.get(place, {})
	return not bool(stored.get("objective_done", false))
