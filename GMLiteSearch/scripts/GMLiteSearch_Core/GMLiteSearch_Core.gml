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
*   						            Version 1.1.0										 *
*   																                         *
*   						            by erkan612					                         *
*   						***************************************                          *
*********************************************************************************************/

//  STEMMING ENGINE (Porter2 Snowball English)
function _gmls_is_vowel(ch) {
        return (ch == "a" || ch == "e" || ch == "i" || ch == "o" || ch == "u" || ch == "y");
}
function _gmls_get_r1(str) {
        var i, found_vowel = false;
        for (i = 1; i <= string_length(str); i++) {
            var ch = string_char_at(str, i);
            if (_gmls_is_vowel(ch)) {
                found_vowel = true;
            } else if (found_vowel && !_gmls_is_vowel(ch)) {
                return string_copy(str, i + 1, string_length(str) - i);
            }
        }
        return "";
}
function _gmls_get_r2(str) {
        var r1 = _gmls_get_r1(str);
        if (string_length(r1) <= 1) return "";
        var i, found_vowel = false;
        for (i = 1; i <= string_length(r1); i++) {
            var ch = string_char_at(r1, i);
            if (_gmls_is_vowel(ch)) {
                found_vowel = true;
            } else if (found_vowel && !_gmls_is_vowel(ch)) {
                return string_copy(r1, i + 1, string_length(r1) - i);
            }
        }
        return "";
}
function _gmls_ends_with(str, suffix) {
        return string_pos(suffix, str) == string_length(str) - string_length(suffix) + 1;
}
function _gmls_replace_suffix(str, old_suffix, new_suffix) {
        if (_gmls_ends_with(str, old_suffix)) {
            return string_copy(str, 1, string_length(str) - string_length(old_suffix)) + new_suffix;
        }
        return str;
}
function _gmls_stemmer(word) {
    if (string_length(word) <= 2) return word;
    
    var original = word;
    var lower = string_lower(word);
    var len = string_length(lower);
    
    if (string_pos("'s'", lower) > 0 || string_pos("'s", lower) > 0) {
        lower = string_replace_all(lower, "'s'", "");
        lower = string_replace_all(lower, "'s", "");
        len = string_length(lower);
    }
    if (string_pos("'", lower) > 0) {
        lower = string_replace_all(lower, "'", "");
        len = string_length(lower);
    }
    
    if (_gmls_ends_with(lower, "sses")) {
        lower = _gmls_replace_suffix(lower, "sses", "ss");
    } else if (_gmls_ends_with(lower, "ies")) {
        lower = _gmls_replace_suffix(lower, "ies", "i");
    } else if (_gmls_ends_with(lower, "ss")) {
        // keep
    } else if (_gmls_ends_with(lower, "s")) {
        lower = _gmls_replace_suffix(lower, "s", "");
    }
    
    var prev_lower = lower;
    if (_gmls_ends_with(lower, "eed")) {
        if (string_length(_gmls_get_r1(lower)) >= 1) {
            lower = _gmls_replace_suffix(lower, "eed", "ee");
        }
    } else if (_gmls_ends_with(lower, "ed")) {
        lower = _gmls_replace_suffix(lower, "ed", "");
        var stem = lower;
        var has_vowel = false;
        for (var i = 1; i <= string_length(stem); i++) {
            if (_gmls_is_vowel(string_char_at(stem, i))) {
                has_vowel = true;
                break;
            }
        }
        if (!has_vowel) lower = prev_lower;
    } else if (_gmls_ends_with(lower, "ing")) {
        lower = _gmls_replace_suffix(lower, "ing", "");
        var stem = lower;
        var has_vowel = false;
        for (var i = 1; i <= string_length(stem); i++) {
            if (_gmls_is_vowel(string_char_at(stem, i))) {
                has_vowel = true;
                break;
            }
        }
        if (!has_vowel) lower = prev_lower;
    }
    
    if (_gmls_ends_with(lower, "y") && string_length(lower) > 1) {
        var before_y = string_char_at(lower, string_length(lower) - 1);
        if (!_gmls_is_vowel(before_y)) {
            lower = _gmls_replace_suffix(lower, "y", "i");
        }
    }
    
    var suffixes2 = ["ational", "tional", "enci", "anci", "izer", "abli", "alli", "entli", "eli", "ousli", "ization", "ation", "ator", "alism", "iveness", "fulness", "ousness", "aliti", "iviti", "biliti", "logi"];
    var replacements2 = ["ate", "tion", "ence", "ance", "ize", "able", "al", "ent", "e", "ous", "ize", "ate", "ate", "al", "ive", "ful", "ous", "al", "ive", "ble", "log"];
    
    for (var i = 0; i < array_length(suffixes2); i++) {
        if (_gmls_ends_with(lower, suffixes2[i])) {
            var r1 = _gmls_get_r1(lower);
            if (string_length(r1) >= string_length(suffixes2[i])) {
                lower = _gmls_replace_suffix(lower, suffixes2[i], replacements2[i]);
                break;
            }
        }
    }
    
    var suffixes3 = ["icate", "ative", "alize", "iciti", "ical", "ful", "ness"];
    var replacements3 = ["ic", "", "al", "ic", "ic", "", ""];
    
    for (var i = 0; i < array_length(suffixes3); i++) {
        if (_gmls_ends_with(lower, suffixes3[i])) {
            var r1 = _gmls_get_r1(lower);
            if (string_length(r1) >= string_length(suffixes3[i])) {
                lower = _gmls_replace_suffix(lower, suffixes3[i], replacements3[i]);
                break;
            }
        }
    }
    
    var endings4 = ["al", "ance", "ence", "er", "ic", "able", "ible", "ant", "ement", "ment", "ent", "ion", "ou", "ism", "ate", "iti", "ous", "ive", "ize"];
    
    for (var i = 0; i < array_length(endings4); i++) {
        if (_gmls_ends_with(lower, endings4[i])) {
            var r2 = _gmls_get_r2(lower);
            if (string_length(r2) >= string_length(endings4[i])) {
                lower = _gmls_replace_suffix(lower, endings4[i], "");
                break;
            }
        }
    }
    
    if (_gmls_ends_with(lower, "ion")) {
        var r2 = _gmls_get_r2(lower);
        if (string_length(r2) >= 3) {
            var stem = string_copy(lower, 1, string_length(lower) - 3);
            var last = string_char_at(stem, string_length(stem));
            if (last == "s" || last == "t") {
                lower = stem;
            }
        }
    }
    
    if (_gmls_ends_with(lower, "e")) {
        var r2 = _gmls_get_r2(lower);
        var r1 = _gmls_get_r1(lower);
        if (string_length(r2) >= 1) {
            lower = _gmls_replace_suffix(lower, "e", "");
        } else if (string_length(r1) >= 1) {
            var stem = _gmls_replace_suffix(lower, "e", "");
            var last_consonant = false;
            var last_char = string_char_at(stem, string_length(stem));
            if (!_gmls_is_vowel(last_char)) {
                var prev_char = string_char_at(stem, string_length(stem) - 1);
                if (!_gmls_is_vowel(prev_char)) {
                    last_consonant = true;
                }
            }
            if (!last_consonant) {
                lower = stem;
            }
        }
    }
    
    if (_gmls_ends_with(lower, "l") && _gmls_get_r2(lower) != "") {
        var prev_char = string_char_at(lower, string_length(lower) - 1);
        if (prev_char == "l") {
            lower = _gmls_replace_suffix(lower, "l", "");
        }
    }
    
    if (string_length(lower) == 0) lower = original;
    
    return lower;
}

