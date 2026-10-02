extends Node
## Global signals between scenes and systems (GDD 19.2).

signal floor_started(floor_index: int)
signal floor_completed(floor_index: int, result: Dictionary)
signal hero_died(cause: StringName)
signal language_changed(locale: String)
signal settings_changed
