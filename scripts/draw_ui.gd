extends Node2D

var r = Rect2()
func _draw():
	var sq_size = EditorOptions.options[EditorOptions.OPTIONS.SQ_SIZE]
	var sel_r = EditorFuncs.selection_manager.selection_rect
	if sel_r:
		draw_rect(sel_r, EditorColors.ui_palette[EditorColors.UI.PRIMARY_TRANSPARENT])
		draw_rect(sel_r, EditorColors.ui_palette[EditorColors.UI.PRIMARY], false, sq_size * 0.06)
		
	if EditorFuncs.selection_manager.selection_made:
		EditorFuncs.selection_manager.selection_made.draw(self)
	
	if EditorFuncs.export_manager.curr_region:
		draw_rect(EditorFuncs.export_manager.curr_rect, EditorColors.ui_palette[EditorColors.UI.SUCCESS], false, 5)