//  INITIALIZATION
function gmls_init() {
    if (!variable_global_exists("gmls") || global.gmls == undefined) {
        global.gmls = {
            // Core data structures
            inverted_index : ds_map_create(),   // word -> ds_map(doc_id -> tf)
            documents      : ds_map_create(),   // doc_id -> {id, text, metadata, word_count}
            word_stats     : ds_map_create(),   // word -> {total_freq, doc_freq}
            doc_count      : 0,
            
            // N‑gram index (character trigrams)
            ngram_index    : ds_map_create(),
            ngram_size     : 3,
            enable_ngrams  : true,
            
            // Configuration
            case_sensitive : false,
            enable_stemming: true,
            min_word_length: 2,
            stop_words     : ds_list_create(),
            
            // Scoring mode
            scoring        : "bm25",
            bm25_k1        : 1.2,
            bm25_b         : 0.75,
            
            // Performance
            max_doc_size   : 50000,
            cache_idf      : ds_map_create(),
            
            // Results
            last_results   : [],
            selected_result: -1
        };
        
        // Default stop words
        var _stop = ["a","an","and","are","as","at","be","by","for","from","has","he",
                     "in","is","it","its","of","on","that","the","to","was","were",
                     "will","with","i","you","we","they","this","that","these","those"];
        for (var i = 0; i < array_length(_stop); i++) {
            ds_list_add(global.gmls.stop_words, _stop[i]);
        }
    }
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

//  N‑GRAM INDEXING
function _gmls_index_ngrams(_text, _doc_id) {
    var _ls = global.gmls;
    if (!_ls.enable_ngrams) return;
    
    var _clean = "";
    var _len = string_length(_text);
    for (var i = 1; i <= _len; i++) {
        var _ch = string_char_at(_text, i);
        var _code = ord(_ch);
        if ((_code >= 48 && _code <= 57) ||
            (_code >= 65 && _code <= 90) ||
            (_code >= 97 && _code <= 122) ||
            _ch == " ") {
            _clean += _ch;
        } else {
            _clean += " ";
        }
    }
    if (!_ls.case_sensitive) _clean = string_lower(_clean);
    
    var _ngram_len = _ls.ngram_size;
    var _text_len = string_length(_clean);
    var _ngram_counts = ds_map_create();
    
    for (var i = 1; i <= _text_len - _ngram_len + 1; i++) {
        var _ngram = string_copy(_clean, i, _ngram_len);
        if (string_pos(" ", _ngram) == 0) {
            if (!ds_map_exists(_ngram_counts, _ngram))
                ds_map_add(_ngram_counts, _ngram, 0);
            ds_map_set(_ngram_counts, _ngram, ds_map_find_value(_ngram_counts, _ngram) + 1);
        }
    }
    
    var _ngram = ds_map_find_first(_ngram_counts);
    while (!is_undefined(_ngram)) {
        var _freq = ds_map_find_value(_ngram_counts, _ngram);
        if (!ds_map_exists(_ls.ngram_index, _ngram))
            ds_map_add(_ls.ngram_index, _ngram, ds_map_create());
        var _doc_map = ds_map_find_value(_ls.ngram_index, _ngram);
        ds_map_add(_doc_map, _doc_id, _freq);
        _ngram = ds_map_find_next(_ngram_counts, _ngram);
    }
    ds_map_destroy(_ngram_counts);
}

//  DOCUMENT ADDITION
function gmls_add_document(_id, _text, _metadata = undefined) {
    if (global.gmls == undefined) return false;
    var _ls = global.gmls;
    
    var _word_estimate = string_length(_text) / 6;
    if (_word_estimate > _ls.max_doc_size) {
        show_debug_message("GMLS warning: document " + string(_id) + " exceeds max_doc_size, truncating.");
        _text = string_copy(_text, 1, _ls.max_doc_size * 6);
    }
    
    if (is_undefined(_metadata)) {
        _metadata = { title: "", tags: [], timestamp: current_time };
    }
    
    ds_map_add(_ls.documents, _id, {
        id: _id,
        text: _text,
        metadata: _metadata,
        word_count: 0
    });
    
    var _words = _gmls_process_text(_text);
    var _doc_words = ds_map_create();
    
    for (var i = 0; i < array_length(_words); i++) {
        var _w = _words[i];
        if (!ds_map_exists(_doc_words, _w)) ds_map_add(_doc_words, _w, 0);
        ds_map_set(_doc_words, _w, ds_map_find_value(_doc_words, _w) + 1);
    }
    
    var _w = ds_map_find_first(_doc_words);
    while (!is_undefined(_w)) {
        var _freq = ds_map_find_value(_doc_words, _w);
        
        if (!ds_map_exists(_ls.inverted_index, _w))
            ds_map_add(_ls.inverted_index, _w, ds_map_create());
        var _docs_map = ds_map_find_value(_ls.inverted_index, _w);
        ds_map_add(_docs_map, _id, _freq);
        
        if (!ds_map_exists(_ls.word_stats, _w))
            ds_map_add(_ls.word_stats, _w, { total_frequency:0, document_frequency:0 });
        var _stats = ds_map_find_value(_ls.word_stats, _w);
        _stats.total_frequency += _freq;
        _stats.document_frequency++;
        
        _w = ds_map_find_next(_doc_words, _w);
    }
    
    var _doc = ds_map_find_value(_ls.documents, _id);
    _doc.word_count = ds_map_size(_doc_words);
    ds_map_destroy(_doc_words);
    _ls.doc_count++;
    
    if (_ls.enable_ngrams) _gmls_index_ngrams(_text, _id);
    
    return true;
}

function gmls_add_document_weighted(_id, _text, _metadata = undefined) {
    if (global.gmls == undefined) return false;
    if (is_undefined(_metadata)) _metadata = { title: "", tags: [], timestamp: current_time };
    
    var _searchable = _text + " ";
    if (_metadata.title != "") {
        _searchable += string_repeat(_metadata.title + " ", 3);
    }
    if (variable_struct_exists(_metadata, "tags") && is_array(_metadata.tags)) {
        for (var i = 0; i < array_length(_metadata.tags); i++) {
            _searchable += string_repeat(_metadata.tags[i] + " ", 2);
        }
    }
    if (variable_struct_exists(_metadata, "author")) _searchable += _metadata.author + " ";
    if (variable_struct_exists(_metadata, "description")) _searchable += _metadata.description + " ";
    
    return gmls_add_document(_id, _searchable, _metadata);
}

function gmls_add_document_enhanced(_id, _text, _metadata = undefined) {
    return gmls_add_document_weighted(_id, _text, _metadata);
}

//  SEARCH METHODS
function gmls_search(_query, _max_results = -1) {
    if (global.gmls == undefined) return [];
    var _ls = global.gmls;
    _gmls_clear_idf_cache();
    
    var _terms = _gmls_process_text(_query);
    if (array_length(_terms) == 0) return [];
    
    var _scores = ds_map_create();
    var _matches = ds_map_create();
    
    for (var i = 0; i < array_length(_terms); i++) {
        var _term = _terms[i];
        if (!ds_map_exists(_ls.inverted_index, _term)) continue;
        
        var _docs = ds_map_find_value(_ls.inverted_index, _term);
        var _doc_id = ds_map_find_first(_docs);
        while (!is_undefined(_doc_id)) {
            var _tf = ds_map_find_value(_docs, _doc_id);
            var _score = 0;
            
            if (_ls.scoring == "tfidf") {
                var _idf = _gmls_get_idf(_term);
                _score = _tf * _idf;
            } else {
                var _doc_len = ds_map_find_value(_ls.documents, _doc_id).word_count;
                var _avg_len = _gmls_total_word_freq() / max(1, _ls.doc_count);
                var _k1 = _ls.bm25_k1;
                var _b = _ls.bm25_b;
                var _idf = _gmls_get_idf(_term);
                var _tf_component = _tf * (_k1 + 1) / (_tf + _k1 * (1 - _b + _b * _doc_len / _avg_len));
                _score = _idf * _tf_component;
            }
            
            if (!ds_map_exists(_scores, _doc_id)) {
                ds_map_add(_scores, _doc_id, 0);
                ds_map_add(_matches, _doc_id, ds_list_create());
            }
            ds_map_set(_scores, _doc_id, ds_map_find_value(_scores, _doc_id) + _score);
            ds_list_add(ds_map_find_value(_matches, _doc_id), _term);
            
            _doc_id = ds_map_find_next(_docs, _doc_id);
        }
    }
    
    var _results = [];
    var _doc_id = ds_map_find_first(_scores);
    while (!is_undefined(_doc_id)) {
        var _doc = ds_map_find_value(_ls.documents, _doc_id);
        var _matched = ds_map_find_value(_matches, _doc_id);
        array_push(_results, {
            id: _doc_id,
            score: ds_map_find_value(_scores, _doc_id),
            document: _doc,
            matched_terms: _gmls_list_to_array(_matched),
            snippet: _gmls_generate_snippet(_doc.text, _terms)
        });
        _doc_id = ds_map_find_next(_scores, _doc_id);
    }
    
    var _did = ds_map_find_first(_matches);
    while (!is_undefined(_did)) {
        ds_list_destroy(ds_map_find_value(_matches, _did));
        _did = ds_map_find_next(_matches, _did);
    }
    ds_map_destroy(_scores);
    ds_map_destroy(_matches);
    
    array_sort(_results, function(a,b) { return b.score - a.score; });
    if (_max_results > 0 && array_length(_results) > _max_results)
        array_resize(_results, _max_results);
    
    _ls.last_results = _results;
    _ls.selected_result = -1;
    return _results;
}

function _gmls_similarity(_a, _b) {
    if (string_length(_a) == 0 || string_length(_b) == 0) return 0;
    var _set_a = ds_map_create();
    var _set_b = ds_map_create();
    for (var i = 1; i < string_length(_a); i++) {
        var _bg = string_char_at(_a, i) + string_char_at(_a, i+1);
        ds_map_add(_set_a, _bg, 0);
    }
    for (var i = 1; i < string_length(_b); i++) {
        var _bg = string_char_at(_b, i) + string_char_at(_b, i+1);
        ds_map_add(_set_b, _bg, 0);
    }
    var _intersect = 0;
    var _key = ds_map_find_first(_set_a);
    while (!is_undefined(_key)) {
        if (ds_map_exists(_set_b, _key)) _intersect++;
        _key = ds_map_find_next(_set_a, _key);
    }
    var _union = ds_map_size(_set_a) + ds_map_size(_set_b) - _intersect;
    ds_map_destroy(_set_a);
    ds_map_destroy(_set_b);
    return (_union == 0) ? 0 : _intersect / _union;
}

function gmls_fuzzy_search(_query, _max_results = 50, _threshold = 0.6) {
    if (global.gmls == undefined) return [];
    var _ls = global.gmls;
    var _terms = _gmls_process_text(_query);
    if (array_length(_terms) == 0) return [];
    
    var _scores = ds_map_create();
    var _word = ds_map_find_first(_ls.inverted_index);
    while (!is_undefined(_word)) {
        for (var i = 0; i < array_length(_terms); i++) {
            var _sim = _gmls_similarity(_word, _terms[i]);
            if (_sim >= _threshold) {
                var _docs = ds_map_find_value(_ls.inverted_index, _word);
                var _did = ds_map_find_first(_docs);
                while (!is_undefined(_did)) {
                    var _tf = ds_map_find_value(_docs, _did);
                    if (!ds_map_exists(_scores, _did))
                        ds_map_add(_scores, _did, 0);
                    ds_map_set(_scores, _did, ds_map_find_value(_scores, _did) + _tf * _sim);
                    _did = ds_map_find_next(_docs, _did);
                }
            }
        }
        _word = ds_map_find_next(_ls.inverted_index, _word);
    }
    
    var _results = [];
    var _did = ds_map_find_first(_scores);
    while (!is_undefined(_did)) {
        var _doc = ds_map_find_value(_ls.documents, _did);
        array_push(_results, {
            id: _did,
            score: ds_map_find_value(_scores, _did),
            document: _doc,
            snippet: _gmls_generate_snippet(_doc.text, _terms)
        });
        _did = ds_map_find_next(_scores, _did);
    }
    ds_map_destroy(_scores);
    array_sort(_results, function(a,b) { return b.score - a.score; });
    if (array_length(_results) > _max_results) array_resize(_results, _max_results);
    _ls.last_results = _results;
    return _results;
}

function gmls_search_prefix(_query, _max_results = -1) {
    if (global.gmls == undefined) return [];
    var _ls = global.gmls;
    var _qlow = string_lower(_query);
    var _scores = ds_map_create();
    var _word = ds_map_find_first(_ls.inverted_index);
    while (!is_undefined(_word)) {
        var _wlow = string_lower(_word);
        if (string_pos(_qlow, _wlow) == 1) {
            var _docs = ds_map_find_value(_ls.inverted_index, _word);
            var _did = ds_map_find_first(_docs);
            while (!is_undefined(_did)) {
                var _tf = ds_map_find_value(_docs, _did);
                if (!ds_map_exists(_scores, _did))
                    ds_map_add(_scores, _did, 0);
                ds_map_set(_scores, _did, ds_map_find_value(_scores, _did) + _tf);
                _did = ds_map_find_next(_docs, _did);
            }
        }
        _word = ds_map_find_next(_ls.inverted_index, _word);
    }
    
    var _results = [];
    var _did = ds_map_find_first(_scores);
    while (!is_undefined(_did)) {
        var _doc = ds_map_find_value(_ls.documents, _did);
        array_push(_results, {
            id: _did,
            score: ds_map_find_value(_scores, _did),
            document: _doc,
            snippet: _gmls_generate_snippet(_doc.text, [_query])
        });
        _did = ds_map_find_next(_scores, _did);
    }
    ds_map_destroy(_scores);
    array_sort(_results, function(a,b) { return b.score - a.score; });
    if (_max_results > 0 && array_length(_results) > _max_results)
        array_resize(_results, _max_results);
    _ls.last_results = _results;
    return _results;
}

function gmls_search_hybrid(_query, _max_results = -1) {
    var _exact = gmls_search(_query, _max_results);
    if (array_length(_exact) > 0 && string_length(_query) > 3)
        return _exact;
    var _prefix = gmls_search_prefix(_query, _max_results);
    var _merged = ds_map_create();
    for (var i = 0; i < array_length(_exact); i++) {
        ds_map_add(_merged, _exact[i].id, _exact[i]);
    }
    for (var i = 0; i < array_length(_prefix); i++) {
        var _id = _prefix[i].id;
        if (ds_map_exists(_merged, _id)) {
            var _existing = ds_map_find_value(_merged, _id);
            _existing.score += _prefix[i].score * 0.5;
        } else {
            ds_map_add(_merged, _id, _prefix[i]);
        }
    }
    var _results = [];
    var _id = ds_map_find_first(_merged);
    while (!is_undefined(_id)) {
        array_push(_results, ds_map_find_value(_merged, _id));
        _id = ds_map_find_next(_merged, _id);
    }
    ds_map_destroy(_merged);
    array_sort(_results, function(a,b) { return b.score - a.score; });
    if (_max_results > 0 && array_length(_results) > _max_results)
        array_resize(_results, _max_results);
    global.gmls.last_results = _results;
    return _results;
}

function gmls_search_ngrams(_query, _max_results = -1) {
    if (global.gmls == undefined) return [];
    var _ls = global.gmls;
    if (!_ls.enable_ngrams) return gmls_search(_query, _max_results);
    
    var _clean = "";
    for (var i = 1; i <= string_length(_query); i++) {
        var _ch = string_char_at(_query, i);
        if ((ord(_ch) >= 48 && ord(_ch) <= 57) ||
            (ord(_ch) >= 65 && ord(_ch) <= 90) ||
            (ord(_ch) >= 97 && ord(_ch) <= 122))
            _clean += _ch;
        else
            _clean += " ";
    }
    if (!_ls.case_sensitive) _clean = string_lower(_clean);
    var _qlen = string_length(_clean);
    var _query_ngrams = [];
    for (var i = 1; i <= _qlen - _ls.ngram_size + 1; i++) {
        var _ng = string_copy(_clean, i, _ls.ngram_size);
        if (string_pos(" ", _ng) == 0) array_push(_query_ngrams, _ng);
    }
    if (array_length(_query_ngrams) == 0) return [];
    
    var _scores = ds_map_create();
    for (var i = 0; i < array_length(_query_ngrams); i++) {
        var _ng = _query_ngrams[i];
        if (ds_map_exists(_ls.ngram_index, _ng)) {
            var _docs = ds_map_find_value(_ls.ngram_index, _ng);
            var _did = ds_map_find_first(_docs);
            while (!is_undefined(_did)) {
                var _freq = ds_map_find_value(_docs, _did);
                if (!ds_map_exists(_scores, _did))
                    ds_map_add(_scores, _did, 0);
                ds_map_set(_scores, _did, ds_map_find_value(_scores, _did) + _freq);
                _did = ds_map_find_next(_docs, _did);
            }
        }
    }
    var _results = [];
    var _did = ds_map_find_first(_scores);
    while (!is_undefined(_did)) {
        var _doc = ds_map_find_value(_ls.documents, _did);
        array_push(_results, {
            id: _did,
            score: ds_map_find_value(_scores, _did),
            document: _doc,
            snippet: _gmls_generate_snippet(_doc.text, [_query])
        });
        _did = ds_map_find_next(_scores, _did);
    }
    ds_map_destroy(_scores);
    array_sort(_results, function(a,b) { return b.score - a.score; });
    if (_max_results > 0 && array_length(_results) > _max_results)
        array_resize(_results, _max_results);
    _ls.last_results = _results;
    return _results;
}

//  DOCUMENT MANAGEMENT
function gmls_remove_document(_id) {
    if (global.gmls == undefined) return false;
    var _ls = global.gmls;
    if (!ds_map_exists(_ls.documents, _id)) return false;
    
    var _word = ds_map_find_first(_ls.inverted_index);
    while (!is_undefined(_word)) {
        var _docs = ds_map_find_value(_ls.inverted_index, _word);
        if (ds_map_exists(_docs, _id)) {
            var _freq = ds_map_find_value(_docs, _id);
            ds_map_delete(_docs, _id);
            var _stats = ds_map_find_value(_ls.word_stats, _word);
            _stats.total_frequency -= _freq;
            _stats.document_frequency--;
            if (_stats.document_frequency <= 0) {
                ds_map_delete(_ls.inverted_index, _word);
                ds_map_delete(_ls.word_stats, _word);
            }
        }
        _word = ds_map_find_next(_ls.inverted_index, _word);
    }
    
    if (_ls.enable_ngrams) {
        var _ng = ds_map_find_first(_ls.ngram_index);
        while (!is_undefined(_ng)) {
            var _docs = ds_map_find_value(_ls.ngram_index, _ng);
            if (ds_map_exists(_docs, _id)) {
                ds_map_delete(_docs, _id);
                if (ds_map_size(_docs) == 0) {
                    ds_map_delete(_ls.ngram_index, _ng);
                }
            }
            _ng = ds_map_find_next(_ls.ngram_index, _ng);
        }
    }
    
    ds_map_delete(_ls.documents, _id);
    _ls.doc_count--;
    return true;
}

function gmls_get_document(_id) {
    if (global.gmls == undefined) return undefined;
    if (ds_map_exists(global.gmls.documents, _id))
        return ds_map_find_value(global.gmls.documents, _id);
    return undefined;
}

function gmls_get_stats() {
    if (global.gmls == undefined) return undefined;
    var _ls = global.gmls;
    return {
        document_count: _ls.doc_count,
        unique_words: ds_map_size(_ls.inverted_index),
        total_word_occurrences: _gmls_total_word_freq(),
        ngram_count: ds_map_size(_ls.ngram_index),
        stemming_enabled: _ls.enable_stemming
    };
}

//  CONFIGURATION
function gmls_set_config(_case_sensitive, _enable_stemming, _min_word_length, _scoring = "bm25") {
    if (global.gmls == undefined) return;
    var _ls = global.gmls;
    _ls.case_sensitive = _case_sensitive;
    _ls.enable_stemming = _enable_stemming;
    _ls.min_word_length = _min_word_length;
    if (_scoring == "tfidf" || _scoring == "bm25") _ls.scoring = _scoring;
}

function gmls_set_bm25_params(_k1, _b) {
    if (global.gmls == undefined) return;
    global.gmls.bm25_k1 = _k1;
    global.gmls.bm25_b = _b;
}

function gmls_add_stop_word(_word) {
    if (global.gmls == undefined) return;
    var _ls = global.gmls;
    if (!_ls.case_sensitive) _word = string_lower(_word);
    ds_list_add(_ls.stop_words, _word);
}

//  PERSISTENCE
function gmls_save_to_string() {
    if (global.gmls == undefined) return "";
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
    if (global.gmls == undefined) gmls_init();
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

//  CLEAR & CLEANUP
function gmls_clear() {
    if (global.gmls == undefined) return;
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
    if (global.gmls == undefined) return;
    var _ls = global.gmls;
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
    global.gmls = undefined;
}