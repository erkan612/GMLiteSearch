

// QUERY UNDERSTANDING & SUGGESTIONS
function gmls_init_query_understanding() {
    var _ls = global.gmls;
    
    if (!variable_struct_exists(_ls, "query_log")) {
        _ls.query_log = ds_list_create();
    }
    if (!variable_struct_exists(_ls, "suggestion_cache")) {
        _ls.suggestion_cache = ds_map_create();
    }
    if (!variable_struct_exists(_ls, "spelling_dict")) {
        _ls.spelling_dict = ds_map_create();
    }
    if (!variable_struct_exists(_ls, "popular_queries")) {
        _ls.popular_queries = ds_map_create();
    }
    if (!variable_struct_exists(_ls, "query_click_graph")) {
        _ls.query_click_graph = ds_map_create();
    }
    if (!variable_struct_exists(_ls, "suggestions_enabled")) {
        _ls.suggestions_enabled = true;
    }
    if (!variable_struct_exists(_ls, "auto_correct_enabled")) {
        _ls.auto_correct_enabled = true;
    }
    if (!variable_struct_exists(_ls, "max_suggestions")) {
        _ls.max_suggestions = 5;
    }
    if (!variable_struct_exists(_ls, "min_prefix_length")) {
        _ls.min_prefix_length = 2;
    }
}

function gmls_log_query(_query, _result_count, _selected_index = -1) {
    var _ls = global.gmls;
    
    var _log_entry = {
        query: _query,
        timestamp: current_time,
        result_count: _result_count,
        selected_index: _selected_index
    };
    
    ds_list_add(_ls.query_log, _log_entry);
    
    var _count = ds_map_exists(_ls.popular_queries, _query) ? ds_map_find_value(_ls.popular_queries, _query) : 0;
    ds_map_add(_ls.popular_queries, _query, _count + 1);
    
    // keep last 1000 queries
    while (ds_list_size(_ls.query_log) > 1000) {
        ds_list_delete(_ls.query_log, 0);
    }
    
    var _terms = _gmls_process_text(_query);
    for (var i = 0; i < array_length(_terms); i++) {
        var _term = _terms[i];
        var _freq = ds_map_exists(_ls.spelling_dict, _term) ? ds_map_find_value(_ls.spelling_dict, _term) : 0;
        ds_map_add(_ls.spelling_dict, _term, _freq + 1);
    }
    
    _gmls_invalidate_suggestion_cache();
}

function gmls_record_click_with_query(_query, _doc_id) {
    var _ls = global.gmls;
    
    if (!ds_map_exists(_ls.query_click_graph, _query)) {
        ds_map_add(_ls.query_click_graph, _query, ds_map_create());
    }
    
    var _doc_map = ds_map_find_value(_ls.query_click_graph, _query);
    var _clicks = ds_map_exists(_doc_map, _doc_id) ? ds_map_find_value(_doc_map, _doc_id) : 0;
    ds_map_add(_doc_map, _doc_id, _clicks + 1);
}

function gmls_get_suggestions(_prefix, _max = -1) {
    var _ls = global.gmls;
    if (!_ls.suggestions_enabled) return [];
    
    if (_max == -1) _max = _ls.max_suggestions;
    if (string_length(_prefix) < _ls.min_prefix_length) return [];
    
    var _prefix_lower = string_lower(_prefix);
    
    if (ds_map_exists(_ls.suggestion_cache, _prefix_lower)) {
        var _cached = ds_map_find_value(_ls.suggestion_cache, _prefix_lower);
        if (array_length(_cached) >= _max) {
            var _result = [];
            for (var i = 0; i < _max; i++) {
                array_push(_result, _cached[i]);
            }
            return _result;
        }
    }
    
    var _suggestions = ds_map_create();
    
    var _query = ds_map_find_first(_ls.popular_queries);
    while (!is_undefined(_query)) {
        if (string_pos(_prefix_lower, string_lower(_query)) == 1) {
            var _count = ds_map_find_value(_ls.popular_queries, _query);
            ds_map_add(_suggestions, _query, _count);
        }
        _query = ds_map_find_next(_ls.popular_queries, _query);
    }
    
    var _term = ds_map_find_first(_ls.inverted_index);
    while (!is_undefined(_term)) {
        if (string_pos(_prefix_lower, _term) == 1) {
            var _freq = 1;
            if (ds_map_exists(_ls.spelling_dict, _term)) {
                _freq = ds_map_find_value(_ls.spelling_dict, _term) + 1;
            }
            ds_map_add(_suggestions, _term, _freq);
        }
        _term = ds_map_find_next(_ls.inverted_index, _term);
    }
    
    var _suggestion_list = [];
    var _sug_key = ds_map_find_first(_suggestions);
    while (!is_undefined(_sug_key)) {
        array_push(_suggestion_list, {
            text: _sug_key,
            score: ds_map_find_value(_suggestions, _sug_key)
        });
        _sug_key = ds_map_find_next(_suggestions, _sug_key);
    }
    
    ds_map_destroy(_suggestions);
    
    array_sort(_suggestion_list, function(a, b) { return b.score - a.score; });
    
	var _results = [];
	for (var i = 0; i < min(_max, array_length(_suggestion_list)); i++) {
	    array_push(_results, string(_suggestion_list[i].text));
	}
    
    ds_map_add(_ls.suggestion_cache, _prefix_lower, _results);
    
    return _results;
}

