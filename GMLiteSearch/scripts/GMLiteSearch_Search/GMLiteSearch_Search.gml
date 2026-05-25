

//  SEARCH METHODS
function gmls_search(_query, _max_results = -1) {
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

//function gmls_search_faceted(_query, _max_results = -1, _return_facets = undefined) {
//    var _ls = global.gmls;
    
//    var _search_results = gmls_search(_query, -1);
    
//    var _doc_ids = [];
//    for (var i = 0; i < array_length(_search_results); i++) {
//        array_push(_doc_ids, _search_results[i].id);
//    }
    
//    var _filtered_ids = _gmls_apply_facet_filters(_doc_ids);
    
//    var _filtered_results = [];
//    var _id_to_result = ds_map_create();
    
//    for (var i = 0; i < array_length(_search_results); i++) {
//        var _res = _search_results[i];
//        ds_map_add(_id_to_result, _res.id, _res);
//    }
    
//    for (var i = 0; i < array_length(_filtered_ids); i++) {
//        var _id = _filtered_ids[i];
//        if (ds_map_exists(_id_to_result, _id)) {
//            array_push(_filtered_results, ds_map_find_value(_id_to_result, _id));
//        }
//    }
    
//    ds_map_destroy(_id_to_result);
    
//    array_sort(_filtered_results, function(a,b) { return b.score - a.score; });
    
//    if (_max_results > 0 && array_length(_filtered_results) > _max_results) {
//        array_resize(_filtered_results, _max_results);
//    }
    
//    var _facet_counts = {};
//    if (!is_undefined(_return_facets)) {
//        _facet_counts = gmls_get_facet_counts(_query, undefined, _return_facets);
//    } else if (array_length(_return_facets) > 0) {
//        _facet_counts = gmls_get_facet_counts(_query, undefined, _return_facets);
//    }
    
//    return {
//        results: _filtered_results,
//        facets: _facet_counts,
//        total: array_length(_filtered_ids),
//        filtered_from: array_length(_search_results)
//    };
//}

function gmls_search_faceted(_query, _max_results = -1, _return_facets = undefined) { // this should work for empty query inputs
    var _ls = global.gmls;
    
    var _doc_ids = [];
    
    if (string_length(_query) > 0) {
        var _search_results = gmls_search(_query, -1);
        for (var i = 0; i < array_length(_search_results); i++) {
            array_push(_doc_ids, _search_results[i].id);
        }
    } else {
        var _doc_id = ds_map_find_first(_ls.documents);
        while (!is_undefined(_doc_id)) {
            array_push(_doc_ids, _doc_id);
            _doc_id = ds_map_find_next(_ls.documents, _doc_id);
        }
    }
    
    var _filtered_ids = _gmls_apply_facet_filters(_doc_ids);
    
    var _filtered_results = [];
    for (var i = 0; i < array_length(_filtered_ids); i++) {
        var _id = _filtered_ids[i];
        var _doc = ds_map_find_value(_ls.documents, _id);
        
        var _score = 1.0;
        var _matched_terms = [];
        var _snippet = "";
        
        if (string_length(_query) > 0) {
            var _search_results = gmls_search(_query, -1);
            for (var j = 0; j < array_length(_search_results); j++) {
                if (_search_results[j].id == _id) {
                    _score = _search_results[j].score;
                    _matched_terms = _search_results[j].matched_terms;
                    _snippet = _search_results[j].snippet;
                    break;
                }
            }
        } else {
            _snippet = string_copy(_doc.text, 1, 200);
            if (string_length(_doc.text) > 200) _snippet += "...";
        }
        
        array_push(_filtered_results, {
            id: _id,
            score: _score,
            document: _doc,
            matched_terms: _matched_terms,
            snippet: _snippet
        });
    }
    
    array_sort(_filtered_results, function(a, b) { return b.score - a.score; });
    
    if (_max_results > 0 && array_length(_filtered_results) > _max_results) {
        array_resize(_filtered_results, _max_results);
    }
    
    var _facet_counts = {};
    if (!is_undefined(_return_facets)) {
        _facet_counts = gmls_get_facet_counts(_query, undefined, _return_facets);
    }
    
    return {
        results: _filtered_results,
        facets: _facet_counts,
        total: array_length(_filtered_ids),
        filtered_from: array_length(_doc_ids)
    };
}

function gmls_search_nearby(_lat, _lng, _radius, _unit = undefined, _query = "", _max_results = -1) {
    var _ls = global.gmls;
    if (is_undefined(_unit)) _unit = _ls.default_geo_unit;
    if (is_undefined(_ls.geo_index)) return [];
    
    var _cache_key = _gmls_geo_cache_key(_lat, _lng, _radius, _unit, _query);
    if (ds_map_exists(_ls.geo_radius_cache, _cache_key)) {
        return ds_map_find_value(_ls.geo_radius_cache, _cache_key);
    }
    
    var _candidates = [];
    
    if (string_length(_query) > 0) {
        var _search_results = gmls_search(_query, -1);
        for (var i = 0; i < array_length(_search_results); i++) {
            var _id = _search_results[i].id;
            if (ds_map_exists(_ls.geo_index, _id)) {
                array_push(_candidates, _id);
            }
        }
    } else {
        var _doc_id = ds_map_find_first(_ls.geo_index);
        while (!is_undefined(_doc_id)) {
            array_push(_candidates, _doc_id);
            _doc_id = ds_map_find_next(_ls.geo_index, _doc_id);
        }
    }
    
    var _results = [];
    
    for (var i = 0; i < array_length(_candidates); i++) {
        var _id = _candidates[i];
        var _geo = ds_map_find_value(_ls.geo_index, _id);
        var _dist = _gmls_haversine_distance(_lat, _lng, _geo.lat, _geo.lng, _unit);
        
        if (_dist <= _radius) {
            var _doc = ds_map_find_value(_ls.documents, _id);
            var _score = 1.0 / (1.0 + _dist / _radius);
            
            if (string_length(_query) > 0) {
                var _search_score = 0;
                var _search_results = gmls_search(_query, -1);
                for (var j = 0; j < array_length(_search_results); j++) {
                    if (_search_results[j].id == _id) {
                        _search_score = _search_results[j].score;
                        break;
                    }
                }
                _score = (_score * 0.4) + (_search_score * 0.6);
            }
            
            array_push(_results, {
                id: _id,
                distance: _dist,
                distance_unit: _unit,
                score: _score,
                document: _doc,
                location: { lat: _geo.lat, lng: _geo.lng },
                geohash: _geo.geohash
            });
        }
    }
    
    array_sort(_results, function(a, b) { return b.score - a.score; });
    
    if (_max_results > 0 && array_length(_results) > _max_results) {
        array_resize(_results, _max_results);
    }
    
    ds_map_add(_ls.geo_radius_cache, _cache_key, _results);
    return _results;
}

function gmls_search_box(_min_lat, _min_lng, _max_lat, _max_lng, _query = "", _max_results = -1) {
    var _ls = global.gmls;
    if (is_undefined(_ls.geo_index)) return [];
    
    var _candidates = [];
    
    if (string_length(_query) > 0) {
        var _search_results = gmls_search(_query, -1);
        for (var i = 0; i < array_length(_search_results); i++) {
            var _id = _search_results[i].id;
            if (ds_map_exists(_ls.geo_index, _id)) {
                array_push(_candidates, _id);
            }
        }
    } else {
        var _doc_id = ds_map_find_first(_ls.geo_index);
        while (!is_undefined(_doc_id)) {
            array_push(_candidates, _doc_id);
            _doc_id = ds_map_find_next(_ls.geo_index, _doc_id);
        }
    }
    
    var _results = [];
    
    for (var i = 0; i < array_length(_candidates); i++) {
        var _id = _candidates[i];
        var _geo = ds_map_find_value(_ls.geo_index, _id);
        
        if (_geo.lat >= _min_lat && _geo.lat <= _max_lat &&
            _geo.lng >= _min_lng && _geo.lng <= _max_lng) {
            
            var _doc = ds_map_find_value(_ls.documents, _id);
            var _score = 1.0;
            
            if (string_length(_query) > 0) {
                var _search_results = gmls_search(_query, -1);
                for (var j = 0; j < array_length(_search_results); j++) {
                    if (_search_results[j].id == _id) {
                        _score = _search_results[j].score;
                        break;
                    }
                }
            }
            
            array_push(_results, {
                id: _id,
                score: _score,
                document: _doc,
                location: { lat: _geo.lat, lng: _geo.lng },
                geohash: _geo.geohash
            });
        }
    }
    
    array_sort(_results, function(a, b) { return b.score - a.score; });
    
    if (_max_results > 0 && array_length(_results) > _max_results) {
        array_resize(_results, _max_results);
    }
    
    return _results;
}

function gmls_search_by_geohash(_geohash_prefix, _query = "", _max_results = -1) {
    var _ls = global.gmls;
    if (is_undefined(_ls.geo_index)) return [];
    
    var _candidates = [];
    
    if (string_length(_query) > 0) {
        var _search_results = gmls_search(_query, -1);
        for (var i = 0; i < array_length(_search_results); i++) {
            var _id = _search_results[i].id;
            if (ds_map_exists(_ls.geo_index, _id)) {
                array_push(_candidates, _id);
            }
        }
    } else {
        var _doc_id = ds_map_find_first(_ls.geo_index);
        while (!is_undefined(_doc_id)) {
            array_push(_candidates, _doc_id);
            _doc_id = ds_map_find_next(_ls.geo_index, _doc_id);
        }
    }
    
    var _results = [];
    
    for (var i = 0; i < array_length(_candidates); i++) {
        var _id = _candidates[i];
        var _geo = ds_map_find_value(_ls.geo_index, _id);
        
        if (string_pos(_geohash_prefix, _geo.geohash) == 1) {
            var _doc = ds_map_find_value(_ls.documents, _id);
            var _score = 1.0;
            
            if (string_length(_query) > 0) {
                var _search_results = gmls_search(_query, -1);
                for (var j = 0; j < array_length(_search_results); j++) {
                    if (_search_results[j].id == _id) {
                        _score = _search_results[j].score;
                        break;
                    }
                }
            }
            
            array_push(_results, {
                id: _id,
                score: _score,
                document: _doc,
                location: { lat: _geo.lat, lng: _geo.lng },
                geohash: _geo.geohash
            });
        }
    }
    
    array_sort(_results, function(a, b) { return b.score - a.score; });
    
    if (_max_results > 0 && array_length(_results) > _max_results) {
        array_resize(_results, _max_results);
    }
    
    return _results;
}

function gmls_search_ltr(_query, _max_results = -1) {
    var _ls = global.gmls;
    
    var _feature_count = ds_map_size(_ls.ltr_features);
    //show_debug_message("LTR Search: " + _query + " (enabled: " + string(_ls.ltr_enabled) + ", features: " + string(_feature_count) + ")");
    
    if (!_ls.ltr_enabled || _feature_count == 0) {
        //show_debug_message("  Using BM25 fallback");
        var _fallback = gmls_search(_query, _max_results);
        for (var i = 0; i < array_length(_fallback); i++) {
            _fallback[i].ltr_score = _fallback[i].score;
            _fallback[i].original_score = _fallback[i].score;
        }
        return _fallback;
    }
    
    var _base_results = gmls_search(_query, -1);
    //show_debug_message("  Base results: " + string(array_length(_base_results)));
    
    for (var i = 0; i < array_length(_base_results); i++) {
        var _features = _gmls_extract_features(_base_results[i].id, _query, _base_results[i]);
        var _ltr_score = _gmls_linear_rank_score(_features);
        _base_results[i].ltr_score = _ltr_score;
        _base_results[i].original_score = _base_results[i].score;
        _base_results[i].score = _ltr_score;
        
        if (i < 3) {
            //show_debug_message("    " + _base_results[i].id + ": bm25=" + string(_base_results[i].original_score) + ", ltr=" + string(_ltr_score));
        }
    }
    
    array_sort(_base_results, function(a, b) { return b.score - a.score; });
    
    if (_max_results > 0 && array_length(_base_results) > _max_results) {
        array_resize(_base_results, _max_results);
    }
    
    for (var i = 0; i < array_length(_base_results); i++) {
        var _id = _base_results[i].id;
        var _impressions = ds_map_exists(_ls.ltr_impressions, _id) ? ds_map_find_value(_ls.ltr_impressions, _id) : 0;
        ds_map_add(_ls.ltr_impressions, _id, _impressions + 1);
    }
    
    _ls.last_results = _base_results;
    return _base_results;
}

function gmls_search_with_understanding(_query, _max_results = -1) {
    var _ls = global.gmls;
    
    var _correction = gmls_correct_query(_query);
    var _search_query = _correction.corrected;
    
    if (_correction.changed) {
        //show_debug_message("[SPELL] '" + _correction.original + "' -> '" + _correction.corrected + "'");
    }
    
    var _suggestions = [];
    var _terms = _gmls_process_text(_search_query);
    if (array_length(_terms) > 0) {
        var _last_term = _terms[array_length(_terms) - 1];
        if (string_length(_last_term) >= _ls.min_prefix_length) {
            _suggestions = gmls_get_suggestions(_last_term);
            //show_debug_message("[SUGGEST] For '" + _last_term + "': " + string(_suggestions));
        }
    }
    
    var _results = gmls_search(_search_query, _max_results);
    
    var _related = gmls_get_related_queries(_search_query);
    
    if (string_length(_search_query) > 0 && _search_query != " ") {
        gmls_log_query(_search_query, array_length(_results));
    }
    
    if (is_undefined(_suggestions)) _suggestions = [];
    //show_debug_message("[DEBUG] Returning suggestions: " + string(_suggestions));
	
    var _result_struct = {
        original_query: _query,
        corrected_query: _search_query,
        was_corrected: _correction.changed,
        results: _results,
        suggestions: _suggestions,
        related_queries: _related,
        result_count: array_length(_results)
    };
    
    return _result_struct;
}

function gmls_search_nearby_2d(_x, _y, _radius, _query = "", _max_results = -1) {
    var _ls = global.gmls;
    if (is_undefined(_ls.geo_index)) return [];
    
    var _candidates = [];
    var _doc_id = ds_map_find_first(_ls.geo_index);
    while (!is_undefined(_doc_id)) {
        var _loc = ds_map_find_value(_ls.geo_index, _doc_id);
        if (_loc.type == "2d" || _loc.type == "grid") {
            array_push(_candidates, _doc_id);
        }
        _doc_id = ds_map_find_next(_ls.geo_index, _doc_id);
    }
    
    if (string_length(_query) > 0) {
        var _search_results = gmls_search(_query, -1);
        var _search_map = ds_map_create();
        for (var i = 0; i < array_length(_search_results); i++) {
            ds_map_add(_search_map, _search_results[i].id, true);
        }
        var _filtered = [];
        for (var i = 0; i < array_length(_candidates); i++) {
            if (ds_map_exists(_search_map, _candidates[i])) {
                array_push(_filtered, _candidates[i]);
            }
        }
        _candidates = _filtered;
        ds_map_destroy(_search_map);
    }
    
    var _results = [];
    for (var i = 0; i < array_length(_candidates); i++) {
        var _id = _candidates[i];
        var _loc = ds_map_find_value(_ls.geo_index, _id);
        var _dist = _gmls_distance_2d(_x, _y, _loc.x, _loc.y);
        
        if (_dist <= _radius) {
            var _doc = ds_map_find_value(_ls.documents, _id);
            var _score = 1.0 / (1.0 + _dist / _radius);
            if (string_length(_query) > 0) {
                var _search_results = gmls_search(_query, -1);
                for (var j = 0; j < array_length(_search_results); j++) {
                    if (_search_results[j].id == _id) {
                        _score = (_score * 0.4) + (_search_results[j].score * 0.6);
                        break;
                    }
                }
            }
            array_push(_results, {
                id: _id,
                distance: _dist,
                score: _score,
                document: _doc,
                position: { x: _loc.x, y: _loc.y }
            });
        }
    }
    
    array_sort(_results, function(a, b) { return b.score - a.score; });
    if (_max_results > 0 && array_length(_results) > _max_results) {
        array_resize(_results, _max_results);
    }
    return _results;
}

function gmls_search_nearby_3d(_x, _y, _z, _radius, _query = "", _max_results = -1) {
    var _ls = global.gmls;
    if (is_undefined(_ls.geo_index)) return [];
    
    var _candidates = [];
    var _doc_id = ds_map_find_first(_ls.geo_index);
    while (!is_undefined(_doc_id)) {
        var _loc = ds_map_find_value(_ls.geo_index, _doc_id);
        if (_loc.type == "3d") {
            array_push(_candidates, _doc_id);
        }
        _doc_id = ds_map_find_next(_ls.geo_index, _doc_id);
    }
    
    if (string_length(_query) > 0) {
        var _search_results = gmls_search(_query, -1);
        var _search_map = ds_map_create();
        for (var i = 0; i < array_length(_search_results); i++) {
            ds_map_add(_search_map, _search_results[i].id, true);
        }
        var _filtered = [];
        for (var i = 0; i < array_length(_candidates); i++) {
            if (ds_map_exists(_search_map, _candidates[i])) {
                array_push(_filtered, _candidates[i]);
            }
        }
        _candidates = _filtered;
        ds_map_destroy(_search_map);
    }
    
    var _results = [];
    for (var i = 0; i < array_length(_candidates); i++) {
        var _id = _candidates[i];
        var _loc = ds_map_find_value(_ls.geo_index, _id);
        var _dist = _gmls_distance_3d(_x, _y, _z, _loc.x, _loc.y, _loc.z);
        
        if (_dist <= _radius) {
            var _doc = ds_map_find_value(_ls.documents, _id);
            var _score = 1.0 / (1.0 + _dist / _radius);
            if (string_length(_query) > 0) {
                var _search_results = gmls_search(_query, -1);
                for (var j = 0; j < array_length(_search_results); j++) {
                    if (_search_results[j].id == _id) {
                        _score = (_score * 0.4) + (_search_results[j].score * 0.6);
                        break;
                    }
                }
            }
            array_push(_results, {
                id: _id,
                distance: _dist,
                score: _score,
                document: _doc,
                position: { x: _loc.x, y: _loc.y, z: _loc.z }
            });
        }
    }
    
    array_sort(_results, function(a, b) { return b.score - a.score; });
    if (_max_results > 0 && array_length(_results) > _max_results) {
        array_resize(_results, _max_results);
    }
    return _results;
}

function gmls_search_nearby_grid(_x, _y, _radius, _cell_size = 100, _query = "", _max_results = -1) {
    var _ls = global.gmls;
    if (is_undefined(_ls.geo_index) || !variable_struct_exists(_ls, "cell_index")) return [];
    
    var _min_cell_x = floor((_x - _radius) / _cell_size);
    var _max_cell_x = floor((_x + _radius) / _cell_size);
    var _min_cell_y = floor((_y - _radius) / _cell_size);
    var _max_cell_y = floor((_y + _radius) / _cell_size);
    
    var _candidates = [];
    var _seen = ds_map_create();
    
    for (var cx = _min_cell_x; cx <= _max_cell_x; cx++) {
        for (var cy = _min_cell_y; cy <= _max_cell_y; cy++) {
            var _cell_key = string(cx) + "," + string(cy);
            if (ds_map_exists(_ls.cell_index, _cell_key)) {
                var _cell_list = ds_map_find_value(_ls.cell_index, _cell_key);
                for (var i = 0; i < ds_list_size(_cell_list); i++) {
                    var _id = ds_list_find_value(_cell_list, i);
                    if (!ds_map_exists(_seen, _id)) {
                        ds_map_add(_seen, _id, true);
                        array_push(_candidates, _id);
                    }
                }
            }
        }
    }
    ds_map_destroy(_seen);
    
    if (string_length(_query) > 0) {
        var _search_results = gmls_search(_query, -1);
        var _search_map = ds_map_create();
        for (var i = 0; i < array_length(_search_results); i++) {
            ds_map_add(_search_map, _search_results[i].id, true);
        }
        var _filtered = [];
        for (var i = 0; i < array_length(_candidates); i++) {
            if (ds_map_exists(_search_map, _candidates[i])) {
                array_push(_filtered, _candidates[i]);
            }
        }
        _candidates = _filtered;
        ds_map_destroy(_search_map);
    }
    
    var _results = [];
    for (var i = 0; i < array_length(_candidates); i++) {
        var _id = _candidates[i];
        var _loc = ds_map_find_value(_ls.geo_index, _id);
        var _dist = _gmls_distance_2d(_x, _y, _loc.x, _loc.y);
        
        if (_dist <= _radius) {
            var _doc = ds_map_find_value(_ls.documents, _id);
            var _score = 1.0 / (1.0 + _dist / _radius);
            array_push(_results, {
                id: _id,
                distance: _dist,
                score: _score,
                document: _doc,
                position: { x: _loc.x, y: _loc.y },
                cell: _loc.cell_key
            });
        }
    }
    
    array_sort(_results, function(a, b) { return b.score - a.score; });
    if (_max_results > 0 && array_length(_results) > _max_results) {
        array_resize(_results, _max_results);
    }
    return _results;
}

function gmls_search_with_snippets(_query, _max_results = -1, _snippet_options = undefined) {
    var _results = gmls_search(_query, _max_results);
    
    for (var i = 0; i < array_length(_results); i++) {
        _results[i].snippet = gmls_generate_advanced_snippet(_results[i].id, _query, _snippet_options);
        _results[i].highlighted_title = "";
        
        var _doc = _results[i].document;
        if (!is_undefined(_doc.metadata) && variable_struct_exists(_doc.metadata, "title")) {
            var _terms = _gmls_process_text(_query);
            var _phrases = _gmls_extract_phrases(_query);
            var _cfg = global.gmls.snippet_config;
            _results[i].highlighted_title = _gmls_highlight_text(_doc.metadata.title, _terms, _phrases, _cfg);
        }
    }
    
    return _results;
}