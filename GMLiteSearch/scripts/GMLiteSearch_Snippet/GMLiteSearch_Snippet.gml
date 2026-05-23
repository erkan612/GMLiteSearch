

// SNIPPETS
function gmls_init_snippets() {
    var _ls = global.gmls;
    
    if (!variable_struct_exists(_ls, "snippet_config")) {
        _ls.snippet_config = {
            default_length: 200,
            highlight_start: "**",
            highlight_end: "**",
            strategy: "best_fragment",
            fragment_count: 2,
            fragment_separator: " ... ",
            min_term_match: 1,
            boost_title: true,
            boost_exact_phrase: 1.5,
            deduplicate: true
        };
    }
}

function gmls_configure_snippets(_config) {
    var _cfg = global.gmls.snippet_config;
    var _keys = variable_struct_get_names(_config);
    for (var i = 0; i < array_length(_keys); i++) {
        var _key = _keys[i];
        _cfg[$ _key] = _config[$ _key];
    }
}

function gmls_generate_advanced_snippet(_doc_id, _query, _options = undefined) {
    var _ls = global.gmls;
    var _cfg = _ls.snippet_config;
    
    if (!is_undefined(_options)) {
        var _merged = {};
        var _cfg_keys = variable_struct_get_names(_cfg);
        for (var i = 0; i < array_length(_cfg_keys); i++) {
            _merged[$ _cfg_keys[i]] = _cfg[$ _cfg_keys[i]];
        }
        var _opt_keys = variable_struct_get_names(_options);
        for (var i = 0; i < array_length(_opt_keys); i++) {
            _merged[$ _opt_keys[i]] = _options[$ _opt_keys[i]];
        }
        _cfg = _merged;
    }
    
    var _doc = ds_map_find_value(_ls.documents, _doc_id);
    if (is_undefined(_doc)) return "";
    
    var _text = _doc.text;
    var _title = "";
    if (!is_undefined(_doc.metadata) && variable_struct_exists(_doc.metadata, "title")) {
        _title = _doc.metadata.title;
    }
    
    var _terms = _gmls_process_text(_query);
    var _phrases = _gmls_extract_phrases(_query);
    
    if (_cfg.strategy == "best_fragment") {
        return _gmls_snippet_best_fragment(_text, _title, _terms, _phrases, _cfg);
    } else if (_cfg.strategy == "surrounding") {
        return _gmls_snippet_surrounding(_text, _title, _terms, _phrases, _cfg);
    } else {
        return _gmls_snippet_balanced(_text, _title, _terms, _phrases, _cfg);
    }
}

function _gmls_extract_phrases(_query) {
    var _phrases = [];
    var _in_quote = false;
    var _current = "";
    
    for (var i = 1; i <= string_length(_query); i++) {
        var _ch = string_char_at(_query, i);
        if (_ch == "\"") {
            if (_in_quote && string_length(_current) > 0) {
                array_push(_phrases, _current);
                _current = "";
            }
            _in_quote = !_in_quote;
        } else if (_in_quote) {
            _current += _ch;
        }
    }
    
    return _phrases;
}

