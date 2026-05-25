/*********************************************************************************************
*                                        MIT License                                         *
*--------------------------------------------------------------------------------------------*
* Copyright (c) 2025 erkan612                                                                *
*                                                                                            *
* Permission is hereby granted, free of charge, to any person obtaining a copy of this       *
* software and associated documentation files (the "Software"), to deal in the Software      *
* without restriction, including without limitation the rights to use, copy, modify, merge,  *
* publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons *
* to whom the Software is furnished to do so, subject to the following conditions:           *
*                                                                                            *
* The above copyright notice and this permission notice shall be included in all copies or   *
* substantial portions of the Software.                                                      *
*                                                                                            *
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,        *
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR   *
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE  *
* FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR       *
* OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER     *
* DEALINGS IN THE SOFTWARE.                                                                  *
**********************************************************************************************
*--------------------------------------------------------------------------------------------*
*   						***************************************                          *
*   						   ██████╗ ███╗   ███╗██╗     ███████╗		                     *
*   						  ██╔════╝ ████╗ ████║██║     ██╔════╝		                     *
*   						  ██║  ███╗██╔████╔██║██║     ███████╗		                     *
*   						  ██║   ██║██║╚██╔╝██║██║     ╚════██║		                     *
*   						  ╚██████╔╝██║ ╚═╝ ██║███████╗███████║		                     *
*   						   ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝		                     *
*   						Lightweight Search Engine for GameMaker	                         *
*   						            Version 1.2.0										 *
*   																                         *
*   						            by erkan612					                         *
*   						***************************************                          *
*********************************************************************************************/

//  INITIALIZATION
function gmls_init() {
	global.gmls = {
	    // Core data structures
	    inverted_index			: ds_map_create(),   // word -> ds_map(doc_id -> tf)
	    documents				: ds_map_create(),   // doc_id -> {id, text, metadata, word_count}
	    word_stats				: ds_map_create(),   // word -> {total_freq, doc_freq}
	    doc_count				: 0,
	    
	    // N‑gram index (character trigrams)
	    ngram_index				: ds_map_create(),
	    ngram_size				: 3,
	    enable_ngrams			: true,
	    
	    // Configuration
	    case_sensitive			: false,
	    enable_stemming			: true,
	    min_word_length			: 2,
	    stop_words				: ds_list_create(),
								
	    // Scoring mode			
	    scoring					: "bm25",
	    bm25_k1					: 1.2,
	    bm25_b					: 0.75,
								
	    // Performance			
	    max_doc_size			: 50000,
	    cache_idf				: ds_map_create(),
	    
	    // Results
	    last_results			: [],
	    selected_result: -1,
		
		debug: {
	        enabled: true,
	        log_level: "info",
	        query_history: [],
	        slow_query_threshold: 100,
	    },
		
		synonyms: undefined,
	};
	
	// Default stop words
	var _stop = ["a","an","and","are","as","at","be","by","for","from","has","he",
	             "in","is","it","its","of","on","that","the","to","was","were",
	             "will","with","i","you","we","they","this","that","these","those"];
	for (var i = 0; i < array_length(_stop); i++) {
	    ds_list_add(global.gmls.stop_words, _stop[i]);
	}
	
	// Init others default
	gmls_init_facets();
	gmls_init_geo();
	gmls_init_ltr();
	gmls_init_snippets();
	gmls_init_query_understanding();
}

//  CLEAR & CLEANUP
function gmls_clear() {
    var _ls = global.gmls;
    var _case = _ls.case_sensitive;
    var _stem = _ls.enable_stemming;
    var _minlen = _ls.min_word_length;
    var _stop_copy = ds_list_create();
    for (var i = 0; i < ds_list_size(_ls.stop_words); i++)
        ds_list_add(_stop_copy, ds_list_find_value(_ls.stop_words, i));
    var _ngram_en = _ls.enable_ngrams;
    var _ngram_sz = _ls.ngram_size;
    var _scoring = _ls.scoring;
    var _k1 = _ls.bm25_k1;
    var _b = _ls.bm25_b;
    
    gmls_cleanup();
    gmls_init();
    
    _ls = global.gmls;
    _ls.case_sensitive = _case;
    _ls.enable_stemming = _stem;
    _ls.min_word_length = _minlen;
    _ls.enable_ngrams = _ngram_en;
    _ls.ngram_size = _ngram_sz;
    _ls.scoring = _scoring;
    _ls.bm25_k1 = _k1;
    _ls.bm25_b = _b;
    ds_list_clear(_ls.stop_words);
    for (var i = 0; i < ds_list_size(_stop_copy); i++)
        ds_list_add(_ls.stop_words, ds_list_find_value(_stop_copy, i));
    ds_list_destroy(_stop_copy);
}