function _gmls_invalidate_suggestion_cache() {
    if (!is_undefined(global.gmls.suggestion_cache)) {
        ds_map_clear(global.gmls.suggestion_cache);
    }
}

function gmls_spell_check(_word) {
    var _ls = global.gmls;
    if (!_ls.auto_correct_enabled) return _word;
    
    var _word_lower = string_lower(_word);
    
    // (case insensitive)
    var _exact_match = false;
    var _dict_word = ds_map_find_first(_ls.spelling_dict);
    while (!is_undefined(_dict_word)) {
        if (string_lower(_dict_word) == _word_lower) {
            _exact_match = true;
            break;
        }
        _dict_word = ds_map_find_next(_ls.spelling_dict, _dict_word);
    }
    if (_exact_match) return _word;
    
    var _index_word = ds_map_find_first(_ls.inverted_index);
    while (!is_undefined(_index_word)) {
        if (string_lower(_index_word) == _word_lower) {
            return _word;
        }
        _index_word = ds_map_find_next(_ls.inverted_index, _index_word);
    }
    
    var _best_match = _word;
    var _best_distance = 999;
    var _best_freq = 0;
    
    var _candidate = ds_map_find_first(_ls.spelling_dict);
    while (!is_undefined(_candidate)) {
        var _dist = _gmls_levenshtein_distance(_word_lower, string_lower(_candidate));
        var _freq = ds_map_find_value(_ls.spelling_dict, _candidate);
        
        if (_dist < _best_distance || (_dist == _best_distance && _freq > _best_freq)) {
            _best_distance = _dist;
            _best_match = _candidate;
            _best_freq = _freq;
        }
        _candidate = ds_map_find_next(_ls.spelling_dict, _candidate);
    }
    
    if (_best_distance <= 2 && _best_distance > 0 && _best_match != _word) {
        return _best_match;
    }
    
    return _word;
}

function gmls_correct_query(_query) {
    var _terms = _gmls_process_text(_query);
    var _corrected_terms = [];
    var _changed = false;
    
    for (var i = 0; i < array_length(_terms); i++) {
        var _corrected = gmls_spell_check(_terms[i]);
        if (_corrected != _terms[i]) _changed = true;
        array_push(_corrected_terms, _corrected);
    }
    
    if (!_changed) return { original: _query, corrected: _query, changed: false };
    
    var _corrected_query = "";
    for (var i = 0; i < array_length(_corrected_terms); i++) {
        if (i > 0) _corrected_query += " ";
        _corrected_query += _corrected_terms[i];
    }
    
    return { original: _query, corrected: _corrected_query, changed: true };
}

function _gmls_levenshtein_distance(_s1, _s2) {
    var _len1 = string_length(_s1);
    var _len2 = string_length(_s2);
    
    if (_len1 == 0) return _len2;
    if (_len2 == 0) return _len1;
    
    var _matrix = array_create(_len1 + 1);
    for (var i = 0; i <= _len1; i++) {
        _matrix[i] = array_create(_len2 + 1);
        _matrix[i][0] = i;
    }
    for (var j = 0; j <= _len2; j++) {
        _matrix[0][j] = j;
    }
    
    for (var i = 1; i <= _len1; i++) {
        for (var j = 1; j <= _len2; j++) {
            var _cost = (string_char_at(_s1, i) == string_char_at(_s2, j)) ? 0 : 1;
            _matrix[i][j] = min(min(
                _matrix[i-1][j] + 1,
                _matrix[i][j-1] + 1),
                _matrix[i-1][j-1] + _cost
            );
        }
    }
    
    return _matrix[_len1][_len2];
}