function _gmls_snippet_best_fragment(_text, _title, _terms, _phrases, _cfg) {
    var _text_lower = string_lower(_text);
    var _title_lower = string_lower(_title);
    var _fragments = [];
    
    var _title_score = 0;
    for (var i = 0; i < array_length(_terms); i++) {
        if (string_pos(_terms[i], _title_lower) > 0) {
            _title_score += 2;
        }
    }
    
    if (_cfg.boost_title && _title_score > 0 && string_length(_title) > 0) {
        var _title_snippet = _gmls_highlight_text(_title, _terms, _phrases, _cfg);
        array_push(_fragments, { text: _title_snippet, score: _title_score, position: -1 });
    }
    
    var _matches = [];
    var _max_matches = 100;
    
    for (var i = 0; i < array_length(_terms) && array_length(_matches) < _max_matches; i++) {
        var _term = _terms[i];
        var _search_pos = 1;
        var _term_len = string_length(_term);
        var _text_len = string_length(_text_lower);
        
        for (var attempts = 0; attempts < 200 && _search_pos <= _text_len; attempts++) {
            _search_pos = string_pos(_term, string_copy(_text_lower, _search_pos, _text_len - _search_pos + 1));
            if (_search_pos > 0) {
                var _actual_pos = _search_pos;
                array_push(_matches, { term: _term, pos: _actual_pos, length: _term_len });
                _search_pos = _actual_pos + _term_len;
                if (_search_pos > _text_len) break;
            } else {
                break;
            }
        }
    }
    
    for (var i = 0; i < array_length(_phrases) && array_length(_matches) < _max_matches; i++) {
        var _phrase = string_lower(_phrases[i]);
        var _search_pos = 1;
        var _phrase_len = string_length(_phrase);
        var _text_len = string_length(_text_lower);
        
        for (var attempts = 0; attempts < 200 && _search_pos <= _text_len; attempts++) {
            _search_pos = string_pos(_phrase, string_copy(_text_lower, _search_pos, _text_len - _search_pos + 1));
            if (_search_pos > 0) {
                var _actual_pos = _search_pos;
                array_push(_matches, { term: _phrase, pos: _actual_pos, length: _phrase_len, is_phrase: true });
                _search_pos = _actual_pos + _phrase_len;
                if (_search_pos > _text_len) break;
            } else {
                break;
            }
        }
    }
    
    if (array_length(_matches) == 0) {
        return string_copy(_text, 1, _cfg.default_length) + "...";
    }
    
    array_sort(_matches, function(a, b) { return a.pos - b.pos; });
    
    var _windows = [];
    var _window_size = _cfg.default_length / _cfg.fragment_count;
    
    for (var i = 0; i < array_length(_matches) && i < 50; i++) {
        var _match = _matches[i];
        var _start = max(1, _match.pos - _window_size / 2);
        var _end_pos = min(string_length(_text), _match.pos + _match.length + _window_size / 2);
        
        if (_start >= _end_pos) continue;
        
        var _window_text = string_copy(_text, _start, _end_pos - _start + 1);
        
        var _score = 0;
        for (var j = 0; j < array_length(_terms); j++) {
            if (string_pos(_terms[j], string_lower(_window_text)) > 0) {
                _score++;
            }
        }
        for (var j = 0; j < array_length(_phrases); j++) {
            if (string_pos(string_lower(_phrases[j]), string_lower(_window_text)) > 0) {
                _score += _cfg.boost_exact_phrase;
            }
        }
        
        var _overlap = false;
        for (var j = 0; j < array_length(_windows); j++) {
            if (abs(_windows[j].start - _start) < _window_size / 3) {
                _overlap = true;
                break;
            }
        }
        
        if (!_overlap) {
            array_push(_windows, { text: _window_text, score: _score, start: _start, end_pos: _end_pos });
        }
    }
    
    array_sort(_windows, function(a, b) { return b.score - a.score; });
    
    var _selected = [];
    for (var i = 0; i < min(_cfg.fragment_count, array_length(_windows)); i++) {
        array_push(_selected, _windows[i]);
    }
    
    array_sort(_selected, function(a, b) { return a.start - b.start; });
    
    var _result = "";
    for (var i = 0; i < array_length(_selected); i++) {
        var _frag = _selected[i];
        var _highlighted = _gmls_highlight_text(_frag.text, _terms, _phrases, _cfg);
        if (i > 0) _result += _cfg.fragment_separator;
        _result += _highlighted;
    }
    
    if (string_length(_result) == 0) {
        _result = string_copy(_text, 1, _cfg.default_length) + "...";
    }
    
    return _result;
}

function _gmls_snippet_surrounding(_text, _title, _terms, _phrases, _cfg) {
    var _text_lower = string_lower(_text);
    var _best_match_pos = -1;
    var _best_match_score = 0;
    
    for (var i = 0; i < array_length(_terms); i++) {
        var _pos = string_pos(_terms[i], _text_lower);
        if (_pos > 0) {
            var _score = 1;
            for (var j = i + 1; j < array_length(_terms); j++) {
                var _near_pos = string_pos(_terms[j], string_copy(_text_lower, max(1, _pos - 50), 100));
                if (_near_pos > 0) _score++;
            }
            if (_score > _best_match_score) {
                _best_match_score = _score;
                _best_match_pos = _pos;
            }
        }
    }
    
    for (var i = 0; i < array_length(_phrases); i++) {
        var _pos = string_pos(_phrases[i], _text_lower);
        if (_pos > 0) {
            _best_match_pos = _pos;
            _best_match_score += _cfg.boost_exact_phrase;
        }
    }
    
    if (_best_match_pos == -1) {
        return string_copy(_text, 1, _cfg.default_length) + "...";
    }
    
    var _start = max(1, _best_match_pos - _cfg.default_length / 2);
    var _end = min(string_length(_text), _best_match_pos + _cfg.default_length / 2);
    
    var _snippet = string_copy(_text, _start, _end - _start + 1);
    
    if (_start > 1) _snippet = "..." + _snippet;
    if (_end < string_length(_text)) _snippet = _snippet + "...";
    
    return _gmls_highlight_text(_snippet, _terms, _phrases, _cfg);
}