function gmls_cleanup() {
    var _ls = global.gmls;
    
    // Core
    var _word = ds_map_find_first(_ls.inverted_index);
    while (!is_undefined(_word)) {
        ds_map_destroy(ds_map_find_value(_ls.inverted_index, _word));
        _word = ds_map_find_next(_ls.inverted_index, _word);
    }
    ds_map_destroy(_ls.inverted_index);
    ds_map_destroy(_ls.documents);
    ds_map_destroy(_ls.word_stats);
    ds_map_destroy(_ls.ngram_index);
    ds_map_destroy(_ls.cache_idf);
    ds_list_destroy(_ls.stop_words);
    
    // Facets
    if (variable_struct_exists(_ls, "facet_index")) ds_map_destroy(_ls.facet_index);
    if (variable_struct_exists(_ls, "facet_cache")) ds_map_destroy(_ls.facet_cache);
    if (variable_struct_exists(_ls, "active_filters")) ds_map_destroy(_ls.active_filters);
    if (variable_struct_exists(_ls, "range_facets")) ds_map_destroy(_ls.range_facets);
	if (variable_struct_exists(_ls, "date_facets")) ds_map_destroy(_ls.date_facets);
    
    // Geo
    if (variable_struct_exists(_ls, "geo_index")) ds_map_destroy(_ls.geo_index);
    if (variable_struct_exists(_ls, "geo_radius_cache")) ds_map_destroy(_ls.geo_radius_cache);
	if (variable_struct_exists(_ls, "cell_index")) ds_map_destroy(_ls.cell_index);
	
	// LTR
	if (variable_struct_exists(_ls, "ltr_features")) ds_map_destroy(_ls.ltr_features);
	if (variable_struct_exists(_ls, "ltr_training_data")) ds_list_destroy(_ls.ltr_training_data);
	if (variable_struct_exists(_ls, "ltr_clicks")) ds_map_destroy(_ls.ltr_clicks);
	if (variable_struct_exists(_ls, "ltr_impressions")) ds_map_destroy(_ls.ltr_impressions);
	if (variable_struct_exists(_ls, "ltr_feature_extractors")) ds_map_destroy(_ls.ltr_feature_extractors);
    
	// Snippet
	if (variable_struct_exists(_ls, "snippet_config")) _ls.snippet_config = undefined;
	
	// Query
	if (variable_struct_exists(_ls, "query_log")) ds_list_destroy(_ls.query_log);
	if (variable_struct_exists(_ls, "suggestion_cache")) ds_map_destroy(_ls.suggestion_cache);
	if (variable_struct_exists(_ls, "spelling_dict")) ds_map_destroy(_ls.spelling_dict);
	if (variable_struct_exists(_ls, "popular_queries")) ds_map_destroy(_ls.popular_queries);
	if (variable_struct_exists(_ls, "query_click_graph")) ds_map_destroy(_ls.query_click_graph);
	
    global.gmls = undefined;
}

//  INTERNAL HELPERS
function _gmls_normalize_word(_word) {
    if (!global.gmls.case_sensitive) _word = string_lower(_word);
    
    var _len = string_length(_word);
    if (_len == 0) return "";
    var _first = string_char_at(_word, 1);
    var _last  = string_char_at(_word, _len);
    if (string_pos(_first, "!?.,;:()\"'") > 0) _word = string_delete(_word, 1, 1);
    _len = string_length(_word);
    if (_len > 0) {
        _last = string_char_at(_word, _len);
        if (string_pos(_last, "!?.,;:()\"'") > 0) _word = string_delete(_word, _len, 1);
    }
    
    if (global.gmls.enable_stemming && string_length(_word) > 0) {
        _word = _gmls_stemmer(_word);
    }
    
    return _word;
}

function _gmls_is_stop_word(_word) {
    var _ls = global.gmls;
    var _norm = _gmls_normalize_word(_word);
    for (var i = 0; i < ds_list_size(_ls.stop_words); i++) {
        if (ds_list_find_value(_ls.stop_words, i) == _norm) return true;
    }
    return false;
}

