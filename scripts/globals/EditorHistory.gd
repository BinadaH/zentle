extends Node

signal history_changed
var undo_redo = UndoRedo.new()
var last_save_version = 1

func _ready():
	undo_redo.max_steps = 50

func create_action(action_name: String, do_call: Callable, undo_call: Callable, call_do: bool = true, do_ref = null, undo_ref = null):
	undo_redo.create_action(action_name)
	
	undo_redo.add_do_method(do_call)
	undo_redo.add_undo_method(undo_call)
	
	if do_ref:
		undo_redo.add_do_reference(do_ref)
	if undo_ref:
		if undo_ref is Array:
			for ref in undo_ref:
				undo_redo.add_undo_reference(ref)
		else:
			undo_redo.add_undo_reference(undo_ref)
	
	undo_redo.commit_action(call_do)
	history_changed.emit()
	
	on_history_modified()

func undo():
	if undo_redo.has_undo():
		undo_redo.undo()
		history_changed.emit()
		on_history_modified()
	
func redo():
	if undo_redo.has_redo():
		undo_redo.redo()
		history_changed.emit()
		on_history_modified()
	
func on_history_modified():
	var curr_version = undo_redo.get_version()
	EditorFiles.check_save_status(curr_version == last_save_version)

func mark_save_point():
	last_save_version = undo_redo.get_version()

func clear():
	undo_redo.clear_history()
