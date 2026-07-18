extends Node
@warning_ignore_start('unused_signal')

## Global Signal bus that contains access to alot of playstate related functions

## Signal to be emitted when the countdown is ready to begin.
## Emit this at a later point if u have a intro cutscene
signal play_song_ready_to_start()

signal play_setup_finished()

signal play_conductor_step_hit(step: int, measure: int)
signal play_conductor_beat_hit(step: int, measure: int)

signal play_song_start()
signal play_song_finished()
signal play_note_hit(note: Note, lane: int, hit_time_difference: float, strum_manager: StrumManager)
signal play_note_miss(note: Note, lane: int, strum_manager: StrumManager)
signal play_note_holding(note: Note, lane: int, hold_difference: float, strum_manager: StrumManager)
signal play_create_note(time: float, lane: int, note_length: float, note_type: String, tempo: float)
signal play_note_created(note: Note, strum: Strum)
signal play_new_event(event_name: String, params: Array, time: float)
signal play_combo_break()

signal play_paused()
signal play_unpaused()
signal play_died()