function _gmls_process_text(_text) {
    var _ls = global.gmls;
    var _words = [];
    var _current = "";
    var _len = string_length(_text);
    for (var i = 1; i <= _len; i++) {
        var _ch = string_char_at(_text, i);
        var _code = ord(_ch);
        // Accept letters, numbers, apostrophe
        if ((_code >= 48 && _code <= 57) ||
            (_code >= 65 && _code <= 90) ||
            (_code >= 97 && _code <= 122) ||
            _ch == "'") {
            _current += _ch;
        } else {
            if (string_length(_current) > 0) {
                var _word = _gmls_normalize_word(_current);
                if (string_length(_word) >= _ls.min_word_length && !_gmls_is_stop_word(_word)) {
                    array_push(_words, _word);
                }
                _current = "";
            }
        }
    }
    if (string_length(_current) > 0) {
        var _word = _gmls_normalize_word(_current);
        if (string_length(_word) >= _ls.min_word_length && !_gmls_is_stop_word(_word)) {
            array_push(_words, _word);
        }
    }
    return _words;
}

function _gmls_generate_snippet(_text, _query_terms, _max_len = 200) {
    var _text_lower = string_lower(_text);
    var _best_pos = -1;
    var _best_count = 0;
    for (var i = 0; i < array_length(_query_terms); i++) {
        var _pos = string_pos(_query_terms[i], _text_lower);
        if (_pos > 0) {
            var _cnt = 1;
            for (var j = i+1; j < array_length(_query_terms); j++) {
                if (string_pos(_query_terms[j], _text_lower) > 0) _cnt++;
            }
            if (_cnt > _best_count) {
                _best_count = _cnt;
                _best_pos = _pos;
            }
        }
    }
    if (_best_pos == -1) return string_copy(_text, 1, _max_len) + "...";
    var _start = max(1, _best_pos - 50);
    var _len = min(_max_len, string_length(_text) - _start + 1);
    return "..." + string_copy(_text, _start, _len) + "...";
}

function _gmls_list_to_array(_list) {
    var _arr = [];
    for (var i = 0; i < ds_list_size(_list); i++) {
        array_push(_arr, ds_list_find_value(_list, i));
    }
    return _arr;
}

function _gmls_total_word_freq() {
    var _ls = global.gmls;
    var _total = 0;
    var _key = ds_map_find_first(_ls.word_stats);
    while (!is_undefined(_key)) {
        var _stats = ds_map_find_value(_ls.word_stats, _key);
        _total += _stats.total_frequency;
        _key = ds_map_find_next(_ls.word_stats, _key);
    }
    return _total;
}

function _gmls_get_idf(_term) {
    var _ls = global.gmls;
    if (ds_map_exists(_ls.cache_idf, _term))
        return ds_map_find_value(_ls.cache_idf, _term);
    var _doc_freq = 1;
    if (ds_map_exists(_ls.word_stats, _term))
        _doc_freq = ds_map_find_value(_ls.word_stats, _term).document_frequency;
    var _idf = log10( (_ls.doc_count + 1) / _doc_freq );
    ds_map_add(_ls.cache_idf, _term, _idf);
    return _idf;
}

function _gmls_clear_idf_cache() {
    ds_map_clear(global.gmls.cache_idf);
}

//  CONFIGURATION
function gmls_set_config(_case_sensitive, _enable_stemming, _min_word_length, _scoring = "bm25") {
    var _ls = global.gmls;
    _ls.case_sensitive = _case_sensitive;
    _ls.enable_stemming = _enable_stemming;
    _ls.min_word_length = _min_word_length;
    if (_scoring == "tfidf" || _scoring == "bm25") _ls.scoring = _scoring;
}

function gmls_set_bm25_params(_k1, _b) {
    global.gmls.bm25_k1 = _k1;
    global.gmls.bm25_b = _b;
}

function gmls_add_stop_word(_word) {
    var _ls = global.gmls;
    if (!_ls.case_sensitive) _word = string_lower(_word);
    ds_list_add(_ls.stop_words, _word);
}