function _gmls_snippet_balanced(_text, _title, _terms, _phrases, _cfg) {
    var _sentences = _gmls_split_sentences(_text);
    var _scored = [];
    
    for (var i = 0; i < array_length(_sentences); i++) {
        var _score = 0;
        var _sentence_lower = string_lower(_sentences[i]);
        
        for (var j = 0; j < array_length(_terms); j++) {
            if (string_pos(_terms[j], _sentence_lower) > 0) {
                _score++;
            }
        }
        
        for (var j = 0; j < array_length(_phrases); j++) {
            if (string_pos(_phrases[j], _sentence_lower) > 0) {
                _score += _cfg.boost_exact_phrase;
            }
        }
        
        if (_score > 0) {
            array_push(_scored, { text: _sentences[i], score: _score, index: i });
        }
    }
    
    if (array_length(_scored) == 0) {
        return string_copy(_text, 1, _cfg.default_length) + "...";
    }
    
    array_sort(_scored, function(a, b) { return b.score - a.score; });
    
    var _selected = [];
    var _used_indices = ds_map_create();
    
    for (var i = 0; i < min(_cfg.fragment_count, array_length(_scored)); i++) {
        var _candidate = _scored[i];
        if (!ds_map_exists(_used_indices, string(_candidate.index))) {
            ds_map_add(_used_indices, string(_candidate.index), true);
            array_push(_selected, _candidate);
        }
    }
    
    ds_map_destroy(_used_indices);
    
    array_sort(_selected, function(a, b) { return a.index - b.index; });
    
    var _result = "";
    for (var i = 0; i < array_length(_selected); i++) {
        if (i > 0) _result += " ";
        var _highlighted = _gmls_highlight_text(_selected[i].text, _terms, _phrases, _cfg);
        _result += _highlighted;
    }
    
    return _result;
}

function _gmls_split_sentences(_text) {
    var _sentences = [];
    var _current = "";
    
    for (var i = 1; i <= string_length(_text); i++) {
        var _ch = string_char_at(_text, i);
        _current += _ch;
        
        if (_ch == "." || _ch == "!" || _ch == "?") {
            if (string_length(_current) > 0) {
                array_push(_sentences, _current);
                _current = "";
            }
        }
    }
    
    if (string_length(_current) > 0) {
        array_push(_sentences, _current);
    }
    
    return _sentences;
}

function _gmls_highlight_text(_text, _terms, _phrases, _cfg) {
    var _result = _text;
    var _highlighted = ds_map_create();
    
    for (var i = 0; i < array_length(_phrases); i++) {
        var _phrase = _phrases[i];
        var _replacement = _cfg.highlight_start + _phrase + _cfg.highlight_end;
        var _temp = string_replace_all(_result, _phrase, _replacement);
        if (_temp != _result) {
            _result = _temp;
            ds_map_add(_highlighted, _phrase, true);
        }
    }
    
    for (var i = 0; i < array_length(_terms); i++) {
        var _term = _terms[i];
        if (!ds_map_exists(_highlighted, _term)) {
            var _replacement = _cfg.highlight_start + _term + _cfg.highlight_end;
            _result = string_replace_all(_result, _term, _replacement);
        }
    }
    
    if (_result == _text && array_length(_terms) > 0) {
        var _lower_text = string_lower(_text);
        var _case_result = "";
        var _last_pos = 1;
        
        for (var i = 0; i < array_length(_terms); i++) {
            var _term_lower = _terms[i];
            var _pos = string_pos(_term_lower, _lower_text);
            if (_pos > 0) {
                var _before = string_copy(_text, _last_pos, _pos - _last_pos);
                var _matched = string_copy(_text, _pos, string_length(_terms[i]));
                _case_result += _before + _cfg.highlight_start + _matched + _cfg.highlight_end;
                _last_pos = _pos + string_length(_terms[i]);
            }
        }
        
        if (string_length(_case_result) > 0) {
            _case_result += string_copy(_text, _last_pos, string_length(_text) - _last_pos + 1);
            _result = _case_result;
        }
    }
    
    return _result;
}

function gmls_get_snippet_candidates(_doc_id, _query, _max_candidates = 3) {
    var _ls = global.gmls;
    var _doc = ds_map_find_value(_ls.documents, _doc_id);
    if (is_undefined(_doc)) return [];
    
    var _text = _doc.text;
    var _terms = _gmls_process_text(_query);
    var _candidates = [];
    
    if (array_length(_terms) == 0) return [];
    
    var _text_lower = string_lower(_text);
    var _text_len = string_length(_text);
    
    for (var t = 0; t < array_length(_terms); t++) {
        var _term = _terms[t];
        var _term_len = string_length(_term);
        
        for (var pos = 1; pos <= _text_len - _term_len + 1; pos++) {
            var _slice = string_copy(_text_lower, pos, _term_len);
            if (_slice == _term) {
                var _start = max(1, pos - 60);
                var _end_pos = min(_text_len, pos + 60);
                
                var _snippet = string_copy(_text, _start, _end_pos - _start + 1);
                if (_start > 1) _snippet = "..." + _snippet;
                if (_end_pos < _text_len) _snippet = _snippet + "...";
                
                array_push(_candidates, {
                    text: _snippet,
                    position: pos,
                    term: _term
                });
                
                pos += _term_len - 1;
            }
        }
    }
    
    var _unique = [];
    var _seen = ds_map_create();
    for (var i = 0; i < array_length(_candidates); i++) {
        var _key = _candidates[i].text;
        if (!ds_map_exists(_seen, _key)) {
            ds_map_add(_seen, _key, true);
            array_push(_unique, _candidates[i]);
        }
    }
    ds_map_destroy(_seen);
    
    if (array_length(_unique) > _max_candidates) {
        array_resize(_unique, _max_candidates);
    }
    
    return _unique;
}