function gmls_get_related_queries(_query, _max = 5) {
    var _ls = global.gmls;
    var _related = ds_map_create();
    var _query_terms = _gmls_process_text(_query);
    
    if (ds_map_exists(_ls.query_click_graph, _query)) {
        var _clicked_docs = ds_map_find_value(_ls.query_click_graph, _query);
        var _doc = ds_map_find_first(_clicked_docs);
        
        while (!is_undefined(_doc)) {
            var _other_query = ds_map_find_first(_ls.query_click_graph);
            while (!is_undefined(_other_query)) {
                if (_other_query != _query) {
                    var _other_docs = ds_map_find_value(_ls.query_click_graph, _other_query);
                    if (ds_map_exists(_other_docs, _doc)) {
                        var _score = ds_map_find_value(_other_docs, _doc);
                        if (ds_map_exists(_related, _other_query)) {
                            _score += ds_map_find_value(_related, _other_query);
                        }
                        ds_map_add(_related, _other_query, _score);
                    }
                }
                _other_query = ds_map_find_next(_ls.query_click_graph, _other_query);
            }
            _doc = ds_map_find_next(_clicked_docs, _doc);
        }
    }
    
    var _pop_query = ds_map_find_first(_ls.popular_queries);
    while (!is_undefined(_pop_query)) {
        if (_pop_query != _query) {
            var _pop_terms = _gmls_process_text(_pop_query);
            var _overlap = 0;
            var _total_terms = max(1, array_length(_query_terms));
            
            for (var i = 0; i < array_length(_query_terms); i++) {
                for (var j = 0; j < array_length(_pop_terms); j++) {
                    if (string_lower(_query_terms[i]) == string_lower(_pop_terms[j])) {
                        _overlap++;
                    }
                }
            }
            
            if (_overlap > 0) {
                var _similarity = _overlap / _total_terms;
                var _score = _similarity * 100;
                
                var _pop_count = ds_map_find_value(_ls.popular_queries, _pop_query);
                _score += _pop_count / 10;
                
                if (ds_map_exists(_related, _pop_query)) {
                    _score += ds_map_find_value(_related, _pop_query);
                }
                ds_map_add(_related, _pop_query, _score);
            }
        }
        _pop_query = ds_map_find_next(_ls.popular_queries, _pop_query);
    }
    
    if (array_length(_query_terms) > 0) {
        var _last_term = _query_terms[array_length(_query_terms) - 1];
        var _completions = gmls_get_suggestions(_last_term, 3);
        
        for (var i = 0; i < array_length(_completions); i++) {
            var _completion = _completions[i];
            if (_completion != _query && !ds_map_exists(_related, _completion)) {
                var _new_query = _query;
                if (string_length(_completion) > string_length(_last_term)) {
                    var _suffix = string_copy(_completion, string_length(_last_term) + 1, string_length(_completion));
                    _new_query = _query + _suffix;
                }
                ds_map_add(_related, _new_query, 50);
            }
        }
    }
    
    if (array_length(_query_terms) > 0) {
        var _search_results = gmls_search(_query, 5);
        var _categories = ds_map_create();
        
        for (var i = 0; i < array_length(_search_results); i++) {
            var _doc = _search_results[i].document;
            if (!is_undefined(_doc.facets) && variable_struct_exists(_doc.facets, "category")) {
                var _cat = _doc.facets.category;
                if (!ds_map_exists(_categories, _cat)) {
                    ds_map_add(_categories, _cat, 0);
                }
                ds_map_set(_categories, _cat, ds_map_find_value(_categories, _cat) + 1);
            }
        }
        
        var _cat = ds_map_find_first(_categories);
        while (!is_undefined(_cat)) {
            var _cat_query = _cat + " games";
            if (!ds_map_exists(_related, _cat_query) && _cat_query != _query) {
                ds_map_add(_related, _cat_query, ds_map_find_value(_categories, _cat) * 20);
            }
            _cat = ds_map_find_next(_categories, _cat);
        }
        ds_map_destroy(_categories);
    }
    
    var _related_list = [];
    var _rel_key = ds_map_find_first(_related);
    while (!is_undefined(_rel_key)) {
        array_push(_related_list, {
            query: _rel_key,
            score: ds_map_find_value(_related, _rel_key)
        });
        _rel_key = ds_map_find_next(_related, _rel_key);
    }
    
    ds_map_destroy(_related);
    
    array_sort(_related_list, function(a, b) { return b.score - a.score; });
    
    var _results = [];
    var _seen = ds_map_create();
    for (var i = 0; i < min(_max * 2, array_length(_related_list)); i++) {
        var _q = _related_list[i].query;
        if (_q != _query && !ds_map_exists(_seen, _q)) {
            ds_map_add(_seen, _q, true);
            array_push(_results, _q);
            if (array_length(_results) >= _max) break;
        }
    }
    ds_map_destroy(_seen);
    
    return _results;
}

function gmls_get_popular_queries(_limit = 10) {
    var _ls = global.gmls;
    var _queries = [];
    
    var _query = ds_map_find_first(_ls.popular_queries);
    while (!is_undefined(_query)) {
        array_push(_queries, {
            query: _query,
            count: ds_map_find_value(_ls.popular_queries, _query)
        });
        _query = ds_map_find_next(_ls.popular_queries, _query);
    }
    
    array_sort(_queries, function(a, b) { return b.count - a.count; });
    
    var _results = [];
    for (var i = 0; i < min(_limit, array_length(_queries)); i++) {
        array_push(_results, _queries[i].query);
    }
    
    return _results;
}

function gmls_get_query_stats() {
    var _ls = global.gmls;
    
    return {
        total_queries: ds_list_size(_ls.query_log),
        unique_queries: ds_map_size(_ls.popular_queries),
        dictionary_size: ds_map_size(_ls.spelling_dict),
        suggestions_enabled: _ls.suggestions_enabled,
        auto_correct_enabled: _ls.auto_correct_enabled
    };
}