//  PERSISTENCE
function gmls_save_to_string() {
    var _ls = global.gmls;
    var _save = {
        doc_count: _ls.doc_count,
        case_sensitive: _ls.case_sensitive,
        enable_stemming: _ls.enable_stemming,
        min_word_length: _ls.min_word_length,
        enable_ngrams: _ls.enable_ngrams,
        ngram_size: _ls.ngram_size,
        scoring: _ls.scoring,
        bm25_k1: _ls.bm25_k1,
        bm25_b: _ls.bm25_b,
        stop_words: [],
        documents: {},
        inverted_index: {},
        word_stats: {},
        ngram_index: {}
    };
    
    for (var i = 0; i < ds_list_size(_ls.stop_words); i++)
        array_push(_save.stop_words, ds_list_find_value(_ls.stop_words, i));
    
    var _did = ds_map_find_first(_ls.documents);
    while (!is_undefined(_did)) {
        var _doc = ds_map_find_value(_ls.documents, _did);
        _save.documents[$ string(_did)] = {
            id: _doc.id,
            text: _doc.text,
            metadata: _doc.metadata,
            word_count: _doc.word_count
        };
        _did = ds_map_find_next(_ls.documents, _did);
    }
    
    var _word = ds_map_find_first(_ls.inverted_index);
    while (!is_undefined(_word)) {
        var _docs = ds_map_find_value(_ls.inverted_index, _word);
        var _doc_map = {};
        var _subid = ds_map_find_first(_docs);
        while (!is_undefined(_subid)) {
            _doc_map[$ string(_subid)] = ds_map_find_value(_docs, _subid);
            _subid = ds_map_find_next(_docs, _subid);
        }
        _save.inverted_index[$ _word] = _doc_map;
        _word = ds_map_find_next(_ls.inverted_index, _word);
    }
    
    var _wstat = ds_map_find_first(_ls.word_stats);
    while (!is_undefined(_wstat)) {
        var _st = ds_map_find_value(_ls.word_stats, _wstat);
        _save.word_stats[$ _wstat] = { total_frequency: _st.total_frequency, document_frequency: _st.document_frequency };
        _wstat = ds_map_find_next(_ls.word_stats, _wstat);
    }
    
    var _ng = ds_map_find_first(_ls.ngram_index);
    while (!is_undefined(_ng)) {
        var _ngdocs = ds_map_find_value(_ls.ngram_index, _ng);
        var _ngmap = {};
        var _ngid = ds_map_find_first(_ngdocs);
        while (!is_undefined(_ngid)) {
            _ngmap[$ string(_ngid)] = ds_map_find_value(_ngdocs, _ngid);
            _ngid = ds_map_find_next(_ngdocs, _ngid);
        }
        _save.ngram_index[$ _ng] = _ngmap;
        _ng = ds_map_find_next(_ls.ngram_index, _ng);
    }
    
    return json_stringify(_save);
}

function gmls_load_from_string(_json) {
    var _data = json_parse(_json);
    if (!is_struct(_data)) return false;
    
    gmls_clear();
    var _ls = global.gmls;
    
    _ls.doc_count = _data.doc_count;
    _ls.case_sensitive = _data.case_sensitive;
    _ls.enable_stemming = _data.enable_stemming;
    _ls.min_word_length = _data.min_word_length;
    _ls.enable_ngrams = _data.enable_ngrams;
    _ls.ngram_size = _data.ngram_size;
    _ls.scoring = _data.scoring;
    _ls.bm25_k1 = _data.bm25_k1;
    _ls.bm25_b = _data.bm25_b;
    
    ds_list_clear(_ls.stop_words);
    for (var i = 0; i < array_length(_data.stop_words); i++)
        ds_list_add(_ls.stop_words, _data.stop_words[i]);
    
    var _keys = variable_struct_get_names(_data.documents);
    for (var i = 0; i < array_length(_keys); i++) {
        var _id = _keys[i];
        var _doc = _data.documents[$ _id];
        ds_map_add(_ls.documents, _id, {
            id: _doc.id,
            text: _doc.text,
            metadata: _doc.metadata,
            word_count: _doc.word_count
        });
    }
    
    var _words = variable_struct_get_names(_data.inverted_index);
    for (var i = 0; i < array_length(_words); i++) {
        var _w = _words[i];
        var _docs_map = ds_map_create();
        var _doclist = _data.inverted_index[$ _w];
        var _dids = variable_struct_get_names(_doclist);
        for (var j = 0; j < array_length(_dids); j++) {
            var _did = _dids[j];
            ds_map_add(_docs_map, _did, _doclist[$ _did]);
        }
        ds_map_add(_ls.inverted_index, _w, _docs_map);
    }
    
    var _statkeys = variable_struct_get_names(_data.word_stats);
    for (var i = 0; i < array_length(_statkeys); i++) {
        var _w = _statkeys[i];
        var _st = _data.word_stats[$ _w];
        ds_map_add(_ls.word_stats, _w, { total_frequency: _st.total_frequency, document_frequency: _st.document_frequency });
    }
    
    var _ngkeys = variable_struct_get_names(_data.ngram_index);
    for (var i = 0; i < array_length(_ngkeys); i++) {
        var _ng = _ngkeys[i];
        var _ngdocs = ds_map_create();
        var _doclist = _data.ngram_index[$ _ng];
        var _dids = variable_struct_get_names(_doclist);
        for (var j = 0; j < array_length(_dids); j++) {
            var _did = _dids[j];
            ds_map_add(_ngdocs, _did, _doclist[$ _did]);
        }
        ds_map_add(_ls.ngram_index, _ng, _ngdocs);
    }
    
    return true;
}