gmui_update();

if (gmui_begin("Search Window", 0, 0, surface_get_width(application_surface), surface_get_height(application_surface), gmui_window_flags.NO_TITLE_BAR | gmui_window_flags.NO_RESIZE)) {
	search_text = gmui_textbox(search_text, "search...", gmui_get().current_window.width - gmui_get().style.window_padding[0] * 2);
	if (gmui_textbox_id() == gmui_get_focused_textbox_id() && string_length(gmui_get_focused_textbox_text()) > 3 && keyboard_check(vk_anykey)) {
		search_results = gmls_search_ngrams(search_text, 10); // update the list
	};
	if (gmui_get_focused_textbox_text() != "" && string_length(gmui_get_focused_textbox_text()) <= 3 && array_length(search_results) != 0) {
		search_results = [ ];
	};
	if (array_length(search_results) > 0) {
		array_foreach(search_results, function(e, i) {
			gmui_text(e.document.text);
		});
	}
	else {
		array_foreach(ds_map_values_to_array(global.gmui.lite_search.documents), function(e, i) {
			gmui_text(e.text);
		});
	};
	
	gmui_end();
};